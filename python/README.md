# Scripts Directory

This directory contains NuShell setup scripts and automation for the AI Agent MCP Server project.

## Directory Structure

```
scripts/
├── setup.nu              # Main setup orchestrator (entry point)
├── build.nu              # Build script to create standalone merged setup.nu
├── lib/                  # NuShell module library
│   ├── common.nu                 # Common utilities (shared functions)
│   ├── os_detection.nu           # OS detection module
│   ├── prerequisites.nu          # Prerequisites validation
│   ├── venv_setup.nu             # Virtual environment setup
│   ├── deps_install.nu           # Dependency installation
│   ├── config_setup.nu           # Configuration setup
│   ├── validation.nu             # Environment validation
│   └── interactive.nu            # Interactive prompts
└── tests/                # NuShell module tests
    ├── unit/
    │   ├── test_os_detection.nu
    │   └── test_prerequisites.nu
    └── integration/
        └── run_all_tests.nu
```

## Usage

### Running Setup Script (Development)

```bash
# Enter devbox shell
devbox shell

# Run setup script
nu scripts/setup.nu

# Run in silent mode (CI/automation)
nu scripts/setup.nu --silent
```

### Building Standalone Script (Distribution)

The build script merges all modules into a single executable file for easy distribution:

```bash
# Build via Taskfile (recommended)
task setup:build

# Or run build script directly
nu scripts/build.nu --yes
```

**Output**: `dist/setup.nu` (single 51KB file, ~1,650 lines)

**Features**:
- Discovers and includes only referenced modules
- Transforms cross-module references (`use lib/common.nu *` → `use common *`)
- Shows preview of included modules before building
- Validates output with help test

### Running Standalone Script (Production)

#### Local Execution
```bash
# Download and run
curl -fsSL https://example.com/setup.nu -o setup.nu
nu setup.nu --silent

# Or save and execute
wget https://example.com/setup.nu
nu setup.nu
```

#### Inline Execution (No Local File)

**Using process substitution** (recommended, no file saved to disk):

```bash
# Interactive mode
nu <(curl -fsSL https://example.com/setup.nu)

# Silent mode (CI/CD)
nu <(curl -fsSL https://example.com/setup.nu) --silent

# Show help
nu <(curl -fsSL https://example.com/setup.nu) --help
```

**How it works**:
- `<(curl ...)` creates a temporary file descriptor (like `/dev/fd/11`)
- Nushell reads from it as if it were a file
- Nothing written to disk
- Equivalent to piping in bash

**Note**: Direct piping (`curl | nu`) does NOT work - Nushell doesn't support stdin execution like bash.

### Running Tests

```bash
# Run all unit tests
task test:nu:unit

# Run integration tests
task test:nu:integration

# Run quick tests (skip slow ones)
task test:nu:quick

# Or run manually
nu scripts/tests/unit/test_os_detection.nu
nu scripts/tests/integration/run_all_tests.nu
```

## Module Conventions

### Import Pattern

All modules use **explicit exports** with `export def`:

```nushell
# In module file (scripts/lib/my_module.nu)
export def my_function [] -> string {
    "Hello from module"
}

# In another file (development)
use lib/my_module.nu *

# In standalone build (automatic transformation)
# use lib/my_module.nu * → use my_module *
```

### Cross-Module Dependencies

Modules can reference each other using `use`:

```nushell
# In scripts/lib/validation.nu
use common *  # Uses common.nu module

export def validate_something [] {
    check_binary_exists "python"  # Function from common module
}
```

The build script automatically:
1. Discovers all module dependencies recursively
2. Includes only referenced modules
3. Transforms `use` statements to reference inline modules

### From Test Files

Tests import modules using relative paths:

```nushell
# In scripts/tests/unit/test_my_module.nu
use ../../lib/my_module.nu *
```

## Build System

### How Build Works

1. **Dependency Discovery**
   - Parses `use` statements from `scripts/setup.nu`
   - Recursively discovers module dependencies
   - Example: `setup.nu` uses `common`, `validation` uses `common` → both included

2. **Module Transformation**
   - Wraps each module in `module { ... }` block
   - Transforms cross-module references: `use common.nu *` → `use common *`
   - Removes external file references

3. **Assembly**
   - Combines: shebang + module definitions + use statements + main script
   - Generates executable standalone script
   - Validates with `--help` test

4. **Output**
   ```
   dist/setup.nu structure:
   ├── #!/usr/bin/env nu
   ├── module common { ... }
   ├── module config_setup { ... }
   ├── module deps_install { ... }
   ├── ... (all discovered modules)
   ├── use common *
   ├── use config_setup *
   ├── ... (use statements)
   └── <main script code>
   ```

### Build Script Features

```bash
nu scripts/build.nu --yes
```

**Output**:
```
🔍 Analyzing module dependencies...

📦 Found 8 required modules:
  • common (7.5 kB bytes)
  • config_setup (4.6 kB bytes)
  • deps_install (5.9 kB bytes)
  • interactive (3.5 kB bytes)
  • os_detection (3.2 kB bytes)
  • prerequisites (6.9 kB bytes)
  • validation (6.6 kB bytes)
  • venv_setup (4.6 kB bytes)

📋 Build plan:
  Main script: scripts/setup.nu
  Modules: common, config_setup, deps_install, interactive, os_detection, prerequisites, validation, venv_setup
  Output: dist/setup.nu

✓ Auto-confirming build (--yes flag)

🔨 Building standalone script...
  Processing module: common
  Processing module: config_setup
  ...

✅ Built dist/setup.nu (51.2 kB bytes)
🧪 Testing standalone script...
✅ Script validation passed
```

