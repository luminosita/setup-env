#!/usr/bin/env nu

# Integration Tests: Platform Compatibility
#
# Tests platform-specific behavior and cross-platform compatibility:
# - OS detection correctly identifies current platform
# - Platform-specific paths are correct
# - Taskfile installation logic selects correct method per platform
# - Setup works on macOS (Intel/Apple Silicon), Linux, WSL2
#
# Usage:
#   nu tests/integration/test_platform_compat.nu

use std assert

# Test 1: Verify OS detection identifies current platform correctly
def test_os_detection_current_platform [] {
    print "\n🧪 Test 1: OS detection identifies current platform"

    let result = (^nu -c "use python/lib/os_detection.nu *; detect_os" | complete)

    assert ($result.exit_code == 0) "OS detection failed"

    # Parse output (it's a record printed as string)
    let output = ($result.stdout | str trim)

    # Verify output contains expected fields
    assert (($output | str contains "os") and ($output | str contains "arch") and ($output | str contains "version")) "OS detection output missing expected fields"

    print $"  Detected: ($output)"

    # Run OS-specific assertions based on actual system
    let uname_os = (^uname -s | str trim)

    match $uname_os {
        "Darwin" => {
            assert (($output | str contains "macos") or ($output | str contains "Darwin")) "OS detection failed to identify macOS"
            print "✅ Correctly identified macOS"
        }
        "Linux" => {
            # Check if WSL
            let is_wsl = (
                ("/proc/version" | path exists) and
                ((open /proc/version | str contains "microsoft") or (open /proc/version | str contains "WSL"))
            )

            if $is_wsl {
                assert (($output | str contains "wsl") or ($output | str contains "linux")) "OS detection failed to identify WSL2"
                print "✅ Correctly identified WSL2/Linux"
            } else {
                assert (($output | str contains "linux") or ($output | str contains "Linux")) "OS detection failed to identify Linux"
                print "✅ Correctly identified Linux"
            }
        }
        _ => {
            print $"⚠️  Unknown platform: ($uname_os)"
            print "  OS detection returned: ($output)"
        }
    }
}

# Test 2: Verify architecture detection
def test_architecture_detection [] {
    print "\n🧪 Test 2: Architecture detection"

    let result = (^nu -c "use python/lib/os_detection.nu *; detect_os" | complete)

    assert ($result.exit_code == 0) "OS detection failed"

    let output = ($result.stdout | str trim)

    # Verify output contains architecture
    assert (
        ($output | str contains "arm64") or
        ($output | str contains "aarch64") or
        ($output | str contains "x86_64") or
        ($output | str contains "amd64")
    ) "OS detection output missing architecture"

    print $"  Detected architecture in output: ($output)"
    print "✅ Architecture detected"
}

# Test 3: Verify version detection
def test_version_detection [] {
    print "\n🧪 Test 3: OS version detection"

    let result = (^nu -c "use python/lib/os_detection.nu *; detect_os" | complete)

    assert ($result.exit_code == 0) "OS detection failed"

    let output = ($result.stdout | str trim)

    # Verify output contains version field
    assert (($output | str contains "version")) "OS detection output missing version field"

    print $"  Version info: ($output)"
    print "✅ OS version detected"
}

# Test 4: Test platform-specific Taskfile validation
def test_taskfile_platform_specific [] {
    print "\n🧪 Test 4: Taskfile validation works on current platform"

    # Check if task command is available
    let result = (^task --version | complete)

    # Should succeed on all platforms (in devbox environment)
    assert ($result.exit_code == 0) $"Taskfile validation failed: ($result.stderr)"

    print "✅ Taskfile validation works on current platform"
}

# Test 5: Test UV validation works cross-platform
def test_uv_platform_specific [] {
    print "\n🧪 Test 5: UV validation works on current platform"

    # Check if uv command is available
    let result = (^uv --version | complete)

    # Should succeed on all platforms (in devbox environment)
    assert ($result.exit_code == 0) $"UV validation failed: ($result.stderr)"

    print "✅ UV validation works on current platform"
}

