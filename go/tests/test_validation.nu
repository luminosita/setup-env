#!/usr/bin/env nu

# Unit tests for Environment Validation Module (Go)
#
# Tests environment validation checks

use std assert
use ../lib/validation.nu *

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

# Test 1: Validate return structure
def test_validation_return_structure [] {
    print "Test: Validation return structure"

    let result = (validate_environment ".go")

    # Verify all required fields exist
    assert ("success" in ($result | columns))
    assert ("passed" in ($result | columns))
    assert ("failed" in ($result | columns))
    assert ("checks" in ($result | columns))

    # Verify checks is a table/list
    assert (($result.checks | describe) =~ "(list|table)")

    # Verify passed + failed equals total checks
    let total = ($result.passed + $result.failed)
    assert ($total == ($result.checks | length))

    print "✅ Return structure valid"
}

# Test 2: Validate checks have expected structure
def test_validation_checks_structure [] {
    print "Test: Validation checks structure"

    let result = (validate_environment ".go")

    for check in $result.checks {
        # Each check should have name, passed, and message
        assert ("name" in ($check | columns))
        assert ("passed" in ($check | columns))
        assert ("message" in ($check | columns))

        # passed should be bool
        assert (($check.passed | describe) =~ "bool")

        # name and message should be non-empty strings
        assert (($check.name | str length) > 0)
        assert (($check.message | str length) > 0)
    }

    print "✅ Checks structure valid"
}

# Test 3: Verify expected number of checks
def test_validation_check_count [] {
    print "Test: Validation check count"

    let result = (validate_environment ".go")

    # Should have 5 checks: go.mod, go-workspace, .env, pre-commit, go-build
    assert (($result.checks | length) == 5)

    let check_names = ($result.checks | get name)
    assert ("go.mod" in $check_names)
    assert ("go-workspace" in $check_names)
    assert (".env" in $check_names)
    assert ("pre-commit" in $check_names)
    assert ("go-build" in $check_names)

    print "✅ Check count valid"
}

# Test 4: Test with non-existent go env
def test_validation_missing_goenv [] {
    print "Test: Validation with missing go env"

    let test_goenv = ".go_nonexistent"

    # Ensure it doesn't exist
    if ($test_goenv | path exists) {
        rm -rf $test_goenv
    }

    let result = (validate_environment $test_goenv)

    # Should have at least one failure (go-workspace check)
    assert ($result.failed > 0)
    assert (not $result.success)

    # Find the go-workspace check
    let workspace_check = ($result.checks | where name == "go-workspace" | first)
    assert (not $workspace_check.passed)

    print "✅ Missing go env handled correctly"
}

# Test 5: Test idempotency
def test_validation_idempotent [] {
    print "Test: Validation is idempotent"

    let result1 = (validate_environment ".go")
    let result2 = (validate_environment ".go")

    # Results should be identical
    assert ($result1.success == $result2.success)
    assert ($result1.passed == $result2.passed)
    assert ($result1.failed == $result2.failed)
    assert (($result1.checks | length) == ($result2.checks | length))

    print "✅ Validation is idempotent"
}

# Test 6: Test check messages are informative
def test_validation_messages [] {
    print "Test: Validation messages are informative"

    let result = (validate_environment ".go")

    for check in $result.checks {
        # Message should contain the check name or description
        assert (($check.message | str length) > 5)

        # Message should indicate pass/fail status
        if $check.passed {
            assert (
                ($check.message | str contains "valid") or
                ($check.message | str contains "exists") or
                ($check.message | str contains "successful") or
                ($check.message | str contains "installed") or
                ($check.message | str contains "configured")
            )
        }
    }

    print "✅ Validation messages are informative"
}

# Main test runner
def main [] {
    print "\n🧪 Running Go Environment Validation Tests\n"

    let had_gomod = (ensure_gomod)

    test_validation_return_structure
    test_validation_checks_structure
    test_validation_check_count
    test_validation_missing_goenv
    test_validation_idempotent
    test_validation_messages

    cleanup_gomod $had_gomod

    print "\n✅ All validation tests passed!\n"
}
