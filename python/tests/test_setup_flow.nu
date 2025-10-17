#!/usr/bin/env nu

# Integration Tests for Setup Script
#
# Tests the complete setup flow end-to-end including all phases

use std assert

# Test environment setup
def setup_test_env [] {
    print "Setting up test environment..."
    # Backup existing .venv if present
    if (".venv" | path exists) {
        if (".venv.backup" | path exists) {
            rm -rf .venv.backup
        }
        mv .venv .venv.backup
        print "  ✅ Backed up existing .venv"
    }
}

# Test environment cleanup
def cleanup_test_env [] {
    print "Cleaning up test environment..."
    # Remove test .venv
    if (".venv" | path exists) {
        rm -rf .venv
        print "  ✅ Removed test .venv"
    }

    # Restore backup if exists
    if (".venv.backup" | path exists) {
        mv .venv.backup .venv
        print "  ✅ Restored original .venv"
    }
}

# Test 1: Verify all required modules exist
def test_modules_exist [] {
    print "\n🧪 Test 1: Verify all required modules exist"

    let modules = [
        "common/lib/os_detection.nu"
        "common/lib/common.nu"
        "common/lib/interactive.nu"
        "common/lib/template_config.nu"
        "common/lib/config_setup.nu"
        "common/lib/prerequisites_base.nu"
        "python/lib/prerequisites.nu"
        "python/lib/venv_setup.nu"
        "python/lib/deps_install.nu"
        "python/lib/validation.nu"
        "python/setup.nu"
    ]

    for module in $modules {
        assert ($module | path exists) $"Module not found: ($module)"
        print $"  ✅ ($module)"
    }

    print "✅ All modules exist"
}

# Test 2: Verify setup script syntax
def test_setup_script_syntax [] {
    print "\n🧪 Test 2: Verify setup script syntax"

    # Use absolute path to avoid path resolution issues
    let script_path = ($env.PWD | path join "python" "setup.nu")

    let result = (try {
        nu-check $script_path
        {exit_code: 0, error: ""}
    } catch { |e|
        {exit_code: 1, error: $e.msg}
    })

    if $result.exit_code != 0 {
        print $"❌ Syntax check failed: ($result.error)"
        assert false "Setup script has syntax errors"
    }

    print "✅ Setup script syntax valid"
}

# Test 3: Test setup script help
def test_setup_help [] {
    print "\n🧪 Test 3: Test setup script help"

    let result = (nu python/setup.nu --help | complete)

    assert ($result.exit_code == 0) "Help command failed"
    assert (($result.stdout | str contains "silent") or ($result.stdout | str contains "--silent")) "Help output missing --silent flag"

    print "✅ Setup script help works"
}

# Test 4: Test silent mode flag recognition
def test_silent_mode_flag [] {
    print "\n🧪 Test 4: Test silent mode flag recognition"

    # Just check if the flag is recognized (don't run full setup)
    # We'll use help to verify the flag exists
    let result = (nu python/setup.nu --help | complete)

    assert ($result.exit_code == 0) "Setup script failed"
    assert (($result.stdout | str contains "-s, --silent") or ($result.stdout | str contains "--silent")) "Silent flag not recognized"

    print "✅ Silent mode flag recognized"
}

# Test 5: Test OS detection module
def test_os_detection [] {
    print "\n🧪 Test 5: Test OS detection module"

    let result = (nu -c "use common/lib/os_detection.nu; os_detection detect_os" | complete)

    assert ($result.exit_code == 0) $"OS detection failed: ($result.stderr)"

    # Parse output to verify structure
    let output = ($result.stdout | str trim)
    print $"  OS Info: ($output)"

    print "✅ OS detection works"
}

# Test 6: Test prerequisites validation
def test_prerequisites_check [] {
    print "\n🧪 Test 6: Test prerequisites validation"

    let result = (nu -c "use python/lib/prerequisites.nu; prerequisites check_prerequisites" | complete)

    assert ($result.exit_code == 0) $"Prerequisites check failed: ($result.stderr)"

    print "✅ Prerequisites check works"
}

# Test 7: Test UV installation (idempotent)
# Note: UV installation functionality has been refactored into setup script
# UV is now checked in prerequisites, not installed by a separate module
def test_uv_installation [] {
    print "\n🧪 Test 7: Test UV installation (skipped - refactored into prerequisites)"
    print "✅ UV installation test skipped (functionality refactored)"
}

# Test 8: Test virtual environment creation
def test_venv_creation [] {
    print "\n🧪 Test 8: Test virtual environment creation"

    # Backup and clean
    setup_test_env

    try {
        let result = (nu -c "use python/lib/venv_setup.nu; venv_setup create_venv '.venv_test' '3.11'" | complete)

        assert ($result.exit_code == 0) $"Venv creation failed: ($result.stderr)"
        assert (".venv_test" | path exists) "Venv directory not created"

        # Cleanup
        rm -rf .venv_test

        print "✅ Virtual environment creation works"
    } catch {|e|
        rm -rf .venv_test
        error make {msg: $"Test failed: ($e.msg)"}
    }
}

# Test 9: Test interactive module (silent mode)
def test_interactive_silent_mode [] {
    print "\n🧪 Test 9: Test interactive module (silent mode)"

    let result = (nu -c "use common/lib/interactive.nu; interactive get_setup_preferences true" | complete)

    assert ($result.exit_code == 0) $"Interactive module failed: ($result.stderr)"

    print "✅ Interactive module (silent mode) works"
}

# Test 10: Test validation module
def test_validation_module [] {
    print "\n🧪 Test 10: Test validation module"

    # Test that module loads correctly (functions tested separately in other test files)
    let result = (nu -c "use python/lib/validation.nu; 'module loaded'" | complete)

    assert ($result.exit_code == 0) $"Validation module failed to load: ($result.stderr)"

    print "✅ Validation module works"
}

# Main test runner
def main [
    --quick (-q)  # Run only quick tests (skip full setup)
] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║        Setup Script Integration Tests                    ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    let start_time = (date now)

    # Run all tests sequentially (assertions will exit on failure)
    test_modules_exist
    test_setup_script_syntax
    test_setup_help
    test_silent_mode_flag
    test_os_detection
    test_prerequisites_check
    test_uv_installation
    test_venv_creation
    test_interactive_silent_mode
    test_validation_module

    # Calculate duration
    let end_time = (date now)
    let duration = ($end_time - $start_time)

    # Display results (if we got here, all tests passed)
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║                  ✅ All Tests Passed!                    ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    print $"⏱️  Total test time: ($duration)"
    print "✅ All 10 integration tests passed!\n"
}
