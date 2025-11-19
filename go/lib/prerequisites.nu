# NuShell module for prerequisite validation with explicit exports (per SPEC-001 D1)
#
# This module validates the presence and versions of required tools (Go 1.21+, Podman, Git)
# within the Devbox environment, returning a structured report of validation results.
#
# NOTE: Checks ALL prerequisites before returning (complete report for better UX).
# Setup script will fail-fast if errors exist (per SPEC-001 D4).
#
# Usage:
#   use go/lib/prerequisites.nu check_prerequisites
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
# Args:
#   project_type: string - "microservice" (default) or "library". Libraries skip container-related tools.
# Returns structured record with validation results and errors
#
# Returns: record<go: bool, go_version: string, podman: bool, podman_version: string, git: bool, git_version: string, errors: list<string>>
export def check_prerequisites [
    project_type: string = "microservice"
] {
    mut errors = []

    # Check Go 1.21+
    let go_check = (check_go)
    let go_ok = $go_check.ok
    let go_version = $go_check.version

    if not $go_ok {
        $errors = ($errors | append $go_check.error)
    }

    # Check common prerequisites (Podman, Git, Task, pre-commit)
    let common = (check_common_prerequisites $project_type)
    $errors = ($errors | append $common.errors)

    return {
        project_type: $project_type,
        go: $go_ok,
        go_version: $go_version,
        podman: $common.podman,
        podman_version: $common.podman_version,
        git: $common.git,
        git_version: $common.git_version,
        task: $common.task,
        task_version: $common.task_version,
        precommit: $common.precommit,
        precommit_version: $common.precommit_version,
        errors: $errors
    }
}

# Check Go version (1.21+)
# Helper function (not exported - private to module)
#
# Returns: record<ok: bool, version: string, error: string>
def check_go [] {
    # Check if Go is available
    let binary_check = (check_binary_exists "go")

    if not $binary_check.exists {
        print "❌ Go not found. Add 'go@latest' to devbox.json packages."
        return {
            installed: false,
            version: "",
            error: "Go not found. Add 'go@latest' to devbox.json packages."
        }
    }

    # Get version
    let version_result = (get_binary_version "go" "version")

    if $version_result.success {
        print $"✅ Go installed: ($version_result.version)"
        return {
            ok: true,
            version: $version_result.version,
            error: ""
        }
    } else {
        print $"❌ Go found but version check failed: ($version_result.error)"
        return {
            ok: false,
            version: "",
            error: $"Go found but version check failed: ($version_result.error)"
        }
    }
}




# Check pre-commit availability
# Helper function (not exported - private to module)
#
# Returns: record<ok: bool, version: string, error: string>
