"""
Unit tests for configuration validation and version history management.

Tests cover:
- editions.json validation
- version_config.json validation
- app_manifest.json validation
- Cross-file consistency checks
- Version history operations
"""

import json
import tempfile
import unittest
from pathlib import Path

from core.version_manager import (
    ConfigValidator,
    ConfigValidationError,
    VersionHistoryManager,
    VersionHistoryError,
)


class ConfigValidatorTests(unittest.TestCase):
    """Tests for configuration validation."""

    def setUp(self):
        """Create temporary config directory for testing."""
        self.temp_dir = tempfile.TemporaryDirectory()
        self.config_dir = Path(self.temp_dir.name)

    def tearDown(self):
        """Clean up temporary directory."""
        self.temp_dir.cleanup()

    def _write_editions_json(self, editions):
        """Helper to write editions.json."""
        with open(self.config_dir / "editions.json", "w") as f:
            json.dump(editions, f)

    def _write_version_config_json(self, versions):
        """Helper to write version_config.json."""
        with open(self.config_dir / "version_config.json", "w") as f:
            json.dump(versions, f)

    def _write_manifest_json(self, manifest):
        """Helper to write app_manifest.json."""
        with open(self.config_dir / "app_manifest.json", "w") as f:
            json.dump(manifest, f)

    def test_validate_edition_format_valid(self):
        """Test valid edition format validation."""
        self.assertTrue(ConfigValidator.validate_edition_format("PUB"))
        self.assertTrue(ConfigValidator.validate_edition_format("EDU46"))
        self.assertTrue(ConfigValidator.validate_edition_format("EDU1012"))
        self.assertTrue(ConfigValidator.validate_edition_format("CUSTOM"))

    def test_validate_edition_format_invalid(self):
        """Test invalid edition format rejection."""
        self.assertFalse(ConfigValidator.validate_edition_format("pub"))  # lowercase
        self.assertFalse(ConfigValidator.validate_edition_format("Pub"))  # mixed case
        self.assertFalse(ConfigValidator.validate_edition_format("edu-46"))  # hyphen
        self.assertFalse(ConfigValidator.validate_edition_format("edu 46"))  # space

    def test_validate_semantic_version_valid(self):
        """Test valid semantic version formats."""
        self.assertTrue(ConfigValidator.validate_semantic_version("1.0.0"))
        self.assertTrue(ConfigValidator.validate_semantic_version("1.2.3"))
        self.assertTrue(ConfigValidator.validate_semantic_version("10.20.30"))
        self.assertTrue(ConfigValidator.validate_semantic_version("0.0.0"))

    def test_validate_semantic_version_invalid(self):
        """Test invalid semantic version rejection."""
        self.assertFalse(ConfigValidator.validate_semantic_version("1.0"))  # missing patch
        self.assertFalse(ConfigValidator.validate_semantic_version("1.0.0.1"))  # extra component
        self.assertFalse(ConfigValidator.validate_semantic_version("01.0.0"))  # leading zero
        self.assertFalse(ConfigValidator.validate_semantic_version("1.02.0"))  # leading zero
        self.assertFalse(ConfigValidator.validate_semantic_version("v1.0.0"))  # prefix

    def test_editions_file_missing(self):
        """Test error when editions.json is missing."""
        with self.assertRaises(ConfigValidationError):
            ConfigValidator.validate_editions_file(
                self.config_dir / "editions.json"
            )

    def test_editions_file_invalid_json(self):
        """Test error on invalid JSON."""
        with open(self.config_dir / "editions.json", "w") as f:
            f.write("{invalid json")

        with self.assertRaises(ConfigValidationError) as cm:
            ConfigValidator.validate_editions_file(
                self.config_dir / "editions.json"
            )
        self.assertIn("JSON", str(cm.exception))

    def test_editions_file_not_object(self):
        """Test error when root is not an object."""
        with open(self.config_dir / "editions.json", "w") as f:
            json.dump(["PUB", "EDU46"], f)

        with self.assertRaises(ConfigValidationError) as cm:
            ConfigValidator.validate_editions_file(
                self.config_dir / "editions.json"
            )
        self.assertIn("object", str(cm.exception))

    def test_editions_file_missing_key(self):
        """Test error when 'supported_editions' key is missing."""
        self._write_editions_json({"other_key": []})

        with self.assertRaises(ConfigValidationError) as cm:
            ConfigValidator.validate_editions_file(
                self.config_dir / "editions.json"
            )
        self.assertIn("supported_editions", str(cm.exception))

    def test_editions_file_empty_list(self):
        """Test error when supported_editions is empty."""
        self._write_editions_json({"supported_editions": []})

        with self.assertRaises(ConfigValidationError) as cm:
            ConfigValidator.validate_editions_file(
                self.config_dir / "editions.json"
            )
        self.assertIn("empty", str(cm.exception))

    def test_editions_file_invalid_edition(self):
        """Test error on invalid edition format."""
        self._write_editions_json({"supported_editions": ["pub"]})  # lowercase

        with self.assertRaises(ConfigValidationError) as cm:
            ConfigValidator.validate_editions_file(
                self.config_dir / "editions.json"
            )
        self.assertIn("format", str(cm.exception))

    def test_editions_file_valid(self):
        """Test successful validation of valid editions.json."""
        self._write_editions_json(
            {"supported_editions": ["PUB", "EDU46", "EDU79", "EDU1012"]}
        )

        result = ConfigValidator.validate_editions_file(
            self.config_dir / "editions.json"
        )
        self.assertEqual(result["supported_editions"], ["PUB", "EDU46", "EDU79", "EDU1012"])

    def test_version_config_file_missing(self):
        """Test error when version_config.json is missing."""
        with self.assertRaises(ConfigValidationError):
            ConfigValidator.validate_version_config_file(
                self.config_dir / "version_config.json"
            )

    def test_version_config_file_invalid_version(self):
        """Test error on invalid version format."""
        self._write_version_config_json({"versions": {"PUB": "1.0"}})

        with self.assertRaises(ConfigValidationError) as cm:
            ConfigValidator.validate_version_config_file(
                self.config_dir / "version_config.json"
            )
        self.assertIn("Invalid version", str(cm.exception))

    def test_version_config_file_valid(self):
        """Test successful validation of valid version_config.json."""
        self._write_version_config_json(
            {"versions": {"PUB": "1.0.0", "EDU46": "1.0.1"}}
        )

        result = ConfigValidator.validate_version_config_file(
            self.config_dir / "version_config.json"
        )
        self.assertEqual(result["versions"]["PUB"], "1.0.0")
        self.assertEqual(result["versions"]["EDU46"], "1.0.1")

    def test_manifest_file_missing(self):
        """Test error when app_manifest.json is missing."""
        with self.assertRaises(ConfigValidationError):
            ConfigValidator.validate_manifest_file(
                self.config_dir / "app_manifest.json"
            )

    def test_manifest_file_missing_required_field(self):
        """Test error when required fields are missing."""
        self._write_manifest_json({"app_name": "Star Trails"})

        with self.assertRaises(ConfigValidationError) as cm:
            ConfigValidator.validate_manifest_file(
                self.config_dir / "app_manifest.json"
            )
        self.assertIn("required", str(cm.exception))

    def test_manifest_file_invalid_edition(self):
        """Test error on invalid edition in manifest."""
        self._write_manifest_json(
            {
                "app_name": "Star Trails",
                "company": "Ubertas Lab",
                "edition": "invalid-edition",
            }
        )

        with self.assertRaises(ConfigValidationError) as cm:
            ConfigValidator.validate_manifest_file(
                self.config_dir / "app_manifest.json"
            )
        self.assertIn("Invalid edition", str(cm.exception))

    def test_manifest_file_valid(self):
        """Test successful validation of valid app_manifest.json."""
        self._write_manifest_json(
            {
                "app_name": "Star Trails",
                "company": "Ubertas Lab",
                "edition": "PUB",
            }
        )

        result = ConfigValidator.validate_manifest_file(
            self.config_dir / "app_manifest.json"
        )
        self.assertEqual(result["edition"], "PUB")

    def test_validate_all_consistent(self):
        """Test validation of all files with consistency checks."""
        self._write_editions_json(
            {"supported_editions": ["PUB", "EDU46"]}
        )
        self._write_version_config_json(
            {"versions": {"PUB": "1.0.0", "EDU46": "1.0.0"}}
        )
        self._write_manifest_json(
            {
                "app_name": "Star Trails",
                "company": "Ubertas Lab",
                "edition": "PUB",
            }
        )

        is_valid, message = ConfigValidator.validate_all(self.config_dir)
        self.assertTrue(is_valid)
        self.assertIn("valid", message.lower())

    def test_validate_all_editions_mismatch(self):
        """Test validation catches edition mismatch."""
        self._write_editions_json(
            {"supported_editions": ["PUB", "EDU46", "EDU79"]}
        )
        self._write_version_config_json(
            {"versions": {"PUB": "1.0.0", "EDU46": "1.0.0"}}
        )
        self._write_manifest_json(
            {
                "app_name": "Star Trails",
                "company": "Ubertas Lab",
                "edition": "PUB",
            }
        )

        is_valid, message = ConfigValidator.validate_all(self.config_dir)
        self.assertFalse(is_valid)
        self.assertIn("mismatch", message.lower())

    def test_validate_all_manifest_edition_invalid(self):
        """Test validation catches invalid edition in manifest."""
        self._write_editions_json(
            {"supported_editions": ["PUB", "EDU46"]}
        )
        self._write_version_config_json(
            {"versions": {"PUB": "1.0.0", "EDU46": "1.0.0"}}
        )
        self._write_manifest_json(
            {
                "app_name": "Star Trails",
                "company": "Ubertas Lab",
                "edition": "INVALID",
            }
        )

        is_valid, message = ConfigValidator.validate_all(self.config_dir)
        self.assertFalse(is_valid)
        self.assertIn("INVALID", message)


