# Virtual Environment Setup Module for Java
#
# This module creates a local Maven/Gradle workspace to keep dependencies
# and caches isolated from the global environment
#
# Public Functions:
# - create_venv: Setup local .m2 and .gradle folders

use ../../common/lib/common.nu *
use config_files.nu *

# Create local Java environment with Maven and Gradle directories
# Args:
#   local_env_path: string - Path to local environment folder (default: .java)
#   version: string - Unused for Java (kept for API compatibility)
# Returns: record {success: bool, main_bin_version: string, error: string}
export def create_venv [local_env_path: string = ".java", version: string = ""] {
    print $"\n🏗️  Setting up local Java environment at ($local_env_path)...\n"

    # Check if local env already exists
    if ($local_env_path | path exists) {
        print $"ℹ️  Local environment already exists at ($local_env_path)"

        # Still check and generate config files if missing
        print "\n📝 Checking configuration files..."
        let config_result = (generate_config_files $local_env_path)

        if not $config_result.success {
            print $"\n⚠️  Warning: Some config files could not be created"
            for error in $config_result.errors {
                print $"  - ($error)"
            }
        } else if ($config_result.created | length) > 0 {
            print $"\n✅ Created ($config_result.created | length) configuration file(s)"
        }

        let java_version = (get_java_version)

        return {
            success: true,
            main_bin_version: $java_version,
            error: ""
        }
    }

    # Create directory structure
    try {
        mkdir $local_env_path
        mkdir ($local_env_path | path join "m2" "repository")
        mkdir ($local_env_path | path join "gradle" "caches")
        mkdir ($local_env_path | path join "gradle" "wrapper")

        print $"✅ Created ($local_env_path) directory structure"
    } catch {|e|
        return {
            success: false,
            main_bin_version: "",
            error: $"Failed to create directory structure: ($e.msg)"
        }
    }

    # Verify pom.xml or build.gradle exists
    let has_maven = ("pom.xml" | path exists)
    let has_gradle = ("build.gradle" | path exists) or ("build.gradle.kts" | path exists)

    if not $has_maven and not $has_gradle {
        print "⚠️  No pom.xml or build.gradle found - you'll need to create a project file"
    } else {
        if $has_maven {
            print "✅ Found pom.xml"
        }
        if $has_gradle {
            print "✅ Found build.gradle"
        }
    }

    # Generate Maven and Gradle config files if missing
    print "\n📝 Checking configuration files..."
    let config_result = (generate_config_files $local_env_path)

    if not $config_result.success {
        print $"\n⚠️  Warning: Some config files could not be created"
        for error in $config_result.errors {
            print $"  - ($error)"
        }
    } else if ($config_result.created | length) > 0 {
        print $"\n✅ Created ($config_result.created | length) configuration file(s)"
    }

    let java_version = (get_java_version)

    return {
        success: true,
        main_bin_version: $java_version,
        error: ""
    }
}

# Get Java version
# Returns: string - Java version
def get_java_version [] {
    let version_result = (^java -version | complete)
    let version_output = if ($version_result.stderr | is-empty) {
        $version_result.stdout
    } else {
        $version_result.stderr
    }

    let version_line = ($version_output | lines | first)
    let version_str = ($version_line | parse -r 'version "([^"]+)"' | get capture0.0? | default "unknown")

    return $version_str
}
