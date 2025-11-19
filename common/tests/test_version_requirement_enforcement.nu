#!/usr/bin/env nu

# Integration tests to verify setup scripts fail when minimum version requirements are not met

use std assert

# Test that validate_version properly rejects versions below minimum
def test_java_version_rejection [] {
    print "Testing Java version rejection for version < 24..."

    use ../lib/common.nu validate_version

    # Test Java 23 (below minimum of 24)
    let result = (validate_version "23" 24 0 "" "Java")

    assert (not $result.valid) "Java 23 should be rejected (minimum is 24)"
    assert (($result.error | str contains "does not meet requirement") or ($result.error | str contains "23"))

    print "✅ Java version rejection test passed"
}

# Test that validate_version properly accepts versions at or above minimum
def test_java_version_acceptance [] {
    print "Testing Java version acceptance for version >= 24..."

    use ../lib/common.nu validate_version

    # Test Java 24 (exactly at minimum)
    let result24 = (validate_version "24" 24 0 "" "Java")
    assert $result24.valid "Java 24 should be accepted (minimum is 24)"

    # Test Java 25 (above minimum)
    let result25 = (validate_version "25" 24 0 "" "Java")
    assert $result25.valid "Java 25 should be accepted (minimum is 24)"

    # Test Java 24.0.1 (above minimum with patch)
    let result_patch = (validate_version "24.0.1" 24 0 "" "Java")
    assert $result_patch.valid "Java 24.0.1 should be accepted (minimum is 24)"

    print "✅ Java version acceptance test passed"
}

# Test that validate_version properly handles Python version requirements
def test_python_version_validation [] {
    print "Testing Python version validation..."

    use ../lib/common.nu validate_version

    # Test Python 3.10 (below minimum of 3.11)
    let result_old = (validate_version "3.10.5" 3 11 "" "Python")
    assert (not $result_old.valid) "Python 3.10 should be rejected (minimum is 3.11)"

    # Test Python 3.11 (exactly at minimum)
    let result_min = (validate_version "3.11.0" 3 11 "" "Python")
    assert $result_min.valid "Python 3.11.0 should be accepted (minimum is 3.11)"

    # Test Python 3.12 (above minimum)
    let result_new = (validate_version "3.12.1" 3 11 "" "Python")
    assert $result_new.valid "Python 3.12.1 should be accepted (minimum is 3.11)"

    print "✅ Python version validation test passed"
}

# Test that validate_version properly handles Go version requirements
def test_go_version_validation [] {
    print "Testing Go version validation..."

    use ../lib/common.nu validate_version

    # Test Go 1.21 (below minimum of 1.22)
    let result_old = (validate_version "1.21.5" 1 22 "" "Go")
    assert (not $result_old.valid) "Go 1.21 should be rejected (minimum is 1.22)"

    # Test Go 1.22 (exactly at minimum)
    let result_min = (validate_version "1.22.0" 1 22 "" "Go")
    assert $result_min.valid "Go 1.22.0 should be accepted (minimum is 1.22)"

    # Test Go 1.23 (above minimum)
    let result_new = (validate_version "1.23.1" 1 22 "" "Go")
    assert $result_new.valid "Go 1.23.1 should be accepted (minimum is 1.22)"

    print "✅ Go version validation test passed"
}

# Test edge cases
def test_version_edge_cases [] {
    print "Testing version validation edge cases..."

    use ../lib/common.nu validate_version

    # Test exact match on major and minor
    let exact = (validate_version "24.0" 24 0 "" "Binary")
    assert $exact.valid "Exact match 24.0 == 24.0 should be valid"

    # Test major version match with higher minor
    let higher_minor = (validate_version "24.5" 24 0 "" "Binary")
    assert $higher_minor.valid "24.5 should be valid when minimum is 24.0"

    # Test just below minimum
    let just_below = (validate_version "23.99" 24 0 "" "Binary")
    assert (not $just_below.valid) "23.99 should be invalid when minimum is 24.0"

    print "✅ Version edge cases test passed"
}

# Test that check_prerequisites returns errors for invalid versions
def test_prerequisites_check_with_invalid_java [] {
    print "Testing prerequisites check integration..."

    # This test verifies the structure - actual version testing requires mocking
    # which is complex in nushell. The unit tests above cover the validation logic.

    # Verify that check_prerequisites function exists and returns proper structure
    use ../../java/lib/prerequisites.nu check_prerequisites
    let result = (check_prerequisites)

    assert ("errors" in $result) "Prerequisites result should have errors field"
    assert (($result.errors | describe) =~ "list") "Errors should be a list"

    # If Java version is actually below 24 in test environment, errors should exist
    # In normal devbox environment, Java 25 is installed, so errors should be empty
    if not $result.java {
        assert (($result.errors | length) > 0) "Errors list should not be empty when Java check fails"
    }

    print "✅ Prerequisites check integration test passed"
}

def main [] {
    print "\n🧪 Running version requirement enforcement tests...\n"

    test_java_version_rejection
    test_java_version_acceptance
    test_python_version_validation
    test_go_version_validation
    test_version_edge_cases
    test_prerequisites_check_with_invalid_java

    print "\n✅ All version requirement enforcement tests passed!\n"
}
