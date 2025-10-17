#!/usr/bin/env nu

# Automated Go Development Environment Setup Script
#
# This script orchestrates the complete Go development environment setup process:
# 1. OS detection
# 2. Prerequisite validation (Go, Podman, Git)
# 3. Taskfile installation
# 4. Go modules initialization
# 5. Dependency installation
# 6. Configuration setup (.env, pre-commit hooks)
# 7. Environment validation
#
# Usage:
#   ./setup.nu              # Interactive mode
#   ./setup.nu --silent     # Silent mode (CI/CD)

use lib/os_detection.nu *
use lib/prerequisites.nu *
use lib/go_setup.nu *
use lib/deps_install.nu *
use lib/config_setup.nu *
use lib/validation.nu *
use lib/interactive.nu *
use lib/template_config.nu *
use lib/common.nu *

# Display welcome banner
def display_welcome [silent: bool] {
    if not $silent {
        print "\n╔═══════════════════════════════════════════════════════════╗"
        print "║   Go Development Environment Setup                        ║"
        print "╚═══════════════════════════════════════════════════════════╝\n"
    } else {
        print "🤖 Running setup in silent mode (CI/CD)"
    }
}

# Display completion summary
def display_completion [duration: duration, errors: list] {
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
def display_next_steps [] {
    print "📚 Next Steps:\n"
    print "  1. Start development server:"
    print "     task dev\n"
    print "  2. Run tests:"
    print "     task test\n"
    print "  3. Build the project:"
    print "     task build\n"
    print "  4. View all available commands:"
    print "     task --list\n"
}

# Main setup orchestrator
def main [
    --silent (-s)  # Run in silent mode (no prompts, use defaults)
] {
    let start_time = (date now)

    # Display welcome
    display_welcome $silent

    # Track errors
    mut errors = []

    # Phase 0: Application Configuration (only if placeholders exist)
    let has_placeholders = (
        ("go.mod" | path exists) and
        (open go.mod | str contains "change-me")
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

    # Phase 3: Go Modules Setup
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 3: Go Modules Setup"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let go_result = (setup_go_modules)

    if not $go_result.success {
        print $"❌ Go modules setup failed: ($go_result.error)"
        exit 1
    }

    print $"✅ Go modules ready: Go ($go_result.go_version)\n"

    # Phase 4: Dependency Installation
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 4: Dependency Installation"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let deps_result = (install_dependencies)

    if not $deps_result.success {
        print $"❌ Dependency installation failed: ($deps_result.error)"
        exit 1
    }

    print $"✅ Dependencies installed: ($deps_result.packages) packages\n"

    # Phase 5: Configuration Setup
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 5: Configuration Setup"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let config_result = (setup_configuration)

    if not $config_result.success {
        for error in $config_result.errors {
            $errors = ($errors | append error)
        }
        print $"⚠️  Configuration setup completed with ($config_result.errors | length) errors\n"
    } else {
        print "✅ Configuration complete\n"
    }

    # Phase 6: Environment Validation
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 6: Environment Validation"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let validation = (validate_environment)

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
        display_next_steps
    }

    # Exit with appropriate code
    if ($errors | length) > 0 {
        exit 1
    } else {
        exit 0
    }
}
