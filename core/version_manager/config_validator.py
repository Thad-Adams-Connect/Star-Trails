"""
Configuration validation module for the versioning system.

This module provides validation logic for:
- editions.json
- version_config.json
- app_manifest.json

It ensures all configuration files are consistent, well-formed, and follow
the semantic versioning rules.
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Any, Tuple


class ConfigValidationError(Exception):
    """Raised when configuration validation fails."""
    pass


class ConfigValidator:
    """Validates application configuration files."""

    SEMANTIC_VERSION_PATTERN = re.compile(
        r"^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)$"
    )

    @staticmethod
    def validate_edition_format(edition: str) -> bool:
        """Check if edition name is valid (alphanumeric, uppercase)."""
        return bool(re.match(r"^[A-Z0-9]+$", edition))

    @staticmethod
    def validate_semantic_version(version_str: str) -> bool:
        """Validate semantic version format (Major.Minor.Patch)."""
        return bool(ConfigValidator.SEMANTIC_VERSION_PATTERN.match(version_str))

    @staticmethod
    def validate_editions_file(editions_path: Path) -> Dict[str, Any]:
        """
        Validate editions.json structure and content.

        Args:
            editions_path: Path to editions.json

        Returns:
            Parsed editions data

        Raises:
            ConfigValidationError: If validation fails
        """
        if not editions_path.exists():
            raise ConfigValidationError(
                f"editions.json not found at {editions_path}"
            )

        try:
            with open(editions_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            raise ConfigValidationError(
                f"editions.json has invalid JSON format: {e}"
            )

        if not isinstance(data, dict):
            raise ConfigValidationError(
                "editions.json root must be a JSON object"
            )

        if "supported_editions" not in data:
            raise ConfigValidationError(
                "editions.json missing required key: 'supported_editions'"
            )

        if not isinstance(data["supported_editions"], list):
            raise ConfigValidationError(
                "'supported_editions' must be a list"
            )

        if len(data["supported_editions"]) == 0:
            raise ConfigValidationError(
                "'supported_editions' cannot be empty"
            )

        # Validate each edition
        for edition in data["supported_editions"]:
            if not isinstance(edition, str):
                raise ConfigValidationError(
                    f"Edition must be string, got {type(edition).__name__}"
                )

            if not ConfigValidator.validate_edition_format(edition):
                raise ConfigValidationError(
                    f"Invalid edition format: '{edition}' "
                    "(must be alphanumeric uppercase)"
                )

        return data

    @staticmethod
    def validate_version_config_file(config_path: Path) -> Dict[str, Any]:
        """
        Validate version_config.json structure and content.

        Args:
            config_path: Path to version_config.json

        Returns:
            Parsed version config data

        Raises:
            ConfigValidationError: If validation fails
        """
        if not config_path.exists():
            raise ConfigValidationError(
                f"version_config.json not found at {config_path}"
            )

        try:
            with open(config_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            raise ConfigValidationError(
                f"version_config.json has invalid JSON format: {e}"
            )

        if not isinstance(data, dict):
            raise ConfigValidationError(
                "version_config.json root must be a JSON object"
            )

        if "versions" not in data:
            raise ConfigValidationError(
                "version_config.json missing required key: 'versions'"
            )

        if not isinstance(data["versions"], dict):
            raise ConfigValidationError(
                "'versions' must be a JSON object"
            )

        if len(data["versions"]) == 0:
            raise ConfigValidationError(
                "'versions' cannot be empty"
            )

        # Validate each version
        for edition, version in data["versions"].items():
            if not isinstance(version, str):
                raise ConfigValidationError(
                    f"Version for {edition} must be string, "
                    f"got {type(version).__name__}"
                )

            if not ConfigValidator.validate_semantic_version(version):
                raise ConfigValidationError(
                    f"Invalid version for {edition}: '{version}' "
                    "(expected format: Major.Minor.Patch)"
                )

        return data

    @staticmethod
    def validate_manifest_file(manifest_path: Path) -> Dict[str, Any]:
        """
        Validate app_manifest.json structure and content.

        Args:
            manifest_path: Path to app_manifest.json

        Returns:
            Parsed manifest data

        Raises:
            ConfigValidationError: If validation fails
        """
        if not manifest_path.exists():
            raise ConfigValidationError(
                f"app_manifest.json not found at {manifest_path}"
            )

        try:
            with open(manifest_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            raise ConfigValidationError(
                f"app_manifest.json has invalid JSON format: {e}"
            )

        if not isinstance(data, dict):
            raise ConfigValidationError(
                "app_manifest.json root must be a JSON object"
            )

        required_fields = ["app_name", "company", "edition"]
        for field in required_fields:
            if field not in data:
                raise ConfigValidationError(
                    f"app_manifest.json missing required field: '{field}'"
                )

        # Validate that fields are strings
        for field in ["app_name", "company"]:
            if not isinstance(data[field], str):
                raise ConfigValidationError(
                    f"'{field}' must be a string in app_manifest.json"
                )

        if not isinstance(data["edition"], str):
            raise ConfigValidationError(
                "'edition' must be a string in app_manifest.json"
            )

        if not ConfigValidator.validate_edition_format(data["edition"]):
            raise ConfigValidationError(
                f"Invalid edition in manifest: '{data['edition']}' "
                "(must be alphanumeric uppercase)"
            )

        return data

    @staticmethod
    def validate_all(
        config_dir: Path = Path("config"),
    ) -> Tuple[bool, str]:
        """
        Validate all configuration files and their consistency.

        Args:
            config_dir: Path to config directory

        Returns:
            Tuple of (is_valid, message)
        """
        try:
            # Validate individual files
            editions_data = ConfigValidator.validate_editions_file(
                config_dir / "editions.json"
            )
            version_data = ConfigValidator.validate_version_config_file(
                config_dir / "version_config.json"
            )
            manifest_data = ConfigValidator.validate_manifest_file(
                config_dir / "app_manifest.json"
            )

            # Ensure editions consistency
            supported_editions = set(editions_data["supported_editions"])
            config_editions = set(version_data["versions"].keys())

            if supported_editions != config_editions:
                missing_in_config = supported_editions - config_editions
                extra_in_config = config_editions - supported_editions

                error_parts = []
                if missing_in_config:
                    error_parts.append(
                        f"Missing in version_config.json: {', '.join(sorted(missing_in_config))}"
                    )
                if extra_in_config:
                    error_parts.append(
                        f"Extra in version_config.json: {', '.join(sorted(extra_in_config))}"
                    )

                raise ConfigValidationError(
                    f"Editions mismatch between files. {' '.join(error_parts)}"
                )

            # Validate manifest edition
            manifest_edition = manifest_data["edition"]
            if manifest_edition not in supported_editions:
                raise ConfigValidationError(
                    f"Manifest edition '{manifest_edition}' not in supported editions: "
                    f"{', '.join(sorted(supported_editions))}"
                )

            return True, "All configuration files are valid and consistent."

        except ConfigValidationError as e:
            return False, str(e)

    @staticmethod
    def print_validation_report(config_dir: Path = Path("config")) -> None:
        """
        Print a detailed validation report to console.

        Args:
            config_dir: Path to config directory
        """
        is_valid, message = ConfigValidator.validate_all(config_dir)

        status = "✓ VALID" if is_valid else "✗ INVALID"
        print(f"\n{status}: Configuration Validation")
        print(f"{'=' * 50}")
        print(f"{message}\n")
