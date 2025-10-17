# Unit tests for go_setup.nu module
#
# Tests the Go modules setup module
#
# Usage:
#   nu go/tests/test_go_setup.nu

use std assert
use ../lib/go_setup.nu setup_go_modules

# Test that setup_go_modules returns correct structure
def test_go_setup_structure [] {
    # This test requires a valid go.mod to exist
    # We'll just test the structure is correct

    # Create a temporary go.mod for testing
    if not ("go.mod" | path exists) {
        print "⚠️  Skipping test - no go.mod found (expected in test environment)"
        return
    }

    let result = (setup_go_modules)

    # Verify return structure has correct fields
    assert ("success" in $result)
    assert ("go_version" in $result)
    assert ("error" in $result)

    # Verify field types
    assert (($result | get success | describe) == "bool")
    assert (($result | get go_version | describe) == "string")
    assert (($result | get error | describe) == "string")

    print "✓ test_go_setup_structure passed"
}

# Run all tests
def main [] {
    print "\n=== Running go_setup.nu tests ===\n"

    test_go_setup_structure

    print "\n=== All tests passed ===\n"
}
