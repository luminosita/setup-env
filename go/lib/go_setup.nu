# Go Modules Setup Module
#
# This module handles Go modules initialization and verification
#
# Public Functions:
# - setup_go_modules: Initialize or verify go.mod exists and is valid

use common.nu *

# Setup Go modules
# Returns: record {success: bool, go_version: string, error: string}
export def setup_go_modules [] {
    print "\n🔧 Setting up Go modules...\n"

    # Check if go.mod exists
    if not ("go.mod" | path exists) {
        return {
            success: false,
            go_version: "",
            error: "go.mod not found. Please initialize with 'go mod init <module-name>'"
        }
    }

    # Verify go.mod is valid by tidying
    let tidy_result = (^go mod tidy | complete)

    if $tidy_result.exit_code != 0 {
        return {
            success: false,
            go_version: "",
            error: $"go mod tidy failed: ($tidy_result.stderr)"
        }
    }

    # Get Go version
    let go_version_result = (^go version | complete)

    if $go_version_result.exit_code != 0 {
        return {
            success: false,
            go_version: "",
            error: "Failed to get Go version"
        }
    }

    let go_version = ($go_version_result.stdout | str trim | parse "go version go{version} {rest}" | get version.0)

    print $"✅ Go modules initialized"

    return {
        success: true,
        go_version: $go_version,
        error: ""
    }
}
