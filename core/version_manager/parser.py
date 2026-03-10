from __future__ import annotations

from typing import Collection

from .edition import Edition
from .validator import BASE_VERSION_PATTERN, VERSION_PATTERN, validate_base_version_string, validate_version_string
from .version import Version


def parse_version_string(
    version: str,
    allowed_editions: Collection[str | Edition] | None = None,
) -> Version:
    normalized = validate_version_string(version, allowed_editions=allowed_editions)
    match = VERSION_PATTERN.fullmatch(normalized)
    if match is None:
        raise ValueError(f"Invalid version string '{version}'.")

    edition = Edition.from_string(match.group("edition"))
    major = int(match.group("major"))
    minor = int(match.group("minor"))
    patch = int(match.group("patch"))
    raw_build = match.group("build")
    build = int(raw_build) if raw_build is not None else None

    return Version(edition=edition, major=major, minor=minor, patch=patch, build=build)


def parse_base_version_string(version: str) -> tuple[int, int, int]:
    normalized = validate_base_version_string(version)
    match = BASE_VERSION_PATTERN.fullmatch(normalized)
    if match is None:
        raise ValueError(f"Invalid base version '{version}'.")
    return (
        int(match.group("major")),
        int(match.group("minor")),
        int(match.group("patch")),
    )


def try_parse_version_string(
    version: str,
    allowed_editions: Collection[str | Edition] | None = None,
) -> Version | None:
    try:
        return parse_version_string(version, allowed_editions=allowed_editions)
    except ValueError:
        return None
