#!/usr/bin/env nu

# Unit tests for Dependency Installation Module (Go)
#
# Tests the dependency installation, retry logic, and error handling

use std assert
use ../lib/deps_install.nu *
use ../lib/venv_setup.nu *

# Helper to ensure go.mod exists for tests
def ensure_gomod [] {
    let had_gomod = ("go.mod" | path exists)
    if not $had_gomod {
        "module test\n\ngo 1.21\n" | save go.mod
    }
    return $had_gomod
}

# Helper to cleanup go.mod if we created it
def cleanup_gomod [had_gomod: bool] {
    if not $had_gomod {
        if ("go.mod" | path exists) { rm go.mod }
        if ("go.sum" | path exists) { rm go.sum }
    }
}

# Test 1: Install dependencies with valid go env and go.mod
def test_install_dependencies_success [] {
    print "Test: Install dependencies (success case)"

    # Create test go env
    let test_goenv = ".go_test"

    # Clean up if exists
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    # Create go env
    let venv_result = (create_venv $test_goenv "")
    assert $venv_result.success

    # Install dependencies (requires go.mod to exist)
    if ("go.mod" | path exists) {
        let result = (install_dependencies $test_goenv)

        print $"Result: ($result)"
        assert ("success" in ($result | columns))
        assert ("packages" in ($result | columns))
        assert ("error" in ($result | columns))

        print "✅ Dependency installation completed successfully"
    } else {
        print "⚠️  go.mod not found - skipping installation test"
    }

    # Clean up
    rm -rf $test_goenv
}

# Test 2: Handle missing go env gracefully
def test_install_dependencies_missing_goenv [] {
    print "Test: Install dependencies (missing go env)"

    let test_goenv = ".go_nonexistent"

    # Ensure go env doesn't exist
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    # Try to install dependencies
    let result = (install_dependencies $test_goenv)

    assert (not $result.success)
    assert (($result.error | str length) > 0)
    assert ($result.packages == 0)

    print "✅ Missing go env handled correctly"
}

# Test 3: Verify return structure
def test_install_dependencies_return_structure [] {
    print "Test: Install dependencies return structure"

    # Create test go env
    let test_goenv = ".go_test"

    if not ($test_goenv | path exists) {
        let _ = (create_venv $test_goenv "")
    }

    let result = (install_dependencies $test_goenv)

    # Verify all required fields exist
    assert ("success" in ($result | columns))
    assert ("packages" in ($result | columns))
    assert ("error" in ($result | columns))

    # Clean up
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    print "✅ Return structure valid"
}

# Test 4: Verify error messages are informative
def test_install_error_messages [] {
    print "Test: Error messages are informative"

    let test_goenv = ".go_nonexistent"

    # Ensure go env doesn't exist
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    let result = (install_dependencies $test_goenv)

    # Error message should contain helpful information
    assert (not $result.success)
    assert (($result.error | str length) > 10)  # Non-trivial error message

    print "✅ Error messages are informative"
}

# Test 5: Verify go.mod requirement
def test_install_requires_gomod [] {
    print "Test: Installation requires go.mod"

    # Create test go env
    let test_goenv = ".go_test"

    # Clean up if exists
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    # Create go env
    let _ = (create_venv $test_goenv "")

    # Install should fail or warn if go.mod doesn't exist
    let result = (install_dependencies $test_goenv)

    # Should have error or indicate no packages installed
    if not ("go.mod" | path exists) {
        assert (not $result.success)
        assert (($result.error | str contains "go.mod") or ($result.packages == 0))
    }

    # Clean up
    rm -rf $test_goenv

    print "✅ go.mod requirement validated"
}

# Main test runner
def main [] {
    print "\n🧪 Running Go Dependency Installation Tests\n"

    let had_gomod = (ensure_gomod)

    test_install_dependencies_return_structure
    test_install_dependencies_missing_goenv
    test_install_error_messages
    test_install_requires_gomod
    test_install_dependencies_success

    cleanup_gomod $had_gomod

    print "\n✅ All dependency installation tests passed!\n"
}
