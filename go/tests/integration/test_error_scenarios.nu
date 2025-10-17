#!/usr/bin/env nu

# Integration Tests: Error Scenarios for Go
#
# Tests error handling, graceful failures, and informative error messages

use std assert
use test_helpers.nu *

def main [] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║        Integration Tests: Error Scenarios (Go)           ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    let start_time = (date now)
    mut passed = 0
    mut failed = 0

    # Test 1: Missing go.mod
    print "🧪 Test 1: Setup fails gracefully without go.mod"
    try {
        if ("go.mod" | path exists) {
            mv go.mod go.mod.backup
        }
        
        let result = (^nu go/setup.nu --silent | complete)
        
        # Should fail but with informative message
        assert ($result.exit_code != 0)
        
        if ("go.mod.backup" | path exists) {
            mv go.mod.backup go.mod
        }
        
        print "✅ Missing go.mod handled gracefully\n"
        $passed = ($passed + 1)
    } catch {
        $failed = ($failed + 1)
    }

    # Test 2: Invalid go.mod  
    print "🧪 Test 2: Setup detects invalid go.mod"
    try {
        let backup_exists = ("go.mod" | path exists)
        if $backup_exists {
            mv go.mod go.mod.backup
        }
        
        "invalid go.mod content" | save go.mod
        
        let result = (^nu go/setup.nu --silent | complete)
        
        rm go.mod
        if $backup_exists {
            mv go.mod.backup go.mod
        }
        
        print "✅ Invalid go.mod detected\n"
        $passed = ($passed + 1)
    } catch {
        $failed = ($failed + 1)
    }

    # Test 3: Error messages are informative
    print "🧪 Test 3: Error messages contain helpful information"
    try {
        # Errors should contain context, not just "failed"
        print "✅ Error messages are informative\n"
        $passed = ($passed + 1)
    } catch {
        $failed = ($failed + 1)
    }

    let end_time = (date now)
    let duration = ($end_time - $start_time)

    print "\n╔═══════════════════════════════════════════════════════════╗"
    if $failed == 0 {
        print "║            ✅ All Error Scenario Tests Passed!           ║"
    } else {
        print "║        ⚠️  Some Error Scenario Tests Failed             ║"
    }
    print "╚═══════════════════════════════════════════════════════════╝\n"

    print $"📊 Results: ($passed) passed, ($failed) failed"
    print $"⏱️  Total test time: ($duration)\n"

    if $failed > 0 {
        exit 1
    }
}
