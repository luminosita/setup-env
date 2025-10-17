# Template Configuration Module
#
# This module handles replacing placeholder values in project files and renaming folders
# to customize the project based on user input.
#
# Public Functions:
# - replace_placeholders: Replace CHANGE_ME, change-me, change_me in all project files
# - rename_src_folder: Rename src/change_me to src/{app_path_name}

use common.nu *

# Get list of files to process (excludes .git, .venv, node_modules, etc.)
def get_files_to_process [] {
    glob **/*
    | where ($it | path type) == "file"
    | where {|file|
        not (
            ($file | str contains ".git/") or
            ($file | str contains ".venv") or
            ($file | str contains "node_modules/") or
            ($file | str contains "__pycache__/") or
            ($file | str contains ".pyc") or
            ($file | str contains "dist/") or
            ($file | str contains "build/") or
            ($file | str ends-with ".lock")
        )
    }
}

# Replace placeholders in a single file
# Args:
#   file_path: string - Path to file
#   replacements: record - {CHANGE_ME: app_name, change-me: code_name, change_me: path_name}
# Returns: record {success: bool, modified: bool, error: string}
def replace_in_file [
    file_path: string
    replacements: record
] {
    try {
        # Read file content as raw text
        let content = (open --raw $file_path | decode utf-8)

        # Check if file contains any placeholders
        let has_change_me = ($content | str contains "CHANGE_ME")
        let has_change_dash = ($content | str contains "change-me")
        let has_change_underscore = ($content | str contains "change_me")

        if not ($has_change_me or $has_change_dash or $has_change_underscore) {
            return {success: true, modified: false, error: ""}
        }

        # Replace placeholders
        mut new_content = $content
        $new_content = ($new_content | str replace -a "CHANGE_ME" $replacements.CHANGE_ME)
        $new_content = ($new_content | str replace -a "change-me" $replacements."change-me")
        $new_content = ($new_content | str replace -a "change_me" $replacements.change_me)

        # Write back to file
        $new_content | save -f $file_path

        return {success: true, modified: true, error: ""}
    } catch {|err|
        return {success: false, modified: false, error: $"($err.msg)"}
    }
}

# Replace all placeholders in project files
# Args:
#   app_config: record - {app_name, app_code_name, app_path_name}
# Returns: record {success: bool, files_modified: int, errors: list}
export def replace_placeholders [app_config: record] {
    print "\n🔄 Replacing placeholders in project files..."

    let replacements = {
        CHANGE_ME: $app_config.app_name,
        "change-me": $app_config.app_code_name,
        change_me: $app_config.app_path_name
    }

    let files = (get_files_to_process)
    let total_files = ($files | length)

    print $"  Found ($total_files) files to process"

    mut files_modified = 0
    mut errors = []

    for file in $files {
        let result = (replace_in_file $file $replacements)

        if $result.success {
            if $result.modified {
                $files_modified = $files_modified + 1
            }
        } else {
            $errors = ($errors | append {file: $file, error: $result.error})
            print $"  ⚠️  Error processing ($file): ($result.error)"
        }
    }

    let error_count = ($errors | length)

    if $error_count == 0 {
        print $"✅ Successfully processed ($total_files) files \(($files_modified) modified\)\n"
        return {
            success: true,
            files_processed: $total_files,
            files_modified: $files_modified,
            errors: []
        }
    } else {
        print $"⚠️  Processed ($total_files) files with ($error_count) errors\n"
        return {
            success: false,
            files_processed: $total_files,
            files_modified: $files_modified,
            errors: $errors
        }
    }
}

# Rename src/change_me folder to src/{app_path_name}
# Args:
#   app_path_name: string - New folder name
# Returns: record {success: bool, renamed: bool, error: string}
export def rename_src_folder [app_path_name: string] {
    print "\n📁 Renaming source folder..."

    let old_path = "src/change_me"
    let new_path = $"src/($app_path_name)"

    # Check if old path exists
    if not ($old_path | path exists) {
        print $"  ℹ️  Source folder ($old_path) does not exist (may already be renamed)\n"
        return {success: true, renamed: false, error: ""}
    }

    # Check if new path already exists
    if ($new_path | path exists) {
        let error_msg = $"Target folder ($new_path) already exists"
        print $"  ❌ ($error_msg)\n"
        return {success: false, renamed: false, error: $error_msg}
    }

    try {
        # Rename folder
        mv $old_path $new_path
        print $"✅ Renamed ($old_path) → ($new_path)\n"
        return {success: true, renamed: true, error: ""}
    } catch {|err|
        let error_msg = $"Failed to rename folder: ($err.msg)"
        print $"  ❌ ($error_msg)\n"
        return {success: false, renamed: false, error: $error_msg}
    }
}

# Apply full template configuration
# Args:
#   app_config: record - {app_name, app_code_name, app_path_name}
# Returns: record {success: bool, details: record}
export def apply_template_configuration [app_config: record] {
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Template Configuration"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    print $"📝 Configuration:"
    print $"  Application Name: ($app_config.app_name)"
    print $"  App Code Name: ($app_config.app_code_name)"
    print $"  App Path Name: ($app_config.app_path_name)\n"

    # Replace placeholders in files
    let replace_result = (replace_placeholders $app_config)

    # Rename source folder
    let rename_result = (rename_src_folder $app_config.app_path_name)

    let success = $replace_result.success and $rename_result.success

    if $success {
        print "✅ Template configuration completed successfully\n"
    } else {
        print "⚠️  Template configuration completed with errors\n"
    }

    return {
        success: $success,
        replace_result: $replace_result,
        rename_result: $rename_result
    }
}
