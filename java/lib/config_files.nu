# Configuration Files Module for Java
#
# This module handles generation of Maven and Gradle configuration files
#
# Public Functions:
# - generate_config_files: Generate .m2/settings.xml and gradle/gradle.properties if missing

use ../../common/lib/common.nu *

# Get the templates directory path
def get_templates_dir [] {
    let script_dir = ($env.CURRENT_FILE | path dirname)
    return ($script_dir | path join ".." "templates")
}

# Generate Maven settings.xml content from template
# Args:
#   local_env_path: string - Path to local environment (e.g., ".java")
# Returns: string - XML content for settings.xml
def generate_maven_settings [local_env_path: string] {
    let repo_path = ($local_env_path | path join "m2" "repository" | path expand)
    let template_path = (get_templates_dir | path join "settings.xml.template")

    # Read template and replace placeholder
    let template = (open $template_path --raw)
    return ($template | str replace "{{LOCAL_REPOSITORY_PATH}}" $repo_path)
}

# Generate Gradle properties content from template
# Args:
#   local_env_path: string - Path to local environment (e.g., ".java")
# Returns: string - Content for gradle.properties
def generate_gradle_properties [local_env_path: string] {
    let gradle_home = ($local_env_path | path join "gradle" | path expand)
    let gradle_cache = ($gradle_home | path join "caches")
    let template_path = (get_templates_dir | path join "gradle.properties.template")

    # Read template and replace placeholders
    let template = (open $template_path --raw)
    let content = ($template | str replace "{{GRADLE_CACHE_PATH}}" $gradle_cache)
    return ($content | str replace "{{GRADLE_USER_HOME}}" $gradle_home)
}

# Generate Maven and Gradle config files if they don't exist
# Args:
#   local_env_path: string - Path to local environment (default: .java)
# Returns: record {success: bool, created: list<string>, errors: list<string>}
export def generate_config_files [local_env_path: string = ".java"] {
    # Ensure local environment exists
    if not ($local_env_path | path exists) {
        return {
            success: false,
            created: [],
            errors: [$"Local environment ($local_env_path) does not exist"]
        }
    }

    # Generate .m2/settings.xml
    let m2_dir = ".m2"
    let settings_xml = ($m2_dir | path join "settings.xml")

    let maven_result = if not ($settings_xml | path exists) {
        try {
            # Create .m2 directory if it doesn't exist
            if not ($m2_dir | path exists) {
                mkdir $m2_dir
            }

            let content = (generate_maven_settings $local_env_path)
            $content | save $settings_xml

            print $"✅ Created ($settings_xml)"
            {created: $settings_xml, error: ""}
        } catch {|e|
            print $"❌ Failed to create ($settings_xml): ($e.msg)"
            {created: "", error: $"Failed to create ($settings_xml): ($e.msg)"}
        }
    } else {
        print $"ℹ️  ($settings_xml) already exists"
        {created: "", error: ""}
    }

    # Generate gradle/gradle.properties
    let gradle_dir = "gradle"
    let gradle_properties = ($gradle_dir | path join "gradle.properties")

    let gradle_result = if not ($gradle_properties | path exists) {
        try {
            # Create gradle directory if it doesn't exist
            if not ($gradle_dir | path exists) {
                mkdir $gradle_dir
            }

            let content = (generate_gradle_properties $local_env_path)
            $content | save $gradle_properties

            print $"✅ Created ($gradle_properties)"
            {created: $gradle_properties, error: ""}
        } catch {|e|
            print $"❌ Failed to create ($gradle_properties): ($e.msg)"
            {created: "", error: $"Failed to create ($gradle_properties): ($e.msg)"}
        }
    } else {
        print $"ℹ️  ($gradle_properties) already exists"
        {created: "", error: ""}
    }

    # Collect results
    mut created = []
    mut errors = []

    if ($maven_result.created | is-not-empty) {
        $created = ($created | append $maven_result.created)
    }
    if ($maven_result.error | is-not-empty) {
        $errors = ($errors | append $maven_result.error)
    }

    if ($gradle_result.created | is-not-empty) {
        $created = ($created | append $gradle_result.created)
    }
    if ($gradle_result.error | is-not-empty) {
        $errors = ($errors | append $gradle_result.error)
    }

    return {
        success: (($errors | length) == 0),
        created: $created,
        errors: $errors
    }
}
