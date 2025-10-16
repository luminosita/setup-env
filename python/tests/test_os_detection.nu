# Unit tests for os_detection.nu module
#
# Tests the OS detection module using explicit import pattern (per SPEC-001 D1)
#
# Usage:
#   nu python/tests/test_os_detection.nu

use std assert
use ../lib/os_detection.nu detect_os

# Test that detect_os returns correct structure
def test_detect_os_structure [] {
    let result = (detect_os)

    # Verify return structure has correct fields
    assert ("os" in $result)
    assert ("arch" in $result)
    assert ("version" in $result)

    # Verify field types are strings
    assert (($result | get os | describe) == "string")
    assert (($result | get arch | describe) == "string")
    assert (($result | get version | describe) == "string")

    print "✓ test_detect_os_structure passed"
}

# Test that OS is one of supported types
def test_detect_os_valid_os [] {
    let result = (detect_os)

    # Verify OS is one of supported types
    assert ($result.os in ["macos", "linux", "wsl2", "unknown"])

    let detected_os = $result.os
    print $"✓ test_detect_os_valid_os passed \(detected: ($detected_os)\)"
}

# Test that architecture is valid
def test_detect_os_valid_arch [] {
    let result = (detect_os)

    # Verify arch is non-empty string
    assert (($result.arch | str length) > 0)

    # Common architectures (not exhaustive, just sanity check)
    # Could be: x86_64, arm64, aarch64, amd64, etc.
    assert (($result.arch | str length) > 2)

    let detected_arch = $result.arch
    print $"✓ test_detect_os_valid_arch passed \(detected: ($detected_arch)\)"
}

# Test that version is returned
def test_detect_os_version [] {
    let result = (detect_os)

    # Verify version is non-empty string
    assert (($result.version | str length) > 0)

    let detected_version = $result.version
    print $"✓ test_detect_os_version passed \(detected: ($detected_version)\)"
}

# Test that function is callable multiple times (idempotent)
def test_detect_os_idempotent [] {
    let result1 = (detect_os)
    let result2 = (detect_os)

    # Results should be identical
    assert ($result1.os == $result2.os)
    assert ($result1.arch == $result2.arch)
    assert ($result1.version == $result2.version)

    print "✓ test_detect_os_idempotent passed"
}

# Run all tests
def main [] {
    print "\n=== Running os_detection.nu tests ===\n"

    test_detect_os_structure
    test_detect_os_valid_os
    test_detect_os_valid_arch
    test_detect_os_version
    test_detect_os_idempotent

    print "\n=== All tests passed ===\n"
}
