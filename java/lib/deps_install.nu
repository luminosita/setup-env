# Dependencies Installation Module for Java
#
# This module handles Maven and Gradle dependency installation
#
# Public Functions:
# - install_dependencies: Install project dependencies

use ../../common/lib/common.nu *

# Install dependencies using Maven or Gradle
# Args:
#   local_env_path: string - Path to local environment (default: .java)
# Returns: record {success: bool, packages: int, error: string}
export def install_dependencies [local_env_path: string = ".java"] {
    print "\n📦 Installing dependencies...\n"

    let has_maven = ("pom.xml" | path exists)
    let has_gradle = ("build.gradle" | path exists) or ("build.gradle.kts" | path exists)

    if not $has_maven and not $has_gradle {
        return {
            success: false,
            packages: 0,
            error: "No pom.xml or build.gradle found - cannot install dependencies"
        }
    }

    mut success = true
    mut packages = 0
    mut errors = []

    # Install Maven dependencies
    if $has_maven {
        print "📦 Installing Maven dependencies..."

        let m2_local_repo = ($local_env_path | path join "m2" "repository" | path expand)

        let result = (^mvn dependency:resolve $"-Dmaven.repo.local=($m2_local_repo)" | complete)

        if $result.exit_code == 0 {
            print "✅ Maven dependencies installed"

            # Count downloaded artifacts (approximate)
            let repo_files = (glob ($m2_local_repo | path join "**" "*") | where ($it | path type) == "file" | length)
            $packages = $repo_files
        } else {
            $success = false
            $errors = ($errors | append $"Maven dependency installation failed: ($result.stderr)")
        }
    }

    # Install Gradle dependencies
    if $has_gradle {
        print "📦 Installing Gradle dependencies..."

        let gradle_home = ($local_env_path | path join "gradle" | path expand)

        let result = (^gradle dependencies $"--gradle-user-home=($gradle_home)" | complete)

        if $result.exit_code == 0 {
            print "✅ Gradle dependencies resolved"

            # Count cached files (approximate)
            let cache_path = ($gradle_home | path join "caches")
            if ($cache_path | path exists) {
                let cache_files = (glob ($cache_path | path join "**" "*") | where ($it | path type) == "file" | length)
                $packages = ($packages + $cache_files)
            }
        } else {
            $success = false
            $errors = ($errors | append $"Gradle dependency resolution failed: ($result.stderr)")
        }
    }

    if $success {
        return {
            success: true,
            packages: $packages,
            error: ""
        }
    } else {
        return {
            success: false,
            packages: $packages,
            error: ($errors | str join ", ")
        }
    }
}
