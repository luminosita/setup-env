#!/usr/bin/env nu

# Automated Development Environment Setup Script (Base)
#
# This script orchestrates the complete development environment setup process:
# 1. OS detection
# 2. Prerequisite validation
# 3. Virtual environment creation
# 4. Dependency installation
# 5. Configuration setup (.env, pre-commit hooks)
# 6. Environment validation
#
# Usage:
#   ./setup.nu              # Interactive mode
#   ./setup.nu --silent     # Silent mode (CI/CD)

# Language-specific configuration
# This record must be defined by the importing script
# export const CONFIG = {
#     lang_name: "Python",
#     env_path: ".venv",
#     version: "3.11",
#     placeholder_file: "pyproject.toml",
#     placeholder_check: 'get project.name? | default "" | str contains "change-me"'
# }

# Quick validation - check if environment is ready
# Returns: bool - true if environment is valid, false if setup needed
# Args:
#   config: record - Configuration with env_path
#   project_type: string - Project type (microservice or library)
#   check_prereqs_fn: closure - Function to check prerequisites
#   validate_env_fn: closure - Function to validate environment
export def quick_validate [
    config: record
    project_type: string
    check_prereqs_fn: closure
    validate_env_fn: closure
] {
    # Check prerequisites
    let prereqs = (do $check_prereqs_fn $project_type)
    if ($prereqs.errors | length) > 0 {
        return false
    }

    # Check if local env exists
    if not ($config.env_path | path exists) {
        return false
    }

    # Run validation
    let validation = (do $validate_env_fn $config.env_path $project_type)
    if $validation.failed > 0 {
        return false
    }

    return true
}

# Display welcome banner
export def display_welcome [silent: bool, lang_name: string] {
    if not $silent {
        print "\n╔═══════════════════════════════════════════════════════════╗"
        print $"║   ($lang_name) Development Environment Setup                           ║"
        print "╚═══════════════════════════════════════════════════════════╝\n"
    } else {
        print "🤖 Running setup in silent mode (CI/CD)"
    }
}

# Display completion summary
export def display_completion [duration: duration, errors: list] {
    print "\n╔═══════════════════════════════════════════════════════════╗"

    if ($errors | length) == 0 {
        print "║                    ✅ Setup Complete!                     ║"
    } else {
        print "║              ⚠️  Setup Complete with Errors              ║"
    }

    print "╚═══════════════════════════════════════════════════════════╝\n"

    print $"⏱️  Total setup time: ($duration)\n"

    if ($errors | length) > 0 {
        print "⚠️  Errors encountered:"
        for error in $errors {
            print $"  - ($error)"
        }
        print ""
    }
}

# Display next steps
export def display_next_steps [has_venv: bool] {
    print "📚 Next Steps:\n"

    if $has_venv {
        print "  1. Activate virtual environment:"
        print "     source .venv/bin/activate\n"
        print "  2. Start development server:"
    } else {
        print "  1. Start development server:"
    }

    print "     task dev\n"

    if $has_venv {
        print "  3. Run tests:"
    } else {
        print "  2. Run tests:"
    }

    print "     task test\n"

    if not $has_venv {
        print "  3. Build the project:"
        print "     task build\n"
    }

    let step = if $has_venv { "4" } else { "4" }
    print $"  ($step). View all available commands:"
    print "     task --list\n"
}

