#!/usr/bin/env nu

# Python Development Environment Setup Script
#
# This script uses the common setup base with Python-specific configuration
#
# Usage:
#   ./setup.nu              # Interactive mode
#   ./setup.nu --silent     # Silent mode (CI/CD)
#   ./setup.nu --library    # Library mode (skip container tools)
#   ./setup.nu --validate   # Quick validation check only

use ../common/lib/os_detection.nu *
use lib/prerequisites.nu *
use lib/venv_setup.nu *
use lib/deps_install.nu *
use ../common/lib/config_setup.nu *
use lib/validation.nu *
use ../common/lib/interactive.nu *
use ../common/lib/template_config.nu *
use ../common/lib/common.nu *
use ../common/setup_base.nu *

# Main setup orchestrator
def main [
    --silent (-s)       # Run in silent mode (no prompts, use defaults)
    --library (-l)      # Library mode (skip container tools: podman, podman-compose, hadolint, trivy)
] {
    # Determine project type
    let project_type = if $library { "library" } else { "microservice" }

    # Configuration for Python
    let config = {
        lang_name: "Python",
        env_path: ".venv",
        version: "3.11",
        placeholder_file: "pyproject.toml",
        placeholder_check: {|| open pyproject.toml | get project.name? | default "" | str contains "change-me" },
        has_venv: true
    }

    # Call common setup orchestrator with Python-specific customizations
    run_setup $config --silent=$silent --project-type=$project_type --check-prereqs-fn={|pt| check_prerequisites $pt} --create-venv-fn={|env_path, version| create_venv $env_path $version} --install-deps-fn={|env_path| install_dependencies $env_path} --validate-env-fn={|env_path, pt| validate_environment $env_path $pt}
}
