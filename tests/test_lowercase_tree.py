from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "lowercase_tree.py"

with tempfile.TemporaryDirectory() as temp:
    base = Path(temp) / "MyMod"
    (base / "AddOns").mkdir(parents=True)
    (base / "AddOns" / "TEST.PBO").write_text("x", encoding="utf-8")
    result = subprocess.run(["python3", str(SCRIPT), str(base)], capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    assert (base / "addons" / "test.pbo").is_file()

print("test_lowercase_tree: OK")
