## 🐚 NuShell - Cross-Platform Shell

### Why NuShell?
NuShell provides cross-platform shell scripting with:
- **Works on macOS, Linux, BSD, and Windows** natively
- **Structured data pipelines** (like JSON, CSV, tables)
- **Type-safe** shell scripting
- **Modern syntax** with improved error messages
- **Replaces Bash** for cross-platform compatibility
- **Built-in commands** for common operations

### NuShell Installation

```bash
# Install NuShell (macOS)
brew install nushell

# Install NuShell (Linux - cargo)
cargo install nu

# Install NuShell (Windows)
winget install nushell

# Or via Devbox (recommended - see Devbox section)
devbox add nushell
```

### NuShell Basic Syntax

```nu
# Variables
let name = "John"
let age = 30
let is_active = true

# Lists
let fruits = ["apple" "banana" "orange"]
let numbers = [1 2 3 4 5]

# Records (like objects/dicts)
let user = {
    name: "John"
    age: 30
    email: "john@example.com"
}

# Conditionals
if $age > 18 {
    print "Adult"
} else {
    print "Minor"
}

# Loops
for fruit in $fruits {
    print $fruit
}

# Pipelines (structured data)
ls | where size > 1kb | select name size | sort-by size

# Error handling
try {
    open file.txt
} catch {
    print "File not found"
}
```

### NuShell Script Example (setup.nu)

```nu
#!/usr/bin/env nu

# Automated environment setup script
# Usage: nu setup.nu [--silent]

def main [--silent] {
    print "🚀 Starting environment setup..."

    # Detect OS (sys requires subcommand)
    let os = (sys host | get name)
    print $"Detected OS: ($os)"

    # Check prerequisites
    check_prerequisites

    # Install uv if not present
    if (which uv | is-empty) {
        print "Installing uv package manager..."
        install_uv
    }

    # Create virtual environment
    print "Creating virtual environment..."
    ^uv venv .venv

    # Install dependencies
    print "Installing dependencies..."
    ^uv sync --all-extras

    # Configure pre-commit (uses pre-commit from devbox or system)
    print "Configuring pre-commit hooks..."
    ^pre-commit install

    # Copy .env.example if needed
    if not (".env" | path exists) {
        ^cp .env.example .env
        print "✅ Created .env file from template"
    }

    # Validate environment
    validate_environment

    print "✅ Setup complete! Run 'uv run uvicorn main:app --reload' to start server"
}

def check_prerequisites [] {
    print "Checking prerequisites..."

    # Check Python version
    let python_version = (python --version | parse "Python {version}" | get version.0)
    if ($python_version < "3.11") {
        error make {msg: "Python 3.11+ required"}
    }
    print $"✅ Python ($python_version)"

    # Check git
    if (which git | is-empty) {
        error make {msg: "Git is required"}
    }
    print "✅ Git installed"

    # Check podman
    if (which podman | is-empty) {
        print "⚠️  Podman not found (optional)"
    } else {
        print "✅ Podman installed"
    }
}

def install_uv [] {
    # Install uv via curl
    http get https://astral.sh/uv/install.sh | bash
}

def validate_environment [] {
    print "Validating environment..."

    # Test imports
    uv run python -c "import fastapi; import pydantic"
    print "✅ All dependencies importable"

    # Check .venv exists
    if (".venv" | path exists) {
        print "✅ Virtual environment created"
    }
}
```

### NuShell Module Organization

**CRITICAL: Use explicit exports for all modules (Decision D1 from SPEC-001 v1)**

NuShell supports module-based code organization for better maintainability and reusability. Follow these guidelines:

#### Module Structure Pattern

```
scripts/
├── setup.nu                 # Main entry point (orchestrator)
├── lib/
│   ├── os_detection.nu      # Module: OS detection (export def detect_os)
│   ├── prerequisites.nu     # Module: Prerequisites validation (export def check_prerequisites)
│   ├── validation.nu        # Module: Environment validation (export def validate_environment)
│   └── error_handler.nu     # Module: Error handling (export def retry_with_backoff)
└── tests/                   # NuShell tests

```

#### Import Strategy: `use` vs `source`

