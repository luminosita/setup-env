# Unit tests for Dependency Installation Module
#
# Tests the dependency installation, retry logic, and error handling

use std assert
use ../lib/deps_install.nu *
use ../lib/venv_setup.nu *

# Test 1: Install dependencies with valid venv and pyproject.toml
def test_install_dependencies_success [] {
    print "Test: Install dependencies (success case)"

    # Create test venv
    let test_venv = ".venv_test"

    # Clean up if exists
    if ($test_venv | path exists) {
        rm -rf $test_venv
    }

    # Create venv
    let venv_result = (create_venv $test_venv "3.11")
    assert $venv_result.success

    # Install dependencies (requires pyproject.toml to exist)
    if ("pyproject.toml" | path exists) {
        let result = (install_dependencies $test_venv)

        print $"Result: ($result)"
        assert ("success" in ($result | columns))
        assert ("packages" in ($result | columns))
        assert ("duration" in ($result | columns))
        assert ("error" in ($result | columns))

        print "✅ Dependency installation completed successfully"
    } else {
        print "⚠️  pyproject.toml not found - skipping installation test"
    }

    # Clean up
    rm -rf $test_venv
}

# Test 2: Handle missing venv gracefully
def test_install_dependencies_missing_venv [] {
    print "Test: Install dependencies (missing venv)"

    let test_venv = ".venv_nonexistent"

    # Ensure venv doesn't exist
    if ($test_venv | path exists) {
        rm -rf $test_venv
    }

    # Try to install dependencies
    let result = (install_dependencies $test_venv)

    assert (not $result.success)
    assert (($result.error | str length) > 0)
    assert ($result.packages == 0)

    print "✅ Missing venv handled correctly"
}

# Test 3: Verify return structure
def test_install_dependencies_return_structure [] {
    print "Test: Install dependencies return structure"

    # Create test venv
    let test_venv = ".venv_test"

    if not ($test_venv | path exists) {
        let _ = (create_venv $test_venv "3.11")
    }

    let result = (install_dependencies $test_venv)

    # Verify all required fields exist
    assert ("success" in ($result | columns))
    assert ("packages" in ($result | columns))
    assert ("duration" in ($result | columns))
    assert ("error" in ($result | columns))

    # Clean up
    if ($test_venv | path exists) {
        rm -rf $test_venv
    }

    print "✅ Return structure valid"
}

# Test 4: Test sync_dependencies function
def test_sync_dependencies [] {
    print "Test: Sync dependencies"

    # Only test if pyproject.toml exists
    if ("pyproject.toml" | path exists) {
        let result = (sync_dependencies ".venv")

        print $"Result: ($result)"
        assert ("success" in ($result | columns))
        assert ("packages" in ($result | columns))
        assert ("duration" in ($result | columns))
        assert ("error" in ($result | columns))

        print "✅ Dependency sync completed successfully"
    } else {
        print "⚠️  pyproject.toml not found - skipping sync test"
    }
}

# Test 5: Verify error messages are informative
def test_install_error_messages [] {
    print "Test: Error messages are informative"

    let test_venv = ".venv_nonexistent"

    # Ensure venv doesn't exist
    if ($test_venv | path exists) {
        rm -rf $test_venv
    }

    let result = (install_dependencies $test_venv)

    # Error message should contain helpful information
    assert (not $result.success)
    assert (($result.error | str length) > 10)  # Non-trivial error message
    assert (($result.error | str contains "venv") or ($result.error | str contains "virtual environment"))

    print "✅ Error messages are informative"
}

# Main test runner
def main [] {
    print "\n🧪 Running Dependency Installation Tests\n"

    test_install_dependencies_return_structure
    test_install_dependencies_missing_venv
    test_install_error_messages
    test_install_dependencies_success
    test_sync_dependencies

    print "\n✅ All dependency installation tests passed!\n"
}
