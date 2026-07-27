from __future__ import annotations

import csv
import json
import os
import shutil
import subprocess
import threading
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import psutil
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.responses import FileResponse, PlainTextResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

CONTROL_ROOT = Path(os.getenv("CONTROL_ROOT", Path(__file__).resolve().parents[1]))
FRONTEND_DIR = CONTROL_ROOT / "frontend"
ENV_FILE = Path(os.getenv("ARMA_ENV_FILE", "/etc/arma3/arma3.env"))
CTL = CONTROL_ROOT / "scripts" / "arma3ctl"
JOB_DIR = Path(os.getenv("ARMA_PANEL_JOB_DIR", "/var/lib/arma3-panel/jobs"))
SERVER_UNIT = "arma3-server.service"

ACTIONS = {
    "start": "Server starten",
    "stop": "Server stoppen",
    "restart": "Server neu starten",
    "update-server": "Server aktualisieren",
    "update-mods": "Mods aktualisieren",
    "update-all": "Server und Mods aktualisieren",
    "backup": "Backup erstellen",
    "sync-keys": "Mod-Keys synchronisieren",
    "doctor": "Diagnose ausführen",
}

app = FastAPI(
    title="TF133 Arma 3 Control",
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
)
app.mount("/assets", StaticFiles(directory=FRONTEND_DIR), name="assets")

_job_guard = threading.Lock()
_active_job_id: str | None = None


class ActionResponse(BaseModel):
    job_id: str
    status: str
    action: str


def require_same_origin(request: Request) -> None:
    """Reject browser requests initiated by another site.

    Requests from command-line clients commonly omit these headers and remain
    supported. Nginx Basic Auth is not a CSRF defence because browsers can send
    cached credentials with a forged form submission.
    """
    fetch_site = request.headers.get("sec-fetch-site", "").lower()
    if fetch_site == "cross-site":
        raise HTTPException(status_code=403, detail="Cross-Site-Aktion abgelehnt")

    source = request.headers.get("origin") or request.headers.get("referer")
    if not source:
        return
    forwarded_proto = request.headers.get("x-forwarded-proto", request.url.scheme)
    forwarded_host = request.headers.get("x-forwarded-host") or request.headers.get("host")
    if not forwarded_host:
        raise HTTPException(status_code=403, detail="Anfrageursprung nicht prüfbar")
    expected = f"{forwarded_proto}://{forwarded_host}".rstrip("/")
    if not source.rstrip("/").startswith(f"{expected}/") and source.rstrip("/") != expected:
        raise HTTPException(status_code=403, detail="Fremder Anfrageursprung")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    if not ENV_FILE.exists():
        return values
    for raw_line in ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def run_command(command: list[str], timeout: int = 10) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
        env={**os.environ, "LANG": "C.UTF-8"},
    )


def service_state() -> dict[str, Any]:
    active = run_command(["systemctl", "is-active", SERVER_UNIT], timeout=4)
    enabled = run_command(["systemctl", "is-enabled", SERVER_UNIT], timeout=4)
    show = run_command(
        [
            "systemctl",
            "show",
            SERVER_UNIT,
            "--property=MainPID,SubState,ActiveState,ActiveEnterTimestampMonotonic",
        ],
        timeout=4,
    )
    props: dict[str, str] = {}
    for line in show.stdout.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            props[key] = value

    pid = int(props.get("MainPID", "0") or 0)
    process: dict[str, Any] = {"pid": pid, "cpu_percent": None, "memory_bytes": None}
    if pid > 0:
        try:
            proc = psutil.Process(pid)
            process.update(
                {
                    "cpu_percent": proc.cpu_percent(interval=0.05),
                    "memory_bytes": proc.memory_info().rss,
                    "started_at": datetime.fromtimestamp(
                        proc.create_time(), tz=timezone.utc
                    ).isoformat(),
                }
            )
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    return {
        "active": active.stdout.strip() == "active",
        "active_state": props.get("ActiveState", active.stdout.strip() or "unknown"),
        "sub_state": props.get("SubState", "unknown"),
        "enabled": enabled.stdout.strip(),
        "process": process,
    }


