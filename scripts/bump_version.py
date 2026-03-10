"""Version management utility scripts."""

import argparse
import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
VERSION_CONFIG = PROJECT_ROOT / "config" / "version_config.json"
VERSION_HISTORY = PROJECT_ROOT / "config" / "version_history.json"


def load_config():
    with VERSION_CONFIG.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_config(config):
    with VERSION_CONFIG.open("w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)
        f.write("\n")


def load_history():
    if not VERSION_HISTORY.exists():
        return {}
    with VERSION_HISTORY.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_history(history):
    with VERSION_HISTORY.open("w", encoding="utf-8") as f:
        json.dump(history, f, indent=2)
        f.write("\n")


def bump_version(edition, component):
    config = load_config()
    history = load_history()
    
    if edition == "all":
        editions = list(config["versions"].keys())
    else:
        editions = [edition.upper()]
    
    for ed in editions:
        if ed not in config["versions"]:
            print(f"Edition {ed} not found")
            continue
            
        version_str = config["versions"][ed]
        major, minor, patch = map(int, version_str.split("."))
        
        if component == "major":
            major += 1
            minor = 0
            patch = 0
        elif component == "minor":
            minor += 1
            patch = 0
        elif component == "patch":
            patch += 1
        
        new_version = f"{major}.{minor}.{patch}"
        config["versions"][ed] = new_version
        print(f"{ed}: {version_str} -> {new_version}")

        # Update history
        if ed not in history:
            history[ed] = []
        if new_version not in history[ed]:
            history[ed].append(new_version)
    
    save_config(config)
    save_history(history)


def main():
    parser = argparse.ArgumentParser(description="Bump version numbers")
    parser.add_argument(
        "component",
        choices=["major", "minor", "patch"],
        help="Version component to bump"
    )
    parser.add_argument(
        "--edition",
        default="all",
        help="Edition to bump (default: all)"
    )
    
    args = parser.parse_args()
    bump_version(args.edition, args.component)


if __name__ == "__main__":
    main()
