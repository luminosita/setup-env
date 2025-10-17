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
    let pre_commit_exists = (".git/hooks/pre-commit" | path exists)

    mut created_gomod = false
    mut created_env_example = false

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

    if $created_gomod {
        print "📝 Created dummy go.mod for testing"
    }
    if $created_env_example {
        print "📝 Created dummy .env.example for testing"
    }
    if $created_gomod or $created_env_example {
        print ""
    }

    return {
        created_gomod: $created_gomod,
        was_real_gomod: $gomod_exists,
        created_env_example: $created_env_example,
        was_real_env_example: $env_example_exists,
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

    # Only remove if we created it (not a real pre-commit file)
    if not $state.was_real_pre_commit {
        if (".git/hooks/pre-commit" | path exists) {
            rm .git/hooks/pre-commit
        }
    }

    if $state.created_gomod or $state.created_env_example {
        print "🧹 Cleaned up dummy test files\n"
    }
}
