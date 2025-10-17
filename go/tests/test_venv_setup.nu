#!/usr/bin/env nu

# Unit tests for Go Environment Setup Module
#
# Tests the Go local environment creation, checking, and Go version detection

use std assert
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

# Test 1: Create Go local environment
def test_create_venv [] {
    print "Test: Create Go local environment"

    let had_gomod = (ensure_gomod)
    let test_goenv = ".go_test"

    # Clean up if exists
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    let result = (create_venv $test_goenv "")

    print $"Result: ($result)"
    assert $result.success
    assert ($result.path | path exists)
    assert (($result.main_bin_version | str length) > 0)

    # Verify directory structure
    assert (($result.path | path join "pkg") | path exists)
    assert (($result.path | path join "cache") | path exists)

    # Clean up
    rm -rf $test_goenv
    cleanup_gomod $had_gomod

    print "✅ Go local environment created successfully"
}

# Test 2: Check existing go env (idempotent)
def test_create_venv_idempotent [] {
    print "Test: Create go env (idempotent)"

    let had_gomod = (ensure_gomod)
    let test_goenv = ".go_test"

    # Create first time
    let result1 = (create_venv $test_goenv "")
    assert $result1.success

    # Create second time (should detect existing)
    let result2 = (create_venv $test_goenv "")
    assert $result2.success
    assert ($result2.path == $result1.path)

    # Clean up
    rm -rf $test_goenv
    cleanup_gomod $had_gomod

    print "✅ Idempotent go env creation works"
}

# Test 3: Check go env exists
def test_check_goenv [] {
    print "Test: Check go env exists"

    let had_gomod = (ensure_gomod)
    let test_goenv = ".go_test"

    # Create go env
    let _ = (create_venv $test_goenv "")

    # Check it exists
    assert ($test_goenv | path exists)
    assert (($test_goenv | path join "pkg") | path exists)
    assert (($test_goenv | path join "cache") | path exists)

    # Clean up
    rm -rf $test_goenv

    # Check non-existent go env
    assert (not ($test_goenv | path exists))

    cleanup_gomod $had_gomod

    print "✅ Go env existence check works"
}

# Test 4: Get Go version
def test_get_go_version [] {
    print "Test: Get Go version"

    let had_gomod = (ensure_gomod)
    let test_goenv = ".go_test"

    # Create go env
    let result = (create_venv $test_goenv "")

    print $"Go version: ($result.main_bin_version)"
    assert $result.success
    assert (($result.main_bin_version | str length) > 0)

    # Should contain "go" version format
    assert (
        ($result.main_bin_version | str contains "go") or
        ($result.main_bin_version | str contains "1.")
    )

    # Clean up
    rm -rf $test_goenv
    cleanup_gomod $had_gomod

    print "✅ Go version detection works"
}

# Test 5: Verify go env structure
def test_goenv_structure [] {
    print "Test: Verify go env directory structure"

    let had_gomod = (ensure_gomod)
    let test_goenv = ".go_test"

    # Create go env
    let _ = (create_venv $test_goenv "")

    # Check for expected directories
    let pkg_dir = ($test_goenv | path join "pkg")
    assert ($pkg_dir | path exists)

    let cache_dir = ($test_goenv | path join "cache")
    assert ($cache_dir | path exists)

    # Check pkg/mod subdirectory is created
    let mod_dir = ($pkg_dir | path join "mod")
    assert ($mod_dir | path exists)

    # Clean up
    rm -rf $test_goenv
    cleanup_gomod $had_gomod

    print "✅ Go env structure is correct"
}

# Test 6: Test with custom path
def test_custom_path [] {
    print "Test: Create go env with custom path"

    let had_gomod = (ensure_gomod)
    let test_goenv = ".go_custom_test"

    # Clean up if exists
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    let result = (create_venv $test_goenv "")

    assert $result.success
    assert ($test_goenv | path exists)
    assert (($result.path | path basename) == ".go_custom_test")

    # Clean up
    rm -rf $test_goenv
    cleanup_gomod $had_gomod

    print "✅ Custom path works"
}

# Main test runner
def main [] {
    print "\n🧪 Running Go Environment Setup Tests\n"

    test_create_venv
    test_create_venv_idempotent
    test_check_goenv
    test_get_go_version
    test_goenv_structure
    test_custom_path

    print "\n✅ All Go environment setup tests passed!\n"
}
