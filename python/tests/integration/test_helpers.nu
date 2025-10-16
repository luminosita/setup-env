# Integration Test Helpers
#
# Common utilities for integration tests including:
# - pyproject.toml management (create/cleanup dummy file)
# - .env.example management (create/cleanup dummy file)
# - Environment backup/restore
# - Test artifact cleanup

# Check if pyproject.toml exists and is a real project file
export def has_real_pyproject [] {
    ("pyproject.toml" | path exists)
}

# Create a dummy pyproject.toml for testing if one doesn't exist
# Returns: record {created_pyproject: bool, was_real_pyproject: bool, created_env_example: bool, was_real_env_example: bool}
export def setup_dummy_pyproject [] {
    let pyproject_exists = ("pyproject.toml" | path exists)
    let env_example_exists = (".env.example" | path exists)
    let pre_commit_exists = (".git/hooks/pre-commit" | path exists)

    mut created_pyproject = false
    mut created_env_example = false

    # Create dummy pyproject.toml if needed
    if not $pyproject_exists {
        let dummy_pyproject = '[project]
name = "test-project"
version = "0.1.0"
description = "Dummy project for integration tests"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.104.0",
    "uvicorn>=0.24.0",
    "pydantic>=2.5.0",
    "pytest>=7.4.0",
]

[project.optional-dependencies]
dev = [
    "ruff>=0.1.0",
    "mypy>=1.7.0",
    "pytest>=7.4.0",
    "pre-commit>=3.5.0",
]

[build-system]
requires = ["setuptools>=68.0"]
build-backend = "setuptools.build_meta"
'
        $dummy_pyproject | save "pyproject.toml"
        $created_pyproject = true
    }

    # Create dummy .env.example if needed
    if not $env_example_exists {
        let dummy_env_example = '# Example environment configuration for tests
# Application
APP_PATH_NAME=test_project

# API Configuration
API_HOST=localhost
API_PORT=8000

# Database
DATABASE_URL=sqlite:///./test.db

# Logging
LOG_LEVEL=INFO

# Development
DEBUG=false
'
        $dummy_env_example | save ".env.example"
        $created_env_example = true
    }

    if $created_pyproject {
        print "📝 Created dummy pyproject.toml for testing"
    }
    if $created_env_example {
        print "📝 Created dummy .env.example for testing"
    }
    if $created_pyproject or $created_env_example {
        print ""
    }

    return {
        created_pyproject: $created_pyproject,
        was_real_pyproject: $pyproject_exists,
        created_env_example: $created_env_example,
        was_real_env_example: $env_example_exists,
        was_real_pre_commit: $pre_commit_exists
    }
}

# Cleanup dummy files if they were created by setup_dummy_pyproject
# Args:
#   state: record - returned from setup_dummy_pyproject
export def cleanup_dummy_pyproject [state: record] {
    # Only remove if we created it (not a real project file)
    if $state.created_pyproject and (not $state.was_real_pyproject) {
        if ("pyproject.toml" | path exists) {
            rm pyproject.toml
        }
    }

    # Only remove if we created it (not a real .env.example file)
    if $state.created_env_example and (not $state.was_real_env_example) {
        if (".env.example" | path exists) {
            rm .env.example
        }
    }

    # Only remove if we created it (not a real .env.example file)
    if not $state.was_real_pre_commit {
        if (".git/hooks/pre-commit" | path exists) {
            rm .git/hooks/pre-commit
        }
    }

    if $state.created_pyproject or $state.created_env_example {
        print "🧹 Cleaned up dummy test files\n"
    }
}
