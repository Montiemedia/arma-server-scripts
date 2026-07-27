const state = {
  activeJobId: null,
  activeTab: "overview",
  jobPoll: null,
};

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => [...document.querySelectorAll(selector)];

function formatBytes(value) {
  if (value === null || value === undefined || Number.isNaN(Number(value))) return "–";
  const units = ["B", "KB", "MB", "GB", "TB"];
  let number = Number(value);
  let index = 0;
  while (number >= 1024 && index < units.length - 1) {
    number /= 1024;
    index += 1;
  }
  return `${number.toLocaleString("de-DE", { maximumFractionDigits: index > 1 ? 1 : 0 })} ${units[index]}`;
}

function formatDate(value) {
  if (!value) return "–";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "–";
  return date.toLocaleString("de-DE");
}

function badgeClass(status) {
  if (["succeeded", "active", "installed"].includes(status)) return "badge badge-ok";
  if (["failed", "inactive", "missing"].includes(status)) return "badge badge-danger";
  if (["queued", "running", "interrupted"].includes(status)) return "badge badge-warning";
  return "badge badge-neutral";
}

async function api(path, options = {}) {
  const response = await fetch(path, {
    cache: "no-store",
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });
  const contentType = response.headers.get("content-type") || "";
  const data = contentType.includes("application/json") ? await response.json() : await response.text();
  if (!response.ok) {
    const detail = typeof data === "object" ? data.detail : data;
    throw new Error(detail || `HTTP ${response.status}`);
  }
  return data;
}

function setText(selector, value) {
  const node = $(selector);
  if (node) node.textContent = value;
}

function setActionsDisabled(disabled) {
  $$('[data-action]').forEach((button) => { button.disabled = disabled; });
}

async function loadStatus() {
  try {
    const data = await api("/api/status");
    const active = data.service.active;
    const serviceBadge = $("#serviceBadge");
    serviceBadge.className = active ? "badge badge-ok" : "badge badge-danger";
    serviceBadge.textContent = active ? "Server läuft" : "Server gestoppt";

    setText("#lastUpdate", `Aktualisiert ${new Date().toLocaleTimeString("de-DE")}`);
    setText("#serviceState", active ? "Aktiv" : "Inaktiv");
    setText("#serviceDetail", `${data.service.active_state} / ${data.service.sub_state}`);

    const process = data.service.process || {};
    setText("#processPid", process.pid ? `PID ${process.pid}` : "Kein Prozess");
    setText("#processMemory", process.memory_bytes ? `${formatBytes(process.memory_bytes)} RAM` : "systemd meldet keinen Prozess");

    setText("#hostCpu", `${Number(data.host.cpu_percent).toLocaleString("de-DE", { maximumFractionDigits: 1 })} %`);
    const load = data.host.load_average || [];
    setText("#hostLoad", load.length ? `Load ${load.map((item) => Number(item).toFixed(2)).join(" / ")}` : "Load Average nicht verfügbar");

    const memory = data.host.memory || {};
    setText("#hostMemory", `${Number(memory.percent || 0).toLocaleString("de-DE", { maximumFractionDigits: 1 })} %`);
    setText("#hostMemoryDetail", `${formatBytes(memory.used)} von ${formatBytes(memory.total)}`);

    const diskPercent = data.disk.total ? (data.disk.used / data.disk.total) * 100 : 0;
    setText("#diskUsage", `${diskPercent.toLocaleString("de-DE", { maximumFractionDigits: 1 })} %`);
    setText("#diskDetail", `${formatBytes(data.disk.free)} frei auf ${data.disk.path}`);
    setText("#modCount", `${data.mods.installed} / ${data.mods.total}`);

    state.activeJobId = data.active_job_id;
    setActionsDisabled(Boolean(state.activeJobId));
    setText("#activeJob", state.activeJobId ? `Auftrag ${state.activeJobId} läuft` : "Kein Auftrag aktiv");
    if (state.activeJobId) pollJob(state.activeJobId);
  } catch (error) {
    const badge = $("#serviceBadge");
    badge.className = "badge badge-danger";
    badge.textContent = "Panel nicht erreichbar";
    setText("#lastUpdate", error.message);
  }
}

async function runAction(action) {
  const labels = {
    start: "Server starten",
    stop: "Server stoppen",
    restart: "Server neu starten",
    "update-server": "Serverdateien aktualisieren",
    "update-mods": "alle aktivierten Workshop-Mods aktualisieren",
    "update-all": "Server und Mods vollständig aktualisieren",
    backup: "Backup erstellen",
    "sync-keys": "Mod-Keys synchronisieren",
    doctor: "Diagnose ausführen",
  };
  const disruptive = ["stop", "restart", "update-server", "update-mods", "update-all"];
  if (disruptive.includes(action) && !window.confirm(`${labels[action]}? Laufende Spielsitzungen können beendet werden.`)) return;

  const notice = $("#actionMessage");
  notice.hidden = true;
  setActionsDisabled(true);
  try {
    const result = await api(`/api/actions/${action}`, { method: "POST", body: "{}" });
    state.activeJobId = result.job_id;
    setText("#activeJob", `Auftrag ${result.job_id} gestartet`);
    setText("#currentJobTitle", labels[action]);
    const status = $("#currentJobStatus");
    status.className = "badge badge-warning";
    status.textContent = "Gestartet";
    $("#currentJobLog").textContent = "Auftrag wurde angenommen. Warte auf Ausgabe ...";
    switchTab("overview");
    pollJob(result.job_id);
  } catch (error) {
    notice.hidden = false;
    notice.textContent = error.message;
    setActionsDisabled(false);
  }
}