def disk_state(path: str) -> dict[str, int | str]:
    target = path if Path(path).exists() else "/"
    usage = shutil.disk_usage(target)
    return {
        "path": target,
        "total": usage.total,
        "used": usage.used,
        "free": usage.free,
    }


def job_path(job_id: str) -> Path:
    return JOB_DIR / f"{job_id}.json"


def log_path(job_id: str) -> Path:
    return JOB_DIR / f"{job_id}.log"


def write_job(job: dict[str, Any]) -> None:
    JOB_DIR.mkdir(parents=True, exist_ok=True)
    temp = job_path(job["id"]).with_suffix(".tmp")
    temp.write_text(json.dumps(job, ensure_ascii=False, indent=2), encoding="utf-8")
    temp.replace(job_path(job["id"]))


def read_job(job_id: str) -> dict[str, Any]:
    path = job_path(job_id)
    if not path.exists():
        raise HTTPException(status_code=404, detail="Auftrag nicht gefunden")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=500, detail="Auftragsstatus beschädigt") from exc


def execute_job(job_id: str, action: str) -> None:
    global _active_job_id
    job = read_job(job_id)
    job.update({"status": "running", "started_at": utc_now()})
    write_job(job)

    command = ["sudo", "-n", str(CTL), action]
    try:
        with log_path(job_id).open("w", encoding="utf-8") as output:
            output.write(f"$ {' '.join(command)}\n\n")
            output.flush()
            result = subprocess.run(
                command,
                stdout=output,
                stderr=subprocess.STDOUT,
                text=True,
                check=False,
                env={**os.environ, "LANG": "C.UTF-8"},
            )
        job["exit_code"] = result.returncode
        job["status"] = "succeeded" if result.returncode == 0 else "failed"
    except Exception as exc:  # noqa: BLE001 - error must be persisted for the dashboard
        with log_path(job_id).open("a", encoding="utf-8") as output:
            output.write(f"\nInterner Fehler: {type(exc).__name__}: {exc}\n")
        job.update({"status": "failed", "exit_code": -1, "error": str(exc)})
    finally:
        job["finished_at"] = utc_now()
        write_job(job)
        with _job_guard:
            if _active_job_id == job_id:
                _active_job_id = None


@app.on_event("startup")
def prepare_state() -> None:
    JOB_DIR.mkdir(parents=True, exist_ok=True)
    for path in JOB_DIR.glob("*.json"):
        try:
            job = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        if job.get("status") in {"queued", "running"}:
            job["status"] = "interrupted"
            job["finished_at"] = utc_now()
            write_job(job)


@app.get("/")
def index() -> FileResponse:
    return FileResponse(FRONTEND_DIR / "index.html")


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/status")
def status() -> dict[str, Any]:
    env = load_env()
    server_dir = env.get("SERVER_DIR", "/home/arma3/server")
    mods_file = Path(env.get("MODS_FILE", "/etc/arma3/mods.csv"))
    mod_total = 0
    mod_installed = 0
    if mods_file.exists():
        with mods_file.open(encoding="utf-8", newline="") as handle:
            for row in csv.DictReader(handle):
                if row.get("enabled") != "1":
                    continue
                mod_total += 1
                target = row.get("target", "")
                if target and (Path(server_dir) / "mods" / target).is_dir():
                    mod_installed += 1

    return {
        "timestamp": utc_now(),
        "service": service_state(),
        "host": {
            "cpu_percent": psutil.cpu_percent(interval=0.1),
            "memory": dict(psutil.virtual_memory()._asdict()),
            "load_average": os.getloadavg() if hasattr(os, "getloadavg") else None,
            "boot_time": datetime.fromtimestamp(
                psutil.boot_time(), tz=timezone.utc
            ).isoformat(),
        },
        "disk": disk_state(server_dir),
        "mods": {"installed": mod_installed, "total": mod_total},
        "active_job_id": _active_job_id,
    }


