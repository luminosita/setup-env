#!/usr/bin/env nu

# Unit Tests: Template Configuration Module
#
# Tests the template configuration functionality including:
# - String replacements (CHANGE_ME, change-me, change_me)
# - Path name transformation
# - Folder renaming
#
# Usage:
#   nu tests/test_template_config.nu

use std assert
use ../../common/lib/interactive.nu *

# Test: transform_to_path_name function
def test_transform_to_path_name [] {
    print "\n🧪 Test: transform_to_path_name"

    # Test lowercase
    let result1 = (transform_to_path_name "MyApp")
    assert equal $result1 "myapp"

    # Test spaces to underscores
    let result2 = (transform_to_path_name "My Cool App")
    assert equal $result2 "my_cool_app"

    # Test hyphens to underscores
    let result3 = (transform_to_path_name "my-cool-app")
    assert equal $result3 "my_cool_app"

    # Test special characters removed
    let result4 = (transform_to_path_name "My@Cool#App!")
    assert equal $result4 "mycoolapp"

    # Test mixed
    let result5 = (transform_to_path_name "My-Cool_App 123")
    assert equal $result5 "my_cool_app_123"

    # Test already valid
    let result6 = (transform_to_path_name "my_app_123")
    assert equal $result6 "my_app_123"

    print "✅ transform_to_path_name works correctly"
}

# Test: String replacement in content
def test_string_replacement [] {
    print "\n🧪 Test: String replacement in content"

    let content = "CHANGE_ME application using change-me and change_me module"

    let replacements = {
        CHANGE_ME: "My Cool App",
        "change-me": "my-cool-app",
        change_me: "my_cool_app"
    }

    mut new_content = $content
    $new_content = ($new_content | str replace -a "CHANGE_ME" $replacements.CHANGE_ME)
    $new_content = ($new_content | str replace -a "change-me" $replacements."change-me")
    $new_content = ($new_content | str replace -a "change_me" $replacements.change_me)

    let expected = "My Cool App application using my-cool-app and my_cool_app module"
    assert equal $new_content $expected

    print "✅ String replacement works correctly"
}

# Test: File replacement (mock test)
def test_file_operations [] {
    print "\n🧪 Test: File operations (placeholder replacement)"

    # Create temporary test directory
    let test_dir = $"/tmp/test_template_(random uuid)"
    mkdir $test_dir

    try {
        # Create test file with placeholders
        let test_file = $"($test_dir)/test.txt"
        "CHANGE_ME\nchange-me\nchange_me" | save $test_file

        # Read and replace
        let content = (open $test_file)
        let new_content = ($content
            | str replace -a "CHANGE_ME" "My App"
            | str replace -a "change-me" "my-app"
            | str replace -a "change_me" "my_app")

        # Save back
        $new_content | save -f $test_file

        # Verify
        let result_content = (open $test_file)
        let expected = "My App\nmy-app\nmy_app"
        assert equal $result_content $expected

        print "✅ File operations work correctly"
    } catch {|err|
        rm -rf $test_dir
        error make {msg: $"Test failed: ($err.msg)"}
    }

    # Cleanup
    rm -rf $test_dir
}

# Test: Folder renaming
def test_folder_renaming [] {
    print "\n🧪 Test: Folder renaming"

    # Create temporary test directory
    let test_dir = $"/tmp/test_rename_(random uuid)"
    mkdir $test_dir

    try {
        # Create source folder
        let old_folder = $"($test_dir)/change_me"
        mkdir $old_folder

        # Create a file in it
        "test content" | save $"($old_folder)/test.txt"

        # Rename
        let new_folder = $"($test_dir)/my_app"
        mv $old_folder $new_folder

        # Verify old doesn't exist, new does
        assert (not ($old_folder | path exists))
        assert ($new_folder | path exists)
        assert ($"($new_folder)/test.txt" | path exists)

        # Verify content preserved
        let content = (open $"($new_folder)/test.txt")
        assert equal $content "test content"

        print "✅ Folder renaming works correctly"
    } catch {|err|
        rm -rf $test_dir
        error make {msg: $"Test failed: ($err.msg)"}
    }

    # Cleanup
    rm -rf $test_dir
}

