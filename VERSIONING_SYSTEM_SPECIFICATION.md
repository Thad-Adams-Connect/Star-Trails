# Star Trails Edition-Based Versioning System - Complete Technical Specification

**Last Updated**: March 9, 2026  
**Status**: Versioning Infrastructure Production Ready  
**Test Coverage**: 43/43 tests passing (100%)

---

## EXECUTIVE SUMMARY

The Star Trails versioning system is a production-grade, cross-platform edition management solution that supports independent version tracking for four software editions:

- **PUB**: Public Edition (default)
- **EDU46**: Education Grades 4–6
- **EDU79**: Education Grades 7–9  
- **EDU1012**: Education Grades 10–12

All editions maintain independent version histories with automatic tracking, comprehensive validation, and seamless CI/CD integration.

Current repository snapshot:
- `version_config.json` current versions: PUB=1.0.4, EDU46=1.0.3, EDU79=1.0.3, EDU1012=1.0.3
- `version_history.json` latest versions: PUB=1.0.4, EDU46=1.0.3, EDU79=1.0.3, EDU1012=1.0.3

Implementation boundary note:
- This specification covers the versioning/config/build infrastructure.
- Runtime gameplay content switching by edition and runtime log-file writing are separate integration layers.

---

## 1. SYSTEM ARCHITECTURE OVERVIEW

### 1.1 Design Principles

1. **Configuration-Driven**: Editions defined in JSON, not hardcoded
2. **Separation of Concerns**: Distinct modules for validation, history, parsing, and version management
3. **Non-Blocking Operations**: All features fail gracefully; never block builds or commits
4. **Backward Compatible**: All new features are opt-in; existing workflows unaffected
5. **Minimal Dependencies**: Pure Python (stdlib only), no external packages required
6. **Test-Driven**: Comprehensive unit test coverage (43 tests, all passing)

### 1.2 Component Hierarchy

```
core/version_manager/ (Reusable versioning module)
├── edition.py               (Edition enum + config loading)
├── validator.py             (Version format validation)
├── parser.py                (Version string parsing)
├── version.py               (Version object + comparisons)
├── config_validator.py      (Configuration file validation)
├── history_manager.py       (Version history tracking)
└── __init__.py              (Public API exports)

config/ (Configuration files)
├── app_manifest.json        (Application metadata + current edition)
├── editions.json            (Supported editions list)
├── version_config.json      (Current versions per edition)
└── version_history.json     (Historical versions per edition)

build/ (Build-time tools)
└── build_version_generator.py  (Generate version payload for CI/CD)

scripts/ (Utility scripts)
├── bump_version.py          (Manual version increment)
└── setup_auto_versioning.py (Git hook installer)

.git/hooks/ (Git automation)
├── pre-commit               (Hook wrapper - polyglot shell/Python)
├── pre-commit.ps1           (Windows implementation)
└── pre-commit.py            (Unix implementation)

tests/ (Quality assurance)
├── version_tests.py         (Original 9 versioning tests)
└── config_tests.py          (New 34 config/history tests)
```

---

## 2. CONFIGURATION FILES

### 2.1 app_manifest.json - Application Metadata

**Location**: `config/app_manifest.json`

**Purpose**: Single source of truth for application configuration and current edition selection.

**Schema**:
```json
{
  "app_name": "Star Trails",             // Display name
  "company": "Ubertas Lab",              // Organization
  "description": "Explore the cosmos...", // Short description
  "edition": "PUB",                       // Current edition (must be in editions.json)
  "repository": "https://github.com/...", // Source repository
  "license": "Proprietary",               // License type
  "created": "2024-01-01",                // Creation timestamp
  "updated": "2026-03-09"                 // Last update timestamp
}
```

**Required Fields**: `app_name`, `company`, `edition`  
**Optional Fields**: `description`, `repository`, `license`, `created`, `updated`

**Validation Rules**:
- `app_name` and `company` must be non-empty strings
- `edition` must match entry in `editions.json` exactly
- Edition format: alphanumeric uppercase (e.g., PUB, EDU46)

**Usage**:
```bash
# Read edition from manifest
edition=$(jq -r '.edition' config/app_manifest.json)

# Use in build generator
python build/build_version_generator.py --use-manifest

# Changed once, affects all downstream builds without script modifications
```

### 2.2 editions.json - Supported Editions Registry

**Location**: `config/editions.json`

**Purpose**: Define which editions are supported and active.

**Schema**:
```json
{
  "supported_editions": ["PUB", "EDU46", "EDU79", "EDU1012"]
}
```

**Validation Rules**:
- Must be valid JSON object
- Must contain `supported_editions` key
- Value must be non-empty array
- All edition names must be alphanumeric uppercase
- No spaces, hyphens, or special characters

**Adding New Edition**:
To add a new edition (e.g., CUSTOM):
1. Add to array in this file: `["PUB", "EDU46", "EDU79", "EDU1012", "CUSTOM"]`
2. Add entry in version_config.json: `"CUSTOM": "1.0.0"`
3. Run validation: `python -c "from core.version_manager import ConfigValidator; ConfigValidator.print_validation_report()"`

### 2.3 version_config.json - Current Versions

**Location**: `config/version_config.json`

**Purpose**: Store current base version for each edition. Single source of truth for version numbers.

