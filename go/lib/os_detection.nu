# NuShell module for OS detection with explicit exports (per SPEC-001 D1)
#
# This module detects the operating system, architecture, and version
# for cross-platform setup script behavior.
#
# Usage:
#   use python/lib/os_detection.nu detect_os
#   let os_info = (detect_os)
#   print $os_info  # {os: "macos", arch: "arm64", version: "14.5"}

# Detect operating system, architecture, and version
# Returns structured record with OS information
#
# Returns: record<os: string, arch: string, version: string>
#   - os: "macos" | "linux" | "wsl2" | "unknown"
#   - arch: Architecture string (e.g., "arm64", "x86_64", "amd64")
#   - version: OS version string (e.g., "14.5", "22.04")
export def detect_os [] {
    # Get system info using NuShell's built-in sys command
    let sys_info = (sys host)

    let os_name = $sys_info.name
    # Get architecture using external uname command since sys host doesn't provide it
    let arch = (^uname -m | str trim)

    # Determine OS type
    let os_type = match $os_name {
        "Darwin" => "macos",
        "Linux" => {
            # Check if WSL2
            let is_wsl = (if ("/proc/version" | path exists) {
                let proc_version = (open /proc/version)
                ($proc_version | str contains "microsoft") or ($proc_version | str contains "WSL")
            } else {
                false
            })

            if $is_wsl {
                "wsl2"
            } else {
                "linux"
            }
        },
        _ => "unknown"
    }

    # Get version information
    let version = match $os_type {
        "macos" => {
            # Use sw_vers to get macOS version
            try {
                (sw_vers -productVersion | str trim)
            } catch {
                "unknown"
            }
        },
        "linux" | "wsl2" => {
            # Try lsb_release first
            if (which lsb_release | is-not-empty) {
                try {
                    (lsb_release -rs | str trim)
                } catch {
                    # Fallback to /etc/os-release
                    if ("/etc/os-release" | path exists) {
                        try {
                            let os_release = (open /etc/os-release | lines)
                            let version_line = ($os_release | find VERSION_ID | first)
                            ($version_line | split row "=" | get 1 | str trim --char '"')
                        } catch {
                            "unknown"
                        }
                    } else {
                        "unknown"
                    }
                }
            } else if ("/etc/os-release" | path exists) {
                # Parse /etc/os-release file
                try {
                    let os_release = (open /etc/os-release | lines)
                    let version_line = ($os_release | find VERSION_ID | first)
                    ($version_line | split row "=" | get 1 | str trim --char '"')
                } catch {
                    "unknown"
                }
            } else {
                "unknown"
            }
        },
        _ => "unknown"
    }

    return {
        os: $os_type,
        arch: $arch,
        version: $version
    }
}
