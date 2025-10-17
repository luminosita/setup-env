# Common prerequisite validation functions
#
# This module provides shared validation for common tools (Podman, Git, Task, pre-commit)
# Language-specific modules extend this with their own runtime checks

use common.nu *

# Check Podman availability
# Returns: record<ok: bool, version: string, error: string>
export def check_podman [] {
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
# Returns: record<ok: bool, version: string, error: string>
export def check_git [] {
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
# Returns: record {ok: bool, version: string, error: string}
export def check_taskfile [] {
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
# Returns: record<ok: bool, version: string, error: string>
export def check_precommit [] {
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

# Check common prerequisites (Podman, Git, Task, pre-commit)
# Returns: record with check results and accumulated errors
# Returns: record<podman: bool, podman_version: string, git: bool, git_version: string, task: bool, task_version: string, precommit: bool, precommit_version: string, errors: list<string>>
export def check_common_prerequisites [] {
    mut errors = []

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
