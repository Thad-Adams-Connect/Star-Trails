from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from core.version_manager.edition import Edition, load_supported_editions
from core.version_manager.version import Version, load_version_config
from core.version_manager.config_validator import ConfigValidator

MAX_BUILD_NUMBER = 2_147_483_647
CI_BUILD_ENV_KEYS = (
    "BUILD_ID",
    "GITHUB_RUN_NUMBER",
    "BUILD_BUILDID",
    "CI_PIPELINE_IID",
    "BITBUCKET_BUILD_NUMBER",
    "APPVEYOR_BUILD_NUMBER",
    "CIRCLE_BUILD_NUM",
    "BUILD_NUMBER",
)


def _normalize_build_number(value: int) -> int:
    if value < 0:
        raise ValueError("Build number must be non-negative.")
    if value > MAX_BUILD_NUMBER:
        raise ValueError(
            f"Build number {value} exceeds platform-safe maximum {MAX_BUILD_NUMBER}."
        )
    return value


def resolve_build_number(cli_build_number: int | None) -> int:
    if cli_build_number is not None:
        return _normalize_build_number(cli_build_number)

    for key in CI_BUILD_ENV_KEYS:
        raw_value = os.getenv(key)
        if raw_value is None:
            continue

        candidate = raw_value.strip()
        if not candidate.isdigit():
            continue

        return _normalize_build_number(int(candidate))

    # Fallback is seconds since 2020-01-01 UTC, stable and integer-only.
    epoch = datetime(2020, 1, 1, tzinfo=timezone.utc)
    build_number = int((datetime.now(timezone.utc) - epoch).total_seconds())
    return _normalize_build_number(build_number)


def create_payload(version: Version) -> dict[str, str]:
    if version.build is None:
        raise ValueError("Version must include a build number.")

    return {
        "EDITION": version.edition.value,
        "VERSION": version.base_version,
        "BUILD_NUMBER": str(version.build),
        "FULL_VERSION": str(version),
        "FLUTTER_BUILD_NAME": version.base_version,
        "FLUTTER_BUILD_NUMBER": str(version.build),
    }


def format_output(payload: dict[str, str], output_format: str) -> str:
    if output_format == "json":
        return json.dumps(payload, indent=2, sort_keys=True)

    # Both text and dotenv use KEY=VALUE lines for easy parsing by CI tools.
    return "\n".join(f"{key}={value}" for key, value in payload.items())


def write_github_output(payload: dict[str, str]) -> None:
    github_output_path = os.getenv("GITHUB_OUTPUT")
    if not github_output_path:
        raise RuntimeError(
            "GITHUB_OUTPUT is not set. Use this option only in GitHub Actions."
        )

    lines = [f"{key}={value}" for key, value in payload.items()]
    with Path(github_output_path).open("a", encoding="utf-8") as output_file:
        output_file.write("\n".join(lines) + "\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate edition-aware version data for CI/CD pipelines."
    )
    parser.add_argument(
        "--edition",
        required=False,
        default=None,
        help="Edition key (PUB, EDU46, EDU79, EDU1012). If not provided and "
        "--use-manifest is True, will read from app_manifest.json.",
    )
    parser.add_argument(
        "--editions-config",
        default=str(PROJECT_ROOT / "config" / "editions.json"),
        help="Path to editions.json.",
    )
    parser.add_argument(
        "--version-config",
        default=str(PROJECT_ROOT / "config" / "version_config.json"),
        help="Path to version_config.json.",
    )
    parser.add_argument(
        "--manifest",
        default=str(PROJECT_ROOT / "config" / "app_manifest.json"),
        help="Path to app_manifest.json for reading edition if --edition not provided.",
    )
    parser.add_argument(
        "--use-manifest",
        action="store_true",
        help="Read edition from app_manifest.json if --edition not provided.",
    )
    parser.add_argument(
        "--build-number",
        type=int,
        default=None,
        help="Optional explicit build number (non-negative integer).",
    )
    parser.add_argument(
        "--output-format",
        choices=("text", "dotenv", "json"),
        default="text",
        help="Output format for stdout.",
    )
    parser.add_argument(
        "--write-file",
        default=None,
        help="Optional file path to write output.",
    )
    parser.add_argument(
        "--set-github-output",
        action="store_true",
        help="Also append outputs to $GITHUB_OUTPUT.",
    )
    parser.add_argument(
        "--validate-config",
        action="store_true",
        help="Validate all configuration files before generating version.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    # Validate configuration files if requested
    if args.validate_config:
        config_dir = Path(args.editions_config).parent
        is_valid, message = ConfigValidator.validate_all(config_dir)
        if not is_valid:
            raise ValueError(f"Configuration validation failed: {message}")

    # Determine edition
    edition_str = args.edition
    if edition_str is None:
        if args.use_manifest:
            # Read edition from manifest
            try:
                with open(args.manifest, "r", encoding="utf-8") as f:
                    manifest = json.load(f)
                    edition_str = manifest.get("edition")
                    if edition_str is None:
                        raise ValueError(
                            "app_manifest.json does not contain 'edition' field"
                        )
            except (FileNotFoundError, json.JSONDecodeError) as e:
                raise RuntimeError(
                    f"Failed to read edition from manifest: {e}"
                )
        else:
            raise ValueError(
                "Edition must be provided via --edition or --use-manifest flag"
            )

    supported_editions = load_supported_editions(args.editions_config)
    selected_edition = Edition.from_string(edition_str)
    if selected_edition not in supported_editions:
        allowed = ", ".join(item.value for item in supported_editions)
        raise ValueError(
            f"Edition '{selected_edition.value}' is not enabled. Allowed editions: {allowed}."
        )

    versions = load_version_config(args.version_config, supported_editions)
    base_version = versions[selected_edition]

    build_number = resolve_build_number(args.build_number)
    full_version = base_version.with_build(build_number)
    payload = create_payload(full_version)

    rendered = format_output(payload, args.output_format)
    print(rendered)

    if args.write_file:
        output_path = Path(args.write_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(rendered + "\n", encoding="utf-8")

    if args.set_github_output:
        write_github_output(payload)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # pragma: no cover
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