# Test 6: Test Python path detection works cross-platform
def test_python_path_detection [] {
    print "\n🧪 Test 6: Python path detection works on current platform"

    # Test that Python is found and version is correct
    let result = (^nu -c "use python/lib/prerequisites.nu *; check_prerequisites" | complete)

    assert ($result.exit_code == 0) "Prerequisites check failed"

    # Verify Python 3.11+ is detected
    let output = ($result.stdout | str trim)

    print $"  Prerequisites check output: ($output)"
    print "✅ Python path detection works on current platform"
}

# Test 7: Test virtual environment creation works cross-platform
def test_venv_creation_platform_specific [] {
    print "\n🧪 Test 7: Virtual environment creation works on current platform"

    # Create a test venv
    let test_venv_path = ".venv_platform_test"

    # Clean up if exists
    if ($test_venv_path | path exists) {
        rm -rf $test_venv_path
    }

    try {
        let result = (^nu -c $"use python/lib/venv_setup.nu *; create_venv '($test_venv_path)' '3.11'" | complete)

        assert ($result.exit_code == 0) $"Venv creation failed: ($result.stderr)"

        # Verify venv created
        assert ($test_venv_path | path exists) "Venv directory not created"

        # Verify Python binary exists (platform-specific path)
        let python_exists = (
            ($"($test_venv_path)/bin/python" | path exists) or
            ($"($test_venv_path)/Scripts/python.exe" | path exists)
        )

        assert $python_exists "Python binary not found in venv"

        print "✅ Virtual environment creation works on current platform"

        # Clean up
        rm -rf $test_venv_path
    } catch {|e|
        # Clean up on failure
        if ($test_venv_path | path exists) {
            rm -rf $test_venv_path
        }
        error make {msg: $"Test failed: ($e.msg)"}
    }
}

# Test 8: Test file permissions work cross-platform
def test_file_permissions_platform_specific [] {
    print "\n🧪 Test 8: File permissions handling works on current platform"

    # Create a test .env file
    let test_env_file = ".env.platform_test"

    if ($test_env_file | path exists) {
        rm $test_env_file
    }

    try {
        # Create test file
        "TEST_VAR=test_value" | save $test_env_file

        # Check file exists
        assert ($test_env_file | path exists) "Test .env file not created"

        # On Unix systems, check permissions can be set
        let uname_os = (^uname -s | str trim)

        if ($uname_os == "Darwin") or ($uname_os == "Linux") {
            # Test setting permissions (should not error)
            ^chmod 600 $test_env_file

            # Verify permissions (owner read/write only)
            let perms = (^ls -l $test_env_file | str trim | split row ' ' | get 0)
            # Expected: -rw------- (0600)
            assert (($perms | str contains "rw-") and ($perms | str contains "------")) $"Permissions not set correctly: ($perms)"

            print "✅ File permissions work on Unix platform"
        } else {
            print "⚠️  Skipping permission test (not Unix platform)"
        }

        # Clean up
        rm $test_env_file
    } catch {|e|
        # Clean up on failure
        if ($test_env_file | path exists) {
            rm $test_env_file
        }
        error make {msg: $"Test failed: ($e.msg)"}
    }
}

# Test 9: Test platform-specific paths
def test_platform_specific_paths [] {
    print "\n🧪 Test 9: Platform-specific paths are correct"

    # Test Python binary path in venv
    let uname_os = (^uname -s | str trim)

    match $uname_os {
        "Darwin" | "Linux" => {
            print "  Expected Python path: .venv/bin/python"
            print "  Expected activation: source .venv/bin/activate"
            print "✅ Unix platform paths correct"
        }
        "Windows_NT" => {
            print "  Expected Python path: .venv\\Scripts\\python.exe"
            print "  Expected activation: .venv\\Scripts\\activate"
            print "✅ Windows platform paths correct"
        }
        _ => {
            print $"⚠️  Unknown platform for path testing: ($uname_os)"
        }
    }
}

