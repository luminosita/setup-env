# Unit tests for prerequisites.nu module
#
# Tests the prerequisite validation module using explicit import pattern (per SPEC-001 D1)
#
# Usage:
#   nu python/tests/test_prerequisites.nu

use std assert
use ../lib/prerequisites.nu check_prerequisites

# Test that check_prerequisites returns correct structure
def test_prerequisites_structure [] {
    let result = (check_prerequisites)

    # Verify return structure has correct fields
    assert ("python" in $result)
    assert ("python_version" in $result)
    assert ("podman" in $result)
    assert ("podman_version" in $result)
    assert ("git" in $result)
    assert ("git_version" in $result)
    assert ("errors" in $result)

    # Verify field types
    assert (($result | get python | describe) == "bool")
    assert (($result | get python_version | describe) == "string")
    assert (($result | get podman | describe) == "bool")
    assert (($result | get podman_version | describe) == "string")
    assert (($result | get git | describe) == "bool")
    assert (($result | get git_version | describe) == "string")
    assert (($result | get errors | describe) =~ "list")

    print "✓ test_prerequisites_structure passed"
}

# Test that prerequisites check returns results
# Note: This test runs in actual environment, so checks should pass if devbox is configured
def test_prerequisites_in_devbox [] {
    let result = (check_prerequisites)

    # In properly configured devbox environment, all should be present
    # If not, this test will help identify configuration issues

    if ($result.errors | is-not-empty) {
        print $"⚠ Prerequisites check found issues (expected if not in devbox shell):"
        $result.errors | each { |err| print $"  - ($err)" }
    }

    # Verify structure is correct regardless of results
    assert (($result | get python | describe) == "bool")
    assert (($result | get errors | describe) =~ "list")

    print $"✓ test_prerequisites_in_devbox passed"
    print $"  Python: ($result.python) - ($result.python_version)"
    print $"  Podman: ($result.podman) - ($result.podman_version)"
    print $"  Git: ($result.git) - ($result.git_version)"
}

# Test that errors list is collected completely
# This verifies Decision D4 behavior (collect all errors, fail-fast handled by caller)
def test_complete_error_collection [] {
    let result = (check_prerequisites)

    # Verify errors is a list (even if empty)
    assert (($result.errors | describe) =~ "list")

    # If any prerequisite is false, there should be corresponding error
    if not $result.python {
        let has_python_error = ($result.errors | any { |err| ($err | str contains "Python") })
        assert $has_python_error "Python failure should have error message"
    }

    if not $result.podman {
        let has_podman_error = ($result.errors | any { |err| ($err | str contains "Podman") })
        assert $has_podman_error "Podman failure should have error message"
    }

    if not $result.git {
        let has_git_error = ($result.errors | any { |err| ($err | str contains "Git") })
        assert $has_git_error "Git failure should have error message"
    }

    print "✓ test_complete_error_collection passed"
}

# Test that version strings are populated when tools are present
def test_version_strings_populated [] {
    let result = (check_prerequisites)

    # If a prerequisite check passes, its version should be populated
    if $result.python {
        assert (($result.python_version | str length) > 0) "Python version should be populated when present"
    }

    if $result.podman {
        # Version could be "unknown" if parsing fails, but should not be empty
        assert (($result.podman_version | str length) > 0) "Podman version should be populated when present"
    }

    if $result.git {
        # Version could be "unknown" if parsing fails, but should not be empty
        assert (($result.git_version | str length) > 0) "Git version should be populated when present"
    }

    print "✓ test_version_strings_populated passed"
}

# Test that function is callable multiple times (idempotent)
def test_prerequisites_idempotent [] {
    let result1 = (check_prerequisites)
    let result2 = (check_prerequisites)

    # Results should be identical
    assert ($result1.python == $result2.python)
    assert ($result1.podman == $result2.podman)
    assert ($result1.git == $result2.git)
    assert (($result1.errors | length) == ($result2.errors | length))

    print "✓ test_prerequisites_idempotent passed"
}

# Run all tests
def main [] {
    print "\n=== Running prerequisites.nu tests ===\n"

    test_prerequisites_structure
    test_prerequisites_in_devbox
    test_complete_error_collection
    test_version_strings_populated
    test_prerequisites_idempotent

    print "\n=== All tests passed ===\n"
}