**Schema**:
```json
{
  "versions": {
    "PUB": "1.0.3",
    "EDU46": "1.0.3",
    "EDU79": "1.0.3",
    "EDU1012": "1.0.3"
  }
}
```

**Validation Rules**:
- Must be valid JSON object with `versions` key
- Value must be object mapping edition names to versions
- All versions must follow semantic versioning (Major.Minor.Patch)
- All supported editions must have entry
- No leading zeros allowed (1.0.3 valid, 1.00.3 invalid)

**Automatic Updates**:
- Git pre-commit hooks increment patch when code changes
- Manual bump script updates on user request
- Never edited directly in production

**Version Format Rules**:
```
Major: Breaking changes (0 or positive integer)
Minor: New features (0 or positive integer)
Patch: Bug fixes (0 or positive integer)

Valid:   1.0.0, 0.1.2, 10.25.300
Invalid: 1.0, 01.0.0, 1.0.0+245 (build number handled separately), v1.0.0
```

### 2.4 version_history.json - Version History Per Edition

**Location**: `config/version_history.json`

**Purpose**: Maintain chronological record of all released versions per edition.

**Schema**:
```json
{
  "PUB": [
    "1.0.0",
    "1.0.1",
    "1.0.2",
    "1.0.3"
  ],
  "EDU46": [
    "1.0.0",
    "1.0.1",
    "1.0.2",
    "1.0.3"
  ],
  "EDU79": [
    "1.0.0",
    "1.0.1",
    "1.0.2",
    "1.0.3"
  ],
  "EDU1012": [
    "1.0.0",
    "1.0.1",
    "1.0.2",
    "1.0.3"
  ]
}
```

**Invariants**:
- Each edition maps to chronologically ordered array
- No duplicates allowed within an edition
- Versions are base versions (no build number)
- Latest version is always last entry
- Format follows semantic versioning

**Automatic Updates**:
- Git hooks append new versions when patch is bumped
- Manual bump script appends new versions
- Version history manager prevents duplicates
- Separate entry created automatically for new editions

---

## 3. CORE MODULES API

### 3.1 core/version_manager/__init__.py - Public API

**Exports**:
```python
from core.version_manager import (
    Edition,
    Version,
    ConfigValidator,
    ConfigValidationError,
    VersionHistoryManager,
    VersionHistoryError,
    load_supported_editions,
    load_version_config,
    parse_version_string,
    parse_base_version_string,
    try_parse_version_string,
    validate_version_string,
    validate_base_version_string,
    is_valid_version_string,
    is_valid_base_version_string,
)
```

### 3.2 edition.py - Edition Management

**Enum Definition**:
```python
class Edition(str, Enum):
    PUB = "PUB"
    EDU46 = "EDU46"
    EDU79 = "EDU79"
    EDU1012 = "EDU1012"
```

**Functions**:

#### Edition.from_string(value: str) -> Edition
```python
# Convert string to Edition enum
edition = Edition.from_string("PUB")  # Returns Edition.PUB
edition = Edition.from_string("pub")  # Raises ValueError
```

#### load_supported_editions(config_path: str) -> List[Edition]
```python
# Load supported editions from editions.json
editions = load_supported_editions("config/editions.json")
# Returns: [Edition.PUB, Edition.EDU46, Edition.EDU79, Edition.EDU1012]

# Check if edition is supported
if Edition.PUB in editions:
    print("PUB edition is supported")
```

#### default_supported_editions() -> List[Edition]
```python
# Get default hardcoded editions (fallback if config unavailable)
editions = default_supported_editions()
# Returns: [Edition.PUB, Edition.EDU46, Edition.EDU79, Edition.EDU1012]
```

### 3.3 version.py - Version Object and Comparisons

**Version Dataclass**:
```python
@dataclass(frozen=True)
class Version:
    edition: Edition      # Which edition (PUB, EDU46, etc.)
    major: int           # Breaking changes
    minor: int           # New features
    patch: int           # Bug fixes
    build: int | None    # CI/CD build number (optional)
```

**Methods**:

#### Version.with_build(build_number: int) -> Version
```python
v = Version(Edition.PUB, 1, 0, 3, build=None)
v_with_build = v.with_build(245)
# Returns: Version(Edition.PUB, 1, 0, 3, build=245)
```

#### Version.bump_major() -> Version
```python
v = Version(Edition.PUB, 1, 2, 3, build=None)
v_bumped = v.bump_major()
# Returns: Version(Edition.PUB, 2, 0, 0, build=None)
# Sets minor and patch to 0
```

#### Version.bump_minor() -> Version
```python
v = Version(Edition.PUB, 1, 2, 3, build=None)
v_bumped = v.bump_minor()
# Returns: Version(Edition.PUB, 1, 3, 0, build=None)
# Sets patch to 0
```

#### Version.bump_patch() -> Version
```python
v = Version(Edition.PUB, 1, 2, 3, build=None)
v_bumped = v.bump_patch()
# Returns: Version(Edition.PUB, 1, 2, 4, build=None)
```

#### Version.is_newer_than(other: Version) -> bool
```python
v1 = Version(Edition.PUB, 1, 0, 3)
v2 = Version(Edition.PUB, 1, 0, 2)
v1.is_newer_than(v2)  # True

v1.is_newer_than(Version(Edition.EDU46, 1, 0, 3))  # Raises ValueError (cross-edition)
```

