# Dependency Installation Module for Go
#
# This module handles dependency installation using go mod download into local .go folder
#
# Public Functions:
# - install_dependencies: Download all Go module dependencies to local .go folder

use ../../common/lib/common.nu *

# Install dependencies
# Args:
#   venv_path: string - Path to virtual environment (default: .venv)
# Returns: record {success: bool, packages: int, cache_path: string, error: string}
export def install_dependencies [local_env_path: string] {
    print "📦 Installing Go dependencies..."

    # Verify local env exists
    let local_full_path = ($local_env_path | path expand)

    if not ($local_full_path | path exists) {
        return {
            success: false,
            packages: 0,
            duration: 0sec,
            error: $"Local Go environment not found at ($local_env_path). Run create_venv first."
        }
    }

    # Verify go.mod exists
    if not ("go.mod" | path exists) {
        return {
            success: false,
            packages: 0,
            cache_path: "",
            error: "go.mod not found"
        }
    }

    # Set environment variables to use local .go folder
    $env.GOPATH = $local_full_path
    $env.GOMODCACHE = ($local_full_path | path join "pkg" "mod")
    $env.GOCACHE = ($local_full_path | path join "cache")

    print $"📁 Installing to ($env.GOMODCACHE)"

    # Download dependencies
    let download_result = (^go mod download | complete)

    if $download_result.exit_code != 0 {
        return {
            success: false,
            packages: 0,
            cache_path: $env.GOMODCACHE,
            error: $"go mod download failed: ($download_result.stderr)"
        }
    }

    # Verify dependencies
    let verify_result = (^go mod verify | complete)

    if $verify_result.exit_code != 0 {
        print "⚠️  Warning: go mod verify failed, but dependencies were downloaded"
        print $verify_result.stderr
    } else {
        print "✅ All modules verified"
    }

    # Get number of dependencies
    let deps_count = (
        ^go list -m all
        | complete
        | get stdout
        | lines
        | length
    )

    print $"✅ Downloaded ($deps_count) modules to .go/pkg/mod"

    return {
        success: true,
        packages: $deps_count,
        cache_path: $env.GOMODCACHE,
        error: ""
    }
}