**✅ ALWAYS use `use` with explicit imports (Decision D1)**
- Provides namespace isolation
- Better IDE support and autocomplete
- Clear function dependencies
- Prevents namespace pollution

**❌ NEVER use `source`**
- Pollutes namespace with all functions
- No explicit dependency management
- Harder to track function origins

#### Explicit Exports (REQUIRED)

All public functions must use `export def`:

```nu
# ✅ CORRECT: Explicit export
# scripts/lib/os_detection.nu

# Detect operating system, architecture, and version
# Returns: record {os: string, arch: string, version: string}
# NOTE: Detailed type annotations (-> record<...>) not supported in NuShell 0.106+
export def detect_os [] {
    # Use sys host subcommand (sys requires a subcommand)
    let sys_info = (sys host)

    let os_name = $sys_info.name
    # sys host doesn't provide arch field, use external uname command
    let arch = (^uname -m | str trim)

    return {
        os: $os_name,
        arch: $arch,
        version: $sys_info.kernel_version
    }
}

# ❌ WRONG: Plain def (not exported, cannot be imported)
def detect_os [] {
    # ... implementation
}
```

#### Module Import Pattern

```nu
# ✅ CORRECT: Explicit function import
use scripts/lib/os_detection.nu detect_os
use scripts/lib/prerequisites.nu check_prerequisites
use scripts/lib/validation.nu validate_environment

# Call imported functions
let os_info = (detect_os)
let prereqs = (check_prerequisites)
let validation = (validate_environment)

# ❌ WRONG: source (pollutes namespace)
source scripts/lib/os_detection.nu
source scripts/lib/prerequisites.nu
```

#### Helper Functions (Private)

Helper functions that should NOT be exported use plain `def`:

```nu
# scripts/lib/prerequisites.nu

# Public function (exported)
export def check_prerequisites [] -> record {
    let python_check = check_python  # Call private helper

    return {
        python: $python_check.ok,
        python_version: $python_check.version
    }
}

# Private helper function (NOT exported)
def check_python [] -> record {
    let version_output = (python --version | complete)

    if $version_output.exit_code != 0 {
        return {ok: false, version: ""}
    }

    return {ok: true, version: $version_output.stdout}
}
```

#### Complete Module Example

**scripts/lib/validation.nu:**
```nu
# Environment validation module
# Provides comprehensive health checks for development environment

# Public function: Validate entire environment
# NOTE: Type annotations (-> record) not supported in detail, use comment documentation
export def validate_environment [] {
    print "Validating environment..."

    mut checks = []

    # Run all validation checks
    $checks = ($checks | append (check_python_version))
    $checks = ($checks | append (check_venv_exists))
    $checks = ($checks | append (check_dependencies_importable))

    let passed = ($checks | where passed == true | length)
    let failed = ($checks | where passed == false | length)

    return {
        passed: $passed,
        failed: $failed,
        checks: $checks
    }
}

# Private helper: Check Python version
def check_python_version [] {
    let version = (python --version | parse "Python {version}" | get version.0)

    if ($version >= "3.11") {
        return {name: "Python version", passed: true, message: $"Python ($version)"}
    } else {
        return {name: "Python version", passed: false, message: $"Python ($version) < 3.11"}
    }
}

# Private helper: Check venv exists
def check_venv_exists [] {
    if (".venv" | path exists) {
        return {name: "Virtual environment", passed: true, message: ".venv directory exists"}
    } else {
        return {name: "Virtual environment", passed: false, message: ".venv directory missing"}
    }
}

# Private helper: Check dependencies importable
def check_dependencies_importable [] {
    let result = (^uv run python -c "import fastapi; import pydantic" | complete)

    if $result.exit_code == 0 {
        return {name: "Dependencies", passed: true, message: "All dependencies importable"}
    } else {
        return {name: "Dependencies", passed: false, message: "Import failed"}
    }
}
```