#### Version.compare_to(other: Version) -> int
```python
# Returns: -1 if self < other, 0 if equal, 1 if self > other
v1 = Version(Edition.PUB, 1, 0, 3)
v2 = Version(Edition.PUB, 1, 0, 2)
v1.compare_to(v2)  # Returns: 1

Version(Edition.PUB, 1, 0, 2).compare_to(v2)  # Returns: 0
```

#### @property Version.base_version -> str
```python
v = Version(Edition.PUB, 1, 0, 3, build=245)
v.base_version  # Returns: "1.0.3"
```

#### __str__(self) -> str
```python
v = Version(Edition.PUB, 1, 0, 3, build=245)
str(v)  # Returns: "PUB-1.0.3+245"

v = Version(Edition.PUB, 1, 0, 3, build=None)
str(v)  # Returns: "PUB-1.0.3"
```

#### Comparison Operators
```python
# @total_ordering applied - all comparisons work
Version(Edition.PUB, 1, 0, 3) > Version(Edition.PUB, 1, 0, 2)  # True
Version(Edition.PUB, 1, 0, 3) >= Version(Edition.PUB, 1, 0, 3)  # True
Version(Edition.PUB, 1, 0, 3) == Version(Edition.PUB, 1, 0, 3)  # True
Version(Edition.PUB, 1, 0, 3) <= Version(Edition.PUB, 1, 0, 4)  # True
Version(Edition.PUB, 1, 0, 3) < Version(Edition.PUB, 1, 0, 4)   # True
```

#### load_version_config(config_path: str, supported_editions: List[Edition]) -> Dict[Edition, Version]
```python
# Load all versions from version_config.json
versions = load_version_config("config/version_config.json", supported_editions)
# Returns: {
#   Edition.PUB: Version(Edition.PUB, 1, 0, 3),
#   Edition.EDU46: Version(Edition.EDU46, 1, 0, 3),
#   ...
# }

# Access specific version
pub_version = versions[Edition.PUB]  # Version(Edition.PUB, 1, 0, 3)
```

### 3.4 validator.py - Version Format Validation

**Functions**:

#### validate_version_string(version: str, allowed_editions: List[Edition]) -> bool
```python
# Validate full version string with edition prefix and optional build number
validate_version_string("PUB-1.0.3", [Edition.PUB])           # True
validate_version_string("PUB-1.0.3+245", [Edition.PUB])       # True
validate_version_string("pub-1.0.3", [Edition.PUB])           # False (lowercase)
validate_version_string("INVALID-1.0.3", [Edition.PUB])       # False (edition not allowed)
validate_version_string("PUB-1.0", [Edition.PUB])             # False (missing patch)

# Raises ValueError with descriptive message on invalid input
```

#### validate_base_version_string(version: str) -> bool
```python
# Validate semantic version without edition or build number
validate_base_version_string("1.0.3")       # True
validate_base_version_string("0.0.0")       # True
validate_base_version_string("1.0")         # False (missing patch)
validate_base_version_string("1.0.3+245")   # False (includes build)
validate_base_version_string("1.0.03")      # False (leading zero)

# Raises ValueError on invalid input
```

#### is_valid_version_string(version: str, allowed_editions: List[Edition] = []) -> bool
```python
# Non-raising version of validate_version_string
is_valid_version_string("PUB-1.0.3", [Edition.PUB])  # True
is_valid_version_string("invalid", [Edition.PUB])     # False (no exception)
```

#### is_valid_base_version_string(version: str) -> bool
```python
# Non-raising version of validate_base_version_string
is_valid_base_version_string("1.0.3")   # True
is_valid_base_version_string("invalid") # False (no exception)
```

### 3.5 parser.py - Version String Parsing

**Functions**:

#### parse_version_string(version: str, allowed_editions: List[Edition]) -> Version
```python
# Parse full version string into Version object
v = parse_version_string("PUB-1.0.3+245", [Edition.PUB])
# Returns: Version(Edition.PUB, 1, 0, 3, build=245)

v = parse_version_string("EDU46-2.5.1", [Edition.EDU46])
# Returns: Version(Edition.EDU46, 2, 5, 1, build=None)

# Raises ValueError if format invalid or edition not allowed
parse_version_string("INVALID-1.0.3", [Edition.PUB])  # Raises ValueError
```

#### parse_base_version_string(version: str) -> Tuple[int, int, int]
```python
# Parse semantic version into (major, minor, patch) tuple
major, minor, patch = parse_base_version_string("1.0.3")
# Returns: (1, 0, 3)

major, minor, patch = parse_base_version_string("10.25.30")
# Returns: (10, 25, 30)

# Raises ValueError on invalid format
parse_base_version_string("1.0")  # Raises ValueError
```

#### try_parse_version_string(version: str, allowed_editions: List[Edition]) -> Version | None
```python
# Safely parse version, return None on failure instead of raising
v = try_parse_version_string("PUB-1.0.3", [Edition.PUB])
# Returns: Version(Edition.PUB, 1, 0, 3)

v = try_parse_version_string("INVALID", [Edition.PUB])
# Returns: None (no exception)
```

