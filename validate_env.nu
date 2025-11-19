#!/usr/bin/env nu

# Environment Validation Orchestrator
#
# This script validates Python and Go environments on devbox startup
# and prompts user to run full setup if validation fails

use common/lib/interactive.nu prompt_yes_no

# Validate a single language environment
# Returns: {lang: string, valid: bool}
def validate_language [lang: string, setup_path: string] {
    let result = (^nu $setup_path --validate | complete)
    return {
        lang: $lang,
        valid: ($result.exit_code == 0)
    }
}

# Prompt user to run setup
def prompt_setup [lang: string, setup_path: string] {
    print $"\n⚠️  ($lang) environment not configured or validation failed"

    let should_setup = (prompt_yes_no $"Would you like to run the ($lang) setup now?" false)

    if $should_setup {
        print $"\n🚀 Running ($lang) setup...\n"
        ^nu $setup_path

        if $env.LAST_EXIT_CODE == 0 {
            print $"\n✅ ($lang) setup completed successfully!\n"
        } else {
            print $"\n❌ ($lang) setup failed. Please check the errors above.\n"
        }
    } else {
        print $"Skipping ($lang) setup. Run 'nu ($setup_path)' manually when ready.\n"
    }
}

# Main validation orchestrator
def main [] {
    # Check if we're in a project directory (has python/ or go/ or java/ subdirectories)
    let has_python = ("python/setup.nu" | path exists)
    let has_go = ("go/setup.nu" | path exists)
    let has_java = ("java/setup.nu" | path exists)

    if not $has_python and not $has_go and not $has_java {
        # Not in a project directory, skip validation
        return
    }

    mut needs_setup = []

    # Validate Python environment
    if $has_python {
        let py_validation = (validate_language "Python" "python/setup.nu")
        if not $py_validation.valid {
            $needs_setup = ($needs_setup | append {lang: "Python", path: "python/setup.nu"})
        }
    }

    # Validate Go environment
    if $has_go {
        let go_validation = (validate_language "Go" "go/setup.nu")
        if not $go_validation.valid {
            $needs_setup = ($needs_setup | append {lang: "Go", path: "go/setup.nu"})
        }
    }

    # Validate Java environment
    if $has_java {
        let java_validation = (validate_language "Java" "java/setup.nu")
        if not $java_validation.valid {
            $needs_setup = ($needs_setup | append {lang: "Java", path: "java/setup.nu"})
        }
    }

    # Prompt for setup if any validation failed
    if ($needs_setup | length) > 0 {
        print "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print "Environment Validation"
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        for setup in $needs_setup {
            prompt_setup $setup.lang $setup.path
        }
    }
}
