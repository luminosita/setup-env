# Common Utilities Module
#
# This module contains shared utilities used across all setup scripts.
# Centralizes common patterns to reduce code duplication.
#
# Public Functions:
# - get_python_bin_path: Get Python binary path for venv
# - check_binary_exists: Check if binary exists in PATH
# - get_binary_version: Get version of a binary
# - validate_python_version_string: Parse and validate Python version

# Get Python binary path for virtual environment
# Args:
#   venv_path: string - Path to virtual environment
# Returns: string - Full path to Python binary
export def get_python_bin_path [venv_path: string] {
    if ($nu.os-info.name == "windows") {
        return ($venv_path | path join "Scripts" "python.exe")
    } else {
        return ($venv_path | path join "bin" "python")
    }
}

# Get installed uv version (convenience function)
# Returns: string (version) or error
export def get_uv_version [] {
    let version_result = (get_binary_version "uv" "--version")

    if $version_result.success {
       return $version_result.version
    } else {
        error make {msg: "UV is not installed"}
    }
}

# Get pre-commit binary path for virtual environment
# Args:
#   venv_path: string - Path to virtual environment
# Returns: string - Full path to pre-commit binary
export def get_precommit_bin_path [venv_path: string] {
    if ($nu.os-info.name == "windows") {
        return ($venv_path | path join "Scripts" "pre-commit.exe")
    } else {
        return ($venv_path | path join "bin" "pre-commit")
    }
}

# Check if binary exists in PATH or at specific path
# Args:
#   binary: string - Binary name or full path
# Returns: record {exists: bool, path: string}
export def check_binary_exists [binary: string] {
    # Check if it's a full path
    if ($binary | path exists) {
        return {exists: true, path: $binary}
    }

    # Check if it's in PATH using which (NuShell builtin)
    let result = (which $binary)

    if ($result | is-not-empty) {
        let binary_path = ($result | first | get path)
        return {exists: true, path: $binary_path}
    }

    return {exists: false, path: ""}
}

# Get version of a binary
# Args:
#   binary: string - Binary name or path
#   version_flag: string - Flag to get version (default: --version)
# Returns: record {success: bool, version: string, error: string}
export def get_binary_version [
    binary: string
    version_flag: string = "--version"
] {
    let result = (^$binary $version_flag | complete)

    if $result.exit_code == 0 {
        let version = ($result.stdout | str trim)
        return {success: true, version: $version, error: ""}
    } else {
        return {
            success: false,
            version: "",
            error: $"Failed to get version: ($result.stderr)"
        }
    }
}

# Parse version string and extract major.minor.patch (universal)
# Args:
#   version_string: string - Version string like "3.11.6" or "Python 3.11.6" or "uv 0.1.35"
#   prefix: string - Optional prefix to remove (e.g., "Python ", "uv ")
# Returns: record {major: int, minor: int, patch: int, full: string}
export def parse_version [
    version_string: string
    prefix: string = ""
] {
    # Remove prefix if provided
    let clean_version = if ($prefix | str length) > 0 {
        ($version_string | str replace $prefix "" | str trim)
    } else {
        # Extract version number using regex pattern
        # Matches: X.Y or X.Y.Z where X, Y, Z are numbers
        let match_result = ($version_string | parse --regex '(\d+\.\d+(?:\.\d+)?)')

        if ($match_result | is-empty) {
            error make {msg: $"No version pattern found in: ($version_string)"}
        }

        ($match_result | first | get capture0)
    }

    # Split by dot
    let parts = ($clean_version | split row ".")

    if ($parts | length) < 2 {
        error make {msg: $"Invalid version format: ($version_string)"}
    }

    let major = ($parts | get 0 | into int)
    let minor = ($parts | get 1 | into int)
    let patch = if ($parts | length) >= 3 {
        # Extract just the number before any suffix (e.g., "6rc1" -> "6")
        let patch_str = ($parts | get 2 | str replace -r '[^0-9].*' '')
        if ($patch_str | str length) > 0 {
            ($patch_str | into int)
        } else {
            0
        }
    } else {
        0
    }

    return {
        major: $major,
        minor: $minor,
        patch: $patch,
        full: $clean_version
    }
}

# Parse Python version string and extract major.minor.patch
# Args:
#   version_string: string - Version string like "Python 3.11.6"
# Returns: record {major: int, minor: int, patch: int, full: string}
export def parse_python_version [version_string: string] {
    return (parse_version $version_string "Python ")
}

# Validate version meets minimum requirement (universal)
# Args:
#   version_string: string - Version string like "3.11.6" or "Python 3.11.6"
#   min_major: int - Minimum major version
#   min_minor: int - Minimum minor version (default: 0)
#   prefix: string - Optional prefix to remove (default: "")
#   binary_name: string - Binary name for error messages (default: "Binary")
# Returns: record {valid: bool, version: record, error: string}
export def validate_version [
    version_string: string
    min_major: int
    min_minor: int = 0
    prefix: string = ""
    binary_name: string = "Binary"
] {
    try {
        let version = (parse_version $version_string $prefix)

        # Check if version meets requirement
        if ($version.major > $min_major) or (($version.major == $min_major) and ($version.minor >= $min_minor)) {
            return {
                valid: true,
                version: $version,
                error: ""
            }
        } else {
            let req_version = $"($min_major).($min_minor)"
            return {
                valid: false,
                version: $version,
                error: $"($binary_name) ($version.full) does not meet requirement (>= ($req_version))"
            }
        }
    } catch {|e|
        return {
            valid: false,
            version: {major: 0, minor: 0, patch: 0, full: ""},
            error: $"Failed to parse version: ($e.msg)"
        }
    }
}

# Validate Python version meets minimum requirement
# Args:
#   version_string: string - Version string like "Python 3.11.6"
#   min_major: int - Minimum major version (default: 3)
#   min_minor: int - Minimum minor version (default: 11)
# Returns: record {valid: bool, version: record, error: string}
export def validate_python_version [
    version_string: string
    min_major: int = 3
    min_minor: int = 11
] {
    return (validate_version $version_string $min_major $min_minor "Python " "Python")
}

# Check if command executed successfully
# Args:
#   result: record - Result from `complete` command
# Returns: bool
export def command_succeeded [result: record] {
    return ($result.exit_code == 0)
}

# Format duration for display
# Args:
#   duration: duration
# Returns: string
export def format_duration [duration: duration] {
    let seconds = ($duration | into int) / 1_000_000_000

    if $seconds < 60 {
        return $"($seconds)s"
    } else if $seconds < 3600 {
        let minutes = ($seconds / 60 | math floor)
        let remaining_seconds = ($seconds mod 60)
        return $"($minutes)m ($remaining_seconds)s"
    } else {
        let hours = ($seconds / 3600 | math floor)
        let remaining_minutes = (($seconds mod 3600) / 60 | math floor)
        return $"($hours)h ($remaining_minutes)m"
    }
}