### 3.6 config_validator.py - Configuration Validation

**Class**: ConfigValidator

**Methods**:

#### ConfigValidator.validate_edition_format(edition: str) -> bool
```python
# Validate edition name format (alphanumeric uppercase)
ConfigValidator.validate_edition_format("PUB")      # True
ConfigValidator.validate_edition_format("EDU46")    # True
ConfigValidator.validate_edition_format("pub")      # False
ConfigValidator.validate_edition_format("edu-46")   # False
```

#### ConfigValidator.validate_semantic_version(version_str: str) -> bool
```python
# Validate semantic version format (Major.Minor.Patch)
ConfigValidator.validate_semantic_version("1.0.0")    # True
ConfigValidator.validate_semantic_version("1.0")      # False
ConfigValidator.validate_semantic_version("01.0.0")   # False (leading zero)
```

#### ConfigValidator.validate_editions_file(editions_path: Path) -> Dict[str, Any]
```python
# Load and validate editions.json structure
data = ConfigValidator.validate_editions_file(Path("config/editions.json"))
# Returns: {"supported_editions": ["PUB", "EDU46", "EDU79", "EDU1012"]}

# Raises ConfigValidationError on invalid file, missing key, or invalid format
```

#### ConfigValidator.validate_version_config_file(config_path: Path) -> Dict[str, Any]
```python
# Load and validate version_config.json structure
data = ConfigValidator.validate_version_config_file(Path("config/version_config.json"))
# Returns: {"versions": {"PUB": "1.0.3", "EDU46": "1.0.3", ...}}

# Raises ConfigValidationError on invalid format or semantic version issues
```

#### ConfigValidator.validate_manifest_file(manifest_path: Path) -> Dict[str, Any]
```python
# Load and validate app_manifest.json structure
data = ConfigValidator.validate_manifest_file(Path("config/app_manifest.json"))
# Returns: {"app_name": "Star Trails", "company": "Ubertas Lab", "edition": "PUB", ...}

# Raises ConfigValidationError if required fields missing or invalid
```

#### ConfigValidator.validate_all(config_dir: Path = Path("config")) -> Tuple[bool, str]
```python
# Validate all files and check consistency
is_valid, message = ConfigValidator.validate_all(Path("config"))
# Returns: (True, "All configuration files are valid and consistent.")
# Returns: (False, "Editions mismatch between files. Missing in version_config.json: EDU79")

# Checks:
# - All files are valid individually
# - Editions in editions.json match version_config.json keys exactly
# - Manifest edition is in supported editions list
```

#### ConfigValidator.print_validation_report(config_dir: Path = Path("config")) -> None
```python
# Print formatted validation report to console
ConfigValidator.print_validation_report(Path("config"))
# Output:
# valid: Configuration Validation
# ==================================================
# All configuration files are valid and consistent.

# Or on failure:
# INVALID: Configuration Validation
# ==================================================
# Manifest edition 'INVALID' not in supported editions: EDU46, EDU79, EDU1012, PUB
```

**Exception**: ConfigValidationError
```python
try:
    ConfigValidator.validate_all()
except ConfigValidationError as e:
    print(f"Validation failed: {e}")
```

### 3.7 history_manager.py - Version History Tracking

**Class**: VersionHistoryManager

**Methods**:

#### VersionHistoryManager.load_history(history_file: Path = ...) -> Dict[str, List[str]]
```python
# Load version history from file
history = VersionHistoryManager.load_history(Path("config/version_history.json"))
# Returns: {
#   "PUB": ["1.0.0", "1.0.1", "1.0.2", "1.0.3"],
#   "EDU46": ["1.0.0", "1.0.1", "1.0.2", "1.0.3"],
#   ...
# }

# Returns empty dict if file doesn't exist
```

#### VersionHistoryManager.save_history(history: Dict[str, List[str]], history_file: Path = ...) -> None
```python
# Save version history to file
history = {
    "PUB": ["1.0.0", "1.0.1", "1.0.2", "1.0.3", "1.0.4"],
    "EDU46": ["1.0.0", "1.0.1"]
}
VersionHistoryManager.save_history(history, Path("config/version_history.json"))

# Creates file if doesn't exist
# Creates parent directories if needed
```

#### VersionHistoryManager.add_version(edition: str, version: str, history_file: Path = ...) -> bool
```python
# Add version to edition's history
# Returns True if added, False if already existed

added = VersionHistoryManager.add_version("PUB", "1.0.4")
# True - version added, file saved

added = VersionHistoryManager.add_version("PUB", "1.0.4")
# False - version already exists, file unchanged

added = VersionHistoryManager.add_version("PUB", "1.0")
# Raises VersionHistoryError (invalid format)

# Automatically handles:
# - Creating new edition if doesn't exist
# - Preventing duplicates
# - Saving to disk after addition
# - Validating version format
```

#### VersionHistoryManager.get_history(edition: str, history_file: Path = ...) -> List[str]
```python
# Get all versions for an edition in chronological order
versions = VersionHistoryManager.get_history("PUB")
# Returns: ["1.0.0", "1.0.1", "1.0.2", "1.0.3"]

versions = VersionHistoryManager.get_history("NONEXISTENT")
# Returns: [] (empty list)
```

