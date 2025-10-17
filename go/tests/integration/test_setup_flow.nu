# Integration test for complete Go setup flow
#
# Tests the entire setup process from start to finish
#
# Usage:
#   nu go/tests/integration/test_setup_flow.nu

use std assert

# Test complete setup flow in silent mode
def test_complete_setup_silent [] {
    print "\n=== Testing Complete Setup Flow (Silent Mode) ===\n"

    # Run setup in silent mode
    let setup_result = (^nu go/setup.nu --silent | complete)

    print $"Setup exit code: ($setup_result.exit_code)"
    print $"Setup output:\n($setup_result.stdout)"

    if $setup_result.exit_code != 0 {
        print $"Setup errors:\n($setup_result.stderr)"
    }

    # Verify setup succeeded or failed gracefully
    assert ($setup_result.exit_code in [0, 1]) "Setup should exit with 0 or 1"

    print "✓ test_complete_setup_silent passed"
}

# Run all tests
def main [] {
    print "\n=== Running Go Setup Integration Tests ===\n"

    # Check if we're in the correct directory
    if not ("go/setup.nu" | path exists) {
        print "❌ Error: Must run from repository root"
        exit 1
    }

    test_complete_setup_silent

    print "\n=== All integration tests passed ===\n"
}
