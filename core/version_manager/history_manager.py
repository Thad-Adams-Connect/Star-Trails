"""
Version history tracking module for the versioning system.

This module manages the version history for each edition, storing all
past release versions and providing functions to track new releases.
"""

import json
from pathlib import Path
from typing import Dict, List, Optional

from .parser import parse_base_version_string


class VersionHistoryError(Exception):
    """Raised when version history operation fails."""
    pass


class VersionHistoryManager:
    """Manages version history tracking per edition."""

    DEFAULT_HISTORY_FILE = Path("config/version_history.json")

    @staticmethod
    def load_history(
        history_file: Path = DEFAULT_HISTORY_FILE,
    ) -> Dict[str, List[str]]:
        """
        Load version history from file.

        Args:
            history_file: Path to version_history.json

        Returns:
            Dictionary mapping edition to list of versions in chronological order

        Raises:
            VersionHistoryError: If history file is malformed
        """
        if not history_file.exists():
            return {}

        try:
            with open(history_file, "r", encoding="utf-8") as f:
                data = json.load(f)

            if not isinstance(data, dict):
                raise VersionHistoryError(
                    "version_history.json root must be a JSON object"
                )

            # Validate structure
            for edition, versions in data.items():
                if not isinstance(versions, list):
                    raise VersionHistoryError(
                        f"History for edition '{edition}' must be a list"
                    )
                for version in versions:
                    if not isinstance(version, str):
                        raise VersionHistoryError(
                            f"Version entries must be strings, "
                            f"got {type(version).__name__} in {edition}"
                        )

            return data

        except json.JSONDecodeError as e:
            raise VersionHistoryError(
                f"version_history.json has invalid JSON format: {e}"
            )

    @staticmethod
    def save_history(
        history: Dict[str, List[str]],
        history_file: Path = DEFAULT_HISTORY_FILE,
    ) -> None:
        """
        Save version history to file.

        Args:
            history: History dictionary
            history_file: Path to version_history.json

        Raises:
            VersionHistoryError: If file write fails
        """
        try:
            history_file.parent.mkdir(parents=True, exist_ok=True)
            with open(history_file, "w", encoding="utf-8") as f:
                json.dump(history, f, indent=2, ensure_ascii=False)
        except (IOError, OSError) as e:
            raise VersionHistoryError(
                f"Failed to write version_history.json: {e}"
            )

    @staticmethod
    def add_version(
        edition: str,
        version: str,
        history_file: Path = DEFAULT_HISTORY_FILE,
    ) -> bool:
        """
        Add a version to an edition's history.

        Prevents duplicate entries and ensures version is a base version
        (no build number).

        Args:
            edition: Edition name (e.g., "PUB")
            version: Base version string (e.g., "1.0.3")
            history_file: Path to version_history.json

        Returns:
            True if version was added, False if already in history

        Raises:
            VersionHistoryError: If version format is invalid
        """
        # Validate and parse version format (must be base version, no build number)
        try:
            parse_base_version_string(version)
        except ValueError as e:
            raise VersionHistoryError(f"Invalid version: {e}")

        history = VersionHistoryManager.load_history(history_file)

        # Initialize list if edition doesn't exist
        if edition not in history:
            history[edition] = []

        # Check if version already exists
        if version in history[edition]:
            return False

        # Add new version
        history[edition].append(version)

        # Save updated history
        VersionHistoryManager.save_history(history, history_file)

        return True

    @staticmethod
    def get_history(
        edition: str,
        history_file: Path = DEFAULT_HISTORY_FILE,
    ) -> List[str]:
        """
        Get version history for a specific edition.

        Args:
            edition: Edition name (e.g., "PUB")
            history_file: Path to version_history.json

        Returns:
            List of versions in chronological order, or empty list if edition
            not found
        """
        history = VersionHistoryManager.load_history(history_file)
        return history.get(edition, [])

    @staticmethod
    def get_latest_version(
        edition: str,
        history_file: Path = DEFAULT_HISTORY_FILE,
    ) -> Optional[str]:
        """
        Get the latest version for an edition.

        Args:
            edition: Edition name (e.g., "PUB")
            history_file: Path to version_history.json

        Returns:
            Latest version string, or None if edition has no history
        """
        versions = VersionHistoryManager.get_history(edition, history_file)
        return versions[-1] if versions else None

    @staticmethod
    def version_exists_in_history(
        edition: str,
        version: str,
        history_file: Path = DEFAULT_HISTORY_FILE,
    ) -> bool:
        """
        Check if a version exists in an edition's history.

        Args:
            edition: Edition name
            version: Base version string
            history_file: Path to version_history.json

        Returns:
            True if version is in history
        """
        versions = VersionHistoryManager.get_history(edition, history_file)
        return version in versions

    @staticmethod
    def print_history_report(
        history_file: Path = DEFAULT_HISTORY_FILE,
    ) -> None:
        """
        Print a formatted version history report.

        Args:
            history_file: Path to version_history.json
        """
        try:
            history = VersionHistoryManager.load_history(history_file)

            print("\n" + "=" * 60)
            print("VERSION HISTORY REPORT")
            print("=" * 60)

            if not history:
                print("No version history found.\n")
                return

            for edition in sorted(history.keys()):
                versions = history[edition]
                print(f"\n{edition}:")
                for i, version in enumerate(versions, 1):
                    latest = " (latest)" if i == len(versions) else ""
                    print(f"  {i:2d}. {version}{latest}")

            print("\n" + "=" * 60 + "\n")

        except VersionHistoryError as e:
            print(f"Error reading history: {e}\n")
