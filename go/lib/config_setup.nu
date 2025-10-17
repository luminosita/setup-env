# Configuration Setup Module for Go
#
# This module handles environment configuration including .env file creation
# and pre-commit hooks installation.
#
# Public Functions:
# - setup_env_file: Create .env file from .env.example
# - install_precommit_hooks: Install pre-commit hooks
# - setup_configuration: Complete configuration setup (env + hooks)

use common.nu *

# Complete configuration setup (env file + pre-commit hooks)
# Returns: record {success: bool, env_created: bool, hooks_installed: bool, errors: list}
export def setup_configuration [] {
    print "\n⚙️  Setting up configuration...\n"

    mut errors = []
    mut env_created = false
    mut hooks_installed = false

    # Setup .env file
    let env_result = (setup_env_file)

    if $env_result.success {
        $env_created = $env_result.created
    } else {
        $errors = ($errors | append $env_result.error)
    }

    # Install pre-commit hooks
    let hooks_result = (install_precommit_hooks)

    if $hooks_result.success {
        $hooks_installed = $hooks_result.installed
    } else {
        $errors = ($errors | append $hooks_result.error)
    }

    # Overall success if no errors
    let success = (($errors | length) == 0)

    if $success {
        print "\n✅ Configuration setup completed successfully\n"
    } else {
        print $"\n⚠️  Configuration setup completed with ($errors | length) errors\n"
    }

    return {
        success: $success,
        env_created: $env_created,
        hooks_installed: $hooks_installed,
        errors: $errors
    }
}

# Check if .env file exists
# Returns: record {exists: bool, path: string}
def check_env_exists [] {
    let env_path = (".env" | path expand)
    let exists = ($env_path | path exists)

    return {exists: $exists, path: $env_path}
}

# Create .env file from .env.example
# Returns: record {success: bool, created: bool, path: string, error: string}
def setup_env_file [] {
    print "📝 Setting up .env configuration..."

    # Check if .env already exists
    let check = (check_env_exists)

    if $check.exists {
        print $"ℹ️  .env file already exists at ($check.path)"
        return {
            success: true,
            created: false,
            path: $check.path,
            error: ""
        }
    }

    # Check if .env.example exists
    if not (".env.example" | path exists) {
        return {
            success: false,
            created: false,
            path: "",
            error: ".env.example not found in current directory"
        }
    }

    # Copy .env.example to .env
    try {
        cp .env.example .env

        # Set permissions to 0600 (owner read/write only)
        ^chmod 600 .env | complete

        let env_path = (".env" | path expand)
        print $"✅ Created .env file at ($env_path)"

        return {
            success: true,
            created: true,
            path: $env_path,
            error: ""
        }
    } catch {|e|
        return {
            success: false,
            created: false,
            path: "",
            error: $"Failed to create .env file: ($e.msg)"
        }
    }
}

# Check if pre-commit is installed
# Returns: record {installed: bool, path: string}
def check_precommit_installed [] {
    let precommit_check = (^which pre-commit | complete)
    let installed = ($precommit_check.exit_code == 0)
    let path = if $installed { $precommit_check.stdout | str trim } else { "" }

    return {installed: $installed, path: $path}
}

# Install pre-commit hooks
# Returns: record {success: bool, installed: bool, error: string}
def install_precommit_hooks [] {
    print "🪝 Installing pre-commit hooks..."

    # Check if pre-commit is installed
    let check = (check_precommit_installed)

    if not $check.installed {
        return {
            success: false,
            installed: false,
            error: "pre-commit not found in PATH. Install with 'brew install pre-commit' or add to devbox.json"
        }
    }

    # Run pre-commit install
    let result = (^pre-commit install | complete)

    if $result.exit_code == 0 {
        print "✅ Pre-commit hooks installed successfully"
        return {
            success: true,
            installed: true,
            error: ""
        }
    } else {
        return {
            success: false,
            installed: false,
            error: $"Pre-commit installation failed: ($result.stderr)"
        }
    }
}
