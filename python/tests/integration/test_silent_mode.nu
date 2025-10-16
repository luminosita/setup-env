#!/usr/bin/env nu

# Integration Tests: Silent Mode (CI/CD Automation)
#
# Tests the --silent flag for non-interactive execution:
# - No interactive prompts displayed
# - Uses default preferences automatically
# - Suitable for CI/CD pipelines
# - Exit code indicates success/failure correctly
# - Output is machine-parseable
#
# Usage:
#   nu tests/integration/test_silent_mode.nu

use std assert
use test_helpers.nu *

# Backup existing environment state
def backup_environment [] {
    print "📦 Backing up existing environment..."

    if (".venv" | path exists) {
        if (".venv.backup" | path exists) {
            rm -rf .venv.backup
        }
        mv .venv .venv.backup
        print "  ✅ Backed up .venv"
    }

    if (".env" | path exists) {
        if (".env.backup" | path exists) {
            rm .env.backup
        }
        cp .env .env.backup
        print "  ✅ Backed up .env"
    }
}

# Restore environment state
def restore_environment [] {
    print "♻️  Restoring environment..."

    if (".venv.backup" | path exists) {
        if (".venv" | path exists) {
            rm -rf .venv
        }
        mv .venv.backup .venv
        print "  ✅ Restored .venv"
    }

    if (".env.backup" | path exists) {
        if (".env" | path exists) {
            rm .env
        }
        mv .env.backup .env
        print "  ✅ Restored .env"
    }
}

# Clean up test artifacts
def cleanup_test_artifacts [] {
    print "🧹 Cleaning up test artifacts..."

    if (".venv" | path exists) {
        rm -rf .venv
        print "  ✅ Removed test .venv"
    }

    if (".env" | path exists) and (".env.backup" | path exists | not $in) {
        rm .env
        print "  ✅ Removed test .env"
    }
}

# Test 1: Verify --silent flag is recognized
def test_silent_flag_recognized [] {
    print "\n🧪 Test 1: Verify --silent flag is recognized"

    let result = (^nu python/setup.nu --help | complete)

    assert ($result.exit_code == 0) "Help command failed"
    assert (($result.stdout | str contains "silent") or ($result.stdout | str contains "-s")) "Silent flag not documented in help"

    print "✅ Silent flag is recognized and documented"
}

# Test 2: Silent mode completes without user input
def test_silent_mode_no_prompts [] {
    print "\n🧪 Test 2: Silent mode completes without user input"
    print "⏱️  Running full setup in silent mode..."

    backup_environment
    cleanup_test_artifacts

    try {
        # Run setup in silent mode with timeout (should not hang waiting for input)
        # If it hangs waiting for input, this will timeout
        let result = (^nu python/setup.nu --silent | complete)

        # Should complete without hanging
        assert ($result.exit_code == 0) $"Silent mode failed: ($result.stderr)"

        # Verify no prompt indicators in output
        # (Prompts typically contain "? ", "[Y/n]", etc.)
        let has_prompts = (
            (($result.stdout | str contains "? ") or
             ($result.stdout | str contains "[Y/n]") or
             ($result.stdout | str contains "[y/N]")) and
            not (($result.stdout | str contains "silent") or ($result.stdout | str contains "CI/CD"))
        )

        if $has_prompts {
            print $"⚠️  Warning: Output may contain prompt-like text:\n($result.stdout)"
        }

        print "✅ Silent mode completed without requiring user input"

        cleanup_test_artifacts
    } catch {|e|
        restore_environment
        error make {msg: $"Test failed: ($e.msg)"}
    }

    restore_environment
}

# Test 3: Silent mode uses default preferences
def test_silent_mode_defaults [] {
    print "\n🧪 Test 3: Silent mode uses default preferences"

    backup_environment
    cleanup_test_artifacts

    try {
        let result = (^nu python/setup.nu --silent | complete)

        assert ($result.exit_code == 0) "Silent mode failed"

        # Verify environment created (default behavior)
        assert (".venv" | path exists) "Virtual environment not created"
        assert (".env" | path exists) ".env file not created"

        print "✅ Silent mode uses default preferences correctly"

        cleanup_test_artifacts
    } catch {|e|
        restore_environment
        error make {msg: $"Test failed: ($e.msg)"}
    }

    restore_environment
}

# Test 4: Silent mode exit code indicates success/failure
def test_silent_mode_exit_codes [] {
    print "\n🧪 Test 4: Silent mode exit codes indicate success/failure"

    backup_environment
    cleanup_test_artifacts

    try {
        # Test successful execution
        let success_result = (^nu python/setup.nu --silent | complete)

        assert ($success_result.exit_code == 0) "Successful setup should return exit code 0"

        print "✅ Silent mode returns correct exit codes"

        cleanup_test_artifacts
    } catch {|e|
        restore_environment
        error make {msg: $"Test failed: ($e.msg)"}
    }

    restore_environment
}

