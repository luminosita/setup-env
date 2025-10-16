#!/usr/bin/env nu

# Automated Development Environment Setup Script
#
# This script orchestrates the complete development environment setup process:
# 1. OS detection
# 2. Prerequisite validation (Python, Podman, Git)
# 3. Taskfile installation
# 4. UV package manager installation
# 5. Python virtual environment creation
# 6. Dependency installation
# 7. Configuration setup (.env, pre-commit hooks)
# 8. Environment validation
#
# Usage:
#   ./setup.nu              # Interactive mode
#   ./setup.nu --silent     # Silent mode (CI/CD)

use lib/os_detection.nu *
use lib/prerequisites.nu *
use lib/venv_setup.nu *
use lib/deps_install.nu *
use lib/config_setup.nu *
use lib/validation.nu *
use lib/interactive.nu *
use lib/common.nu *

# Display welcome banner
def display_welcome [silent: bool] {
    if not $silent {
        print "\n╔═══════════════════════════════════════════════════════════╗"
        print "║   Development Environment Setup                           ║"
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
    print "  1. Activate virtual environment:"
    print "     source .venv/bin/activate\n"
    print "  2. Start development server:"
    print "     task dev\n"
    print "  3. Run tests:"
    print "     task test\n"
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

    # Phase 3: Virtual Environment Creation
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 3: Python Virtual Environment Setup"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let venv_result = (create_venv ".venv" "3.11")

    if not $venv_result.success {
        print $"❌ Virtual environment creation failed: ($venv_result.error)"
        exit 1
    }

    print $"✅ Virtual environment ready: Python ($venv_result.python_version)\n"

    # Phase 4: Dependency Installation
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 4: Dependency Installation"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let deps_result = (install_dependencies ".venv")

    if not $deps_result.success {
        print $"❌ Dependency installation failed: ($deps_result.error)"
        exit 1
    }

    print $"✅ Dependencies installed: ($deps_result.packages) packages\n"

    # Phase 5: Configuration Setup
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Phase 5: Configuration Setup"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let config_result = (setup_configuration ".venv")

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

    let validation = (validate_environment ".venv")

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
