# Interactive Prompts Module
#
# This module handles user prompts with sensible defaults and supports
# silent mode for CI/CD automation.
#
# Public Functions:
# - prompt_yes_no: Prompt user for yes/no question with default
# - prompt_choice: Prompt user to choose from options
# - get_setup_preferences: Get all setup preferences (IDE, verbose mode, etc.)

# Prompt user for yes/no question
# Args:
#   question: string - Question to ask
#   default: bool - Default answer (true = yes, false = no)
# Returns: bool - User's answer
export def prompt_yes_no [
    question: string
    default: bool = true
] {
    let default_str = if $default { "Y/n" } else { "y/N" }
    let prompt_text = $"($question) [($default_str)]: "

    print -n $prompt_text

    let answer = (input)

    # If empty, use default
    if ($answer | str trim | is-empty) {
        return $default
    }

    # Parse answer
    let answer_lower = ($answer | str trim | str downcase)

    return (($answer_lower == "y") or ($answer_lower == "yes"))
}

# Prompt user to choose from options
# Args:
#   question: string - Question to ask
#   options: list<string> - List of options
#   default_index: int - Default option index (0-based)
# Returns: string - Selected option
export def prompt_choice [
    question: string
    options: list
    default_index: int = 0
] {
    print $"\n($question)"

    for i in 0..<($options | length) {
        let option = ($options | get $i)
        let marker = if ($i == $default_index) { ">" } else { " " }
        print $"  ($marker) ($i + 1). ($option)"
    }

    let default_display = ($default_index + 1)
    print -n $"\nChoice [($default_display)]: "

    let answer = (input)

    # If empty, use default
    if ($answer | str trim | is-empty) {
        return ($options | get $default_index)
    }

    # Parse answer (1-indexed)
    try {
        let choice_index = (($answer | str trim | into int) - 1)

        if ($choice_index >= 0) and ($choice_index < ($options | length)) {
            return ($options | get $choice_index)
        } else {
            print $"⚠️  Invalid choice, using default: ($options | get $default_index)"
            return ($options | get $default_index)
        }
    } catch {
        print $"⚠️  Invalid input, using default: ($options | get $default_index)"
        return ($options | get $default_index)
    }
}

# Get setup preferences from user
# Args:
#   silent: bool - If true, use defaults without prompting
# Returns: record {ide: string, verbose: bool}
export def get_setup_preferences [silent: bool = false] {
    if $silent {
        print "🤖 Running in silent mode - using default preferences"
        return {
            ide: "vscode",
            verbose: true
        }
    }

    print "\n⚙️  Setup Preferences\n"

    # Prompt for IDE preference
    let ide_options = ["VS Code", "None (skip IDE setup)"]
    let ide_choice = (prompt_choice "Which IDE would you like to configure?" $ide_options 0)

    let ide = if ($ide_choice == "VS Code") {
        "vscode"
    } else {
        "none"
    }

    # Prompt for verbose mode
    let verbose = (prompt_yes_no "Enable verbose output?" true)

    print ""

    return {
        ide: $ide,
        verbose: $verbose
    }
}

# Display setup summary
# Args:
#   preferences: record - Setup preferences
export def display_setup_summary [preferences: record] {
    print "\n📋 Setup Summary:"
    print $"  IDE: ($preferences.ide)"
    print $"  Verbose: ($preferences.verbose)"
    print ""
}
