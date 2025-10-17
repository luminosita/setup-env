# Environment Validation Module for Go
#
# This module validates the complete Go development environment setup
#
# Public Functions:
# - validate_environment: Run all validation checks

use ../../common/lib/common.nu *

# Validate the complete development environment
# Args:
#   local_env_path: string - Path to local Go environment (default: .go)
# Returns: record {success: bool, passed: int, failed: int, checks: list}
export def validate_environment [local_env_path: string = ".go"] {
    print "\n🔍 Validating environment...\n"

    mut checks = []
    mut passed = 0
    mut failed = 0

    # Check 1: Go modules
    let go_mod_check = (validate_go_mod)
    $checks = ($checks | append $go_mod_check)
    if $go_mod_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    # Check 2: Local Go workspace
    let go_workspace_check = (validate_go_workspace $local_env_path)
    $checks = ($checks | append $go_workspace_check)
    if $go_workspace_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    # Check 3: .env file
    let env_check = (validate_env_file)
    $checks = ($checks | append $env_check)
    if $env_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    # Check 4: Pre-commit hooks
    let hooks_check = (validate_precommit_hooks)
    $checks = ($checks | append $hooks_check)
    if $hooks_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    # Check 5: Go build
    let build_check = (validate_go_build)
    $checks = ($checks | append $build_check)
    if $build_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    let success = ($failed == 0)

    if $success {
        print $"\n✅ Environment validation passed: ($passed)/($passed) checks"
    } else {
        print $"\n⚠️  Environment validation: ($passed)/($passed + $failed) checks passed, ($failed) failed"
    }

    return {
        success: $success,
        passed: $passed,
        failed: $failed,
        checks: $checks
    }
}

# Validate go.mod exists and is valid
def validate_go_mod [] {
    print "  Checking go.mod..."

    if not ("go.mod" | path exists) {
        print "  ❌ go.mod not found"
        return {name: "go.mod", passed: false, message: "go.mod not found"}
    }

    let verify_result = (^go mod verify | complete)

    if $verify_result.exit_code == 0 {
        print "  ✅ go.mod valid"
        return {name: "go.mod", passed: true, message: "go.mod valid"}
    } else {
        print $"  ❌ go.mod verification failed"
        return {name: "go.mod", passed: false, message: "go mod verify failed"}
    }
}

# Validate local Go workspace exists
# Args:
#   local_env_path: string - Path to local Go environment
def validate_go_workspace [local_env_path: string] {
    print $"  Checking ($local_env_path) workspace..."

    if not ($local_env_path | path exists) {
        print $"  ❌ ($local_env_path) workspace not found"
        return {name: "go-workspace", passed: false, message: $"($local_env_path) workspace not found"}
    }

    # Check required subdirectories
    let pkg_exists = (($local_env_path | path join "pkg") | path exists)
    let cache_exists = (($local_env_path | path join "cache") | path exists)

    if $pkg_exists and $cache_exists {
        print $"  ✅ ($local_env_path) workspace configured"
        return {name: "go-workspace", passed: true, message: $"($local_env_path) workspace configured"}
    } else {
        print $"  ⚠️  ($local_env_path) workspace incomplete"
        return {name: "go-workspace", passed: false, message: $"($local_env_path) workspace missing subdirectories"}
    }
}

# Validate .env file exists
def validate_env_file [] {
    print "  Checking .env file..."

    if (".env" | path exists) {
        print "  ✅ .env file exists"
        return {name: ".env", passed: true, message: ".env file exists"}
    } else {
        print "  ⚠️  .env file not found"
        return {name: ".env", passed: false, message: ".env file not found"}
    }
}

# Validate pre-commit hooks are installed
def validate_precommit_hooks [] {
    print "  Checking pre-commit hooks..."

    if (".git/hooks/pre-commit" | path exists) {
        print "  ✅ Pre-commit hooks installed"
        return {name: "pre-commit", passed: true, message: "Pre-commit hooks installed"}
    } else {
        print "  ⚠️  Pre-commit hooks not installed"
        return {name: "pre-commit", passed: false, message: "Pre-commit hooks not installed"}
    }
}

# Validate Go build works
def validate_go_build [] {
    print "  Checking Go build..."

    let build_result = (^go build -v ./... | complete)

    if $build_result.exit_code == 0 {
        print "  ✅ Go build successful"
        return {name: "go-build", passed: true, message: "Go build successful"}
    } else {
        print $"  ❌ Go build failed"
        return {name: "go-build", passed: false, message: "Go build failed"}
    }
}
