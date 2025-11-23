# Development Tools Installation Module for Go
#
# This module handles installation of Go development tools (linters, generators, debuggers)
# It attempts go install first, then falls back to binary installation if needed.
#
# Public Functions:
# - install_tools: Install all Go development tools to local .go/bin folder

use ../../common/lib/common.nu *

# Install a single tool with automatic fallback from go install to binary
# Args:
#   tool: record - Tool configuration with name, package, binary_name, and optional binary_install command
# Returns: record {success: bool, method: string, error: string}
def install_go_tool [tool: record] {
    # Check if tool already exists (idempotency)
    let bin_path = ($env.GOPATH | path join "bin" $tool.binary_name)
    if ($bin_path | path exists) {
        print $"  ⏭️  ($tool.name) already installed"
        return {
            success: true,
            method: "already installed",
            error: ""
        }
    }

    print $"  📦 Installing ($tool.name)..."

    # Try go install first
    let install_result = (^go install $tool.package | complete)

    if $install_result.exit_code == 0 {
        # Verify binary exists
        let bin_path = ($env.GOPATH | path join "bin" $tool.binary_name)
        if ($bin_path | path exists) {
            print $"    ✅ ($tool.name) installed via go install"
            return {
                success: true,
                method: "go install",
                error: ""
            }
        }
    }

    # If go install failed and binary installation is available, try that
    if "binary_install" in $tool {
        print $"    ⚠️  go install failed, trying binary installation..."

        let binary_cmd = ($tool.binary_install | str replace "{bin_dir}" $env.GOBIN)
        let binary_result = (^sh -c $binary_cmd | complete)

        if $binary_result.exit_code == 0 {
            # Verify binary exists
            let bin_path = ($env.GOPATH | path join "bin" $tool.binary_name)
            if ($bin_path | path exists) {
                print $"    ✅ ($tool.name) installed via binary"
                return {
                    success: true,
                    method: "binary",
                    error: ""
                }
            }
        }

        # Both methods failed
        return {
            success: false,
            method: "both failed",
            error: $"go install: ($install_result.stderr), binary: ($binary_result.stderr)"
        }
    }

    # Only go install available and it failed
    return {
        success: false,
        method: "go install",
        error: $install_result.stderr
    }
}

# Install all development tools
# Args:
#   local_env_path: string - Path to local environment (default: .go)
# Returns: record {success: bool, installed: int, failed: list, error: string}
export def install_tools [local_env_path: string] {
    print "🛠️  Installing Go development tools..."

    # Verify local env exists
    let local_full_path = ($local_env_path | path expand)

    if not ($local_full_path | path exists) {
        return {
            success: false,
            installed: 0,
            failed: [],
            error: $"Local Go environment not found at ($local_env_path). Run create_venv first."
        }
    }

    # Set environment variables to use local .go folder
    $env.GOPATH = $local_full_path
    $env.GOBIN = ($local_full_path | path join "bin")
    $env.GOMODCACHE = ($local_full_path | path join "pkg" "mod")
    $env.GOCACHE = ($local_full_path | path join "cache")
    $env.CGO_ENABLED = "0"

    # Create bin directory if it doesn't exist
    let bin_path = ($local_full_path | path join "bin")
    if not ($bin_path | path exists) {
        mkdir $bin_path
    }

    print $"📁 Installing to ($bin_path)\n"

    # Define tools to install with binary fallback options
    let tools = [
        {
            name: "golangci-lint",
            package: "github.com/golangci/golangci-lint/cmd/golangci-lint@latest",
            binary_name: "golangci-lint",
            binary_install: "curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b {bin_dir} v2.1.0"
        },
        {
            name: "gosec",
            package: "github.com/securego/gosec/v2/cmd/gosec@latest",
            binary_name: "gosec",
            binary_install: "curl -sfL https://raw.githubusercontent.com/securego/gosec/master/install.sh | sh -s -- -b {bin_dir} latest"
        },
        {
            name: "goimports",
            package: "golang.org/x/tools/cmd/goimports@latest",
            binary_name: "goimports"
        },
        {
            name: "gopls",
            package: "golang.org/x/tools/gopls@latest",
            binary_name: "gopls"
        },
        {
            name: "govulncheck",
            package: "golang.org/x/vuln/cmd/govulncheck@latest",
            binary_name: "govulncheck"
        },
        {
            name: "staticcheck",
            package: "honnef.co/go/tools/cmd/staticcheck@latest",
            binary_name: "staticcheck"
        },
        {
            name: "wire",
            package: "github.com/google/wire/cmd/wire@latest",
            binary_name: "wire"
        },
        {
            name: "swag",
            package: "github.com/swaggo/swag/cmd/swag@latest",
            binary_name: "swag"
        },
        {
            name: "mockgen",
            package: "github.com/golang/mock/mockgen@latest",
            binary_name: "mockgen"
        },
        {
            name: "air",
            package: "github.com/air-verse/air@latest",
            binary_name: "air"
        },
        {
            name: "dlv",
            package: "github.com/go-delve/delve/cmd/dlv@latest",
            binary_name: "dlv"
        }
    ]

    mut installed_count = 0
    mut failed_tools = []

    # Install each tool
    for tool in $tools {
        let result = (install_go_tool $tool)

        if $result.success {
            $installed_count = ($installed_count + 1)
        } else {
            print $"    ❌ Failed to install ($tool.name)"
            print $"       Error: ($result.error)"
            $failed_tools = ($failed_tools | append {
                tool: $tool.name,
                error: $result.error
            })
        }
    }

    print ""

    if ($failed_tools | length) == 0 {
        print $"✅ Successfully installed ($installed_count)/($tools | length) tools"
        return {
            success: true,
            installed: $installed_count,
            failed: [],
            error: ""
        }
    } else {
        print $"⚠️  Installed ($installed_count)/($tools | length) tools, ($failed_tools | length) failed"
        return {
            success: false,
            installed: $installed_count,
            failed: $failed_tools,
            error: $"($failed_tools | length) tools failed to install"
        }
    }
}
