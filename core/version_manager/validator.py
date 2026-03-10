from __future__ import annotations

import re
from typing import Collection

from .edition import Edition, validate_editions

VERSION_PATTERN = re.compile(
    r"^(?P<edition>[A-Z0-9]+)-"
    r"(?P<major>0|[1-9]\d*)\."
    r"(?P<minor>0|[1-9]\d*)\."
    r"(?P<patch>0|[1-9]\d*)"
    r"(?:\+(?P<build>0|[1-9]\d*))?$"
)

BASE_VERSION_PATTERN = re.compile(
    r"^(?P<major>0|[1-9]\d*)\."
    r"(?P<minor>0|[1-9]\d*)\."
    r"(?P<patch>0|[1-9]\d*)$"
)


def validate_base_version_string(version: str) -> str:
    normalized = str(version).strip()
    if not BASE_VERSION_PATTERN.fullmatch(normalized):
        raise ValueError(
            "Invalid base version format. Expected 'Major.Minor.Patch', "
            "for example '1.0.1'."
        )
    return normalized


def validate_version_string(
    version: str,
    allowed_editions: Collection[str | Edition] | None = None,
) -> str:
    normalized = str(version).strip()
    match = VERSION_PATTERN.fullmatch(normalized)
    if not match:
        raise ValueError(
            "Invalid version format. Expected 'Edition-Major.Minor.Patch' "
            "or 'Edition-Major.Minor.Patch+Build'."
        )

    edition = Edition.from_string(match.group("edition"))

    expected_editions = (
        validate_editions(allowed_editions)
        if allowed_editions is not None
        else list(Edition)
    )
    if edition not in expected_editions:
        expected = ", ".join(item.value for item in expected_editions)
        raise ValueError(
            f"Edition '{edition.value}' is not enabled. Allowed editions: {expected}."
        )

    return normalized


def is_valid_version_string(
    version: str,
    allowed_editions: Collection[str | Edition] | None = None,
) -> bool:
    try:
        validate_version_string(version, allowed_editions)
        return True
    except ValueError:
        return False


def is_valid_base_version_string(version: str) -> bool:
    try:
        validate_base_version_string(version)
        return True
    except ValueError:
        return False