@app.get("/api/mods")
def mods() -> dict[str, Any]:
    env = load_env()
    server_dir = Path(env.get("SERVER_DIR", "/home/arma3/server"))
    mods_file = Path(env.get("MODS_FILE", "/etc/arma3/mods.csv"))
    if not mods_file.exists():
        raise HTTPException(status_code=500, detail=f"Modliste fehlt: {mods_file}")

    entries: list[dict[str, Any]] = []
    with mods_file.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            target_path = server_dir / "mods" / row["target"]
            size = None
            if target_path.is_dir():
                result = run_command(["du", "-sb", str(target_path)], timeout=20)
                if result.returncode == 0 and result.stdout:
                    try:
                        size = int(result.stdout.split()[0])
                    except (ValueError, IndexError):
                        size = None
            entries.append(
                {
                    **row,
                    "enabled": row.get("enabled") == "1",
                    "installed": target_path.is_dir(),
                    "size_bytes": size,
                }
            )
    return {"mods": entries}


@app.get("/api/logs", response_class=PlainTextResponse)
def logs(lines: int = Query(default=200, ge=20, le=2000)) -> str:
    result = run_command(
        [
            "journalctl",
            "-u",
            SERVER_UNIT,
            "-n",
            str(lines),
            "--no-pager",
            "-o",
            "short-iso",
        ],
        timeout=15,
    )
    if result.returncode not in (0, 1):
        raise HTTPException(status_code=500, detail=result.stderr.strip() or "Logabruf fehlgeschlagen")
    return result.stdout or "Noch keine Serverlogs vorhanden.\n"


@app.post("/api/actions/{action}", response_model=ActionResponse, status_code=202)
def action(action: str, request: Request) -> ActionResponse:
    global _active_job_id
    require_same_origin(request)
    if action not in ACTIONS:
        raise HTTPException(status_code=404, detail="Unbekannte Aktion")
    if not CTL.is_file():
        raise HTTPException(status_code=500, detail=f"Steuerscript fehlt: {CTL}")

    with _job_guard:
        if _active_job_id is not None:
            raise HTTPException(
                status_code=409,
                detail=f"Es läuft bereits ein Auftrag: {_active_job_id}",
            )
        job_id = uuid.uuid4().hex[:12]
        _active_job_id = job_id
        job = {
            "id": job_id,
            "action": action,
            "label": ACTIONS[action],
            "status": "queued",
            "created_at": utc_now(),
            "started_at": None,
            "finished_at": None,
            "exit_code": None,
        }
        write_job(job)
        thread = threading.Thread(target=execute_job, args=(job_id, action), daemon=True)
        thread.start()

    return ActionResponse(job_id=job_id, status="queued", action=action)


@app.get("/api/jobs")
def jobs(limit: int = Query(default=20, ge=1, le=100)) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    if JOB_DIR.exists():
        for path in sorted(JOB_DIR.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
            try:
                entries.append(json.loads(path.read_text(encoding="utf-8")))
            except json.JSONDecodeError:
                continue
            if len(entries) >= limit:
                break
    return {"jobs": entries, "active_job_id": _active_job_id}


@app.get("/api/jobs/{job_id}")
def job(job_id: str) -> dict[str, Any]:
    if not job_id.isalnum():
        raise HTTPException(status_code=400, detail="Ungültige Auftrags-ID")
    return read_job(job_id)


@app.get("/api/jobs/{job_id}/log", response_class=PlainTextResponse)
def job_log(job_id: str, tail: int = Query(default=500, ge=20, le=5000)) -> str:
    if not job_id.isalnum():
        raise HTTPException(status_code=400, detail="Ungültige Auftrags-ID")
    path = log_path(job_id)
    if not path.exists():
        return "Noch keine Ausgabe vorhanden.\n"
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    return "\n".join(lines[-tail:]) + "\n"
