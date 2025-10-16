# Environment Validation Module
#
# This module performs comprehensive health checks on the development environment
# including Python version, Taskfile functionality, dependency imports, and
# file permissions.
#
# Public Functions:
# - validate_environment: Run all validation checks
# - validate_python_version: Check Python version >= 3.11
# - validate_taskfile: Check Taskfile installation and functionality
# - validate_dependencies: Test critical module imports

use common.nu

# Run all validation checks
# Args:
#   venv_path: string - Path to virtual environment (default: .venv)
# Returns: record {passed: int, failed: int, checks: list}
export def validate_environment [venv_path: string = ".venv"] {
    print "\n🔍 Running environment validation checks...\n"

    mut checks = []

    # Run all checks
    $checks = ($checks | append (validate_python_version $venv_path))
    $checks = ($checks | append (validate_taskfile))
    $checks = ($checks | append (validate_dependencies $venv_path))
    $checks = ($checks | append (validate_env_file))
    $checks = ($checks | append (validate_precommit_hooks))
    $checks = ($checks | append (validate_venv_permissions $venv_path))

    # Count passed/failed
    let passed = ($checks | where passed == true | length)
    let failed = ($checks | where passed == false | length)

    # Display results
    print $"Validation Results: ($passed)/($passed + $failed) checks passed\n"

    for check in $checks {
        if $check.passed {
            print $"✅ ($check.name): ($check.message)"
        } else {
            print $"❌ ($check.name): ($check.error)"
        }
    }

    print ""

    return {
        passed: $passed,
        failed: $failed,
        checks: $checks
    }
}

# Validation check record structure:
# {name: string, passed: bool, message: string, error: string}

# Validate Python version (>= 3.11)
# Assumes Python binary exists (validated in earlier setup phase)
# Args:
#   venv_path: string - Path to virtual environment
# Returns: record {name, passed, message, error}
export def validate_python_version [venv_path: string = ".venv"] {
    let check_name = "Python Version (>= 3.11)"

    let python_bin = (common get_python_bin_path $venv_path)

    # Get version (assumes binary exists)
    let version_result = (common get_binary_version $python_bin "--version")

    # Validate version meets requirement (using common.nu function)
    let validation = (common validate_python_version $version_result.version 3 11)

    if $validation.valid {
        let requirement = ">= 3.11"
        return {
            name: $check_name,
            passed: true,
            message: $"Python ($validation.version.full) meets requirement \(($requirement)\)",
            error: ""
        }
    } else {
        return {
            name: $check_name,
            passed: false,
            message: "",
            error: $validation.error
        }
    }
}

# Validate Taskfile functionality
# Assumes Taskfile binary exists (validated in earlier setup phase)
# Returns: record {name, passed, message, error}
def validate_taskfile [] {
    let check_name = "Taskfile Functionality"

    # Check task --list (assumes task binary exists)
    let list_result = (^task --list | complete)

    if not (common command_succeeded $list_result) {
        return {
            name: $check_name,
            passed: false,
            message: "",
            error: $"Taskfile --list command failed: ($list_result.stderr)"
        }
    } else {
        return {
            name: $check_name,
            passed: true,
            message: $"Taskfile functional",
            error: ""
        }
    }
}

# Validate critical module imports
# Assumes Python binary exists (validated in earlier setup phase)
# Args:
#   venv_path: string - Path to virtual environment
# Returns: record {name, passed, message, error}
def validate_dependencies [venv_path: string = ".venv"] {
    let check_name = "Critical Module Imports"

    let python_bin = (common get_python_bin_path $venv_path)

    # Try to import mcp_server package (assumes python binary exists)
    let import_cmd = "import mcp_server; print('OK')"
    let result = (^$python_bin -c $import_cmd | complete)

    if (common command_succeeded $result) {
        return {
            name: $check_name,
            passed: true,
            message: "All critical modules importable",
            error: ""
        }
    } else {
        return {
            name: $check_name,
            passed: false,
            message: "",
            error: $"Module import failed: ($result.stderr)"
        }
    }
}

# Validate .env file exists
# Returns: record {name, passed, message, error}
def validate_env_file [] {
    let check_name = ".env File Exists"

    if (".env" | path exists) {
        return {
            name: $check_name,
            passed: true,
            message: ".env file configured",
            error: ""
        }
    } else {
        return {
            name: $check_name,
            passed: false,
            message: "",
            error: ".env file not found"
        }
    }
}

# Validate pre-commit hooks installed
# Returns: record {name, passed, message, error}
def validate_precommit_hooks [] {
    let check_name = "Pre-commit Hooks Installed"

    # Check if .git/hooks/pre-commit exists
    let hook_path = (".git" | path join "hooks" "pre-commit")

    if ($hook_path | path exists) {
        return {
            name: $check_name,
            passed: true,
            message: "Pre-commit hooks installed",
            error: ""
        }
    } else {
        return {
            name: $check_name,
            passed: false,
            message: "",
            error: "Pre-commit hooks not installed in .git/hooks/"
        }
    }
}

# Validate file permissions for .venv
# Assumes venv exists (created in earlier setup phase)
# Args:
#   venv_path: string - Path to virtual environment
# Returns: record {name, passed, message, error}
def validate_venv_permissions [venv_path: string = ".venv"] {
    let check_name = "Virtual Environment Permissions"

    # Check if venv directory is readable (assumes it exists)
    let python_bin = (common get_python_bin_path $venv_path)

    if ($python_bin | path exists) {
        return {
            name: $check_name,
            passed: true,
            message: "Virtual environment permissions OK",
            error: ""
        }
    } else {
        return {
            name: $check_name,
            passed: false,
            message: "",
            error: $"Python binary not accessible at ($python_bin)"
        }
    }
}
