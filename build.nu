#!/usr/bin/env nu

# Build standalone setup script by merging main script with required modules
#
# Usage:
#   nu build.nu python --yes    # Build Python setup script
#   nu build.nu go --yes        # Build Go setup script
#   nu build.nu java --yes      # Build Java setup script
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

# Discover template files in templates directory
# Args:
#   base_dir: string - Base directory (python, go, or java)
# Returns: list<record {name: string, content: string}> - List of template files
def discover_templates [base_dir: string] {
    let templates_dir = ($base_dir | path join "templates")

    if not ($templates_dir | path exists) {
        return []
    }

    glob ($templates_dir | path join "*.template")
        | each { |file|
            let name = ($file | path basename)
            let content = (open $file --raw)
            {name: $name, content: $content}
        }
}

# Discover all required modules by traversing use statements
# Args:
#   main_script: string - Path to main script
#   lib_dir: string - Directory containing modules
#   common_lib_dir: string - Directory containing common modules
# Returns: record {modules: list<string>, common_modules: list<string>}
def discover_required_modules [main_script: string, lib_dir: string, common_lib_dir: string] {
    mut required = []
    mut common_required = []
    mut to_process = (parse_use_statements $main_script)

    # Traverse dependency tree
    while ($to_process | length) > 0 {
        let current = ($to_process | first)
        $to_process = ($to_process | skip 1)

        # Skip if already processed
        if ($current in $required) or ($current in $common_required) {
            continue
        }

        # Check if module is in common/lib first
        let common_module_path = ($common_lib_dir | path join $"($current).nu")
        let common_base_path = ($"common/($current).nu")
        let lib_module_path = ($lib_dir | path join $"($current).nu")

        if ($common_module_path | path exists) {
            # Module is in common/lib
            $common_required = ($common_required | append $current)
            let deps = (parse_use_statements $common_module_path)
            $to_process = ($to_process | append $deps | uniq)
        } else if ($common_base_path | path exists) {
            # Module is in common/ (e.g., setup_base.nu)
            $common_required = ($common_required | append $current)
            let deps = (parse_use_statements $common_base_path)
            $to_process = ($to_process | append $deps | uniq)
        } else if ($lib_module_path | path exists) {
            # Module is in base_dir/lib
            $required = ($required | append $current)
            let deps = (parse_use_statements $lib_module_path)
            $to_process = ($to_process | append $deps | uniq)
        }
    }

    return {
        modules: ($required | sort),
        common_modules: ($common_required | sort)
    }
}