# Main setup orchestrator
export def run_setup [
    config: record
    --silent (-s)                # Run in silent mode (no prompts, use defaults)
    --project-type: string = "microservice"  # Project type (microservice or library)
    --check-prereqs-fn: closure  # Closure to check prerequisites
    --create-venv-fn: closure    # Closure to create virtual environment
    --install-deps-fn: closure   # Closure to install dependencies
    --install-tools-fn: any = null  # Optional: closure to install language-specific tools (or null)
    --validate-env-fn: closure   # Closure to validate environment
] {
    # Run quick validation
    if (quick_validate $config $project_type $check_prereqs_fn $validate_env_fn) {
        print $"✅ ($config.lang_name) development environment is valid"
        exit 0
    }

    let start_time = (date now)

    # Display welcome
    display_welcome $silent $config.lang_name

    # Track errors
    mut errors = []

    # Phase 0: Application Configuration (only if placeholders exist)
    let has_placeholders = (
        ($config.placeholder_file | path exists) and
        (do $config.placeholder_check)
    )

    let app_config = if $has_placeholders {
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print "Phase 0: Application Configuration"
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

        let config = (get_app_configuration $silent)
        if not $config.skip {
            let template_result = (apply_template_configuration $config)

            if not $template_result.success {
                $errors = ($errors | append "Template configuration")
            }

            $config
        }
    } else {
        # Use defaults if no placeholders
        {
            app_name: "Application",
            app_code_name: "app",
            app_path_name: "app"
        }
    }

    # Get setup preferences (interactive or silent)
    let preferences = (get_setup_preferences $silent)

    if not $silent {
        display_setup_summary $preferences
    }

    # Phase 1: OS Detection
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 1: Operating System Detection"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let os_info = (detect_os)
    print $"✅ Detected: ($os_info.os) ($os_info.arch) ($os_info.version)\n"

    # Phase 2: Prerequisites Validation
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print $"Phase 2: Prerequisites Validation - ($project_type) mode"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let prereqs = (do $check_prereqs_fn $project_type)

    if ($prereqs.errors | length) > 0 {
        print "❌ Prerequisites check failed:\n"
        for error in $prereqs.errors {
            print $"  - ($error)"
        }
        print "\n⚠️  Setup cannot continue without required prerequisites."
        exit 1
    }

    print "✅ All prerequisites validated\n"

    # Phase 3: Virtual Environment Setup
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 3: Virtual Environment Setup"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let venv_result = (do $create_venv_fn $config.env_path $config.version)

    if not $venv_result.success {
        print $"❌ Virtual environment creation failed: ($venv_result.error)"
        exit 1
    }

    print $"✅ Virtual environment ready: ($config.lang_name) ($venv_result.main_bin_version)\n"

    # Phase 4: Dependency Installation
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 4: Dependency Installation"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let deps_result = (do $install_deps_fn $config.env_path)

    if not $deps_result.success {
        print $"❌ Dependency installation failed: ($deps_result.error)"
        exit 1
    }

    print $"✅ Dependencies installed: ($deps_result.packages) packages\n"

    # Phase 5 (Optional): Development Tools Installation
    let next_phase = if ($install_tools_fn != null) {
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print "Phase 5: Development Tools Installation"
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

        let tools_result = (do $install_tools_fn $config.env_path)

        if not $tools_result.success {
            for failed in $tools_result.failed {
                $errors = ($errors | append $"Tool ($failed.tool) failed to install")
            }
            print $"⚠️  Tools installation completed with ($tools_result.failed | length) failures\n"
        } else {
            print $"✅ All development tools installed: ($tools_result.installed) tools\n"
        }

        6  # Next phase number
    } else {
        5  # Next phase number if no tools
    }

    # Phase 5/6: Configuration Setup
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print $"Phase ($next_phase): Configuration Setup"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let config_result = (setup_configuration $config.env_path)

    if not $config_result.success {
        for error in $config_result.errors {
            $errors = ($errors | append $error)
        }
        print $"⚠️  Configuration setup completed with ($config_result.errors | length) errors\n"
    } else {
        print "✅ Configuration complete\n"
    }

    # Phase 6/7: Environment Validation
    let validation_phase = ($next_phase + 1)
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print $"Phase ($validation_phase): Environment Validation - ($project_type) mode"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let validation = (do $validate_env_fn $config.env_path $project_type)

    if $validation.failed > 0 {
        $errors = ($errors | append $"($validation.failed) validation checks failed")
    }

    # Calculate duration
    let end_time = (date now)
    let duration = ($end_time - $start_time)

    # Display completion summary
    display_completion $duration $errors

    # Display next steps
    if ($errors | length) == 0 {
        display_next_steps $config.has_venv
    }

    # Exit with appropriate code
    if ($errors | length) > 0 {
        exit 1
    } else {
        exit 0
    }
}
