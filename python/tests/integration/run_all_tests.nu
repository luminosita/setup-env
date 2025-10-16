#!/usr/bin/env nu

# Integration Test Suite Runner
#
# Orchestrates all integration tests for the setup script:
# - Full setup flow (end-to-end)
# - Error scenarios
# - Silent mode (CI/CD)
# - Performance benchmarks
# - Platform compatibility
#
# Usage:
#   nu tests/integration/run_all_tests.nu
#   nu tests/integration/run_all_tests.nu --quick       # Skip performance tests
#   nu tests/integration/run_all_tests.nu --suite=flow  # Run specific suite

use std assert

# Format duration in human-readable format
def format_duration [duration: duration] {
    let total_seconds = ($duration | into int) / 1_000_000_000
    let minutes = ($total_seconds / 60 | math floor)
    let seconds = ($total_seconds mod 60 | math floor)

    if $minutes > 0 {
        $"($minutes)m ($seconds)s"
    } else {
        $"($seconds)s"
    }
}

# Run a test suite
def run_test_suite [
    name: string
    script: string
    args: list<string> = []
] {
    print $"\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print $"🧪 Running Test Suite: ($name)"
    print $"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    let start_time = (date now)

    # Build command with args
    let cmd = if ($args | length) > 0 {
        ["nu" $script ...$args]
    } else {
        ["nu" $script]
    }

    # Run test suite
    let result = (do { run-external ...$cmd } | complete)

    let end_time = (date now)
    let duration = ($end_time - $start_time)

    {
        name: $name
        script: $script
        exit_code: $result.exit_code
        passed: ($result.exit_code == 0)
        duration: $duration
        stdout: $result.stdout
        stderr: $result.stderr
    }
}

# Display test suite results
def display_suite_results [results: list<record>] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║           Integration Test Suite Results                ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    let total = ($results | length)
    let passed = ($results | where passed == true | length)
    let failed = ($results | where passed == false | length)

    # Display individual suite results
    for suite in $results {
        let status_icon = if $suite.passed { "✅" } else { "❌" }
        let duration_str = (format_duration $suite.duration)

        print $"($status_icon) ($suite.name)"
        print $"    Duration: ($duration_str)"

        if not $suite.passed {
            print $"    Exit code: ($suite.exit_code)"

            # Show last 20 lines of stdout (test output)
            if ($suite.stdout | str length) > 0 {
                let stdout_lines = ($suite.stdout | lines)
                let line_count = ($stdout_lines | length)
                let show_lines = if $line_count > 20 { 20 } else { $line_count }
                let start_idx = if $line_count > 20 { $line_count - 20 } else { 0 }

                print "    Test output (last 20 lines):"
                for line in ($stdout_lines | skip $start_idx) {
                    print $"      ($line)"
                }
            }

            # Show stderr if present
            if ($suite.stderr | str length) > 0 {
                print $"    Stderr: ($suite.stderr | lines | first 5 | str join '\n           ')"
            }
        }
        print ""
    }

    # Summary
    print $"📊 Summary: ($passed)/($total) test suites passed"

    if $failed > 0 {
        print $"⚠️  ($failed) test suite\(s\) failed"
    }
}

# Main test runner
def main [
    --quick (-q)         # Skip performance tests (faster)
    --suite: string      # Run specific suite only (flow, error, silent, perf, platform)
] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║         AI Agent MCP Server - Integration Tests         ║"
    print "║                 Full Test Suite Runner                  ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    # Detect platform
    let uname_os = (^uname -s | str trim)
    let uname_arch = (^uname -m | str trim)
    print $"🖥️  Platform: ($uname_os) ($uname_arch)"

    if $quick {
        print "⚡ Running in quick mode (performance tests use --quick flag)"
    }

    if $suite != null {
        print $"🎯 Running specific suite: ($suite)"
    }

    print ""

    let overall_start = (date now)
    mut results = []

    # Define test suites
    let suites = [
        {name: "Setup Flow (End-to-End)", script: "python/tests/integration/test_setup_flow.nu", args: [], enabled: true, tag: "flow"}
        {name: "Error Scenarios", script: "python/tests/integration/test_error_scenarios.nu", args: [], enabled: true, tag: "error"}
        {name: "Silent Mode (CI/CD)", script: "python/tests/integration/test_silent_mode.nu", args: [], enabled: true, tag: "silent"}
        {name: "Performance Benchmarks", script: "python/tests/integration/test_performance.nu", args: (if $quick { ["--quick"] } else { [] }), enabled: true, tag: "perf"}
        {name: "Platform Compatibility", script: "python/tests/integration/test_platform_compat.nu", args: [], enabled: true, tag: "platform"}
    ]

    # Filter suites if specific suite requested
    let suites_to_run = if $suite != null {
        $suites | where tag == $suite
    } else {
        $suites | where enabled == true
    }

    # Check if any suites to run
    if ($suites_to_run | length) == 0 {
        print $"❌ No test suites found matching: ($suite)"
        print "\nAvailable suites:"
        print "  - flow       : Setup Flow (End-to-End)"
        print "  - error      : Error Scenarios"
        print "  - silent     : Silent Mode (CI/CD)"
        print "  - perf       : Performance Benchmarks"
        print "  - platform   : Platform Compatibility"
        exit 1
    }

    let suite_count = ($suites_to_run | length)
    print $"Running ($suite_count) test suite\(s\)..."
    print ""

    # Run each test suite
    for suite in $suites_to_run {
        let result = (run_test_suite $suite.name $suite.script $suite.args)
        $results = ($results | append $result)
    }

    # Calculate overall duration
    let overall_end = (date now)
    let overall_duration = ($overall_end - $overall_start)

    # Display results
    display_suite_results $results

    # Overall timing
    let overall_duration_str = (format_duration $overall_duration)
    print $"\n⏱️  Total test suite time: ($overall_duration_str)\n"

    # Exit with appropriate code
    let failed_count = ($results | where passed == false | length)

    if $failed_count > 0 {
        print "❌ Test suite failed - see errors above\n"
        exit 1
    } else {
        print "✅ All integration test suites passed!\n"
        exit 0
    }
}
