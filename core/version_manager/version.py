from __future__ import annotations

import json
from dataclasses import dataclass
from functools import total_ordering
from pathlib import Path
from typing import Collection

from .edition import Edition, validate_editions
from .validator import BASE_VERSION_PATTERN, validate_base_version_string


@total_ordering
@dataclass(frozen=True)
class Version:
    """Edition-scoped software version."""

    edition: Edition
    major: int
    minor: int
    patch: int
    build: int | None = None

    def __post_init__(self) -> None:
        if self.major < 0 or self.minor < 0 or self.patch < 0:
            raise ValueError("Major, minor, and patch must be non-negative integers.")
        if self.build is not None and self.build < 0:
            raise ValueError("Build number must be a non-negative integer.")

    @property
    def base_version(self) -> str:
        return f"{self.major}.{self.minor}.{self.patch}"

    def with_build(self, build: int | None) -> "Version":
        return Version(
            edition=self.edition,
            major=self.major,
            minor=self.minor,
            patch=self.patch,
            build=build,
        )

    def bump_major(self) -> "Version":
        return Version(self.edition, self.major + 1, 0, 0)

    def bump_minor(self) -> "Version":
        return Version(self.edition, self.major, self.minor + 1, 0)

    def bump_patch(self) -> "Version":
        return Version(self.edition, self.major, self.minor, self.patch + 1)

    def compare_to(self, other: "Version", include_build: bool = True) -> int:
        if self.edition != other.edition:
            raise ValueError(
                f"Cannot compare different editions: {self.edition.value} vs {other.edition.value}."
            )

        if (self.major, self.minor, self.patch) != (other.major, other.minor, other.patch):
            return (
                (self.major, self.minor, self.patch)
                > (other.major, other.minor, other.patch)
            ) - (
                (self.major, self.minor, self.patch)
                < (other.major, other.minor, other.patch)
            )

        if not include_build:
            return 0

        left_build = self.build if self.build is not None else -1
        right_build = other.build if other.build is not None else -1
        return (left_build > right_build) - (left_build < right_build)

    def is_newer_than(self, other: "Version", include_build: bool = True) -> bool:
        return self.compare_to(other, include_build=include_build) > 0

    def __lt__(self, other: object) -> bool:
        if not isinstance(other, Version):
            return NotImplemented
        return self.compare_to(other, include_build=True) < 0

    def __str__(self) -> str:
        base = f"{self.edition.value}-{self.base_version}"
        return f"{base}+{self.build}" if self.build is not None else base

    @classmethod
    def from_base_version(
        cls,
        edition: Edition,
        base_version: str,
        build: int | None = None,
    ) -> "Version":
        normalized = validate_base_version_string(base_version)
        match = BASE_VERSION_PATTERN.fullmatch(normalized)
        if match is None:
            raise ValueError(f"Invalid base version '{base_version}'.")

        major = int(match.group("major"))
        minor = int(match.group("minor"))
        patch = int(match.group("patch"))
        return cls(edition=edition, major=major, minor=minor, patch=patch, build=build)


def load_version_config(
    config_path: str | Path,
    supported_editions: Collection[str | Edition] | None = None,
) -> dict[Edition, Version]:
    """Load edition base versions from config/version_config.json."""

    configured_editions = (
        validate_editions(supported_editions)
        if supported_editions is not None
        else list(Edition)
    )

    path = Path(config_path)
    with path.open("r", encoding="utf-8") as file:
        payload = json.load(file)

    raw_versions = payload.get("versions", payload)
    if not isinstance(raw_versions, dict):
        raise ValueError(
            f"Invalid format in {path}. Expected an object with edition keys or a 'versions' map."
        )

    result: dict[Edition, Version] = {}
    for edition in configured_editions:
        raw_version = raw_versions.get(edition.value)
        if raw_version is None:
            raise KeyError(
                f"Edition '{edition.value}' is missing from {path}."
            )
        result[edition] = Version.from_base_version(edition, str(raw_version))

    return result
