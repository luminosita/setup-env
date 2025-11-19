#!/usr/bin/env nu

# Unit tests for version parsing and validation functions

use std assert
use ../lib/common.nu [parse_version validate_version]

# Test parsing version with major.minor.patch format
def test_parse_version_full [] {
    print "Testing parse_version with major.minor.patch..."

    let result = (parse_version "24.0.1")

    assert ($result.major == 24)
    assert ($result.minor == 0)
    assert ($result.patch == 1)
    assert ($result.full == "24.0.1")

    print "✅ parse_version with major.minor.patch passed"
}

# Test parsing version with major.minor format
def test_parse_version_major_minor [] {
    print "Testing parse_version with major.minor..."

    let result = (parse_version "25.0")

    assert ($result.major == 25)
    assert ($result.minor == 0)
    assert ($result.patch == 0)
    assert ($result.full == "25.0")

    print "✅ parse_version with major.minor passed"
}

# Test parsing version with major only (Java 25 case)
def test_parse_version_major_only [] {
    print "Testing parse_version with major only (Java 25)..."

    # This test will FAIL with current implementation
    # Java version "25" should be parsed as major=25, minor=0, patch=0
    let result = (parse_version "25")

    assert ($result.major == 25)
    assert ($result.minor == 0)
    assert ($result.patch == 0)
    assert ($result.full == "25")

    print "✅ parse_version with major only passed"
}

# Test parsing version from Java output format
def test_parse_version_from_java_output [] {
    print "Testing parse_version from Java version output..."

    # Java outputs like: openjdk version "25" 2025-09-16
    # We should extract just "25"
    let result = (parse_version "25")

    assert ($result.major == 25)
    assert ($result.minor == 0)
    assert ($result.patch == 0)

    print "✅ parse_version from Java output passed"
}

# Test validate_version with version that meets requirement
def test_validate_version_meets_requirement [] {
    print "Testing validate_version with version meeting requirement..."

    # Java 25 should meet requirement >= 24
    let result = (validate_version "25" 24 0)

    assert $result.valid
    assert ($result.version.major == 25)
    assert ($result.error == "")

    print "✅ validate_version meeting requirement passed"
}

# Test validate_version with version that exceeds requirement
def test_validate_version_exceeds_requirement [] {
    print "Testing validate_version with version exceeding requirement..."

    # Java 25.0.1 should meet requirement >= 24.0
    let result = (validate_version "25.0.1" 24 0)

    assert $result.valid
    assert ($result.version.major == 25)
    assert ($result.error == "")

    print "✅ validate_version exceeding requirement passed"
}

# Test validate_version with version that doesn't meet requirement
def test_validate_version_fails_requirement [] {
    print "Testing validate_version with version not meeting requirement..."

    # Java 23 should NOT meet requirement >= 24
    let result = (validate_version "23.0.1" 24 0)

    assert (not $result.valid)
    assert ($result.version.major == 23)
    assert (($result.error | str length) > 0)

    print "✅ validate_version failing requirement passed"
}

# Test validate_version with exact minimum version
def test_validate_version_exact_minimum [] {
    print "Testing validate_version with exact minimum version..."

    # Java 24.0 should meet requirement >= 24.0
    let result = (validate_version "24.0" 24 0)

    assert $result.valid
    assert ($result.version.major == 24)
    assert ($result.version.minor == 0)

    print "✅ validate_version exact minimum passed"
}

# Test validate_version with minor version check
def test_validate_version_minor_check [] {
    print "Testing validate_version with minor version requirement..."

    # Python 3.11 should meet requirement >= 3.11
    let result = (validate_version "3.11.6" 3 11)

    assert $result.valid

    # Python 3.10 should NOT meet requirement >= 3.11
    let result2 = (validate_version "3.10.1" 3 11)
    assert (not $result2.valid)

    print "✅ validate_version minor check passed"
}

def main [] {
    print "\n🧪 Running version validation unit tests...\n"

    test_parse_version_full
    test_parse_version_major_minor
    test_parse_version_major_only
    test_parse_version_from_java_output
    test_validate_version_meets_requirement
    test_validate_version_exceeds_requirement
    test_validate_version_fails_requirement
    test_validate_version_exact_minimum
    test_validate_version_minor_check

    print "\n✅ All version validation tests passed!\n"
}
