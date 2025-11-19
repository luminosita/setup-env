#!/usr/bin/env nu

# Unit tests for Java prerequisites module

use std assert
use ../lib/prerequisites.nu check_prerequisites

def test_prerequisites_structure [] {
    print "Testing prerequisites structure..."

    let result = (check_prerequisites)

    # Check that all required fields exist
    assert ("java" in $result)
    assert ("java_version" in $result)
    assert ("maven" in $result)
    assert ("maven_version" in $result)
    assert ("gradle" in $result)
    assert ("gradle_version" in $result)
    assert ("podman" in $result)
    assert ("git" in $result)
    assert ("task" in $result)
    assert ("precommit" in $result)
    assert ("errors" in $result)

    # Check types
    assert (($result.java | describe) == "bool")
    assert (($result.maven | describe) == "bool")
    assert (($result.gradle | describe) == "bool")
    assert (($result.errors | describe) =~ "list")

    print "✅ Prerequisites structure test passed"
}

def test_java_check [] {
    print "Testing Java check..."

    let result = (check_prerequisites)

    # Java should be available in devbox environment
    if $result.java {
        assert (not ($result.java_version | is-empty))
        print $"✅ Java check passed - version: ($result.java_version)"
    } else {
        print "⚠️  Java not found - this is expected if not in devbox shell"
    }
}

def test_maven_check [] {
    print "Testing Maven check..."

    let result = (check_prerequisites)

    # Maven should be available in devbox environment
    if $result.maven {
        assert (not ($result.maven_version | is-empty))
        print $"✅ Maven check passed - version: ($result.maven_version)"
    } else {
        print "⚠️  Maven not found - this is expected if not in devbox shell"
    }
}

def test_gradle_check [] {
    print "Testing Gradle check..."

    let result = (check_prerequisites)

    # Gradle should be available in devbox environment
    if $result.gradle {
        assert (not ($result.gradle_version | is-empty))
        print $"✅ Gradle check passed - version: ($result.gradle_version)"
    } else {
        print "⚠️  Gradle not found - this is expected if not in devbox shell"
    }
}

def main [] {
    print "\n🧪 Running Java prerequisites unit tests...\n"

    test_prerequisites_structure
    test_java_check
    test_maven_check
    test_gradle_check

    print "\n✅ All Java prerequisites tests passed!\n"
}
