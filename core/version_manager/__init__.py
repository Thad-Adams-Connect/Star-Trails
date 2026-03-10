"""Reusable cross-platform versioning module."""

from .config_validator import ConfigValidator, ConfigValidationError
from .edition import Edition, default_supported_editions, load_supported_editions
from .edition_detector import EditionDetector
from .history_manager import VersionHistoryManager, VersionHistoryError
from .parser import parse_base_version_string, parse_version_string, try_parse_version_string
from .validator import (
    is_valid_base_version_string,
    is_valid_version_string,
    validate_base_version_string,
    validate_version_string,
)
from .version import Version, load_version_config

__all__ = [
    "Edition",
    "Version",
    "ConfigValidator",
    "EditionDetector",
    "ConfigValidationError",
    "VersionHistoryManager",
    "VersionHistoryError",
    "default_supported_editions",
    "load_supported_editions",
    "load_version_config",
    "parse_base_version_string",
    "parse_version_string",
    "try_parse_version_string",
    "validate_version_string",
    "validate_base_version_string",
    "is_valid_version_string",
    "is_valid_base_version_string",
]
