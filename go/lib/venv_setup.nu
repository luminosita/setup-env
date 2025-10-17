# Virtual Environment Setup Module for Go
#
# This module handles Go local environment initialization and verification
#
# Public Functions:
# - create_venv: Initialize or verify go.mod exists and is valid, setup local Go environment folder

use ../../common/lib/common.nu *

# Create/verify Go local environment with modules and dependencies
# Args:
#   local_env_path: string - Path to local Go environment (default: .go)
#   go_version: string - Go version (not used, kept for compatibility)
# Returns: record {success: bool, path: string, main_bin_version: string, error: string}
export def create_venv [local_env_path: string = ".go", go_version: string = ""] {
    print "\n🔧 Setting up Go environment...\n"

    # Check if go.mod exists
    if not ("go.mod" | path exists) {
        return {
            success: false,
            main_bin_version: "",
            path: "",
            error: "go.mod not found. Please initialize with 'go mod init <module-name>'"
        }
    }

    # Create local Go environment folder structure
    let local_path = ($local_env_path | path expand)

    print $"📁 Creating local Go workspace at ($local_env_path)/"

    try {
        mkdir $local_env_path
        mkdir ($local_env_path | path join "pkg")
        mkdir ($local_env_path | path join "cache")

        print $"✅ Local Go workspace created at ($local_path)"
    } catch {|e|
        # Folders may already exist, that's ok
        if ($local_env_path | path exists) {
            print $"ℹ️  Local Go workspace already exists at ($local_path)"
        } else {
            return {
                success: false,
                main_bin_version: "",
                path: "",
                error: $"Failed to create ($local_env_path) directory: ($e.msg)"
            }
        }
    }

    # Set environment variables for local Go workspace
    $env.GOPATH = $local_path
    $env.GOMODCACHE = ($local_path | path join "pkg" "mod")
    $env.GOCACHE = ($local_path | path join "cache")

    print $"✅ GOPATH set to ($local_path)"
    print $"✅ GOMODCACHE set to ($env.GOMODCACHE)"
    print $"✅ GOCACHE set to ($env.GOCACHE)"

    # Verify go.mod is valid by tidying
    print "\n🔍 Verifying go.mod..."
    let tidy_result = (^go mod tidy | complete)

    if $tidy_result.exit_code != 0 {
        return {
            success: false,
            main_bin_version: "",
            path: $local_path,
            error: $"go mod tidy failed: ($tidy_result.stderr)"
        }
    }

    # Get Go version
    let go_version_result = (^go version | complete)

    if $go_version_result.exit_code != 0 {
        return {
            success: false,
            main_bin_version: "",
            path: $local_path,
            error: "Failed to get Go version"
        }
    }

    let go_version = ($go_version_result.stdout | str trim | parse "go version go{version} {rest}" | get version.0)

    print $"\n✅ Go modules initialized \(version ($go_version)\)"

    return {
        success: true,
        path: $local_path,
        main_bin_version: $go_version,
        error: ""
    }
}