#### VersionHistoryManager.get_latest_version(edition: str, history_file: Path = ...) -> str | None
```python
# Get most recent version for an edition
latest = VersionHistoryManager.get_latest_version("PUB")
# Returns: "1.0.3"

latest = VersionHistoryManager.get_latest_version("EMPTY_EDITION")
# Returns: None
```

#### VersionHistoryManager.version_exists_in_history(edition: str, version: str, history_file: Path = ...) -> bool
```python
# Check if version is in an edition's history
exists = VersionHistoryManager.version_exists_in_history("PUB", "1.0.3")
# Returns: True

exists = VersionHistoryManager.version_exists_in_history("PUB", "1.0.999")
# Returns: False
```

#### VersionHistoryManager.print_history_report(history_file: Path = ...) -> None
```python
# Print formatted history report
VersionHistoryManager.print_history_report(Path("config/version_history.json"))
# Output:
# ============================================================
# VERSION HISTORY REPORT
# ============================================================
#
# EDU1012:
#    1. 1.0.0
#    2. 1.0.3
#
# EDU46:
#    1. 1.0.0
#    2. 1.0.3 (latest)
#
# EDU79:
#    1. 1.0.0
#    2. 1.0.3 (latest)
#
# PUB:
#    1. 1.0.0
#    2. 1.0.1
#    3. 1.0.2
#    4. 1.0.3 (latest)
#
# ============================================================
```

**Exception**: VersionHistoryError
```python
try:
    VersionHistoryManager.add_version("PUB", "invalid")
except VersionHistoryError as e:
    print(f"History operation failed: {e}")
```

---

## 4. BUILD GENERATOR

### 4.1 build/build_version_generator.py

**Purpose**: Generate version payload for CI/CD pipelines with optional manifest reading and config validation.

**Command Line Interface**:

```bash
python build/build_version_generator.py [OPTIONS]

Options:
  --edition EDITION              Edition key (PUB, EDU46, EDU79, EDU1012)
                                 If not provided, reads from manifest with --use-manifest
  
  --use-manifest                 Read edition from app_manifest.json instead of --edition
  
  --manifest PATH                Path to app_manifest.json for reading edition
                                 Default: config/app_manifest.json
  
  --editions-config PATH         Path to editions.json
                                 Default: config/editions.json
  
  --version-config PATH          Path to version_config.json
                                 Default: config/version_config.json
  
  --build-number NUMBER          Explicit build number (non-negative integer)
                                 If not provided, resolved from CI env vars or timestamp fallback
  
  --output-format {text,dotenv,json}
                                 Output format for stdout
                                 text: KEY=VALUE lines (default)
                                 dotenv: KEY=VALUE with .env compatibility
                                 json: Pretty-printed JSON object
  
  --write-file PATH              Write output to file instead of (or in addition to) stdout
  
  --set-github-output            Append outputs to $GITHUB_OUTPUT (GitHub Actions)
  
  --validate-config              Validate all config files before generating version
```

**Build Number Resolution**:

Priority order (first available wins):
1. Explicit `--build-number` argument
2. Environment variables (checked in order):
   - `BUILD_ID` (Jenkins)
   - `GITHUB_RUN_NUMBER` (GitHub Actions)
   - `BUILD_BUILDID` (Azure Pipelines)
   - `CI_PIPELINE_IID` (GitLab CI)
   - `BITBUCKET_BUILD_NUMBER` (Bitbucket Pipelines)
   - `APPVEYOR_BUILD_NUMBER` (AppVeyor)
   - `CIRCLE_BUILD_NUM` (CircleCI)
   - `BUILD_NUMBER` (Generic)
3. Fallback: Seconds since 2020-01-01 UTC (stable, deterministic)

**Output Payload**:

Text format:
```
EDITION=PUB
VERSION=1.0.3
BUILD_NUMBER=195269663
FULL_VERSION=PUB-1.0.3+195269663
FLUTTER_BUILD_NAME=1.0.3
FLUTTER_BUILD_NUMBER=195269663
```

JSON format:
```json
{
  "BUILD_NUMBER": "195269663",
  "EDITION": "PUB",
  "FLUTTER_BUILD_NAME": "1.0.3",
  "FLUTTER_BUILD_NUMBER": "195269663",
  "FULL_VERSION": "PUB-1.0.3+195269663",
  "VERSION": "1.0.3"
}
```

**Usage Examples**:

```bash
# Explicit edition
python build/build_version_generator.py --edition PUB

# Read edition from manifest
python build/build_version_generator.py --use-manifest

# With config validation
python build/build_version_generator.py --use-manifest --validate-config

# Explicit build number
python build/build_version_generator.py --edition PUB --build-number 245

# Export to file
python build/build_version_generator.py --use-manifest --write-file /tmp/version.txt

# JSON output
python build/build_version_generator.py --use-manifest --output-format json

# GitHub Actions integration
python build/build_version_generator.py --use-manifest --set-github-output
```

**Shell Integration**:

```bash
# Use output in shell
export $(python build/build_version_generator.py --use-manifest)
echo "Building $EDITION version $FULL_VERSION"

# In GitHub Actions workflow
- name: Generate version
  run: |
    python build/build_version_generator.py --use-manifest --set-github-output
```