## Module Documentation

### common.nu

Common utilities used across all modules.

**Exported Functions:**
- `get_python_bin_path [venv_path: string] -> string` - Get Python binary path
- `get_precommit_bin_path [venv_path: string] -> string` - Get pre-commit binary path
- `check_binary_exists [binary_name: string] -> record` - Check if binary exists in PATH
- `get_binary_version [binary_name: string, version_flag: string] -> record` - Get binary version
- `get_uv_version [] -> string` - Get installed UV version

### os_detection.nu

Detects operating system, architecture, and version.

**Exported Functions:**
- `detect_os [] -> record<os: string, arch: string, version: string>`

**Supported OS:**
- macOS (Darwin)
- Linux (Ubuntu, Fedora, Arch, etc.)
- WSL2 (Windows Subsystem for Linux)

### prerequisites.nu

Validates required tools are installed and meet version requirements.

**Exported Functions:**
- `check_prerequisites [] -> record`

**Validated Tools:**
- Python 3.11+
- Podman
- Git
- Taskfile
- UV (uv package manager)

### venv_setup.nu

Handles Python virtual environment creation and management.

**Exported Functions:**
- `create_venv [venv_path: string] -> record`
- `check_venv_exists [venv_path: string] -> bool`
- `get_venv_python_version [venv_path: string] -> record`

### deps_install.nu

Dependency installation with retry logic and progress indicators.

**Exported Functions:**
- `install_dependencies [venv_path: string] -> record`
- `sync_dependencies [venv_path: string] -> record`

**Features:**
- Retry logic (3 attempts with exponential backoff)
- Network failure handling
- Progress indicators
- Duration tracking

### config_setup.nu

Configuration setup including environment files and pre-commit hooks.

**Exported Functions:**
- `setup_env_file [] -> record`
- `install_precommit_hooks [venv_path: string] -> record`
- `setup_configuration [venv_path: string] -> record`

### validation.nu

Comprehensive environment validation checks.

**Exported Functions:**
- `validate_environment [venv_path: string] -> record`
- `validate_python_version [venv_path: string] -> record`
- `validate_taskfile [] -> record`
- `validate_dependencies [venv_path: string] -> record`

### interactive.nu

User prompt handling with silent mode support.

**Exported Functions:**
- `get_setup_preferences [silent: bool] -> record`
- `confirm_action [message: string, default: bool, silent: bool] -> bool`
- `display_setup_summary [preferences: record]`

## Development Guidelines

### Adding New Modules

1. Create module file in `scripts/lib/module_name.nu`
2. Use explicit exports: `export def function_name [] { ... }`
3. Add module header documentation with usage examples
4. If using other modules: `use common *` at top of file
5. Create test file in `scripts/tests/unit/test_module_name.nu`
6. Import with relative path: `use ../../lib/module_name.nu *`
7. Rebuild standalone script: `task setup:build`

### Testing Requirements

- All modules must have corresponding test files
- Tests must use explicit import pattern
- Tests should be idempotent (can run multiple times)
- Tests should work in any environment (use mocks when needed)
- Run tests before committing: `task test:nu:unit`

### Code Style

- Use structured data (records, lists) over string parsing
- Prefer NuShell built-in commands over external tools
- Use `try-catch` for error handling
- Provide actionable error messages with remediation steps
- Document function parameters and return types
- Export only public functions (keep helpers internal)

### Build Integration

When adding/removing modules:
1. Update `use` statements in `scripts/setup.nu`
2. Build script automatically discovers dependencies
3. Run `task setup:build` to verify standalone script works
4. Test standalone script: `nu dist/setup.nu --help`

## Distribution Patterns

### For GitHub Releases

```bash
# Build standalone script
task setup:build

# Upload dist/setup.nu as release asset
gh release create v1.0.0 dist/setup.nu

# Users can then run:
nu <(curl -fsSL https://github.com/user/repo/releases/download/v1.0.0/setup.nu) --silent
```

### For Raw GitHub Content

```bash
# Commit dist/setup.nu to repository
git add dist/setup.nu
git commit -m "build: Update standalone setup script"

# Users can run:
nu <(curl -fsSL https://raw.githubusercontent.com/user/repo/main/dist/setup.nu)
```

### For CI/CD Pipelines

```yaml
# .github/workflows/setup.yml
steps:
  - name: Run setup
    run: |
      nu <(curl -fsSL https://example.com/setup.nu) --silent
```

## Troubleshooting

### Build Issues

**Problem**: Build script fails with "module not found"
```bash
# Solution: Check use statements in modules
grep -r "^use " scripts/lib/*.nu
```

**Problem**: Standalone script validation fails
```bash
# Solution: Test individual modules first
nu scripts/setup.nu --help
task test:nu:unit
```

### Execution Issues

**Problem**: `curl | nu` doesn't work
```bash
# Solution: Use process substitution instead
nu <(curl -fsSL https://example.com/setup.nu)
```

**Problem**: "Module not found" in standalone script
```bash
# Solution: Rebuild to include missing modules
task setup:build
```

## Related Documentation

- **CLAUDE.md** - Root orchestration and conventions (Section: Implementation Phase Instructions)
- **SPEC-001** - Technical specification for setup script
- **US-001** - User story for automated setup script
- **devbox.json** - Development environment configuration
- **Taskfile.yml** - Task automation (see `task --list` for available commands)
