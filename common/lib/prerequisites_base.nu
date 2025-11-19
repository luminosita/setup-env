# Common prerequisite validation functions
#
# This module provides shared validation for common tools (Podman, Git, Task, pre-commit)
# Language-specific modules extend this with their own runtime checks

use common.nu *

# Check NuShell availability and version
# Returns: record<ok: bool, version: string, error: string>
export def check_nushell [] {
    let binary_check = (check_binary_exists "nu")

    if not $binary_check.exists {
        return {
            ok: false,
            version: "",
            error: "NuShell not found. Add 'nushell@latest' to devbox.json packages."
        }
    }

    # Get version
    let version_result = (get_binary_version "nu" "--version")

    if $version_result.success {
        # Validate version (require 0.108.0)
        let validation = (validate_version $version_result.version 0 108 "" "NuShell")

        if $validation.valid {
            print $"✅ NuShell installed: ($version_result.version)"
            return {
                ok: true,
                version: $version_result.version,
                error: ""
            }
        } else {
            return {
                ok: false,
                version: $version_result.version,
                error: $"($validation.error). Required: >= 0.108.0"
            }
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"NuShell found but version check failed: ($version_result.error)"
        }
    }
}

# Check Podman availability and version
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
        # Validate version (require 5.6.2)
        let validation = (validate_version $version_result.version 5 6 "podman version " "Podman")

        if $validation.valid {
            print $"✅ Podman installed: ($version_result.version)"
            return {
                ok: true,
                version: $version_result.version,
                error: ""
            }
        } else {
            return {
                ok: false,
                version: $version_result.version,
                error: $"($validation.error). Required: >= 5.6.2"
            }
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"Podman found but version check failed: ($version_result.error)"
        }
    }
}

# Check Podman Compose availability and version
# Returns: record<ok: bool, version: string, error: string>
export def check_podman_compose [] {
    let binary_check = (check_binary_exists "podman-compose")

    if not $binary_check.exists {
        return {
            ok: false,
            version: "",
            error: "podman-compose not found. Add 'podman-compose@latest' to devbox.json packages."
        }
    }

    # Get version
    let version_result = (get_binary_version "podman-compose" "--version")

    if $version_result.success {
        # Validate version (require 1.5.0)
        let validation = (validate_version $version_result.version 1 5 "podman-compose version " "podman-compose")

        if $validation.valid {
            print $"✅ podman-compose installed: ($version_result.version)"
            return {
                ok: true,
                version: $version_result.version,
                error: ""
            }
        } else {
            return {
                ok: false,
                version: $version_result.version,
                error: $"($validation.error). Required: >= 1.5.0"
            }
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"podman-compose found but version check failed: ($version_result.error)"
        }
    }
}

# Check Hadolint availability and version
# Returns: record<ok: bool, version: string, error: string>
export def check_hadolint [] {
    let binary_check = (check_binary_exists "hadolint")

    if not $binary_check.exists {
        return {
            ok: false,
            version: "",
            error: "hadolint not found. Add 'hadolint@latest' to devbox.json packages."
        }
    }

    # Get version
    let version_result = (get_binary_version "hadolint" "--version")

    if $version_result.success {
        # Validate version (require 2.13.1)
        let validation = (validate_version $version_result.version 2 13 "Haskell Dockerfile Linter " "Hadolint")

        if $validation.valid {
            print $"✅ Hadolint installed: ($version_result.version)"
            return {
                ok: true,
                version: $version_result.version,
                error: ""
            }
        } else {
            return {
                ok: false,
                version: $version_result.version,
                error: $"($validation.error). Required: >= 2.13.1"
            }
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"Hadolint found but version check failed: ($version_result.error)"
        }
    }
}

# Check Trivy availability and version
# Returns: record<ok: bool, version: string, error: string>
export def check_trivy [] {
    let binary_check = (check_binary_exists "trivy")

    if not $binary_check.exists {
        return {
            ok: false,
            version: "",
            error: "trivy not found. Add 'trivy@latest' to devbox.json packages."
        }
    }

    # Get version
    let version_result = (get_binary_version "trivy" "--version")

    if $version_result.success {
        # Validate version (require 0.66.0)
        let validation = (validate_version $version_result.version 0 66 "Version: " "Trivy")

        if $validation.valid {
            print $"✅ Trivy installed: ($version_result.version)"
            return {
                ok: true,
                version: $version_result.version,
                error: ""
            }
        } else {
            return {
                ok: false,
                version: $version_result.version,
                error: $"($validation.error). Required: >= 0.66.0"
            }
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"Trivy found but version check failed: ($version_result.error)"
        }
    }
}