# Create embedded templates module from template files
# Args:
#   templates: list<record {name: string, content: string}> - Template files
# Returns: string - Module definition with embedded templates
def create_templates_module [templates: list] {
    if ($templates | is-empty) {
        return ""
    }

    # Create constant definitions for each template
    let template_defs = $templates | each { |tmpl|
        let const_name = (template_filename_to_constant $tmpl.name)
        # Escape the content for nushell strings (escape backslashes and quotes)
        let escaped = ($tmpl.content | str replace -a '\' '\\' | str replace -a '"' '\"')
        $"export const ($const_name) = \"($escaped)\""
    } | str join "\n\n"

    return $"module templates {\n($template_defs)\n}\n"
}

# Transform use statements in content to use inline module names
# Args:
#   content: string - File content to transform
# Returns: string - Transformed content
def transform_use_statements [content: string] {
    $content
        | lines
        | where not ($it | str starts-with "#!")
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

# Convert template filename to constant name
# Args:
#   template_filename: string - Template filename (e.g., "settings.xml.template")
# Returns: string - Constant name (e.g., "SETTINGS_XML_TEMPLATE")
def template_filename_to_constant [template_filename: string] {
    let base = ($template_filename | str replace ".template" "" | str replace "." "_" | str upcase)
    $"($base)_TEMPLATE"
}

# Transform config_files module to use embedded templates
# Args:
#   content: string - Original config_files module content
# Returns: string - Transformed content that uses embedded templates
def transform_config_files_for_standalone [content: string] {
    let result = (
        $content
        | lines
        | reduce -f {lines: [], skip: false, next_template: null, added_import: false} { |line, acc|
            # Add 'use templates *' after the first 'use' statement
            if (not $acc.added_import) and ($line =~ '^use ') {
                {lines: ($acc.lines | append $line | append "use templates *"), skip: $acc.skip, next_template: $acc.next_template, added_import: true}
            } else if $line =~ '# Get the templates directory path' {
                # Skip the get_templates_dir function entirely
                {lines: $acc.lines, skip: true, next_template: $acc.next_template, added_import: $acc.added_import}
            } else if $acc.skip {
                if $line =~ '^}$' {
                    {lines: $acc.lines, skip: false, next_template: $acc.next_template, added_import: $acc.added_import}
                } else {
                    {lines: $acc.lines, skip: true, next_template: $acc.next_template, added_import: $acc.added_import}
                }
            } else if $line =~ 'let template_path = \(get_templates_dir \| path join "(.+\.template)"\)' {
                # Extract template filename and convert to constant name
                # Match pattern: (get_templates_dir | path join "filename.template")
                let matches = ($line | parse -r 'let template_path = \(get_templates_dir \| path join "(?P<filename>.+\.template)"\)')
                if ($matches | length) > 0 {
                    let template_file = ($matches | first | get filename)
                    let const_name = (template_filename_to_constant $template_file)
                    # Store for next line and skip this line
                    {lines: $acc.lines, skip: $acc.skip, next_template: $const_name, added_import: $acc.added_import}
                } else {
                    {lines: ($acc.lines | append $line), skip: $acc.skip, next_template: $acc.next_template, added_import: $acc.added_import}
                }
            } else if $line =~ 'let template = \(open \$template_path --raw\)' and ($acc.next_template != null) {
                # Replace with embedded template constant
                let indent = ($line | str replace -r '^(\s*).*' '$1')
                let new_line = $"($indent)let template = \$($acc.next_template)"
                {lines: ($acc.lines | append $new_line), skip: $acc.skip, next_template: null, added_import: $acc.added_import}
            } else {
                {lines: ($acc.lines | append $line), skip: $acc.skip, next_template: $acc.next_template, added_import: $acc.added_import}
            }
        }
    )

    $result.lines | str join "\n"
}

# Main entry point
def main [
    base_dir: string = "python"  # Base directory (python, go, or java)
    --yes (-y)                    # Auto-confirm build
] {
    # Validate base_dir
    if $base_dir not-in ["python", "go", "java"] {
        print $"❌ Error: base_dir must be 'python', 'go', or 'java', got '($base_dir)'"
        exit 1
    }

    let main_script = ($base_dir | path join "setup.nu")
    let lib_dir = ($base_dir | path join "lib")
    let common_lib_dir = "common/lib"
    let output_file = ($"dist/setup-($base_dir).nu")

    # Verify directories exist
    if not ($main_script | path exists) {
        print $"❌ Error: Main script not found: ($main_script)"
        exit 1
    }

    if not ($lib_dir | path exists) {
        print $"❌ Error: Lib directory not found: ($lib_dir)"
        exit 1
    }

    if not ($common_lib_dir | path exists) {
        print $"❌ Error: Common lib directory not found: ($common_lib_dir)"
        exit 1
    }

    print $"🔍 Analyzing module dependencies for ($base_dir)...\n"

    # Discover required modules
    let discovered = (discover_required_modules $main_script $lib_dir $common_lib_dir)
    let required_modules = $discovered.modules
    let common_modules = $discovered.common_modules

    # Discover template files
    let templates = (discover_templates $base_dir)

    # Display analysis
    print $"📦 Found ($required_modules | length) base modules + ($common_modules | length) common modules:"
    for module in $required_modules {
        let path = ($lib_dir | path join $"($module).nu")
        let size = (ls $path | get size | first)
        print $"  • ($module) \(($size) bytes\) [base]"
    }
    for module in $common_modules {
        # Check both common/lib and common/ for the module
        let lib_path = ($common_lib_dir | path join $"($module).nu")
        let base_path = ($"common/($module).nu")
        let path = if ($lib_path | path exists) {
            $lib_path
        } else {
            $base_path
        }
        let size = (ls $path | get size | first)
        print $"  • ($module) \(($size) bytes\) [common]"
    }

    if ($templates | length) > 0 {
        print $"\n📄 Found ($templates | length) template files:"
        for tmpl in $templates {
            let size = ($tmpl.content | str length)
            print $"  • ($tmpl.name) \(($size) bytes\)"
        }
    }
    print ""

    # Find unused modules
    let all_modules = (glob ($lib_dir | path join "*.nu") | each { |f| $f | path basename | str replace '.nu' '' })
    let unused = ($all_modules | where $it not-in $required_modules)

    if ($unused | length) > 0 {
        print $"ℹ️  Skipping ($unused | length) unused base modules:"
        for module in $unused {
            print $"  • ($module)"
        }
        print ""
    }

    # Display build plan
    print "📋 Build plan:"
    print $"  Main script: ($main_script)"
    print $"  Base modules: ($required_modules | str join ', ')"
    print $"  Common modules: ($common_modules | str join ', ')"
    print $"  Output: ($output_file)"
    print ""

    if $yes {
        print "✓ Auto-confirming build (--yes flag)\n"
    } else {
        print "ℹ️  Add --yes flag to auto-confirm build\n"
    }

    print "🔨 Building standalone script...\n"

    # Create templates module if templates exist
    let templates_module = if ($templates | length) > 0 {
        let template_count = ($templates | length)
        print $"  Processing templates module \(($template_count) templates\)"
        create_templates_module $templates
    } else {
        ""
    }

    # Separate setup_base from other common modules
    let setup_base_content = if "setup_base" in $common_modules {
        let base_path = "common/setup_base.nu"
        print $"  Processing setup_base as top-level code"
        let raw_content = open $base_path
        transform_use_statements $raw_content
    } else {
        ""
    }

    # Build common module definitions first (excluding setup_base)
    let common_module_defs = $common_modules | where $it != "setup_base" | each { |name|
        # Check both common/lib and common/ for the module
        let lib_path = ($common_lib_dir | path join $"($name).nu")
        let base_path = ($"common/($name).nu")
        let path = if ($lib_path | path exists) {
            $lib_path
        } else {
            $base_path
        }
        print $"  Processing common module: ($name)"

        let raw_content = open $path
        let content = transform_use_statements $raw_content
        $"module ($name) {\n($content)\n}\n"
    } | str join "\n"

    # Build base module definitions
    let base_module_defs = $required_modules | each { |name|
        let path = ($lib_dir | path join $"($name).nu")
        print $"  Processing base module: ($name)"

        let raw_content = open $path
        # Apply special transformation for config_files module if it uses templates
        let content = if $name == "config_files" and ($templates | length) > 0 {
            let transformed = transform_use_statements $raw_content
            transform_config_files_for_standalone $transformed
        } else {
            transform_use_statements $raw_content
        }
        $"module ($name) {\n($content)\n}\n"
    } | str join "\n"

    # Combine all modules (templates first if exists, then common without setup_base, then base)
    let all_modules = if ($templates | length) > 0 {
        ["templates"] | append ($common_modules | where $it != "setup_base") | append $required_modules
    } else {
        ($common_modules | where $it != "setup_base") | append $required_modules
    }

    # Generate use statements for all modules (excluding setup_base which is inlined)
    let use_statements = $all_modules
        | each { |name| $"use ($name) *" }
        | str join "\n"

    # Read and transform main script
    print $"  Processing main script: ($main_script)"
    let main = open $main_script
        | lines
        | where not ($it | str starts-with "use ")
        | where not ($it | str starts-with "#!")
        | str join "\n"

    # Combine all parts (templates module first if exists, then common modules, then base modules, then use statements, then setup_base content, then main)
    let standalone = if ($templates | length) > 0 {
        $"#!/usr/bin/env nu\n\n($templates_module)\n($common_module_defs)\n($base_module_defs)\n($use_statements)\n\n($setup_base_content)\n\n($main)"
    } else {
        $"#!/usr/bin/env nu\n\n($common_module_defs)\n($base_module_defs)\n($use_statements)\n\n($setup_base_content)\n\n($main)"
    }

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
