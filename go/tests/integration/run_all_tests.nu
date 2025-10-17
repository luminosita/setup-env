#!/usr/bin/env nu

# Integration Test Suite Runner for Go
#
# Runs all integration test suites and provides a comprehensive report

def main [] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║         Integration Tests - Go                            ║"
    print "║                 Full Test Suite Runner                    ║"
    print "╚═══════════════════════════════════════════════════════════╝"

    print $"\n🖥️  Platform: ($nu.os-info.name) ($nu.os-info.arch)\n"

    let suite_start = (date now)

    # Test suites to run
    let test_suites = [
        {name: "Setup Flow (End-to-End)", file: "go/tests/integration/test_setup_flow.nu"}
        {name: "Error Scenarios", file: "go/tests/integration/test_error_scenarios.nu"}
        {name: "Silent Mode (CI/CD)", file: "go/tests/integration/test_silent_mode.nu"}
        {name: "Performance Benchmarks", file: "go/tests/integration/test_performance.nu"}
        {name: "Platform Compatibility", file: "go/tests/integration/test_platform_compat.nu"}
    ]

    mut results = []

    print $"Running ($test_suites | length) test suites..."
    print ""

    for suite in $test_suites {
        print ""
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print $"🧪 Running Test Suite: ($suite.name)"
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print ""

        let test_start = (date now)
        let result = (^nu $suite.file | complete)
        let test_end = (date now)
        let duration = ($test_end - $test_start)

        $results = ($results | append {
            name: $suite.name,
            exit_code: $result.exit_code,
            duration: $duration,
            stdout: $result.stdout,
            stderr: $result.stderr
        })
    }

    let suite_end = (date now)
    let total_duration = ($suite_end - $suite_start)

    # Display results summary
    print ""
    print "╔═══════════════════════════════════════════════════════════╗"
    print "║           Integration Test Suite Results                ║"
    print "╚═══════════════════════════════════════════════════════════╝"
    print ""

    mut all_passed = true

    for result in $results {
        let status = if $result.exit_code == 0 { "✅" } else { "❌" }
        let duration_sec = ($result.duration | into int) / 1_000_000_000

        print $"($status) ($result.name)"
        print $"    Duration: ($duration_sec)s"

        if $result.exit_code != 0 {
            $all_passed = false
            print $"    Exit code: ($result.exit_code)"

            # Show last 20 lines of output for failed tests
            let output_lines = ($result.stdout | lines)
            let last_lines = if ($output_lines | length) > 20 {
                $output_lines | last 20
            } else {
                $output_lines
            }

            print "    Test output (last 20 lines):"
            for line in $last_lines {
                print $"      ($line)"
            }
        }
        print ""
    }

    let passed_count = ($results | where exit_code == 0 | length)
    let failed_count = ($results | where exit_code != 0 | length)
    let total_duration_sec = ($total_duration | into int) / 1_000_000_000

    print $"📊 Summary: ($passed_count)/($results | length) test suites passed"
    if $failed_count > 0 {
        print $"⚠️  ($failed_count) test suites failed"
    }

    print ""
    print $"⏱️  Total test suite time: ($total_duration_sec)s"
    print ""

    if $all_passed {
        print "✅ All integration test suites passed!"
        exit 0
    } else {
        print "❌ Test suite failed - see errors above"
        exit 1
    }
}
