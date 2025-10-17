# Integration Test Helpers (Go)
#
# Common utilities for integration tests including:
# - go.mod management (create/cleanup dummy file)
# - .env.example management (create/cleanup dummy file)
# - Environment backup/restore
# - Test artifact cleanup

# Check if go.mod exists and is a real project file
export def has_real_gomod [] {
    ("go.mod" | path exists)
}

# Create a dummy go.mod for testing if one doesn't exist
# Returns: record {created_gomod: bool, was_real_gomod: bool, created_env_example: bool, was_real_env_example: bool}
export def setup_dummy_gomod [] {
    let gomod_exists = ("go.mod" | path exists)
    let env_example_exists = (".env.example" | path exists)
    let pre_commit_config_exists = (".pre-commit-config.yaml" | path exists)
    let pre_commit_exists = (".git/hooks/pre-commit" | path exists)
    let git_exists = (".git" | path exists)

    mut created_gomod = false
    mut created_env_example = false
    mut created_pre_commit_config = false
    mut created_git = false

    # Create dummy go.mod if needed
    if not $gomod_exists {
        let dummy_gomod = 'module github.com/test/test-project

go 1.21

require (
	github.com/gin-gonic/gin v1.9.1
	github.com/stretchr/testify v1.8.4
)
'
        $dummy_gomod | save "go.mod"
        $created_gomod = true
    }

    # Create dummy .env.example if needed
    if not $env_example_exists {
        let dummy_env_example = '# Example environment configuration for tests
# Application
APP_PATH_NAME=test_project

# API Configuration
API_HOST=localhost
API_PORT=8080

# Database
DATABASE_URL=postgres://localhost:5432/test

# Logging
LOG_LEVEL=INFO

# Development
DEBUG=false
'
        $dummy_env_example | save ".env.example"
        $created_env_example = true
    }

    # Create dummy .pre-commit-config.yaml if needed
    if not $pre_commit_config_exists {
        let dummy_pre_commit_config = 'repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
'
        $dummy_pre_commit_config | save ".pre-commit-config.yaml"
        $created_pre_commit_config = true
    }

    # Create .git directory if needed
    if not $git_exists {
        mkdir .git
        mkdir .git/hooks
        $created_git = true
    }

    if $created_gomod {
        print "📝 Created dummy go.mod for testing"
    }
    if $created_env_example {
        print "📝 Created dummy .env.example for testing"
    }
    if $created_pre_commit_config {
        print "📝 Created dummy .pre-commit-config.yaml for testing"
    }
    if $created_git {
        print "📝 Created dummy .git directory for testing"
    }
    if $created_gomod or $created_env_example or $created_pre_commit_config or $created_git {
        print ""
    }

    return {
        created_gomod: $created_gomod,
        was_real_gomod: $gomod_exists,
        created_env_example: $created_env_example,
        was_real_env_example: $env_example_exists,
        created_pre_commit_config: $created_pre_commit_config,
        was_real_pre_commit_config: $pre_commit_config_exists,
        created_git: $created_git,
        was_real_git: $git_exists,
        was_real_pre_commit: $pre_commit_exists
    }
}

# Cleanup dummy files if they were created by setup_dummy_gomod
# Args:
#   state: record - returned from setup_dummy_gomod
export def cleanup_dummy_gomod [state: record] {
    # Only remove if we created it (not a real project file)
    if $state.created_gomod and (not $state.was_real_gomod) {
        if ("go.mod" | path exists) {
            rm go.mod
        }
        # Also remove go.sum if it was created
        if ("go.sum" | path exists) and (not $state.was_real_gomod) {
            rm go.sum
        }
    }

    # Only remove if we created it (not a real .env.example file)
    if $state.created_env_example and (not $state.was_real_env_example) {
        if (".env.example" | path exists) {
            rm .env.example
        }
    }

    # Only remove if we created it (not a real .pre-commit-config.yaml file)
    if $state.created_pre_commit_config and (not $state.was_real_pre_commit_config) {
        if (".pre-commit-config.yaml" | path exists) {
            rm .pre-commit-config.yaml
        }
    }

    # Only remove if we created it (not a real .git directory)
    if $state.created_git and (not $state.was_real_git) {
        if (".git" | path exists) {
            rm -rf .git
        }
    }

    # Only remove if we created it (not a real pre-commit file)
    if not $state.was_real_pre_commit {
        if (".git/hooks/pre-commit" | path exists) {
            rm .git/hooks/pre-commit
        }
    }

    if $state.created_gomod or $state.created_env_example or $state.created_pre_commit_config or $state.created_git {
        print "🧹 Cleaned up dummy test files\n"
    }
}
