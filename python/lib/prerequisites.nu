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

use ../../common/lib/common.nu *
use ../../common/lib/prerequisites_base.nu *

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

    # Check UV package manager
    let uv_check = (check_uv)
    let uv_ok = $uv_check.ok
    let uv_version = $uv_check.version

    if not $uv_ok {
        $errors = ($errors | append $uv_check.error)
    }

    # Check common prerequisites (Podman, Git, Task, pre-commit)
    let common = (check_common_prerequisites)
    $errors = ($errors | append $common.errors)

    return {
        python: $python_ok,
        python_version: $python_version,
        podman: $common.podman,
        podman_version: $common.podman_version,
        git: $common.git,
        git_version: $common.git_version,
        task: $common.task,
        task_version: $common.task_version,
        uv: $uv_ok,
        uv_version: $uv_version,
        precommit: $common.precommit,
        precommit_version: $common.precommit_version,
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

# Check pre-commit availability
# Helper function (not exported - private to module)
#
# Returns: record<ok: bool, version: string, error: string>
