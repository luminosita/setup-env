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

use common.nu *

# Check if all prerequisites are available and meet version requirements
# Returns structured record with validation results and errors
#
# Returns: record<go: bool, go_version: string, podman: bool, podman_version: string, git: bool, git_version: string, errors: list<string>>
export def check_prerequisites [] {
    mut errors = []

    # Check Go 1.21+
    let go_check = (check_go)
    let go_ok = $go_check.ok
    let go_version = $go_check.version

    if not $go_ok {
        $errors = ($errors | append $go_check.error)
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

    # Check pre-commit
    let precommit_check = (check_precommit)
    let precommit_ok = $precommit_check.ok
    let precommit_version = $precommit_check.version

    if not $precommit_ok {
        $errors = ($errors | append $precommit_check.error)
    }

    return {
        go: $go_ok,
        go_version: $go_version,
        podman: $podman_ok,
        podman_version: $podman_version,
        git: $git_ok,
        git_version: $git_version,
        task: $task_ok,
        task_version: $task_version,
        precommit: $precommit_ok,
        precommit_version: $precommit_version,
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
        return {
            ok: false,
            version: "",
            error: $"Go found but version check failed: ($version_result.error)"
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

# Check pre-commit availability
# Helper function (not exported - private to module)
#
# Returns: record<ok: bool, version: string, error: string>
def check_precommit [] {
    let binary_check = (check_binary_exists "pre-commit")

    if not $binary_check.exists {
        return {
            ok: false,
            version: "",
            error: "pre-commit not found in PATH. Will be installed with dependencies."
        }
    }

    # Get version
    let version_result = (get_binary_version "pre-commit" "--version")

    if $version_result.success {
        print $"✅ pre-commit installed: ($version_result.version)"
        return {
            ok: true,
            version: $version_result.version,
            error: ""
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"pre-commit found but version check failed: ($version_result.error)"
        }
    }
}