async function pollJob(jobId) {
  if (state.jobPoll) clearTimeout(state.jobPoll);
  try {
    const [job, log] = await Promise.all([
      api(`/api/jobs/${jobId}`),
      api(`/api/jobs/${jobId}/log?tail=1000`),
    ]);
    setText("#currentJobTitle", job.label || job.action);
    const badge = $("#currentJobStatus");
    badge.className = badgeClass(job.status);
    badge.textContent = job.status;
    const consoleNode = $("#currentJobLog");
    consoleNode.textContent = log;
    consoleNode.scrollTop = consoleNode.scrollHeight;

    if (["queued", "running"].includes(job.status)) {
      state.activeJobId = jobId;
      setActionsDisabled(true);
      state.jobPoll = setTimeout(() => pollJob(jobId), 1800);
    } else {
      state.activeJobId = null;
      setActionsDisabled(false);
      setText("#activeJob", "Kein Auftrag aktiv");
      await Promise.all([loadStatus(), loadJobs()]);
    }
  } catch (error) {
    $("#currentJobLog").textContent = `Auftragsstatus konnte nicht geladen werden: ${error.message}`;
    setActionsDisabled(false);
  }
}

async function loadMods() {
  const body = $("#modsBody");
  body.innerHTML = '<tr><td colspan="6" class="empty">Modliste wird geladen.</td></tr>';
  try {
    const data = await api("/api/mods");
    body.innerHTML = data.mods.map((mod) => {
      const source = mod.type === "workshop" ? "Steam Workshop" : "Lokal";
      const status = mod.installed ? "Installiert" : "Fehlt";
      return `<tr>
        <td>${escapeHtml(mod.name)}</td>
        <td>${source}</td>
        <td>${mod.workshop_id ? `<code>${escapeHtml(mod.workshop_id)}</code>` : "–"}</td>
        <td><code>${escapeHtml(mod.target)}</code></td>
        <td><span class="${badgeClass(mod.installed ? "installed" : "missing")}">${status}</span></td>
        <td>${formatBytes(mod.size_bytes)}</td>
      </tr>`;
    }).join("");
  } catch (error) {
    body.innerHTML = `<tr><td colspan="6" class="empty">${escapeHtml(error.message)}</td></tr>`;
  }
}

async function loadLogs() {
  const node = $("#serverLog");
  node.textContent = "Serverlog wird geladen.";
  try {
    node.textContent = await api(`/api/logs?lines=${$("#logLines").value}`);
    node.scrollTop = node.scrollHeight;
  } catch (error) {
    node.textContent = `Logabruf fehlgeschlagen: ${error.message}`;
  }
}

async function loadJobs() {
  const body = $("#jobsBody");
  try {
    const data = await api("/api/jobs?limit=50");
    if (!data.jobs.length) {
      body.innerHTML = '<tr><td colspan="5" class="empty">Noch keine Aufträge.</td></tr>';
      return;
    }
    body.innerHTML = data.jobs.map((job) => `<tr>
      <td>${formatDate(job.created_at)}</td>
      <td>${escapeHtml(job.label || job.action)}</td>
      <td><span class="${badgeClass(job.status)}">${escapeHtml(job.status)}</span></td>
      <td>${job.exit_code === null || job.exit_code === undefined ? "–" : job.exit_code}</td>
      <td><button class="link-button" data-job-id="${job.id}">Ausgabe</button></td>
    </tr>`).join("");
    $$('[data-job-id]').forEach((button) => button.addEventListener("click", () => showJobLog(button.dataset.jobId)));
  } catch (error) {
    body.innerHTML = `<tr><td colspan="5" class="empty">${escapeHtml(error.message)}</td></tr>`;
  }
}

async function showJobLog(jobId) {
  const node = $("#selectedJobLog");
  node.hidden = false;
  node.textContent = "Ausgabe wird geladen.";
  try {
    node.textContent = await api(`/api/jobs/${jobId}/log?tail=5000`);
    node.scrollIntoView({ behavior: "smooth", block: "nearest" });
  } catch (error) {
    node.textContent = error.message;
  }
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>'"]/g, (char) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;",
  })[char]);
}

function switchTab(tabName) {
  state.activeTab = tabName;
  $$(".tab").forEach((tab) => tab.classList.toggle("is-active", tab.dataset.tab === tabName));
  $$(".panel-view").forEach((view) => view.classList.toggle("is-active", view.id === tabName));
  if (tabName === "mods") loadMods();
  if (tabName === "logs") loadLogs();
  if (tabName === "jobs") loadJobs();
}

function initialise() {
  $$(".tab").forEach((tab) => tab.addEventListener("click", () => switchTab(tab.dataset.tab)));
  $$('[data-action]').forEach((button) => button.addEventListener("click", () => runAction(button.dataset.action)));
  $("#refreshMods").addEventListener("click", loadMods);
  $("#refreshLogs").addEventListener("click", loadLogs);
  $("#refreshJobs").addEventListener("click", loadJobs);
  $("#logLines").addEventListener("change", loadLogs);

  loadStatus();
  loadJobs();
  setInterval(loadStatus, 10000);
}

document.addEventListener("DOMContentLoaded", initialise);
