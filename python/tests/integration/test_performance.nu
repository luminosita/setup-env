#!/usr/bin/env nu

# Integration Tests: Performance Benchmarks
#
# Tests setup script performance against targets:
# - First-time setup completes within 30 minutes
# - Idempotent re-run completes within 2 minutes
# - Dependency installation completes within reasonable time
# - Validation checks are fast (<10 seconds total)
#
# Usage:
#   nu tests/integration/test_performance.nu
#   nu tests/integration/test_performance.nu --quick  # Skip full setup (faster)

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
    }

    if (".env" | path exists) {
        if (".env.backup" | path exists) {
            rm .env.backup
        }
        cp .env .env.backup
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
    }

    if (".env.backup" | path exists) {
        if (".env" | path exists) {
            rm .env
        }
        mv .env.backup .env
    }
}

# Clean up test artifacts
def cleanup_test_artifacts [] {
    print "🧹 Cleaning up test artifacts..."

    if (".venv" | path exists) {
        rm -rf .venv
    }

    if (".env" | path exists) and (".env.backup" | path exists | not $in) {
        rm .env
    }
}

# Format duration in human-readable format
def format_duration [duration] {
    let total_seconds = ($duration | into int) / 1_000_000_000
    let minutes = ($total_seconds / 60 | math floor)
    let seconds = ($total_seconds mod 60 | math floor)

    if $minutes > 0 {
        $"($minutes)m ($seconds)s"
    } else {
        $"($seconds)s"
    }
}

# Test 1: Measure first-time setup duration
def test_first_time_setup_duration [] {
    print "\n🧪 Test 1: First-time setup duration (target: < 30 minutes)"
    print "⏱️  This test executes full setup from scratch...\n"

    backup_environment
    cleanup_test_artifacts

    try {
        let start_time = (date now)

        # Run full setup in silent mode
        print "🚀 Running: nu python/setup.nu --silent\n"
        let result = (^nu python/setup.nu --silent | complete)

        let end_time = (date now)
        let duration = ($end_time - $start_time)

        # Calculate duration in seconds for comparison
        let total_seconds = ($duration | into int) / 1_000_000_000
        let minutes = ($total_seconds / 60)

        assert ($result.exit_code == 0) "Setup failed"

        # Display timing
        let formatted_duration = (format_duration $duration)
        print $"\n⏱️  First-time setup completed in: ($formatted_duration)"

        # Check against 30-minute target
        # Note: We set a warning threshold rather than hard failure
        # as performance varies by hardware and network
        if $minutes > 30 {
            print $"⚠️  WARNING: Setup exceeded 30-minute target (actual: ($formatted_duration))"
            print "   This may be acceptable on slower hardware or network"
        } else {
            print "✅ Setup completed within 30-minute target"
        }

        # Report on individual components (if we can extract from output)
        print "\n📊 Performance Breakdown:"
        print $"  Total duration: ($formatted_duration)"
        print $"  Average: ($total_seconds)s"

        cleanup_test_artifacts
    } catch {|e|
        restore_environment
        error make {msg: $"Test failed: ($e.msg)"}
    }

    restore_environment
}

# Test 2: Measure idempotent re-run duration
def test_idempotent_rerun_duration [] {
    print "\n🧪 Test 2: Idempotent re-run duration (target: < 2 minutes)"
    print "⏱️  This test runs setup twice to measure re-run performance...\n"

    backup_environment
    cleanup_test_artifacts

    try {
        # First run (setup environment)
        print "🚀 First run: nu python/setup.nu --silent\n"
        let first_run = (^nu python/setup.nu --silent | complete)
        assert ($first_run.exit_code == 0) "First setup run failed"

        # Second run (idempotent - should be fast)
        print "\n🚀 Second run (idempotent): nu python/setup.nu --silent\n"
        let start_time = (date now)
        let second_run = (^nu python/setup.nu --silent | complete)
        let end_time = (date now)
        let duration = ($end_time - $start_time)

        assert ($second_run.exit_code == 0) "Second setup run failed"

        # Calculate duration in seconds
        let total_seconds = ($duration | into int) / 1_000_000_000
        let minutes = ($total_seconds / 60)

        let formatted_duration = (format_duration $duration)
        print $"\n⏱️  Idempotent re-run completed in: ($formatted_duration)"

        # Check against 2-minute target
        if $minutes > 2 {
            print $"⚠️  WARNING: Re-run exceeded 2-minute target (actual: ($formatted_duration))"
            print "   This may indicate unnecessary re-installation or slow validation"
        } else {
            print "✅ Idempotent re-run completed within 2-minute target"
        }

        cleanup_test_artifacts
    } catch {|e|
        restore_environment
        error make {msg: $"Test failed: ($e.msg)"}
    }

    restore_environment
}

# Test 3: Measure validation phase duration
def test_validation_phase_duration [] {
    print "\n🧪 Test 3: Validation phase duration (target: < 10 seconds)"

    # Setup environment first
    backup_environment
    cleanup_test_artifacts

    try {
        # Run setup to create environment
        let setup_result = (^nu python/setup.nu --silent | complete)
        assert ($setup_result.exit_code == 0) "Setup failed"

        # Measure validation directly
        let start_time = (date now)
        let result = (^nu -c "use python/lib/validation.nu *; validate_environment '.venv'" | complete)
        let end_time = (date now)
        let duration = ($end_time - $start_time)

        let total_seconds = ($duration | into int) / 1_000_000_000
        let formatted_duration = (format_duration $duration)

        print $"\n⏱️  Validation phase completed in: ($formatted_duration)"

        # Validation should be fast (< 10 seconds)
        if $total_seconds > 10 {
            print $"⚠️  WARNING: Validation exceeded 10-second target (actual: ($formatted_duration))"
        } else {
            print "✅ Validation completed within 10-second target"
        }

        cleanup_test_artifacts
    } catch {|e|
        restore_environment
        error make {msg: $"Test failed: ($e.msg)"}
    }

    restore_environment
}

