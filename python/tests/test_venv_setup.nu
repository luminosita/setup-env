# Unit tests for Virtual Environment Setup Module
#
# Tests the virtual environment creation, checking, and Python version detection

use std assert
use ../lib/venv_setup.nu *

# Test 1: Create virtual environment
def test_create_venv [] {
    print "Test: Create virtual environment"

    # Use a test venv path
    let test_venv = ".venv_test"

    # Clean up if exists
    if ($test_venv | path exists) {
        rm -rf $test_venv
    }

    let result = (create_venv $test_venv "3.11")

    print $"Result: ($result)"
    assert $result.success
    assert ($result.path | path exists)
    assert (($result.python_version | str length) > 0)

    # Clean up
    rm -rf $test_venv

    print "✅ Virtual environment created successfully"
}

# Test 2: Check existing venv (idempotent)
def test_create_venv_idempotent [] {
    print "Test: Create venv (idempotent)"

    let test_venv = ".venv_test"

    # Create first time
    let result1 = (create_venv $test_venv "3.11")
    assert $result1.success

    # Create second time (should detect existing)
    let result2 = (create_venv $test_venv "3.11")
    assert $result2.success
    assert ($result2.path == $result1.path)

    # Clean up
    rm -rf $test_venv

    print "✅ Idempotent venv creation works"
}

# Test 3: Check venv exists
def test_check_venv [] {
    print "Test: Check venv exists"

    let test_venv = ".venv_test"

    # Create venv
    let _ = (create_venv $test_venv "3.11")

    # Check it exists
    let check = (check_venv $test_venv)
    assert $check.exists

    # Clean up
    rm -rf $test_venv

    # Check non-existent venv
    let check2 = (check_venv $test_venv)
    assert (not $check2.exists)

    print "✅ Venv existence check works"
}

# Test 4: Get Python version from venv
def test_get_venv_python_version [] {
    print "Test: Get Python version from venv"

    let test_venv = ".venv_test"

    # Create venv
    let _ = (create_venv $test_venv "3.11")

    # Get Python version
    let version = (get_venv_python_version $test_venv)

    print $"Python version: ($version)"
    assert $version.success
    assert (($version.version | str length) > 0)

    # Should contain "3."
    assert ($version.version | str starts-with "3.")

    # Clean up
    rm -rf $test_venv

    print "✅ Python version detection works"
}

# Test 5: Handle non-existent venv
def test_get_version_nonexistent_venv [] {
    print "Test: Get version from non-existent venv"

    let test_venv = ".venv_nonexistent"

    # Ensure it doesn't exist
    if ($test_venv | path exists) {
        rm -rf $test_venv
    }

    # Try to get version
    let version = (get_venv_python_version $test_venv)

    assert (not $version.success)
    assert (($version.error | str length) > 0)

    print "✅ Non-existent venv handled correctly"
}

# Test 6: Verify venv structure
def test_venv_structure [] {
    print "Test: Verify venv directory structure"

    let test_venv = ".venv_test"

    # Create venv
    let _ = (create_venv $test_venv "3.11")

    # Check for expected directories
    let bin_dir = if ($nu.os-info.name == "windows") {
        ($test_venv | path join "Scripts")
    } else {
        ($test_venv | path join "bin")
    }

    assert ($bin_dir | path exists)

    let lib_dir = ($test_venv | path join "lib")
    assert ($lib_dir | path exists)

    # Clean up
    rm -rf $test_venv

    print "✅ Venv structure is correct"
}

# Main test runner
def main [] {
    print "\n🧪 Running Virtual Environment Setup Tests\n"

    test_create_venv
    test_create_venv_idempotent
    test_check_venv
    test_get_venv_python_version
    test_get_version_nonexistent_venv
    test_venv_structure

    print "\n✅ All virtual environment tests passed!\n"
}
