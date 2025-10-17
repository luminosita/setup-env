#!/usr/bin/env nu

# Integration Tests: Performance Benchmarks for Go
#
# Tests that setup completes within acceptable time limits

use std assert
use test_helpers.nu *

def main [] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║     Integration Tests: Performance Benchmarks - Go       ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    # Setup dummy files
    let gomod_state = (setup_dummy_gomod)
    
    let start_time = (date now)
    mut passed = 0
    mut failed = 0

    # Test 1: OS detection is fast
    print "🧪 Test 1: OS detection performance (target: < 1 second)"
    try {
        let iterations = 10
        let test_start = (date now)
        
        for i in 1..$iterations {
            ^nu -c "use common/lib/os_detection.nu *; detect_os" | complete | ignore
        }
        
        let test_end = (date now)
        let duration = ($test_end - $test_start)
        let avg = ($duration / $iterations)
        
        print $"  ⏱️  ($iterations) iterations completed in: ($duration)"
        print $"    Average per call: ($avg)"
        
        # Should be very fast (< 1s per call)
        assert (($avg | into int) < 1_000_000_000)
        
        print "✅ OS detection is fast (< 1s per call)\n"
        $passed = ($passed + 1)
    } catch {
        $failed = ($failed + 1)
    }

    # Test 2: Prerequisites check is reasonable
    print "🧪 Test 2: Prerequisites check performance (target: < 2 seconds)"
    try {
        let iterations = 5
        print $"  Running prerequisites check ($iterations) times..."
        
        let test_start = (date now)
        
        for i in 1..$iterations {
            ^nu -c "use go/lib/prerequisites.nu *; check_prerequisites" | complete | ignore
        }
        
        let test_end = (date now)
        let duration_ms = (($test_end - $test_start) | into int) / 1_000_000
        let avg_sec = ($duration_ms / $iterations / 1000)
        
        print $"\n⏱️  ($iterations) prerequisites checks completed in: ($duration_ms)ms"
        print $"  Average per call: ($avg_sec)s"
        
        # Should be reasonably fast
        assert ($avg_sec < 2)
        
        print "✅ Prerequisites check is fast (< 2s per call)\n"
        $passed = ($passed + 1)
    } catch {
        $failed = ($failed + 1)
    }

    let end_time = (date now)
    let duration = ($end_time - $start_time)

    print "\n╔═══════════════════════════════════════════════════════════╗"
    if $failed == 0 {
        print "║        ✅ All Performance Benchmarks Passed!             ║"
    } else {
        print "║        ⚠️  Some Performance Benchmarks Failed           ║"
    }
    print "╚═══════════════════════════════════════════════════════════╝\n"

    print $"📊 Results: ($passed) passed, ($failed) failed"
    print $"⏱️  Total benchmark time: ($duration)\n"

    # Cleanup
    cleanup_dummy_gomod $gomod_state

    if $failed > 0 {
        exit 1
    }
}
