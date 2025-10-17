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

use lib/os_detection.nu *
use lib/prerequisites.nu *
use lib/venv_setup.nu *
use lib/deps_install.nu *
use lib/config_setup.nu *
use lib/validation.nu *
use lib/interactive.nu *
use lib/template_config.nu *
use lib/common.nu *

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
    --silent (-s)  # Run in silent mode (no prompts, use defaults)
] {
    let start_time = (date now)

    # Display welcome
    display_welcome $silent $config.lang_name

    # Track errors
    mut errors = []

    # Phase 0: Application Configuration (only if placeholders exist)
    let has_placeholders = (
        ($config.placeholder_file | path exists) and
        (do { open $config.placeholder_file | ($config.placeholder_check) } | complete | get stdout | str trim | into bool)
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
    print "Phase 2: Prerequisites Validation"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let prereqs = (check_prerequisites)

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

    let venv_result = (create_venv $config.env_path $config.version)

    if not $venv_result.success {
        print $"❌ Virtual environment creation failed: ($venv_result.error)"
        exit 1
    }

    print $"✅ Virtual environment ready: ($config.lang_name) ($venv_result.main_bin_version)\n"

    # Phase 4: Dependency Installation
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 4: Dependency Installation"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let deps_result = (install_dependencies $config.env_path)

    if not $deps_result.success {
        print $"❌ Dependency installation failed: ($deps_result.error)"
        exit 1
    }

    print $"✅ Dependencies installed: ($deps_result.packages) packages\n"

    # Phase 5: Configuration Setup
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 5: Configuration Setup"
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

    # Phase 6: Environment Validation
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 6: Environment Validation"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let validation = (validate_environment $config.env_path)

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