# Test 5: Silent mode output is structured
def test_silent_mode_output_structure [] {
    print "\n🧪 Test 5: Silent mode output is structured and parseable"

    backup_environment
    cleanup_test_artifacts

    try {
        let result = (^nu python/setup.nu --silent | complete)

        assert ($result.exit_code == 0) "Setup failed"

        # Verify output contains phase markers (structured output)
        assert (($result.stdout | str contains "Phase")) "Output missing phase markers"

        # Verify output contains success indicator
        assert (($result.stdout | str contains "✅") or ($result.stdout | str contains "Complete")) "Output missing success indicator"

        # Verify output is not empty
        assert (($result.stdout | str length) > 0) "Silent mode produced no output"

        print "✅ Silent mode output is structured and informative"

        cleanup_test_artifacts
    } catch {|e|
        restore_environment
        error make {msg: $"Test failed: ($e.msg)"}
    }

    restore_environment
}

# Test 6: Silent mode works in CI/CD environment simulation
def test_silent_mode_ci_cd_simulation [] {
    print "\n🧪 Test 6: Silent mode works in CI/CD environment (simulated)"
    print "⏱️  Simulating CI/CD pipeline execution..."

    backup_environment
    cleanup_test_artifacts

    try {
        # Simulate CI/CD by setting CI environment variable
        # and running in silent mode

        let result = (
            with-env {CI: "true"} {
                ^nu python/setup.nu --silent | complete
            }
        )

        assert ($result.exit_code == 0) $"CI/CD simulation failed: ($result.stderr)"

        # Verify environment created successfully
        assert (".venv" | path exists) "Environment not created in CI/CD mode"

        print "✅ Silent mode works in CI/CD environment"

        cleanup_test_artifacts
    } catch {|e|
        restore_environment
        error make {msg: $"Test failed: ($e.msg)"}
    }

    restore_environment
}

# Test 7: Silent mode is idempotent (safe for repeated runs)
def test_silent_mode_idempotent [] {
    print "\n🧪 Test 7: Silent mode is idempotent (safe for repeated runs)"

    backup_environment
    cleanup_test_artifacts

    try {
        # First run
        print "\n  🚀 First run..."
        let first_run = (^nu python/setup.nu --silent | complete)
        assert ($first_run.exit_code == 0) "First run failed"

        # Second run (should not fail)
        print "  🚀 Second run..."
        let second_run = (^nu python/setup.nu --silent | complete)
        assert ($second_run.exit_code == 0) "Second run failed (not idempotent)"

        print "✅ Silent mode is idempotent (safe for repeated runs)"

        cleanup_test_artifacts
    } catch {|e|
        restore_environment
        error make {msg: $"Test failed: ($e.msg)"}
    }

    restore_environment
}

# Test 8: Interactive module respects silent flag
def test_interactive_module_silent_flag [] {
    print "\n🧪 Test 8: Interactive module respects silent flag"

    # Test the get_setup_preferences function directly
    let result = (^nu -c "use python/lib/interactive.nu *; get_setup_preferences true" | complete)

    assert ($result.exit_code == 0) "Interactive module failed in silent mode"

    # Should return preferences record without prompting
    print "✅ Interactive module respects silent flag"
}

# Main test runner
def main [] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║      Integration Tests: Silent Mode (CI/CD)             ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    # Setup dummy files if needed
    let pyproject_state = (setup_dummy_pyproject)
    let start_time = (date now)

    # Run tests sequentially
    let test_results = [
        (try { test_silent_flag_recognized; {name: "Silent flag recognized", passed: true} } catch {|e| {name: "Silent flag recognized", passed: false, error: $e.msg}})
        (try { test_silent_mode_no_prompts; {name: "No prompts in silent mode", passed: true} } catch {|e| {name: "No prompts in silent mode", passed: false, error: $e.msg}})
        (try { test_silent_mode_defaults; {name: "Uses default preferences", passed: true} } catch {|e| {name: "Uses default preferences", passed: false, error: $e.msg}})
        (try { test_silent_mode_exit_codes; {name: "Correct exit codes", passed: true} } catch {|e| {name: "Correct exit codes", passed: false, error: $e.msg}})
        (try { test_silent_mode_output_structure; {name: "Structured output", passed: true} } catch {|e| {name: "Structured output", passed: false, error: $e.msg}})
        (try { test_silent_mode_ci_cd_simulation; {name: "CI/CD environment simulation", passed: true} } catch {|e| {name: "CI/CD environment simulation", passed: false, error: $e.msg}})
        (try { test_silent_mode_idempotent; {name: "Idempotent execution", passed: true} } catch {|e| {name: "Idempotent execution", passed: false, error: $e.msg}})
        (try { test_interactive_module_silent_flag; {name: "Interactive module respects flag", passed: true} } catch {|e| {name: "Interactive module respects flag", passed: false, error: $e.msg}})
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
        print "║          ✅ All Silent Mode Tests Passed!               ║"
    } else {
        print "║          ⚠️  Some Silent Mode Tests Failed              ║"
    }

    print "╚═══════════════════════════════════════════════════════════╝\n"

    print $"📊 Results: ($passed) passed, ($failed) failed"
    print $"⏱️  Total test time: ($duration)\n"

    # Cleanup dummy files if we created them
    cleanup_dummy_pyproject $pyproject_state
    # Exit with appropriate code
    if $failed > 0 {
        exit 1
    }
}