class VersionHistoryManagerTests(unittest.TestCase):
    """Tests for version history management."""

    def setUp(self):
        """Create temporary directory for testing."""
        self.temp_dir = tempfile.TemporaryDirectory()
        self.history_file = Path(self.temp_dir.name) / "version_history.json"

    def tearDown(self):
        """Clean up temporary directory."""
        self.temp_dir.cleanup()

    def test_load_history_new_file(self):
        """Test loading history from non-existent file returns empty dict."""
        history = VersionHistoryManager.load_history(self.history_file)
        self.assertEqual(history, {})

    def test_load_history_existing_file(self):
        """Test loading history from existing file."""
        initial_history = {"PUB": ["1.0.0", "1.0.1"]}
        with open(self.history_file, "w") as f:
            json.dump(initial_history, f)

        history = VersionHistoryManager.load_history(self.history_file)
        self.assertEqual(history["PUB"], ["1.0.0", "1.0.1"])

    def test_save_history(self):
        """Test saving history to file."""
        history = {"PUB": ["1.0.0", "1.0.1"], "EDU46": ["1.0.0"]}
        VersionHistoryManager.save_history(history, self.history_file)

        self.assertTrue(self.history_file.exists())

        with open(self.history_file, "r") as f:
            saved = json.load(f)
        self.assertEqual(saved, history)

    def test_add_version_new_edition(self):
        """Test adding a version to a new edition."""
        added = VersionHistoryManager.add_version(
            "PUB", "1.0.0", self.history_file
        )
        self.assertTrue(added)

        history = VersionHistoryManager.load_history(self.history_file)
        self.assertEqual(history["PUB"], ["1.0.0"])

    def test_add_version_existing_edition(self):
        """Test adding another version to existing edition."""
        VersionHistoryManager.add_version(
            "PUB", "1.0.0", self.history_file
        )
        VersionHistoryManager.add_version(
            "PUB", "1.0.1", self.history_file
        )

        history = VersionHistoryManager.load_history(self.history_file)
        self.assertEqual(history["PUB"], ["1.0.0", "1.0.1"])

    def test_add_version_duplicate(self):
        """Test adding duplicate version returns False."""
        VersionHistoryManager.add_version(
            "PUB", "1.0.0", self.history_file
        )
        added = VersionHistoryManager.add_version(
            "PUB", "1.0.0", self.history_file
        )
        self.assertFalse(added)

        history = VersionHistoryManager.load_history(self.history_file)
        self.assertEqual(history["PUB"], ["1.0.0"])

    def test_add_version_invalid_format(self):
        """Test adding version with invalid format."""
        with self.assertRaises(VersionHistoryError):
            VersionHistoryManager.add_version(
                "PUB", "1.0", self.history_file
            )

    def test_get_history(self):
        """Test retrieving history for an edition."""
        VersionHistoryManager.add_version(
            "EDU46", "1.0.0", self.history_file
        )
        VersionHistoryManager.add_version(
            "EDU46", "1.0.1", self.history_file
        )

        history = VersionHistoryManager.get_history("EDU46", self.history_file)
        self.assertEqual(history, ["1.0.0", "1.0.1"])

    def test_get_history_nonexistent_edition(self):
        """Test retrieving history for non-existent edition."""
        history = VersionHistoryManager.get_history("MISSING", self.history_file)
        self.assertEqual(history, [])

    def test_get_latest_version(self):
        """Test getting the latest version."""
        VersionHistoryManager.add_version(
            "PUB", "1.0.0", self.history_file
        )
        VersionHistoryManager.add_version(
            "PUB", "1.0.1", self.history_file
        )
        VersionHistoryManager.add_version(
            "PUB", "1.0.2", self.history_file
        )

        latest = VersionHistoryManager.get_latest_version("PUB", self.history_file)
        self.assertEqual(latest, "1.0.2")

    def test_get_latest_version_nonexistent_edition(self):
        """Test getting latest version for non-existent edition."""
        latest = VersionHistoryManager.get_latest_version("MISSING", self.history_file)
        self.assertIsNone(latest)

    def test_version_exists_in_history(self):
        """Test checking if version exists in history."""
        VersionHistoryManager.add_version(
            "EDU79", "1.0.0", self.history_file
        )

        self.assertTrue(
            VersionHistoryManager.version_exists_in_history(
                "EDU79", "1.0.0", self.history_file
            )
        )
        self.assertFalse(
            VersionHistoryManager.version_exists_in_history(
                "EDU79", "1.0.1", self.history_file
            )
        )

    def test_multiple_editions(self):
        """Test managing history for multiple editions."""
        VersionHistoryManager.add_version(
            "PUB", "1.0.0", self.history_file
        )
        VersionHistoryManager.add_version(
            "EDU46", "1.0.0", self.history_file
        )
        VersionHistoryManager.add_version(
            "PUB", "1.0.1", self.history_file
        )
        VersionHistoryManager.add_version(
            "EDU46", "1.0.1", self.history_file
        )

        pub_history = VersionHistoryManager.get_history("PUB", self.history_file)
        edu_history = VersionHistoryManager.get_history("EDU46", self.history_file)

        self.assertEqual(pub_history, ["1.0.0", "1.0.1"])
        self.assertEqual(edu_history, ["1.0.0", "1.0.1"])


if __name__ == "__main__":
    unittest.main()