# Test 4: Measure OS detection performance
def test_os_detection_performance [] {
    print "\n🧪 Test 4: OS detection performance (target: < 1 second)"

    let iterations = 10

    print $"  Running OS detection ($iterations) times..."

    let start_time = (date now)

    for i in 1..$iterations {
        let result = (^nu -c "use common/lib/os_detection.nu *; detect_os" | complete)
        assert ($result.exit_code == 0) $"OS detection failed on iteration ($i)"
    }

    let end_time = (date now)
    let total_duration = ($end_time - $start_time)
    let total_seconds = ($total_duration | into int) / 1_000_000_000
    let avg_seconds = ($total_seconds / $iterations)

    let formatted_duration = (format_duration $total_duration)

    print $"\n⏱️  ($iterations) OS detections completed in: ($formatted_duration)"
    print $"  Average per call: ($avg_seconds)s"

    if $avg_seconds > 1 {
        print "⚠️  WARNING: OS detection slower than expected (> 1s average)"
    } else {
        print "✅ OS detection is fast (< 1s per call)"
    }
}

# Test 5: Measure prerequisites check performance
def test_prerequisites_check_performance [] {
    print "\n🧪 Test 5: Prerequisites check performance (target: < 2 seconds)"

    let iterations = 5

    print $"  Running prerequisites check ($iterations) times..."

    let start_time = (date now)

    for i in 1..$iterations {
        let result = (^nu -c "use python/lib/prerequisites.nu *; check_prerequisites" | complete)
        assert ($result.exit_code == 0) $"Prerequisites check failed on iteration ($i)"
    }

    let end_time = (date now)
    let total_duration = ($end_time - $start_time)
    let total_seconds = ($total_duration | into int) / 1_000_000_000
    let avg_seconds = ($total_seconds / $iterations)

    let formatted_duration = (format_duration $total_duration)

    print $"\n⏱️  ($iterations) prerequisites checks completed in: ($formatted_duration)"
    print $"  Average per call: ($avg_seconds)s"

    if $avg_seconds > 2 {
        print "⚠️  WARNING: Prerequisites check slower than expected (> 2s average)"
    } else {
        print "✅ Prerequisites check is fast (< 2s per call)"
    }
}

# Main test runner
def main [
    --quick (-q)  # Skip full setup test (faster)
] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║        Integration Tests: Performance Benchmarks        ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    # Setup dummy files if needed
    let pyproject_state = (setup_dummy_pyproject)
    let start_time = (date now)

    # Run tests sequentially
    let test_results = if $quick {
        # Quick mode: skip full setup test
        [
            (try { test_idempotent_rerun_duration; {name: "Idempotent re-run duration", passed: true} } catch {|e| {name: "Idempotent re-run duration", passed: false, error: $e.msg}})
            (try { test_validation_phase_duration; {name: "Validation phase duration", passed: true} } catch {|e| {name: "Validation phase duration", passed: false, error: $e.msg}})
            (try { test_os_detection_performance; {name: "OS detection performance", passed: true} } catch {|e| {name: "OS detection performance", passed: false, error: $e.msg}})
            (try { test_prerequisites_check_performance; {name: "Prerequisites check performance", passed: true} } catch {|e| {name: "Prerequisites check performance", passed: false, error: $e.msg}})
        ]
    } else {
        # Full mode: run all tests
        [
            (try { test_first_time_setup_duration; {name: "First-time setup duration", passed: true} } catch {|e| {name: "First-time setup duration", passed: false, error: $e.msg}})
            (try { test_idempotent_rerun_duration; {name: "Idempotent re-run duration", passed: true} } catch {|e| {name: "Idempotent re-run duration", passed: false, error: $e.msg}})
            (try { test_validation_phase_duration; {name: "Validation phase duration", passed: true} } catch {|e| {name: "Validation phase duration", passed: false, error: $e.msg}})
            (try { test_os_detection_performance; {name: "OS detection performance", passed: true} } catch {|e| {name: "OS detection performance", passed: false, error: $e.msg}})
            (try { test_prerequisites_check_performance; {name: "Prerequisites check performance", passed: true} } catch {|e| {name: "Prerequisites check performance", passed: false, error: $e.msg}})
        ]
    }

    # Print failures
    for result in $test_results {
        if not $result.passed {
            print $"❌ Test '($result.name)' failed: ($result.error)"
        }
    }

    # Calculate stats
    let passed = ($test_results | where passed == true | length)
    let failed = ($test_results | where passed == false | length)

    # Calculate total duration
    let end_time = (date now)
    let total_duration = ($end_time - $start_time)
    let formatted_duration = (format_duration $total_duration)

    # Display results
    print "\n╔═══════════════════════════════════════════════════════════╗"

    if $failed == 0 {
        print "║        ✅ All Performance Benchmarks Passed!            ║"
    } else {
        print "║        ⚠️  Some Performance Benchmarks Failed           ║"
    }

    print "╚═══════════════════════════════════════════════════════════╝\n"

    print $"📊 Results: ($passed) passed, ($failed) failed"
    print $"⏱️  Total benchmark time: ($formatted_duration)\n"

    if $quick {
        print "ℹ️  Ran in quick mode (skipped full setup test)"
        print "   Run without --quick flag to test full setup duration\n"
    }

    # Cleanup dummy files if we created them
    cleanup_dummy_pyproject $pyproject_state
    # Exit with appropriate code
    if $failed > 0 {
        exit 1
    }
}