# Test: Get app configuration in silent mode
def test_get_app_configuration_silent [] {
    print "\n🧪 Test: get_app_configuration (silent mode)"

    let config = (get_app_configuration true)

    # Check structure
    assert ("app_name" in ($config | columns))
    assert ("app_code_name" in ($config | columns))
    assert ("app_path_name" in ($config | columns))

    # Check default values
    assert equal $config.app_name "CHANGE_ME"
    assert equal $config.app_code_name "change-me"
    assert equal $config.app_path_name "change_me"

    print "✅ get_app_configuration (silent) works correctly"
}

# Test: Multiple placeholder patterns in same content
def test_multiple_placeholder_patterns [] {
    print "\n🧪 Test: Multiple placeholder patterns"

    let content = "Project CHANGE_ME has code change-me and module change_me. CHANGE_ME again!"

    let replacements = {
        CHANGE_ME: "SuperApp",
        "change-me": "super-app",
        change_me: "super_app"
    }

    mut new_content = $content
    $new_content = ($new_content | str replace -a "CHANGE_ME" $replacements.CHANGE_ME)
    $new_content = ($new_content | str replace -a "change-me" $replacements."change-me")
    $new_content = ($new_content | str replace -a "change_me" $replacements.change_me)

    let expected = "Project SuperApp has code super-app and module super_app. SuperApp again!"
    assert equal $new_content $expected

    print "✅ Multiple placeholder patterns work correctly"
}

# Test: Edge case - empty transformations
def test_edge_cases [] {
    print "\n🧪 Test: Edge cases"

    # Test single character
    let result1 = (transform_to_path_name "A")
    assert equal $result1 "a"

    # Test numbers only
    let result2 = (transform_to_path_name "123")
    assert equal $result2 "123"

    # Test underscores only
    let result3 = (transform_to_path_name "___")
    assert equal $result3 "___"

    # Test mixed with numbers
    let result4 = (transform_to_path_name "App2024")
    assert equal $result4 "app2024"

    print "✅ Edge cases handled correctly"
}

# Main test runner
def main [] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║     Unit Tests: Template Configuration Module           ║"
    print "╚═══════════════════════════════════════════════════════════╝"

    let start_time = (date now)

    # Run all tests
    let test_results = [
        (try { test_transform_to_path_name; {name: "transform_to_path_name", passed: true} } catch {|e| {name: "transform_to_path_name", passed: false, error: $e.msg}})
        (try { test_string_replacement; {name: "String replacement", passed: true} } catch {|e| {name: "String replacement", passed: false, error: $e.msg}})
        (try { test_file_operations; {name: "File operations", passed: true} } catch {|e| {name: "File operations", passed: false, error: $e.msg}})
        (try { test_folder_renaming; {name: "Folder renaming", passed: true} } catch {|e| {name: "Folder renaming", passed: false, error: $e.msg}})
        (try { test_get_app_configuration_silent; {name: "get_app_configuration (silent)", passed: true} } catch {|e| {name: "get_app_configuration (silent)", passed: false, error: $e.msg}})
        (try { test_multiple_placeholder_patterns; {name: "Multiple placeholder patterns", passed: true} } catch {|e| {name: "Multiple placeholder patterns", passed: false, error: $e.msg}})
        (try { test_edge_cases; {name: "Edge cases", passed: true} } catch {|e| {name: "Edge cases", passed: false, error: $e.msg}})
    ]

    # Print failures
    for result in $test_results {
        if not $result.passed {
            print $"❌ Test '($result.name)' failed: ($result.error)"
        }
    }

    # Calculate stats
    let passed = ($test_results | where passed == true | length)
    let failed = ($test_results | where passed == false | length)
    let total = ($test_results | length)

    # Calculate duration
    let end_time = (date now)
    let duration = ($end_time - $start_time)

    # Display results
    print "\n╔═══════════════════════════════════════════════════════════╗"

    if $failed == 0 {
        print "║              ✅ All Tests Passed!                        ║"
    } else {
        print "║              ⚠️  Some Tests Failed                       ║"
    }

    print "╚═══════════════════════════════════════════════════════════╝\n"

    print $"📊 Results: ($passed)/($total) tests passed"
    print $"⏱️  Total test time: ($duration)\n"

    # Exit with appropriate code
    if $failed > 0 {
        exit 1
    }
}
