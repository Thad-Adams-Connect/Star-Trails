"""
Edition Detection Module

Detects the current edition from various sources:
- Executable name
- Environment variables
- App manifest
- Command line arguments
"""

import os
import sys
import json
from pathlib import Path
from typing import Optional


class EditionDetector:
    """Detect and validate the current edition."""
    
    VALID_EDITIONS = ["PUB", "EDU46", "EDU79", "EDU1012"]
    
    @staticmethod
    def from_executable_name() -> Optional[str]:
        """
        Detect edition from executable name.
        
        Examples:
            StarTrails-PUB -> PUB
            StarTrails-EDU46.exe -> EDU46
            startrails-edu79 -> EDU79
        
        Returns:
            Edition string if detected, None otherwise
        """
        executable = Path(sys.argv[0]).stem.upper()
        
        for edition in EditionDetector.VALID_EDITIONS:
            if edition in executable:
                return edition
        
        return None
    
    @staticmethod
    def from_environment() -> Optional[str]:
        """
        Detect edition from environment variables.
        
        Checks (in order):
            - APP_EDITION
            - STAR_TRAILS_EDITION
            - EDITION
        
        Returns:
            Edition string if found and valid, None otherwise
        """
        env_vars = ["APP_EDITION", "STAR_TRAILS_EDITION", "EDITION"]
        
        for var in env_vars:
            value = os.getenv(var, "").upper()
            if value in EditionDetector.VALID_EDITIONS:
                return value
        
        return None
    
    @staticmethod
    def from_manifest(manifest_path: Path = Path("config/app_manifest.json")) -> Optional[str]:
        """
        Detect edition from app manifest.
        
        Args:
            manifest_path: Path to app_manifest.json
        
        Returns:
            Edition string if found in manifest, None otherwise
        """
        try:
            if not manifest_path.exists():
                return None
            
            with open(manifest_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            edition = data.get('edition', '').upper()
            if edition in EditionDetector.VALID_EDITIONS:
                return edition
        
        except (json.JSONDecodeError, IOError):
            pass
        
        return None
    
    @staticmethod
    def from_build_profile(edition_hint: str, profiles_dir: Path = Path("build_profiles")) -> Optional[str]:
        """
        Validate edition exists in build profiles.
        
        Args:
            edition_hint: Edition to validate
            profiles_dir: Directory containing build profile JSON files
        
        Returns:
            Validated edition if profile exists, None otherwise
        """
        edition = edition_hint.upper()
        
        if edition not in EditionDetector.VALID_EDITIONS:
            return None
        
        profile_path = profiles_dir / f"{edition.lower()}.json"
        
        if profile_path.exists():
            return edition
        
        return None
    
    @staticmethod
    def detect(prefer_manifest: bool = True) -> str:
        """
        Detect edition using all available methods.
        
        Priority (default with prefer_manifest=True):
            1. Environment variables (explicit override)
            2. App manifest (default configuration)
            3. Executable name (convenience)
            4. Fallback to PUB
        
        Priority (with prefer_manifest=False):
            1. Environment variables
            2. Executable name
            3. App manifest
            4. Fallback to PUB
        
        Args:
            prefer_manifest: Whether to prioritize manifest over executable name
        
        Returns:
            Valid edition string (always returns a valid edition)
        """
        # Environment always takes highest priority (explicit override)
        edition = EditionDetector.from_environment()
        if edition:
            return edition
        
        if prefer_manifest:
            # Manifest → Executable → PUB
            edition = EditionDetector.from_manifest()
            if edition:
                return edition
            
            edition = EditionDetector.from_executable_name()
            if edition:
                return edition
        else:
            # Executable → Manifest → PUB
            edition = EditionDetector.from_executable_name()
            if edition:
                return edition
            
            edition = EditionDetector.from_manifest()
            if edition:
                return edition
        
        # Fallback to public edition
        return "PUB"
    
    @staticmethod
    def get_build_profile(edition: Optional[str] = None) -> Optional[dict]:
        """
        Load build profile for the given edition.
        
        Args:
            edition: Edition to load. If None, auto-detect.
        
        Returns:
            Build profile dict if found, None otherwise
        """
        if edition is None:
            edition = EditionDetector.detect()
        
        edition = edition.upper()
        profile_path = Path("build_profiles") / f"{edition.lower()}.json"
        
        try:
            if not profile_path.exists():
                return None
            
            with open(profile_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        
        except (json.JSONDecodeError, IOError):
            return None
    
    @staticmethod
    def get_enabled_features(edition: Optional[str] = None) -> list:
        """
        Get list of enabled features for the given edition.
        
        Args:
            edition: Edition to check. If None, auto-detect.
        
        Returns:
            List of feature strings. Empty list if edition not found.
        """
        features_path = Path("config/features.json")
        
        if edition is None:
            edition = EditionDetector.detect()
        
        edition = edition.upper()
        
        try:
            if not features_path.exists():
                return []
            
            with open(features_path, 'r', encoding='utf-8') as f:
                features_data = json.load(f)
            
            return features_data.get(edition, [])
        
        except (json.JSONDecodeError, IOError):
            return []
    
    @staticmethod
    def is_feature_enabled(feature: str, edition: Optional[str] = None) -> bool:
        """
        Check if a specific feature is enabled for the given edition.
        
        Args:
            feature: Feature name to check
            edition: Edition to check. If None, auto-detect.
        
        Returns:
            True if feature is enabled, False otherwise
        """
        features = EditionDetector.get_enabled_features(edition)
        return feature in features


# CLI interface
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Detect Star Trails edition")
    parser.add_argument("--prefer-manifest", action="store_true",
                        help="Prefer manifest over executable name")
    parser.add_argument("--print-profile", action="store_true",
                        help="Print full build profile")
    parser.add_argument("--print-features", action="store_true",
                        help="Print enabled features")
    parser.add_argument("--check-feature", metavar="FEATURE",
                        help="Check if specific feature is enabled")
    
    args = parser.parse_args()
    
    edition = EditionDetector.detect(prefer_manifest=args.prefer_manifest)
    
    if args.print_profile:
        profile = EditionDetector.get_build_profile(edition)
        if profile:
            print(json.dumps(profile, indent=2))
        else:
            print(f"No build profile found for edition: {edition}", file=sys.stderr)
            sys.exit(1)
    
    elif args.print_features:
        features = EditionDetector.get_enabled_features(edition)
        print(json.dumps(features, indent=2))
    
    elif args.check_feature:
        enabled = EditionDetector.is_feature_enabled(args.check_feature, edition)
        print("true" if enabled else "false")
        sys.exit(0 if enabled else 1)
    
    else:
        print(edition)
