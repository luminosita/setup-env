#!/usr/bin/env nu

# Unit tests for Configuration Files Module (Java)
#
# Tests the Maven and Gradle config file generation

use std assert
use ../lib/config_files.nu *

# Test 1: Generate config files in a fresh environment
def test_generate_config_files_new [] {
    print "Test: Generate config files in new environment"

    # Create test directory
    let test_dir = ".java_test_config"

    # Clean up if exists
    if ($test_dir | path exists) {
        rm -rf $test_dir
    }
    if (".m2" | path exists) {
        rm -rf .m2
    }
    if ("gradle" | path exists) {
        rm -rf gradle
    }

    # Create test Java environment
    mkdir $test_dir

    # Generate config files
    let result = (generate_config_files $test_dir)

    print $"Result: ($result)"

    # Check result structure
    assert ("success" in ($result | columns))
    assert ("created" in ($result | columns))
    assert ("errors" in ($result | columns))

    # Check success
    assert $result.success

    # Check that files were created
    assert (".m2/settings.xml" | path exists)
    assert ("gradle/gradle.properties" | path exists)

    # Check that created list contains both files
    assert (($result.created | length) == 2)

    # Cleanup
    rm -rf $test_dir
    rm -rf .m2
    rm -rf gradle

    print "✅ Generate config files test passed"
}

# Test 2: Idempotent - don't recreate existing files
def test_generate_config_files_idempotent [] {
    print "Test: Config file generation is idempotent"

    # Create test directory
    let test_dir = ".java_test_config_idem"

    # Clean up if exists
    if ($test_dir | path exists) {
        rm -rf $test_dir
    }
    if (".m2" | path exists) {
        rm -rf .m2
    }
    if ("gradle" | path exists) {
        rm -rf gradle
    }

    # Create test Java environment
    mkdir $test_dir

    # Generate config files first time
    let result1 = (generate_config_files $test_dir)
    assert $result1.success
    assert (($result1.created | length) == 2)

    # Generate again - should not recreate
    let result2 = (generate_config_files $test_dir)
    assert $result2.success
    assert (($result2.created | length) == 0)

    # Cleanup
    rm -rf $test_dir
    rm -rf .m2
    rm -rf gradle

    print "✅ Idempotent test passed"
}

# Test 3: Verify content of generated files
def test_config_file_content [] {
    print "Test: Verify config file content"

    # Create test directory
    let test_dir = ".java_test_config_content"

    # Clean up if exists
    if ($test_dir | path exists) {
        rm -rf $test_dir
    }
    if (".m2" | path exists) {
        rm -rf .m2
    }
    if ("gradle" | path exists) {
        rm -rf gradle
    }

    # Create test Java environment
    mkdir $test_dir

    # Generate config files
    let result = (generate_config_files $test_dir)
    assert $result.success

    # Check Maven settings.xml content
    let maven_content = (open .m2/settings.xml --raw)
    assert ($maven_content | str contains "localRepository")
    assert ($maven_content | str contains $test_dir)

    # Check Gradle properties content
    let gradle_content = (open gradle/gradle.properties --raw)
    assert ($gradle_content | str contains "gradle.user.home")
    assert ($gradle_content | str contains $test_dir)

    # Cleanup
    rm -rf $test_dir
    rm -rf .m2
    rm -rf gradle

    print "✅ Config file content test passed"
}

# Test 4: Error handling - missing local env
def test_missing_local_env [] {
    print "Test: Error handling for missing local environment"

    let test_dir = ".java_test_missing"

    # Make sure it doesn't exist
    if ($test_dir | path exists) {
        rm -rf $test_dir
    }

    # Try to generate without creating local env
    let result = (generate_config_files $test_dir)

    # Should fail
    assert (not $result.success)
    assert (($result.errors | length) > 0)

    print "✅ Missing local env test passed"
}

# Main test runner
def main [] {
    print "\n🧪 Running Configuration Files Tests\n"

    mut results = []

    # Run tests
    let test1 = (try {
        test_generate_config_files_new
        "passed"
    } catch {|e|
        print $"❌ test_generate_config_files_new failed: ($e.msg)"
        "failed"
    })
    $results = ($results | append $test1)

    let test2 = (try {
        test_generate_config_files_idempotent
        "passed"
    } catch {|e|
        print $"❌ test_generate_config_files_idempotent failed: ($e.msg)"
        "failed"
    })
    $results = ($results | append $test2)

    let test3 = (try {
        test_config_file_content
        "passed"
    } catch {|e|
        print $"❌ test_config_file_content failed: ($e.msg)"
        "failed"
    })
    $results = ($results | append $test3)

    let test4 = (try {
        test_missing_local_env
        "passed"
    } catch {|e|
        print $"❌ test_missing_local_env failed: ($e.msg)"
        "failed"
    })
    $results = ($results | append $test4)

    # Count results
    let passed = ($results | where $it == "passed" | length)
    let failed = ($results | where $it == "failed" | length)

    # Summary
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print $"║   Tests Passed: ($passed) | Failed: ($failed)                             ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    if $failed > 0 {
        exit 1
    }
}