**Return Code**:
- `0`: Success
- `1`: Error (invalid arguments, missing config file, validation failure, etc.)

---

## 5. MANUAL VERSION BUMPING

### 5.1 scripts/bump_version.py

**Purpose**: Manually increment version numbers with automatic history tracking.

**Command Line Interface**:

```bash
python scripts/bump_version.py COMPONENT [OPTIONS]

Arguments:
  COMPONENT              Version component to bump
                         Choices: major, minor, patch

Options:
  --edition EDITION      Edition to bump (default: all)
                         Choices: PUB, EDU46, EDU79, EDU1012, or edition name
                         If not 'all', bumps only that edition
```

**Behavior**:

When bumping a component:
- **major**: Increments major, resets minor and patch to 0
- **minor**: Increments minor, resets patch to 0
- **patch**: Increments patch only

Updates:
- `config/version_config.json` (writes new version)
- `config/version_history.json` (appends new version)

**Usage Examples**:

```bash
# Bump patch for all editions
python scripts/bump_version.py patch

# Bump major for PUB only
python scripts/bump_version.py major --edition PUB

# Bump minor for EDU46
python scripts/bump_version.py minor --edition EDU46

# Bump patch for all editions
python scripts/bump_version.py patch
```

**Output Example**:

```
PUB: 1.0.3 -> 1.0.4
EDU46: 1.0.3 -> 1.0.4
EDU79: 1.0.3 -> 1.0.4
EDU1012: 1.0.3 -> 1.0.4
```

---

## 6. GIT HOOKS - AUTOMATIC VERSIONING

### 6.1 Git Hook Architecture

**Three-part system**:

1. **`.git/hooks/pre-commit`** - Polyglot shell/Python wrapper (executable entry point)
2. **`.git/hooks/pre-commit.ps1`** - Windows implementation (PowerShell)
3. **`.git/hooks/pre-commit.py`** - Unix implementation (Python)

**Wrapper Routing**:
- Windows: Routes to PowerShell implementation
- macOS/Linux: Routes to Python implementation

**Guarantee**: Hooks never block commits (exit code 0 always, even on failure)

### 6.2 Hook Behavior

**Trigger**: Runs on `git commit` before commit is created

**Detection**:
Using `git diff --cached --name-only`, detects if changes include:
- Files in `lib/*` directory, OR
- Files in `core/*` directory, AND
- Excludes `*.md` documentation files

**Action** (if code changes detected):
1. Load current versions from `config/version_config.json`
2. Load version history from `config/version_history.json` (if exists)
3. Increment patch for ALL editions
4. Append new versions to history for each edition
5. Save both files
6. Git add both files to staged changes
7. Continue commit with updated files included

**Action** (if no code changes):
- No changes, commit proceeds normally

**Error Handling**:
- If any step fails (json parsing, file I/O, permissions): Log warning but exit 0
- Commit always succeeds
- User can retry manual bump if needed

### 6.3 Hook Installation

```bash
# Setup auto-versioning hooks
python scripts/setup_auto_versioning.py

# Output:
# Checking dependencies... OK
# Setting up Git hooks...
# - Platform: Windows/Unix
# - Hook installed: .git/hooks/pre-commit
# - Hook installed: .git/hooks/pre-commit.ps1 (Windows only)
# Auto-versioning is ready!
```

**One-time setup per clone**:
- Detects platform automatically
- Copies hook files to `.git/hooks/`
- Verifies dependencies
- Never runs twice (idempotent)

---

## 7. TESTING

### 7.1 Test Suite Overview

**Total Tests**: 43 (all passing)
- **Original version tests**: 9 tests
- **Config validation tests**: 21 tests
- **Version history tests**: 13 tests

**Execution**: ~75ms total

### 7.2 Running Tests

```bash
# Run all tests with discovery
python -m unittest discover -s tests -p "*_tests.py"

# Run version tests only
python -m unittest tests.version_tests -v

# Run config tests only
python -m unittest tests.config_tests -v

# Run single test class
python -m unittest tests.config_tests.ConfigValidatorTests

# Run single test method
python -m unittest tests.config_tests.ConfigValidatorTests.test_validate_all_consistent
```

### 7.3 Test Categories

**Version Tests (9)**: `tests/version_tests.py`
- Version parsing with and without build numbers
- Version comparison across build numbers
- Cross-edition comparison rejection
- Invalid version rejection
- Config loading for editions and versions
- Build generator payload shape validation
- Explicit build number handling

**Config Validator Tests (21)**: `tests/config_tests.py`
- Edition format validation (valid/invalid)
- Semantic version validation (valid/invalid)
- editions.json validation (structure, content, errors)
- version_config.json validation (structure, content, errors)
- app_manifest.json validation (structure, required fields, content)
- Cross-file consistency validation (mismatch detection)
- Manifest edition validation against supported editions

**Version History Tests (13)**: `tests/config_tests.py`
- Loading history from existing/new files
- Saving history with proper formatting
- Adding versions to new/existing editions
- Duplicate prevention
- Version format validation
- Latest version retrieval
- History existence checks
- Multi-edition management

---

## 8. COMPLETE WORKFLOW EXAMPLES

### 8.1 Development Workflow

