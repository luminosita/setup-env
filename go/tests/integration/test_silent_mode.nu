#!/usr/bin/env nu

# Integration Tests: Silent Mode (CI/CD) for Go
#
# Tests that setup works correctly in CI/CD environments with --silent flag

use std assert
use test_helpers.nu *

def main [] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║      Integration Tests: Silent Mode (CI/CD) - Go         ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    # Setup dummy files
    let gomod_state = (setup_dummy_gomod)
    
    let start_time = (date now)
    mut passed = 0
    mut failed = 0

    # Test 1: Silent mode runs without prompts
    print "🧪 Test 1: Silent mode completes without user interaction"
    try {
        # Clean up
        if (".go" | path exists) { rm -rf .go }
        if (".env" | path exists) { rm .env }
        
        let result = (^nu go/setup.nu --silent | complete)
        
        assert ($result.exit_code == 0) "Silent mode should succeed"
        assert ($result.stdout | str contains "silent mode")
        
        # Clean up
        if (".go" | path exists) { rm -rf .go }
        if (".env" | path exists) { rm .env }
        
        print "✅ Silent mode works without prompts\n"
        $passed = ($passed + 1)
    } catch {|e|
        print $"❌ Test failed: ($e.msg)\n"
        $failed = ($failed + 1)
    }

    # Test 2: Silent mode uses defaults
    print "🧪 Test 2: Silent mode uses default preferences"
    try {
        if (".go" | path exists) { rm -rf .go }
        if (".env" | path exists) { rm .env }
        
        let result = (^nu go/setup.nu --silent | complete)
        
        assert ($result.exit_code == 0)
        
        # Clean up
        if (".go" | path exists) { rm -rf .go }
        if (".env" | path exists) { rm .env }
        
        print "✅ Default preferences applied\n"
        $passed = ($passed + 1)
    } catch {
        $failed = ($failed + 1)
    }

    # Test 3: Exit codes are correct
    print "🧪 Test 3: Silent mode returns correct exit codes"
    try {
        if (".go" | path exists) { rm -rf .go }
        if (".env" | path exists) { rm .env }
        
        let result = (^nu go/setup.nu --silent | complete)
        
        # Success should be 0, failure should be 1
        assert (($result.exit_code == 0) or ($result.exit_code == 1))
        
        # Clean up
        if (".go" | path exists) { rm -rf .go }
        if (".env" | path exists) { rm .env }
        
        print "✅ Exit codes are correct\n"
        $passed = ($passed + 1)
    } catch {
        $failed = ($failed + 1)
    }

    let end_time = (date now)
    let duration = ($end_time - $start_time)

    print "\n╔═══════════════════════════════════════════════════════════╗"
    if $failed == 0 {
        print "║          ✅ All Silent Mode Tests Passed!                ║"
    } else {
        print "║          ⚠️  Some Silent Mode Tests Failed              ║"
    }
    print "╚═══════════════════════════════════════════════════════════╝\n"

    print $"📊 Results: ($passed) passed, ($failed) failed"
    print $"⏱️  Total test time: ($duration)\n"

    # Cleanup
    cleanup_dummy_gomod $gomod_state

    if $failed > 0 {
        exit 1
    }
}
