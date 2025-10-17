# Dependency Installation Module for Go
#
# This module handles dependency installation using go mod download
#
# Public Functions:
# - install_dependencies: Download all Go module dependencies

use common.nu *

# Install dependencies using go mod download
# Returns: record {success: bool, packages: int, error: string}
export def install_dependencies [] {
    print "\n📦 Installing Go dependencies...\n"

    # Ensure go.mod exists
    if not ("go.mod" | path exists) {
        return {
            success: false,
            packages: 0,
            error: "go.mod not found"
        }
    }

    # Download dependencies
    let download_result = (^go mod download | complete)

    if $download_result.exit_code != 0 {
        return {
            success: false,
            packages: 0,
            error: $"go mod download failed: ($download_result.stderr)"
        }
    }

    # Get number of dependencies
    let deps_count = (
        ^go list -m all
        | complete
        | get stdout
        | lines
        | length
    )

    print $"✅ Downloaded ($deps_count) modules"

    return {
        success: true,
        packages: $deps_count,
        error: ""
    }
}