```bash
# Day 1: Start work
cd Star\ Trails
python -m venv .venv
source .venv/bin/activate  # or .venv\Scripts\Activate.ps1 on Windows

# Setup auto-versioning
python scripts/setup_auto_versioning.py
# Output: Auto-versioning is ready!

# Development: Make changes to lib/ and core/
# (examples: fix bugs, add features)
git add lib/screens/menu_screen.dart
git add lib/utils/constants.dart

# Commit code
git commit -m "Fix merchant pricing logic"
# Hook runs automatically:
# Bumped PUB: 1.0.3 -> 1.0.4
# Bumped EDU46: 1.0.3 -> 1.0.4
# Bumped EDU79: 1.0.3 -> 1.0.4
# Bumped EDU1012: 1.0.3 -> 1.0.4
# Version auto-incremented and history updated

# View changes
git log -1
# Shows both code changes and version_config.json + version_history.json updated

# Day 2: Manual version bump needed (coordinated multi-edition release)
python scripts/bump_version.py minor
# Output:
# PUB: 1.0.4 -> 1.1.0
# EDU46: 1.0.4 -> 1.1.0
# EDU79: 1.0.4 -> 1.1.0
# EDU1012: 1.0.4 -> 1.1.0
```

### 8.2 Build Pipeline Workflow

```bash
# In CI/CD pipeline (GitHub Actions example)

- name: Checkout code
  uses: actions/checkout@v2

- name: Setup Python
  uses: actions/setup-python@v2
  with:
    python-version: '3.11'

- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: 'latest'

- name: Get Flutter dependencies
  run: flutter pub get

- name: Run tests
  run: |
    python -m unittest discover -s tests -p "*_tests.py"
    flutter test

- name: Generate version
  run: |
    python build/build_version_generator.py \
      --use-manifest \
      --validate-config \
      --set-github-output

- name: Build Android Release
  run: |
    export $(python build/build_version_generator.py --use-manifest)
    flutter build apk \
      --release \
      --build-name "$FLUTTER_BUILD_NAME" \
      --build-number "$FLUTTER_BUILD_NUMBER" \
      --dart-define APP_EDITION="$EDITION" \
      --dart-define FULL_VERSION="$FULL_VERSION"

- name: Upload artifact
  uses: actions/upload-artifact@v2
  with:
    name: "star-trails-${{ env.EDITION }}-${{ env.FULL_VERSION }}"
    path: build/app/outputs/flutter-apk/app-release.apk
```

### 8.3 Multi-Edition Release Workflow

```bash
# Release version 2.0.0 for all editions

# Step 1: Manual major version bump
python scripts/bump_version.py major

# Step 2: Verify versions
cat config/version_config.json
# Output:
# {
#   "versions": {
#     "PUB": "2.0.0",
#     "EDU46": "2.0.0",
#     "EDU79": "2.0.0",
#     "EDU1012": "2.0.0"
#   }
# }

# Step 3: Check manifest edition (controls default build)
cat config/app_manifest.json | jq '.edition'
# Output: "PUB"

# Step 4: Build each edition (or use CI/CD matrix)
for edition in PUB EDU46 EDU79 EDU1012; do
  python build/build_version_generator.py --edition "$edition" --validate-config
  # ... use output for build ...
done

# Step 5: Verify history updated correctly
python -c "from core.version_manager import VersionHistoryManager; VersionHistoryManager.print_history_report()"
# Output shows all editions with 2.0.0 as latest version
```

### 8.4 Configuration Validation in CI/CD

```bash
# Validate configuration before build process

python build/build_version_generator.py --use-manifest --validate-config

# Output (on success):
# EDITION=PUB
# VERSION=1.0.3
# BUILD_NUMBER=195269663
# FULL_VERSION=PUB-1.0.3+195269663
# FLUTTER_BUILD_NAME=1.0.3
# FLUTTER_BUILD_NUMBER=195269663

# On validation failure:
# ValueError: Configuration validation failed: 
# Editions mismatch between files. Missing in version_config.json: EDU79

# Build stops, full output provided for debugging
```

---

## 9. SYSTEM INVARIANTS & GUARANTEES

### 9.1 Correctness Invariants

1. **Edition Consistency**: All three config files (editions.json, version_config.json, app_manifest.json) must reference only consistent editions
   - Validation catches mismatches

2. **Version Ordering**: Versions in version_history.json are always in chronological order
   - Latest version is always at list end
   - VersionHistoryManager enforces this

3. **Semantic Versioning**: All versions follow Major.Minor.Patch format
   - No leading zeros
   - All components non-negative integers
   - Validation enforces compliance

4. **Edition Identity**: Edition names are immutable case-sensitive identifiers
   - Only alphanumeric uppercase allowed
   - Edition.from_string() is case-sensitive

5. **Build Number Isolation**: Build numbers are never persisted to version_config.json
   - Only exist in full version strings during build
   - Allows rebuild without version increment

### 9.2 Operational Guarantees

1. **Non-Blocking Commits**: Git hooks never block commits
   - Exit code always 0
   - Exceptions caught and logged
   - Commit proceeds if hook fails

2. **Non-Blocking Builds**: Configuration validation is optional
   - `--validate-config` flag enables it
   - Build succeeds without validation if flag not used

3. **No Data Loss**: All operations preserve history
   - Version history accumulated, never removed
   - Old versions accessible for analysis/rollback planning

