from __future__ import annotations

import json
from enum import Enum
from pathlib import Path
from typing import Iterable


class Edition(str, Enum):
    """Supported software editions."""

    PUB = "PUB"
    EDU46 = "EDU46"
    EDU79 = "EDU79"
    EDU1012 = "EDU1012"

    @classmethod
    def from_string(cls, value: str) -> "Edition":
        normalized = value.strip().upper()
        try:
            return cls(normalized)
        except ValueError as exc:
            supported = ", ".join(edition.value for edition in cls)
            raise ValueError(
                f"Unsupported edition '{value}'. Expected one of: {supported}."
            ) from exc


def default_supported_editions() -> list[Edition]:
    return list(Edition)


def validate_editions(editions: Iterable[str | Edition]) -> list[Edition]:
    resolved: list[Edition] = []
    for edition in editions:
        if isinstance(edition, Edition):
            resolved.append(edition)
        else:
            resolved.append(Edition.from_string(str(edition)))

    if not resolved:
        raise ValueError("At least one edition must be configured.")

    unique = list(dict.fromkeys(resolved))
    if len(unique) != len(resolved):
        raise ValueError("Duplicate editions found in configuration.")

    return unique


def load_supported_editions(config_path: str | Path) -> list[Edition]:
    """Load supported editions from config/editions.json."""

    path = Path(config_path)
    with path.open("r", encoding="utf-8") as file:
        payload = json.load(file)

    raw_editions = payload.get("supported_editions")
    if not isinstance(raw_editions, list):
        raise ValueError(
            f"Invalid format in {path}. Expected 'supported_editions' list."
        )

    return validate_editions(raw_editions)
