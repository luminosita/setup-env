#!/usr/bin/env nu

# Build standalone setup script by merging main script with required modules
#
# Usage:
#   nu python/build.nu --yes    # Build without confirmation
#
# Features:
# - Discovers modules recursively
# - Only includes modules referenced in use statements
# - Converts cross-module references (use common.nu * -> use common *)
# - Shows preview of what will be included

# Parse use statements from a file to extract module names
# Args:
#   file_path: string - Path to file to parse
# Returns: list<string> - List of module names (without .nu extension)
def parse_use_statements [file_path: string] {
    open $file_path
        | lines
        | where ($it | str starts-with "use ")
        | each { |line|
            # Extract module name from "use lib/module.nu *" or "use module.nu *"
            let parts = ($line | str replace "use " "" | split row " ")
            let module_path = ($parts | first)
            $module_path | path basename | str replace '.nu' ''
        }
}

# Discover all required modules by traversing use statements
# Args:
#   main_script: string - Path to main script
#   lib_dir: string - Directory containing modules
# Returns: list<string> - Sorted list of unique module names
def discover_required_modules [main_script: string, lib_dir: string] {
    mut required = []
    mut to_process = (parse_use_statements $main_script)

    # Traverse dependency tree
    while ($to_process | length) > 0 {
        let current = ($to_process | first)
        $to_process = ($to_process | skip 1)

        # Skip if already processed
        if $current in $required {
            continue
        }

        # Add to required list
        $required = ($required | append $current)

        # Check if module file exists and parse its dependencies
        let module_path = ($lib_dir | path join $"($current).nu")
        if ($module_path | path exists) {
            let deps = (parse_use_statements $module_path)
            $to_process = ($to_process | append $deps | uniq)
        }
    }

    $required | sort
}

# Transform use statements in content to use inline module names
# Args:
#   content: string - File content to transform
# Returns: string - Transformed content
def transform_use_statements [content: string] {
    $content
        | lines
        | each { |line|
            if ($line | str starts-with "use ") {
                # Convert "use lib/common.nu *" to "use common *"
                # Convert "use common.nu *" to "use common *"
                let parts = ($line | str replace "use " "" | split row " ")
                let module_path = ($parts | first)
                let module_name = ($module_path | path basename | str replace '.nu' '')
                let rest = ($parts | skip 1 | str join " ")
                $"use ($module_name) ($rest)"
            } else {
                $line
            }
        }
        | str join "\n"
}

# Main entry point
def main [--yes (-y)] {
    let main_script = "python/setup.nu"
    let lib_dir = "python/lib"
    let output_file = "dist/setup.nu"

    print "🔍 Analyzing module dependencies...\n"

    # Discover required modules
    let required_modules = discover_required_modules $main_script $lib_dir

    # Display analysis
    print $"📦 Found ($required_modules | length) required modules:"
    for module in $required_modules {
        let path = ($lib_dir | path join $"($module).nu")
        let size = (ls $path | get size | first)
        print $"  • ($module) \(($size) bytes\)"
    }
    print ""

    # Find unused modules
    let all_modules = (glob ($lib_dir | path join "*.nu") | each { |f| $f | path basename | str replace '.nu' '' })
    let unused = ($all_modules | where $it not-in $required_modules)

    if ($unused | length) > 0 {
        print $"ℹ️  Skipping ($unused | length) unused modules:"
        for module in $unused {
            print $"  • ($module)"
        }
        print ""
    }

    # Display build plan
    print "📋 Build plan:"
    print $"  Main script: ($main_script)"
    print $"  Modules: ($required_modules | str join ', ')"
    print $"  Output: ($output_file)"
    print ""

    if $yes {
        print "✓ Auto-confirming build (--yes flag)\n"
    } else {
        print "ℹ️  Add --yes flag to auto-confirm build\n"
    }

    print "🔨 Building standalone script...\n"

    # Build module definitions
    let modules = $required_modules | each { |name|
        let path = ($lib_dir | path join $"($name).nu")
        print $"  Processing module: ($name)"

        let raw_content = open $path
        let content = transform_use_statements $raw_content
        $"module ($name) {\n($content)\n}\n"
    } | str join "\n"

    # Generate use statements for all modules
    let use_statements = $required_modules
        | each { |name| $"use ($name) *" }
        | str join "\n"

    # Read and transform main script
    print $"  Processing main script: ($main_script)"
    let main = open $main_script
        | lines
        | where not ($it | str starts-with "use ")
        | str join "\n"

    # Combine all parts
    let standalone = $"#!/usr/bin/env nu\n\n($modules)\n($use_statements)\n\n($main)"

    # Ensure output directory exists
    mkdir dist

    # Write output
    $standalone | save -f $output_file
    chmod +x $output_file

    # Display results
    print ""
    let output_size = (ls $output_file | get size | first)
    print $"✅ Built ($output_file) \(($output_size) bytes\)"

    # Verify it works
    print "\n🧪 Testing standalone script..."
    let test_result = (do { nu $output_file --help } | complete)

    if $test_result.exit_code == 0 {
        print "✅ Script validation passed"
    } else {
        print "❌ Script validation failed:"
        print $test_result.stderr
        exit 1
    }
}