4. **Idempotent Setup**: setup_auto_versioning.py can be run multiple times
   - Same result each time
   - No duplicates or conflicts

5. **Platform Transparency**: Hooks work identically on Windows, macOS, Linux
   - Logic encapsulated in platform-specific implementations
   - Wrapper routes automatically

### 9.3 API Stability

- Exception hierarchy defined explicitly
- Error messages are descriptive and actionable
- Function signatures follow Python conventions
- No internal state breaks between calls
- Dataclasses are frozen (immutable)

---

## 10. ERROR HANDLING & RECOVERY

### 10.1 Configuration Errors

**Missing Edition in manifest**:
```python
# Error: Manifest edition 'INVALID' not in supported editions: PUB, EDU46, EDU79, EDU1012
# Solution: Update config/app_manifest.json with valid edition
```

**Edition Mismatch**:
```python
# Error: Missing in version_config.json: EDU79
# Solution: Add "EDU79": "1.0.0" to config/version_config.json versions object
```

**Invalid Version Format**:
```python
# Error: Invalid version format: '1.0' (expected Format: Major.Minor.Patch)
# Solution: Use correct format like '1.0.3'
```

### 10.2 Runtime Recovery

**Failed Hook Execution**:
- Commit succeeds (exit 0)
- Version not bumped
- Manual bump required: `python scripts/bump_version.py patch`

**Failed Config Validation**:
- Build continues if `--validate-config` not used
- Use `--validate-config` flag to enforce validation
- Fix issues in config files and retry

**Missing Config Files**:
- ConfigValidator raises ConfigValidationError
- Message indicates which file is missing
- Create file with proper structure from examples

---

## 11. DEPLOYMENT CHECKLIST

### 11.1 Initial Setup

- [ ] Clone repository
- [ ] Create Python virtual environment
- [ ] Run `python scripts/setup_auto_versioning.py`
- [ ] Verify hooks installed: `ls -la .git/hooks/pre-commit*`
- [ ] Run tests: `python -m unittest discover -s tests -p "*_tests.py"`
- [ ] Validate config: `python build/build_version_generator.py --use-manifest --validate-config`

### 11.2 Pre-Release

- [ ] Update app_manifest.json if edition changing
- [ ] Run version bump: `python scripts/bump_version.py patch` (or major/minor)
- [ ] Verify version_config.json and version_history.json updated
- [ ] Review manifest edition matches target: `jq '.edition' config/app_manifest.json`
- [ ] Commit version changes with meaningful message
- [ ] Push to main branch

### 11.3 Build/Release

- [ ] Generate version: `python build/build_version_generator.py --use-manifest --validate-config`
- [ ] Confirm all output variables populated
- [ ] Use version info in build commands (--dart-define, --build-name, etc.)
- [ ] Tag release: `git tag v$(jq -r '.versions.PUB' config/version_config.json)`
- [ ] Upload artifacts with version in name

### 11.4 Post-Release

- [ ] Verify version_history.json includes release version
- [ ] Run `VersionHistoryManager.print_history_report()` to confirm
- [ ] Announce version to users/teams
- [ ] Archive release artifacts

---

## 12. TECHNICAL SPECIFICATIONS SUMMARY

| Aspect | Detail |
|--------|--------|
| **Supported Editions** | PUB, EDU46, EDU79, EDU1012 |
| **Version Format** | Edition-Major.Minor.Patch+Build |
| **Build Number Range** | 0 to 2,147,483,647 (32-bit safe) |
| **Configuration Language** | JSON |
| **Automation** | Git pre-commit hooks (PowerShell + Python) |
| **Testing** | Python unittest (43 tests, 100% pass) |
| **Dependencies** | Python 3.6+, Git (no external packages) |
| **Platforms** | Windows, macOS, Linux, CI/CD systems |
| **Backward Compatibility** | 100% (existing workflows unaffected) |
| **Integration Points** | Flutter (--dart-define), GitHub Actions, All CI/CD |
| **Performance** | <100ms for all operations |

---

## 13. VERSION HISTORY OF THIS SYSTEM

The versioning system was implemented in phases:

1. **Phase 1**: Core versioning module (edition, version, parser, validator)
2. **Phase 2**: Auto-versioning via Git hooks
3. **Phase 3**: Configuration validation module
4. **Phase 4**: Version history tracking system
5. **Phase 5**: Build generator enhancements (manifest support)
6. **Phase 6**: Comprehensive testing (43 unit tests)

**Current State**: Versioning/config infrastructure is production ready and fully tested. Runtime edition-content loading and runtime logging writer integration remain planned application-layer enhancements.

---

## END OF SPECIFICATION

**This document is complete and self-contained. All modules, APIs, workflows, and examples are documented above.**

**To verify correctness:**
1. Cross-reference module APIs with actual source code in `core/version_manager/`
2. Run all tests: `python -m unittest discover -s tests -p "*_tests.py"`
3. Test build generator with all flags: `python build/build_version_generator.py --use-manifest --validate-config`
4. Verify Git hooks integrate properly: Make test commit with `lib/` changes
5. Validate configuration: `python -c "from core.version_manager import ConfigValidator; ConfigValidator.print_validation_report()"`
