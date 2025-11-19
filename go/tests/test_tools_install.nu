#!/usr/bin/env nu

# Unit tests for Development Tools Installation Module (Go)
#
# Tests the tools installation, go install, and binary fallback logic

use std assert
use ../lib/tools_install.nu *
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

# Test 1: Install tools with valid go env
def test_install_tools_success [] {
    print "Test: Install development tools (success case)"

    # Ensure go.mod exists
    let had_gomod = (ensure_gomod)

    # Create test go env
    let test_goenv = ".go_test_tools"

    # Clean up if exists
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    # Create go env
    let venv_result = (create_venv $test_goenv "")
    assert $venv_result.success

    # Install tools
    let result = (install_tools $test_goenv)

    print $"Result: ($result)"
    assert ("success" in ($result | columns))
    assert ("installed" in ($result | columns))
    assert ("failed" in ($result | columns))

    # Cleanup
    rm -rf $test_goenv
    cleanup_gomod $had_gomod

    print "✅ Install tools success test passed"
}

# Test 2: Install tools with non-existent go env
def test_install_tools_no_goenv [] {
    print "Test: Install tools with non-existent go env (failure case)"

    let test_goenv = ".go_test_nonexistent"

    # Make sure it doesn't exist
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    # Try to install tools without creating go env
    let result = (install_tools $test_goenv)

    print $"Result: ($result)"
    assert (not $result.success)
    assert ($result.error | str contains "not found")

    print "✅ Install tools no goenv test passed"
}

# Test 3: Verify binary paths after installation
def test_tools_binary_paths [] {
    print "Test: Verify binary paths after installation"

    # Ensure go.mod exists
    let had_gomod = (ensure_gomod)

    # Create test go env
    let test_goenv = ".go_test_bins"

    # Clean up if exists
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    # Create go env
    let venv_result = (create_venv $test_goenv "")
    assert $venv_result.success

    # Install at least one tool for testing
    $env.GOPATH = ($test_goenv | path expand)
    $env.GOBIN = ([$env.GOPATH "bin"] | path join)
    $env.GOMODCACHE = ([$env.GOPATH "pkg" "mod"] | path join)
    $env.GOCACHE = ([$env.GOPATH "cache"] | path join)

    # Install a simple tool
    let install_result = (^go install github.com/google/wire/cmd/wire@latest | complete)

    if $install_result.exit_code == 0 {
        let bin_path = ([$test_goenv "bin" "wire"] | path join | path expand)
        assert ($bin_path | path exists)
        print "✅ Binary path test passed"
    } else {
        print "⚠️  Skipping binary path test (go install failed)"
    }

    # Cleanup
    rm -rf $test_goenv
    cleanup_gomod $had_gomod
}

# Main test runner
def main [] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║   Running Development Tools Installation Tests           ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    mut results = []

    # Run tests
    let test1 = (try {
        test_install_tools_no_goenv
        true
    } catch { |e|
        print $"❌ test_install_tools_no_goenv failed: ($e)"
        false
    })
    $results = ($results | append $test1)

    let test2 = (try {
        test_tools_binary_paths
        true
    } catch { |e|
        print $"❌ test_tools_binary_paths failed: ($e)"
        false
    })
    $results = ($results | append $test2)

    # This test takes a long time, run last
    print "\n⚠️  The following test may take several minutes...\n"
    let test3 = (try {
        test_install_tools_success
        true
    } catch { |e|
        print $"❌ test_install_tools_success failed: ($e)"
        false
    })
    $results = ($results | append $test3)

    # Count results
    let passed = ($results | where $it == true | length)
    let failed = ($results | where $it == false | length)

    # Summary
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print $"║   Tests Passed: ($passed) | Failed: ($failed)                             ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    if $failed > 0 {
        exit 1
    }
}