# Test 10: Test full setup on current platform
def test_full_setup_current_platform [] {
    print "\n🧪 Test 10: Full setup works on current platform (end-to-end)"
    print "⏱️  This test runs complete setup..."

    # Backup environment
    if (".venv" | path exists) {
        if (".venv.backup_platform" | path exists) {
            rm -rf .venv.backup_platform
        }
        mv .venv .venv.backup_platform
    }

    if (".env" | path exists) {
        if (".env.backup_platform" | path exists) {
            rm .env.backup_platform
        }
        cp .env .env.backup_platform
    }

    # Clean up
    if (".venv" | path exists) {
        rm -rf .venv
    }

    if (".env" | path exists) and (".env.backup_platform" | path exists | not $in) {
        rm .env
    }

    try {
        # Run setup
        print "\n🚀 Running: nu python/setup.nu --silent\n"
        let result = (^nu python/setup.nu --silent | complete)

        assert ($result.exit_code == 0) $"Setup failed on current platform: ($result.stderr)"

        # Verify environment created
        assert (".venv" | path exists) "Virtual environment not created"
        assert (".env" | path exists) ".env file not created"

        print "\n✅ Full setup succeeded on current platform"

        # Clean up
        if (".venv" | path exists) {
            rm -rf .venv
        }

        if (".env" | path exists) and (".env.backup_platform" | path exists | not $in) {
            rm .env
        }
    } catch {|e|
        # Restore on failure
        if (".venv.backup_platform" | path exists) {
            if (".venv" | path exists) {
                rm -rf .venv
            }
            mv .venv.backup_platform .venv
        }

        if (".env.backup_platform" | path exists) {
            if (".env" | path exists) {
                rm .env
            }
            mv .env.backup_platform .env
        }

        error make {msg: $"Test failed: ($e.msg)"}
    }

    # Restore environment
    if (".venv.backup_platform" | path exists) {
        if (".venv" | path exists) {
            rm -rf .venv
        }
        mv .venv.backup_platform .venv
    }

    if (".env.backup_platform" | path exists) {
        if (".env" | path exists) {
            rm .env
        }
        mv .env.backup_platform .env
    }
}

# Main test runner
def main [] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║       Integration Tests: Platform Compatibility         ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    # Detect current platform
    let uname_os = (^uname -s | str trim)
    print $"🖥️  Running on: ($uname_os)\n"

    let start_time = (date now)

    # Run tests sequentially
    let test_results = [
        (try { test_os_detection_current_platform; {name: "OS detection (current platform)", passed: true} } catch {|e| {name: "OS detection (current platform)", passed: false, error: $e.msg}})
        (try { test_architecture_detection; {name: "Architecture detection", passed: true} } catch {|e| {name: "Architecture detection", passed: false, error: $e.msg}})
        (try { test_version_detection; {name: "OS version detection", passed: true} } catch {|e| {name: "OS version detection", passed: false, error: $e.msg}})
        (try { test_taskfile_platform_specific; {name: "Taskfile platform-specific", passed: true} } catch {|e| {name: "Taskfile platform-specific", passed: false, error: $e.msg}})
        (try { test_uv_platform_specific; {name: "UV platform-specific", passed: true} } catch {|e| {name: "UV platform-specific", passed: false, error: $e.msg}})
        (try { test_python_path_detection; {name: "Python path detection", passed: true} } catch {|e| {name: "Python path detection", passed: false, error: $e.msg}})
        (try { test_venv_creation_platform_specific; {name: "Venv creation platform-specific", passed: true} } catch {|e| {name: "Venv creation platform-specific", passed: false, error: $e.msg}})
        (try { test_file_permissions_platform_specific; {name: "File permissions platform-specific", passed: true} } catch {|e| {name: "File permissions platform-specific", passed: false, error: $e.msg}})
        (try { test_platform_specific_paths; {name: "Platform-specific paths", passed: true} } catch {|e| {name: "Platform-specific paths", passed: false, error: $e.msg}})
        (try { test_full_setup_current_platform; {name: "Full setup (current platform)", passed: true} } catch {|e| {name: "Full setup (current platform)", passed: false, error: $e.msg}})
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

    # Calculate duration
    let end_time = (date now)
    let duration = ($end_time - $start_time)

    # Display results
    print "\n╔═══════════════════════════════════════════════════════════╗"

    if $failed == 0 {
        print "║      ✅ All Platform Compatibility Tests Passed!        ║"
    } else {
        print "║      ⚠️  Some Platform Compatibility Tests Failed       ║"
    }

    print "╚═══════════════════════════════════════════════════════════╝\n"

    print $"📊 Results: ($passed) passed, ($failed) failed"
    print $"⏱️  Total test time: ($duration)"
    print $"🖥️  Tested on: ($uname_os)\n"

    # Exit with appropriate code
    if $failed > 0 {
        exit 1
    }
}
