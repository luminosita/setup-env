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

# Prompt user for text input
# Args:
#   question: string - Question to ask
#   default: string - Default answer
#   --validator: closure - Optional validation closure that returns {valid: bool, error: string}
# Returns: string - User's answer
export def prompt_text [
    question: string
    default: string = ""
    --validator: closure
] {
    loop {
        let prompt_text = if ($default | is-empty) {
            $"($question): "
        } else {
            $"($question) [($default)]: "
        }

        print -n $prompt_text
        let answer = (input | str trim)

        # If empty, use default
        let value = if ($answer | is-empty) { $default } else { $answer }

        # Validate if validator provided
        if ($validator | is-not-empty) {
            let validation_result = (do $validator $value)
            if $validation_result.valid {
                return $value
            } else {
                print $"❌ ($validation_result.error)"
            }
        } else {
            return $value
        }
    }
}

# Transform code name to path name (lowercase, underscores only)
# Args:
#   code_name: string - Code name (e.g., "mcp_server" or "My Server")
# Returns: string - Path name (e.g., "mcp_server" or "my_server")
export def transform_to_path_name [code_name: string] {
    $code_name
    | str downcase
    | str replace -a ' ' '_'
    | str replace -a '-' '_'
    | str replace -a -r '[^a-z0-9_]' ''
}

# Get application configuration from user
# Args:
#   silent: bool - If true, use defaults without prompting
# Returns: record {app_name: string, app_code_name: string, app_path_name: string}
export def get_app_configuration [silent: bool = false] {
    if $silent {
        return {
            skip: true,
            app_name: "CHANGE_ME",
            app_code_name: "change-me",
            app_path_name: "change_me"
        }
    }

    let search_replace = (prompt_yes_no "Replace default application name in files and paths?" true)

    if $search_replace {
        print "\n📝 Application Configuration\n"

        # Prompt for application name
        let app_name = (prompt_text
            "Application Name (e.g., \"AI Agent MCP Server\")"
            "My Application"
            --validator {|x| if ($x | is-empty) {
                {valid: false, error: "Application name cannot be empty"}
            } else {
                {valid: true, error: ""}
            }}
        )

        # Prompt for code name
        let app_code_name = (prompt_text
            "App Code Name (e.g., \"mcp_server\" or \"my-app\")"
            "my_app"
            --validator {|x|
                if ($x | is-empty) {
                    {valid: false, error: "Code name cannot be empty"}
                } else if ($x | str contains ' ') {
                    {valid: false, error: "Code name cannot contain spaces (use hyphens or underscores)"}
                } else {
                    {valid: true, error: ""}
                }
            }
        )

        # Transform to path name
        let app_path_name = (transform_to_path_name $app_code_name)

        print $"\n✅ Configuration:"
        print $"  Application Name: ($app_name)"
        print $"  App Code Name: ($app_code_name)"
        print $"  App Path Name: ($app_path_name)"
        print ""

        return {
            skip: false,
            app_name: $app_name,
            app_code_name: $app_code_name,
            app_path_name: $app_path_name
        }
    }

    return {
        skip: true,
        app_name: "CHANGE_ME",
        app_code_name: "change-me",
        app_path_name: "change_me"
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
    let ide_options = ["None (skip IDE setup)", "VS Code", "Skip Setup (exit)"]
    let ide_choice = (prompt_choice "Which IDE would you like to configure?" $ide_options 0)

    let ide = if ($ide_choice == "VS Code") {
        "vscode"
    } else if ($ide_choice == "None (skip IDE setup)") {
        "none"
    } else {
        "exit"
    }

    # Prompt for verbose mode
    let verbose = (prompt_yes_no "Enable verbose output?" false)

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
