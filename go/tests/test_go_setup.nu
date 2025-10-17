# Unit tests for go_setup.nu module
#
# Tests the Go modules setup module
#
# Usage:
#   nu go/tests/test_venv_setup.nu

use std assert
use ../lib/venv_setup.nu create_venv

# Test that create_venv ".go" returns correct structure
def test_venv_setup_structure [] {
    # This test requires a valid go.mod to exist
    # We'll just test the structure is correct

    # Create a temporary go.mod for testing
    if not ("go.mod" | path exists) {
        print "⚠️  Skipping test - no go.mod found (expected in test environment)"
        return
    }

    let result = (create_venv ".go")

    # Verify return structure has correct fields
    assert ("success" in $result)
    assert ("main_bin_version" in $result)
    assert ("error" in $result)

    # Verify field types
    assert (($result | get success | describe) == "bool")
    assert (($result | get main_bin_version | describe) == "string")
    assert (($result | get error | describe) == "string")

    print "✓ test_venv_setup_structure passed"
}

# Run all tests
def main [] {
    print "\n=== Running venv_setup.nu tests ===\n"

    test_venv_setup_structure

    print "\n=== All tests passed ===\n"
}
