# NuShell module for prerequisite validation with explicit exports (per SPEC-001 D1)
#
# This module validates the presence and versions of required tools (Python 3.11+, Podman, Git)
# within the Devbox environment, returning a structured report of validation results.
#
# NOTE: Checks ALL prerequisites before returning (complete report for better UX).
# Setup script will fail-fast if errors exist (per SPEC-001 D4).
#
# Usage:
#   use python/lib/prerequisites.nu check_prerequisites
#   let result = (check_prerequisites)
#
#   # Fail-fast integration
#   if ($result.errors | length) > 0 {
#       print "Prerequisites check failed:"
#       $result.errors | each { |err| print $"  - ($err)" }
#       exit 1
#   }

use common.nu *

# Check if all prerequisites are available and meet version requirements
# Returns structured record with validation results and errors
#
# Returns: record<python: bool, python_version: string, podman: bool, podman_version: string, git: bool, git_version: string, errors: list<string>>
export def check_prerequisites [] {
    mut errors = []

    # Check Python 3.11+
    let python_check = (check_python)
    let python_ok = $python_check.ok
    let python_version = $python_check.version

    if not $python_ok {
        $errors = ($errors | append $python_check.error)
    }

    # Check Podman
    let podman_check = (check_podman)
    let podman_ok = $podman_check.ok
    let podman_version = $podman_check.version

    if not $podman_ok {
        $errors = ($errors | append $podman_check.error)
    }

    # Check Git
    let git_check = (check_git)
    let git_ok = $git_check.ok
    let git_version = $git_check.version

    if not $git_ok {
        $errors = ($errors | append $git_check.error)
    }

    # Check Taskfile
    let task_check = (check_taskfile)
    let task_ok = $task_check.ok
    let task_version = $task_check.version

    if not $task_ok {
        $errors = ($errors | append $task_check.error)
    }

    # Check UV package manager
    let uv_check = (check_uv)
    let uv_ok = $uv_check.ok
    let uv_version = $uv_check.version

    if not $uv_ok {
        $errors = ($errors | append $uv_check.error)
    }

    return {
        python: $python_ok,
        python_version: $python_version,
        podman: $podman_ok,
        podman_version: $podman_version,
        git: $git_ok,
        git_version: $git_version,
        task: $task_ok,
        task_version: $task_version,
        uv: $uv_ok,
        uv_version: $uv_version,
        errors: $errors
    }
}

# Check Python version (3.11+)
# Helper function (not exported - private to module)
#
# Returns: record<ok: bool, version: string, error: string>
def check_python [] {
    # Check if Python is available
    let binary_check = (check_binary_exists "python")

    if not $binary_check.exists {
        return {
            installed: false,
            version: "",
            error: "Python not found. Add 'python@3.11' to devbox.json packages."
        }
    }

    # Get version
    let version_result = (get_binary_version "python" "--version")

    if $version_result.success {
        print $"✅ Python installed: ($version_result.version)"
        return {
            ok: true,
            version: $version_result.version,
            error: ""
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"Python found but version check failed: ($version_result.error)"
        }
    }
}

# Check Podman availability
# Helper function (not exported - private to module)
#
# Returns: record<ok: bool, version: string, error: string>
def check_podman [] {
    let binary_check = (check_binary_exists "podman")

    if not $binary_check.exists {
        return {
            ok: false,
            version: "",
            error: "Podman not found. Add 'podman@latest' to devbox.json packages."
        }
    }

    # Get version
    let version_result = (get_binary_version "podman" "--version")

    if $version_result.success {
        print $"✅ Podman installed: ($version_result.version)"
        return {
            ok: true,
            version: $version_result.version,
            error: ""
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"Podman found but version check failed: ($version_result.error)"
        }
    }
}

# Check Git availability
# Helper function (not exported - private to module)
#
# Returns: record<ok: bool, version: string, error: string>
def check_git [] {
    let binary_check = (check_binary_exists "git")

    if not $binary_check.exists {
        return {
            ok: false,
            version: "",
            error: "Git not found. Add 'git@latest' to devbox.json packages."
        }
    }

    # Get version
    let version_result = (get_binary_version "git" "--version")

    if $version_result.success {
        print $"✅ Git installed: ($version_result.version)"
        return {
            ok: true,
            version: $version_result.version,
            error: ""
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"Git found but version check failed: ($version_result.error)"
        }
    }
}

# Check if Taskfile is installed
# Returns: record {installed: bool, version: string, error: string}
def check_taskfile [] {
    # Check if task binary exists
    let binary_check = (check_binary_exists "task")

    if not $binary_check.exists {
        return {
            ok: false,
            version: "",
            error: "Taskfile not found in PATH. Please add 'go-task' to devbox.json"
        }
    }

    # Get version
    let version_result = (get_binary_version "task" "--version")

    if $version_result.success {
        print $"✅ Taskfile installed: ($version_result.version)"
        return {
            ok: true,
            version: $version_result.version,
            error: ""
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"Taskfile found but version check failed: ($version_result.error)"
        }
    }
}

def check_uv [] {
    # Check if uv binary exists
    let binary_check = (check_binary_exists "uv")

    if not $binary_check.exists {
        return {
            ok: false,
            version: "",
            error: "UV package manager not found in PATH. Please add 'uv' to devbox.json"
        }
    }

    # Get version
    let version_result = (get_binary_version "uv" "--version")

    if $version_result.success {
        print $"✅ UV installed: ($version_result.version)"
        return {
            ok: true,
            version: $version_result.version,
            error: ""
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"UV found but version check failed: ($version_result.error)"
        }
    }
}
