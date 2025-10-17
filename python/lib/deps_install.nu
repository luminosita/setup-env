# Dependency Installation Module
#
# This module handles Python dependency installation via uv package manager.
# It includes retry logic for network failures, progress indicators, and
# comprehensive error handling.
#
# Public Functions:
# - install_dependencies: Install Python dependencies from pyproject.toml
# - sync_dependencies: Sync dependencies (uv sync command)

use ../../common/lib/common.nu *

# Install dependencies
# Args:
#   venv_path: string - Path to virtual environment (default: .venv)
# Returns: record {success: bool, packages: int, duration: duration, error: string}
export def install_dependencies [venv_path: string] {
    print "📦 Installing Python dependencies..."

    # Verify venv exists
    let venv_full_path = ($venv_path | path expand)
    let python_bin = (get_python_bin_path $venv_full_path)

    if not ($python_bin | path exists) {
        return {
            success: false,
            packages: 0,
            duration: 0sec,
            error: $"Virtual environment not found at ($venv_path). Run create_venv first."
        }
    }

    # Verify pyproject.toml exists
    if not ("pyproject.toml" | path exists) {
        return {
            success: false,
            packages: 0,
            duration: 0sec,
            error: "pyproject.toml not found in current directory"
        }
    }

    # Install with retry logic
    let result = (install_with_retry $venv_full_path)

    if $result.success {
        print $"✅ Installed ($result.packages) packages in ($result.duration)"
        return {
            success: true,
            packages: $result.packages,
            duration: $result.duration,
            error: ""
        }
    } else {
        print $"❌ Dependency installation failed: ($result.error)"
        return {
            success: false,
            packages: 0,
            duration: $result.duration,
            error: $result.error
        }
    }
}

# Sync dependencies using uv sync
# Args:
#   venv_path: string - Path to virtual environment (default: .venv)
# Returns: record {success: bool, packages: int, duration: duration, error: string}
export def sync_dependencies [venv_path: string = ".venv"] {
    print "🔄 Syncing Python dependencies..."

    let start_time = (date now)

    # Use uv sync command which reads from pyproject.toml
    let result = (^uv sync | complete)

    let end_time = (date now)
    let duration = ($end_time - $start_time)

    if $result.exit_code == 0 {
        # Parse package count from output
        let output = ($result.stdout + $result.stderr)
        let packages = (parse_package_count $output)

        print $"✅ Dependencies synced in ($duration)"

        return {
            success: true,
            packages: $packages,
            duration: $duration,
            error: ""
        }
    } else {
        return {
            success: false,
            packages: 0,
            duration: $duration,
            error: $"Dependency sync failed: ($result.stderr)"
        }
    }
}

# Parse package count from uv output
# Args:
#   output: string - UV command output
# Returns: int - Number of packages installed
def parse_package_count [output: string] {
    # Try to extract package count from UV output
    # Example: "Installed 45 packages in 2.3s"
    let matches = ($output | parse -r 'Installed (\d+) package')

    if ($matches | length) > 0 {
        return ($matches | first | get capture0 | into int)
    }

    # If parsing fails, return 0
    return 0
}

# Install dependencies with retry logic
# Args:
#   venv_path: string - Path to virtual environment
#   max_attempts: int - Maximum retry attempts (default: 3)
# Returns: record {success: bool, packages: int, duration: duration, error: string, attempts: int}
def install_with_retry [
    venv_path: string
    max_attempts: int = 3
] {
    let backoff = [1sec 2sec 4sec]
    let start_time = (date now)

    for attempt in 0..<$max_attempts {
        print $"📦 Attempt ($attempt + 1) of ($max_attempts): Installing dependencies..."

        # Use uv pip install with pyproject.toml
        # The -e . flag installs the package in editable mode
        # --extra dev includes development dependencies (ruff, mypy, pytest, pre-commit, etc.)
        let result = (^uv pip install -e ".[dev]" | complete)

        if $result.exit_code == 0 {
            let end_time = (date now)
            let duration = ($end_time - $start_time)

            # Parse package count from output
            let output = ($result.stdout + $result.stderr)
            let packages = (parse_package_count $output)

            print $"✅ Dependencies installed successfully in ($duration)"

            return {
                success: true,
                packages: $packages,
                duration: $duration,
                error: "",
                attempts: ($attempt + 1)
            }
        }

        # Installation failed
        print $"❌ Installation attempt ($attempt + 1) failed"

        # If not last attempt, wait before retrying
        if $attempt < ($max_attempts - 1) {
            let wait_time = ($backoff | get $attempt)
            print $"⏳ Waiting ($wait_time) before retry..."
            sleep $wait_time
        } else {
            # Last attempt failed
            let end_time = (date now)
            let duration = ($end_time - $start_time)

            return {
                success: false,
                packages: 0,
                duration: $duration,
                error: $"Dependency installation failed after ($max_attempts) attempts: ($result.stderr)",
                attempts: $max_attempts
            }
        }
    }

    # Should not reach here, but handle it
    let end_time = (date now)
    let duration = ($end_time - $start_time)

    return {
        success: false,
        packages: 0,
        duration: $duration,
        error: "Unexpected error in retry logic",
        attempts: $max_attempts
    }
}
