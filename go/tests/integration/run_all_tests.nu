#!/usr/bin/env nu

# Integration Test Runner for Go Setup
#
# Runs all integration tests in sequence
#
# Usage:
#   nu go/tests/integration/run_all_tests.nu

def main [] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║   Go Setup Integration Test Suite                        ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    let start_time = (date now)

    mut tests = []
    mut passed = 0
    mut failed = 0

    # Test 1: Setup Flow
    print "Running test_setup_flow.nu..."
    let test1 = (^nu go/tests/integration/test_setup_flow.nu | complete)
    if $test1.exit_code == 0 {
        $passed = ($passed + 1)
        print "✅ test_setup_flow.nu passed\n"
    } else {
        $failed = ($failed + 1)
        print "❌ test_setup_flow.nu failed\n"
        print $test1.stderr
    }
    $tests = ($tests | append {name: "test_setup_flow.nu", passed: ($test1.exit_code == 0)})

    # Summary
    let end_time = (date now)
    let duration = ($end_time - $start_time)

    print "╔═══════════════════════════════════════════════════════════╗"
    print $"║   Test Results: ($passed) passed, ($failed) failed"
    print "╚═══════════════════════════════════════════════════════════╝"
    print $"\n⏱️  Total time: ($duration)\n"

    if $failed > 0 {
        exit 1
    }
}