# Check Sonar Scanner availability and version
# Returns: record<ok: bool, version: string, error: string>
export def check_sonarscanner [] {
    let binary_check = (check_binary_exists "sonar-scanner")

    if not $binary_check.exists {
        return {
            ok: false,
            version: "",
            error: "sonar-scanner not found. Add 'sonar-scanner-cli@latest' to devbox.json packages."
        }
    }

    # Get version
    let version_result = (get_binary_version "sonar-scanner" "--version")

    if $version_result.success {
        # Validate version (require 7.2)
        let validation = (validate_version $version_result.version 7 2 "" "Sonar Scanner")

        if $validation.valid {
            print $"✅ Sonar Scanner installed: ($version_result.version)"
            return {
                ok: true,
                version: $version_result.version,
                error: ""
            }
        } else {
            return {
                ok: false,
                version: $version_result.version,
                error: $"($validation.error). Required: >= 7.2"
            }
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"Sonar Scanner found but version check failed: ($version_result.error)"
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

# Check if Taskfile is installed and version
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
        # Validate version (require 3.45.4)
        let validation = (validate_version $version_result.version 3 45 "" "Taskfile")

        if $validation.valid {
            print $"✅ Taskfile installed: ($version_result.version)"
            return {
                ok: true,
                version: $version_result.version,
                error: ""
            }
        } else {
            return {
                ok: false,
                version: $version_result.version,
                error: $"($validation.error). Required: >= 3.45.4"
            }
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"Taskfile found but version check failed: ($version_result.error)"
        }
    }
}

# Check pre-commit availability and version
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
        # Validate version (require 4.3.0)
        let validation = (validate_version $version_result.version 4 3 "pre-commit " "pre-commit")

        if $validation.valid {
            print $"✅ pre-commit installed: ($version_result.version)"
            return {
                ok: true,
                version: $version_result.version,
                error: ""
            }
        } else {
            return {
                ok: false,
                version: $version_result.version,
                error: $"($validation.error). Required: >= 4.3.0"
            }
        }
    } else {
        return {
            ok: false,
            version: "",
            error: $"pre-commit found but version check failed: ($version_result.error)"
        }
    }
}

# Check common prerequisites (NuShell, Taskfile, Podman, Podman Compose, Hadolint, Trivy, Git, pre-commit, Sonar Scanner)
# Args:
#   project_type: string - "microservice" (default) or "library". Libraries skip container-related tools.
# Returns: record with check results and accumulated errors
export def check_common_prerequisites [
    project_type: string = "microservice"
] {
    mut errors = []

    let is_library = ($project_type == "library")

    # Check NuShell
    let nushell_check = (check_nushell)
    let nushell_ok = $nushell_check.ok
    let nushell_version = $nushell_check.version

    if not $nushell_ok {
        $errors = ($errors | append $nushell_check.error)
    }

    # Check Taskfile
    let task_check = (check_taskfile)
    let task_ok = $task_check.ok
    let task_version = $task_check.version

    if not $task_ok {
        $errors = ($errors | append $task_check.error)
    }

    # Check Podman (skip for libraries)
    let podman_check = if $is_library {
        {ok: true, version: "skipped", error: ""}
    } else {
        (check_podman)
    }
    let podman_ok = $podman_check.ok
    let podman_version = $podman_check.version

    if not $podman_ok {
        $errors = ($errors | append $podman_check.error)
    }

    # Check Podman Compose (skip for libraries)
    let podman_compose_check = if $is_library {
        {ok: true, version: "skipped", error: ""}
    } else {
        (check_podman_compose)
    }
    let podman_compose_ok = $podman_compose_check.ok
    let podman_compose_version = $podman_compose_check.version

    if not $podman_compose_ok {
        $errors = ($errors | append $podman_compose_check.error)
    }

    # Check Hadolint (skip for libraries)
    let hadolint_check = if $is_library {
        {ok: true, version: "skipped", error: ""}
    } else {
        (check_hadolint)
    }
    let hadolint_ok = $hadolint_check.ok
    let hadolint_version = $hadolint_check.version

    if not $hadolint_ok {
        $errors = ($errors | append $hadolint_check.error)
    }

    # Check Trivy (skip for libraries)
    let trivy_check = if $is_library {
        {ok: true, version: "skipped", error: ""}
    } else {
        (check_trivy)
    }
    let trivy_ok = $trivy_check.ok
    let trivy_version = $trivy_check.version

    if not $trivy_ok {
        $errors = ($errors | append $trivy_check.error)
    }

    # Check Git
    let git_check = (check_git)
    let git_ok = $git_check.ok
    let git_version = $git_check.version

    if not $git_ok {
        $errors = ($errors | append $git_check.error)
    }

    # Check pre-commit
    let precommit_check = (check_precommit)
    let precommit_ok = $precommit_check.ok
    let precommit_version = $precommit_check.version

    if not $precommit_ok {
        $errors = ($errors | append $precommit_check.error)
    }

    # Check Sonar Scanner
    let sonarscanner_check = (check_sonarscanner)
    let sonarscanner_ok = $sonarscanner_check.ok
    let sonarscanner_version = $sonarscanner_check.version

    if not $sonarscanner_ok {
        $errors = ($errors | append $sonarscanner_check.error)
    }

    return {
        project_type: $project_type,
        nushell: $nushell_ok,
        nushell_version: $nushell_version,
        task: $task_ok,
        task_version: $task_version,
        podman: $podman_ok,
        podman_version: $podman_version,
        podman_compose: $podman_compose_ok,
        podman_compose_version: $podman_compose_version,
        hadolint: $hadolint_ok,
        hadolint_version: $hadolint_version,
        trivy: $trivy_ok,
        trivy_version: $trivy_version,
        git: $git_ok,
        git_version: $git_version,
        precommit: $precommit_ok,
        precommit_version: $precommit_version,
        sonarscanner: $sonarscanner_ok,
        sonarscanner_version: $sonarscanner_version,
        errors: $errors
    }
}
