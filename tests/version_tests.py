from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from core.version_manager.edition import Edition, load_supported_editions
from core.version_manager.parser import parse_base_version_string, parse_version_string
from core.version_manager.validator import (
    is_valid_base_version_string,
    is_valid_version_string,
)
from core.version_manager.version import Version, load_version_config


class VersionParserTests(unittest.TestCase):
    def test_parse_version_with_build(self) -> None:
        parsed = parse_version_string("PUB-1.2.3+245")
        self.assertEqual(parsed.edition, Edition.PUB)
        self.assertEqual(parsed.major, 1)
        self.assertEqual(parsed.minor, 2)
        self.assertEqual(parsed.patch, 3)
        self.assertEqual(parsed.build, 245)

    def test_parse_base_version(self) -> None:
        self.assertEqual(parse_base_version_string("10.11.12"), (10, 11, 12))

    def test_invalid_version_is_rejected(self) -> None:
        self.assertFalse(is_valid_version_string("PUB-1.0"))
        self.assertFalse(is_valid_version_string("UNKNOWN-1.0.0"))
        self.assertFalse(is_valid_base_version_string("1.0"))


class VersionComparisonTests(unittest.TestCase):
    def test_build_number_comparison(self) -> None:
        lower = Version(edition=Edition.PUB, major=1, minor=0, patch=1, build=10)
        higher = Version(edition=Edition.PUB, major=1, minor=0, patch=1, build=11)
        self.assertTrue(higher > lower)
        self.assertTrue(higher.is_newer_than(lower))

    def test_cross_edition_comparison_raises(self) -> None:
        pub_version = Version(edition=Edition.PUB, major=1, minor=0, patch=1)
        edu_version = Version(edition=Edition.EDU46, major=1, minor=0, patch=1)
        with self.assertRaises(ValueError):
            _ = pub_version < edu_version


class ConfigLoadingTests(unittest.TestCase):
    def test_load_supported_editions(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            editions_path = Path(temp_dir) / "editions.json"
            editions_path.write_text(
                json.dumps(
                    {
                        "supported_editions": ["PUB", "EDU46", "EDU79", "EDU1012"],
                    }
                ),
                encoding="utf-8",
            )
            loaded = load_supported_editions(editions_path)
            self.assertEqual(
                loaded,
                [Edition.PUB, Edition.EDU46, Edition.EDU79, Edition.EDU1012],
            )

    def test_load_version_config(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "version_config.json"
            config_path.write_text(
                json.dumps(
                    {
                        "versions": {
                            "PUB": "1.0.1",
                            "EDU46": "1.1.0",
                            "EDU79": "2.0.0",
                            "EDU1012": "3.4.5",
                        }
                    }
                ),
                encoding="utf-8",
            )
            versions = load_version_config(config_path)
            self.assertEqual(versions[Edition.EDU1012].base_version, "3.4.5")


class BuildGeneratorTests(unittest.TestCase):
    @staticmethod
    def _load_generator_module():
        script_path = PROJECT_ROOT / "build" / "build_version_generator.py"
        spec = importlib.util.spec_from_file_location("build_version_generator", script_path)
        if spec is None or spec.loader is None:
            raise RuntimeError("Failed to load build version generator module.")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_payload_shape(self) -> None:
        module = self._load_generator_module()
        payload = module.create_payload(
            Version(edition=Edition.EDU79, major=2, minor=5, patch=0, build=321)
        )
        self.assertEqual(payload["EDITION"], "EDU79")
        self.assertEqual(payload["VERSION"], "2.5.0")
        self.assertEqual(payload["BUILD_NUMBER"], "321")
        self.assertEqual(payload["FULL_VERSION"], "EDU79-2.5.0+321")

    def test_explicit_build_number(self) -> None:
        module = self._load_generator_module()
        self.assertEqual(module.resolve_build_number(99), 99)


if __name__ == "__main__":
    unittest.main()