**scripts/setup.nu:**
```nu
#!/usr/bin/env nu

# Main setup script (orchestrator)
# Usage: nu setup.nu [--silent]

# Import modules with explicit function imports (per Decision D1)
use scripts/lib/os_detection.nu detect_os
use scripts/lib/prerequisites.nu check_prerequisites
use scripts/lib/validation.nu validate_environment

def main [--silent] {
    print "🚀 Starting environment setup..."

    # Use imported functions
    let os_info = (detect_os)
    print $"Detected OS: ($os_info.os) ($os_info.arch)"

    let prereqs = (check_prerequisites)
    if ($prereqs.errors | length) > 0 {
        print "❌ Prerequisites check failed:"
        $prereqs.errors | each { |err| print $"  - ($err)" }
        exit 1
    }

    # ... rest of setup logic

    let validation = (validate_environment)
    print $"Validation: ($validation.passed)/($validation.passed + $validation.failed) checks passed"

    if $validation.failed > 0 {
        print "❌ Environment validation failed"
        exit 1
    }

    print "✅ Setup complete!"
}
```

#### Best Practices

1. **One module per responsibility** - Each .nu file should have a single, clear purpose
2. **Use explicit exports** - Always use `export def` for public functions
3. **Document function signatures** - Include parameter and return types
4. **Keep modules focused** - Avoid large, multi-purpose modules
5. **Use helper functions** - Private helpers (plain `def`) for internal logic
6. **Import explicitly** - Use `use module.nu function_name`, not `use module.nu *`
7. **Test modules independently** - Each module should be unit-testable

#### Module Import Examples

```nu
# ✅ CORRECT: Import specific functions
use scripts/lib/os_detection.nu detect_os
use scripts/lib/prerequisites.nu [check_prerequisites check_python]

# ✅ CORRECT: Import all exports from module (when needed)
use scripts/lib/validation.nu *

# ❌ WRONG: source pollutes namespace
source scripts/lib/os_detection.nu

# ❌ WRONG: Plain def without export (cannot be imported)
# In module:
def my_function [] {  # Missing 'export'
    print "This cannot be imported!"
}
```

#### References

- **NuShell Modules Documentation:** https://www.nushell.sh/book/modules.html
- **SPEC-001 v2 Decision D1:** Use `use` with explicit exports for maintainability
- **Implementation Guide:** See `/artifacts/tech_specs/SPEC-001_automated_setup_script_v2.md`

### Common NuShell Pitfalls & Solutions

**IMPORTANT**: Real issues encountered during implementation (NuShell 0.106.1). Follow these patterns to avoid syntax errors.

#### 1. Type Annotations Not Supported

**❌ WRONG:**
```nu
export def detect_os [] -> record<os: string, arch: string, version: string> {
    # Error: Parse mismatch, detailed type annotations not supported
}
```

**✅ CORRECT:**
```nu
# Use comment documentation for type information
# Returns: record {os: string, arch: string, version: string}
export def detect_os [] {
    return {os: "macos", arch: "arm64", version: "14.5"}
}
```

#### 2. sys Command Requires Subcommand

**❌ WRONG:**
```nu
let sys_info = (sys | get host)  # Error: sys doesn't support piping
```

**✅ CORRECT:**
```nu
let sys_info = (sys host)  # Use sys host subcommand directly
```

#### 3. sys host Doesn't Provide Architecture

**❌ WRONG:**
```nu
let sys_info = (sys host)
let arch = $sys_info.arch  # Error: Column 'arch' not found
```

**✅ CORRECT:**
```nu
let sys_info = (sys host)
let arch = (^uname -m | str trim)  # Use external uname with ^ prefix
```

#### 4. External Commands Need ^ Prefix

**❌ WRONG:**
```nu
uv venv .venv           # May conflict with NuShell builtins
tar -xzf file.tar.gz    # Error: NuShell tries to parse flags
```

**✅ CORRECT:**
```nu
^uv venv .venv          # ^ prefix ensures external command
^tar -xzf file.tar.gz   # Prevents NuShell flag parsing
^chmod +x script.sh
^mv source dest
```

#### 5. Mutable Variables in Catch Blocks

**❌ WRONG:**
```nu
mut error_msg = ""
try {
    # ... code
} catch { |err|
    $error_msg = $"Failed: ($err)"  # Error: Capture of mutable variable
}
```

**✅ CORRECT:**
```nu
let result = (try {
    # ... code
    {success: true, error: ""}
} catch { |err|
    {success: false, error: $"Failed: ($err)"}
})

if not $result.success {
    print $result.error
}
```

