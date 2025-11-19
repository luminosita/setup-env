#!/usr/bin/env nu

# Integration Test Runner for Java Setup Scripts
#
# This script runs all integration tests for the Java setup system
#
# Usage:
#   ./run_all_tests.nu              # Run all tests
#   ./run_all_tests.nu --quick      # Skip performance tests

def main [
    --quick (-q)  # Skip performance tests
] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║   Java Setup Scripts - Integration Tests                  ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    if $quick {
        print "🏃 Running in quick mode (skipping performance tests)\n"
    }

    mut results = []

    # Test 1: Prerequisites check integration
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Test 1: Prerequisites Check Integration"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    print "Verifying all prerequisites can be checked..."

    let test1 = (try {
        use ../../lib/prerequisites.nu check_prerequisites
        let result = (check_prerequisites)

        if "errors" in $result {
            print "✅ Prerequisites check completed"
            "passed"
        } else {
            print "❌ Prerequisites check returned invalid structure"
            "failed"
        }
    } catch {|e|
        print $"❌ Prerequisites check failed: ($e.msg)"
        "failed"
    })
    $results = ($results | append $test1)

    print ""

    # Test 2: Virtual environment setup integration
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Test 2: Virtual Environment Setup Integration"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    print "Verifying venv setup module can be loaded..."

    let test2 = (try {
        use ../../lib/venv_setup.nu create_venv
        print "✅ Venv setup module loaded successfully"
        "passed"
    } catch {|e|
        print $"❌ Venv setup module failed to load: ($e.msg)"
        "failed"
    })
    $results = ($results | append $test2)

    print ""

    # Test 3: Dependencies installation integration
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Test 3: Dependencies Installation Integration"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    print "Verifying deps installation module can be loaded..."

    let test3 = (try {
        use ../../lib/deps_install.nu install_dependencies
        print "✅ Deps installation module loaded successfully"
        "passed"
    } catch {|e|
        print $"❌ Deps installation module failed to load: ($e.msg)"
        "failed"
    })
    $results = ($results | append $test3)

    print ""

    # Test 4: Validation integration
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Test 4: Validation Integration"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    print "Verifying validation module can be loaded..."

    let test4 = (try {
        use ../../lib/validation.nu validate_environment
        print "✅ Validation module loaded successfully"
        "passed"
    } catch {|e|
        print $"❌ Validation module failed to load: ($e.msg)"
        "failed"
    })
    $results = ($results | append $test4)

    print ""

    # Summary
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Test Summary"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    let passed = ($results | where $it == "passed" | length)
    let failed = ($results | where $it == "failed" | length)
    let skipped = ($results | where $it == "skipped" | length)
    let total = ($results | length)

    print $"Total tests: ($total)"
    print $"✅ Passed: ($passed)"
    if $failed > 0 {
        print $"❌ Failed: ($failed)"
    }
    if $skipped > 0 {
        print $"⏭️  Skipped: ($skipped)"
    }

    print ""

    if $failed > 0 {
        print "❌ Some tests failed"
        exit 1
    } else {
        print "✅ All integration tests passed!"
        exit 0
    }
}
