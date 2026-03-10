# -*- coding: utf-8 -*-
"""Setup auto-versioning for the repository."""

import platform
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
HOOKS_DIR = PROJECT_ROOT / ".git" / "hooks"

WRAPPER_CONTENT = '''#!/bin/sh
""":"
HOOK_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOOK_DIR/pre-commit.ps1" "$@"
fi

if command -v powershell >/dev/null 2>&1; then
  exec powershell -NoProfile -ExecutionPolicy Bypass -File "$HOOK_DIR/pre-commit.ps1" "$@"
fi

if command -v python3 >/dev/null 2>&1; then
  exec python3 "$HOOK_DIR/pre-commit.py" "$@"
fi

exec python "$HOOK_DIR/pre-commit.py" "$@"
"":"""
'''


def setup_git_hook() -> None:
    """Install the pre-commit hook for auto-versioning."""

    pre_commit = HOOKS_DIR / "pre-commit"

    if platform.system() == "Windows":
        pre_commit.write_text(WRAPPER_CONTENT, encoding="utf-8", newline="\n")
        print("Installed PowerShell pre-commit hook wrapper")
        print("  Hook will run: .git/hooks/pre-commit.ps1")
    else:
        pre_commit_py = HOOKS_DIR / "pre-commit.py"
        if pre_commit_py.exists():
            if pre_commit.exists() or pre_commit.is_symlink():
                pre_commit.unlink()
            try:
                pre_commit.symlink_to(pre_commit_py)
            except OSError:
                shutil.copy(pre_commit_py, pre_commit)
            pre_commit.chmod(0o755)
            print("Made pre-commit hook executable")

    print("\nAuto-versioning is now enabled!")
    print("  - Versions will auto-increment on commits to lib/ or core/")
    print("  - Skip with: git commit --no-verify")
    print("\nManual bump: python scripts/bump_version.py {patch|minor|major}")


def check_dependencies() -> bool:
    """Verify Python and Git are available."""

    try:
        subprocess.run([sys.executable, "--version"], capture_output=True, check=True)
        subprocess.run(["git", "--version"], capture_output=True, check=True)
        print("Dependencies verified")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("ERROR: Python and Git are required")
        return False


def main() -> int:
    print("Setting up auto-versioning...\n")
    if not check_dependencies():
        return 1

    print()
    setup_git_hook()
    return 0


if __name__ == "__main__":
    sys.exit(main())