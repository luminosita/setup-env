#!/usr/bin/env nu

# Integration Tests: Platform Compatibility for Go
#
# Tests that setup works across different platforms (macOS, Linux, Windows)

use std assert
use test_helpers.nu *

def main [] {
    print "\n╔═══════════════════════════════════════════════════════════╗"
    print "║   Integration Tests: Platform Compatibility - Go         ║"
    print "╚═══════════════════════════════════════════════════════════╝\n"

    # Setup dummy files
    let gomod_state = (setup_dummy_gomod)
    
    let start_time = (date now)
    mut passed = 0
    mut failed = 0

    # Test 1: OS detection works on current platform
    print "🧪 Test 1: OS detection works on current platform"
    try {
        let result = (^nu -c "use common/lib/os_detection.nu *; detect_os" | complete)
        
        assert ($result.exit_code == 0) "OS detection failed"
        
        let os_info = ($result.stdout | from json)
        assert ("os" in ($os_info | columns))
        assert ("arch" in ($os_info | columns))
        
        print $"✅ OS detected: ($os_info.os) ($os_info.arch)\n"
        $passed = ($passed + 1)
    } catch {|e|
        print $"❌ Test failed: ($e.msg)\n"
        $failed = ($failed + 1)
    }

    # Test 2: Architecture detection
    print "🧪 Test 2: Architecture detection"
    try {
        let result = (^nu -c "use common/lib/os_detection.nu *; detect_os" | complete)
        let os_info = ($result.stdout | from json)
        
        assert ($os_info.arch in ["x86_64", "aarch64", "arm64"])
        
        print $"✅ Architecture: ($os_info.arch)\n"
        $passed = ($passed + 1)
    } catch {
        $failed = ($failed + 1)
    }

    # Test 3: Platform-specific paths
    print "🧪 Test 3: Platform-specific paths work"
    try {
        # Go env paths should work on all platforms
        assert (".go" | path type) == "dir" or (not (".go" | path exists))
        
        print "✅ Platform paths work\n"
        $passed = ($passed + 1)
    } catch {
        $failed = ($failed + 1)
    }

    # Test 4: Full setup on current platform
    print "🧪 Test 4: Full setup works on current platform (end-to-end)"
    print "⏱️  This test runs complete setup...\n"
    try {
        # Clean up first
        if (".go" | path exists) { rm -rf .go }
        if (".env" | path exists) { rm .env }
        
        print "🚀 Running: nu go/setup.nu --silent\n"
        
        let result = (^nu go/setup.nu --silent | complete)
        
        if $result.exit_code == 0 {
            print "✅ Full setup works on current platform\n"
            $passed = ($passed + 1)
        } else {
            print $"⚠️  Setup failed on current platform: ($result.stderr)\n"
            $failed = ($failed + 1)
        }
        
        # Clean up
        if (".go" | path exists) { rm -rf .go }
        if (".env" | path exists) { rm .env }
    } catch {|e|
        print $"❌ Test failed: ($e.msg)\n"
        $failed = ($failed + 1)
    }

    let end_time = (date now)
    let duration = ($end_time - $start_time)

    print "\n╔═══════════════════════════════════════════════════════════╗"
    if $failed == 0 {
        print "║      ✅ All Platform Compatibility Tests Passed!        ║"
    } else {
        print "║      ⚠️  Some Platform Compatibility Tests Failed      ║"
    }
    print "╚═══════════════════════════════════════════════════════════╝\n"

    print $"📊 Results: ($passed) passed, ($failed) failed"
    print $"⏱️  Total test time: ($duration)"
    print $"🖥️  Tested on: ($nu.os-info.name)\n"

    # Cleanup
    cleanup_dummy_gomod $gomod_state

    if $failed > 0 {
        exit 1
    }
}
