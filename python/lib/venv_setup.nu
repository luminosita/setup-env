# Python Virtual Environment Setup Module
#
# This module handles the creation and management of Python virtual environments using uv.
# It creates a virtual environment at .venv/ and provides utilities to activate and verify it.
#
# Public Functions:
# - create_venv: Create Python virtual environment using uv
# - check_venv_exists: Check if virtual environment exists
# - get_venv_python_version: Get Python version in virtual environment

use ../../common/lib/common.nu *

# Create Python virtual environment using uv
# Args:
#   venv_path: string - Path where virtual environment should be created (default: .venv)
#   python_version: string - Python version to use (default: 3.11)
# Returns: record {success: bool, path: string, python_version: string, error: string}
export def create_venv [
    venv_path: string = ".venv"
    python_version: string = "3.11"
] {
    print $"🐍 Creating Python virtual environment at ($venv_path)..."

    # Check if venv already exists
    let check = (check_venv_exists $venv_path)

    if $check.exists {
        print $"ℹ️  Virtual environment already exists at ($check.path)"
        return (verify_venv_and_get_version $venv_path "Using existing venv")
    }

    # Create virtual environment using uv
    print $"📦 Running: uv venv ($venv_path) --python ($python_version)"

    let result = (^uv venv $venv_path --python $python_version | complete)

    if $result.exit_code != 0 {
        return {
            success: false,
            path: "",
            python_version: "",
            error: $"Virtual environment creation failed: ($result.stderr)"
        }
    }

    # Verify creation and get version
    return (verify_venv_and_get_version $venv_path "Virtual environment created")
}

# Check if virtual environment exists (exported version)
# Args:
#   venv_path: string - Path to virtual environment (default: .venv)
# Returns: record {exists: bool, path: string}
export def check_venv [venv_path: string = ".venv"] {
    return (check_venv_exists $venv_path)
}

# Check if virtual environment exists
# Args:
#   venv_path: string - Path to virtual environment (default: .venv)
# Returns: record {exists: bool, path: string}
def check_venv_exists [venv_path: string = ".venv"] {
    let venv_full_path = ($venv_path | path expand)
    let python_bin = (get_python_bin_path $venv_full_path)

    let exists = ($python_bin | path exists)

    return {exists: $exists, path: $venv_full_path}
}

# Get Python version in virtual environment
# Args:
#   venv_path: string - Path to virtual environment
# Returns: record {success: bool, version: string, error: string}
export def get_venv_python_version [venv_path: string = ".venv"] {
    let python_bin = (get_python_bin_path $venv_path)

    if not ($python_bin | path exists) {
        return {
            success: false,
            version: "",
            error: $"Python binary not found at ($python_bin)"
        }
    }

    let version_result = (get_binary_version $python_bin "--version")

    if $version_result.success {
        # Remove "Python " prefix from version
        let clean_version = ($version_result.version | str replace "Python " "")
        return {success: true, version: $clean_version, error: ""}
    } else {
        return {
            success: false,
            version: "",
            error: $version_result.error
        }
    }
}

# Verify venv and get its Python version (extracted common logic)
# Args:
#   venv_path: string - Path to virtual environment
#   action_msg: string - Message describing the action ("Using existing venv" or "Virtual environment created")
# Returns: record {success: bool, path: string, python_version: string, error: string}
def verify_venv_and_get_version [
    venv_path: string
    action_msg: string
] {
    let check = (check_venv_exists $venv_path)

    if not $check.exists {
        return {
            success: false,
            path: "",
            python_version: "",
            error: $"Virtual environment not found at ($venv_path)"
        }
    }

    # Get Python version
    let py_ver = (get_venv_python_version $check.path)

    if $py_ver.success {
        print $"✅ ($action_msg) with Python ($py_ver.version)"
        return {
            success: true,
            path: $check.path,
            main_bin_version: $py_ver.version,
            error: ""
        }
    } else {
        print $"⚠️  Warning: ($action_msg) but Python version check failed"
        return {
            success: true,
            path: $check.path,
            python_version: "unknown",
            error: ""
        }
    }
}