#### 6. String Interpolation with Parentheses

**❌ WRONG:**
```nu
print $"Detected: ($result.os)"  # Error: Shell tries to execute 'detected:' command
```

**✅ CORRECT - Option 1: Extract variable**
```nu
let detected_os = $result.os
print $"Detected: ($detected_os)"
```

**✅ CORRECT - Option 2: Escape parentheses**
```nu
print $"Detected: \(($result.os)\)"
```

#### 7. Shell Redirection (Bash-style Not Supported)

**❌ WRONG:**
```nu
let output = (command 2>&1 | complete)  # Error: Use out+err> not 2>&1
```

**✅ CORRECT:**
```nu
let output = (^command | complete)  # complete captures stdout + stderr
```

#### 8. Test Assertions with Comparisons

**❌ WRONG:**
```nu
assert ($result.arch | str length) > 0  # Error: Extra positional argument
```

**✅ CORRECT:**
```nu
assert (($result.arch | str length) > 0)  # Wrap comparison in extra parentheses
```

#### 9. Version Parsing Edge Cases

**❌ FRAGILE:**
```nu
let version = ($output | split row " " | get 1)
# Breaks on "Python 3.11.5+" or "Python 3.11.5rc1"
```

**✅ ROBUST:**
```nu
let version_str = ($output | str trim | split row " " | get 1)
let clean_version = ($version_str | split row "+" | get 0 | split row "rc" | get 0)
let parts = ($clean_version | split row ".")
let major = ($parts | get 0 | into int)
let minor = ($parts | get 1 | into int)
```

#### 10. Error Handling Best Practices

**❌ WRONG:**
```nu
def check_tool [] {
    if (which tool | is-empty) {
        error make {msg: "Tool not found"}  # Abrupt exit
    }
}
```

**✅ CORRECT:**
```nu
def check_tool [] {
    if (which tool | is-empty) {
        return {ok: false, error: "Tool not found. Install: devbox add tool"}
    }
    return {ok: true, error: ""}
}
```

### NuShell vs Bash Comparison

| Feature | Bash | NuShell |
|---------|------|---------|
| **Cross-platform** | ❌ (macOS/Linux only) | ✅ (macOS/Linux/Windows) |
| **Structured data** | ❌ (text-based) | ✅ (JSON, CSV, tables) |
| **Type safety** | ❌ | ✅ |
| **Error messages** | Poor | Excellent |
| **Modern syntax** | ❌ | ✅ |
| **Learning curve** | Medium | Medium |

### NuShell Commands Reference

```bash
# File operations
ls                    # List files (returns table)
open file.txt         # Read file
save file.txt         # Write file
cp source dest        # Copy
mv source dest        # Move
rm file.txt           # Remove

# Data manipulation
ls | where size > 1mb                    # Filter
ls | select name size                    # Select columns
ls | sort-by size                        # Sort
ls | first 5                             # Limit
open data.json | get users | length      # JSON operations

# System operations
sys                   # System information
ps                    # Process list
which python          # Find command
env                   # Environment variables

# String operations
"hello world" | str upcase               # Uppercase
"  text  " | str trim                    # Trim whitespace
"hello,world" | split row ","            # Split string

# HTTP operations
http get https://api.github.com/repos/nushell/nushell
http post https://api.example.com/data { key: "value" }
```

**NuShell Scripting Conventions:**
- **Location:** All NuShell scripts in `scripts/` directory
- **Module Library:** Reusable modules in `scripts/lib/` with explicit exports (`export def`)
- **Testing:** NuShell module tests in `scripts/tests/` (NOT in `tests/` directory)
- **Import Pattern:** Use `use ../lib/module.nu function_name` for explicit imports (per SPEC-001 D1)
- **Test Execution:** Run tests with `nu scripts/tests/test_module_name.nu`
- **Naming Convention:** Test files named `test_module_name.nu` matching module being tested

**Directory Separation:**
- `scripts/` - NuShell setup scripts and automation (DevOps/Infrastructure)
- `tests/` - Python application tests (unit, integration, e2e)
- `src/` - Python application source code

---
