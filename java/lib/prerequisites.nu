# Prerequisites Check Module for Java
#
# This module validates all required tools for Java development
#
# Public Functions:
# - check_prerequisites: Check all required tools

use ../../common/lib/common.nu *
use ../../common/lib/prerequisites_base.nu *

# Check all prerequisites for Java development (silent - no printing)
# Args:
#   project_type: string - "microservice" (default) or "library". Libraries skip container-related tools.
# Returns: record {java: bool, java_version: string, maven: bool, maven_version: string, gradle: bool, gradle_version: string, podman: bool, git: bool, task: bool, precommit: bool, errors: list}
export def check_prerequisites [
    project_type: string = "microservice"
] {
    # Check common prerequisites (Podman, Git, Task, pre-commit)
    let common = (check_common_prerequisites $project_type)

    # Check Java
    let java_result = (check_java)

    # Check Maven
    let maven_result = (check_maven)

    # Check Gradle
    let gradle_result = (check_gradle)

    # Aggregate errors
    mut errors = []
    if not $java_result.ok {
        $errors = ($errors | append $java_result.error)
    }
    if not $maven_result.ok {
        $errors = ($errors | append $maven_result.error)
    }
    if not $gradle_result.ok {
        $errors = ($errors | append $gradle_result.error)
    }

    $errors = ($errors | append $common.errors | flatten)

    return {
        project_type: $project_type,
        java: $java_result.ok,
        java_version: $java_result.version,
        maven: $maven_result.ok,
        maven_version: $maven_result.version,
        gradle: $gradle_result.ok,
        gradle_version: $gradle_result.version,
        podman: $common.podman,
        git: $common.git,
        task: $common.task,
        precommit: $common.precommit,
        errors: $errors
    }
}

# Check Java installation (>= 24)
# Returns: record {ok: bool, version: string, error: string}
def check_java [] {
    let java_check = (check_binary_exists "java")
    if not $java_check.exists {
        print "❌ Java not found in PATH"
        return {ok: false, version: "", error: "Java not found in PATH"}
    }

    # Get version from java -version (outputs to stderr)
    let version_result = (^java -version | complete)
    let version_output = if ($version_result.stderr | is-empty) {
        $version_result.stdout
    } else {
        $version_result.stderr
    }

    # Parse version from output like: openjdk version "24.0.2" or java version "24.0.2"
    let version_line = ($version_output | lines | first)
    let version_str = ($version_line | parse -r 'version "([^"]+)"' | get capture0.0? | default "")

    if ($version_str | is-empty) {
        print "❌ Could not parse Java version"
        return {ok: false, version: "", error: "Could not parse Java version"}
    }

    # Validate Java >= 24
    let validation = (validate_version $version_str 24 0)

    if $validation.valid {
        print $"✅ Java installed: ($version_str)"
        return {
            ok: true,
            version: $version_str,
            error: ""
        }
    } else {
        print $"❌ Java version ($version_str) does not meet minimum requirement: >= 24"
        return {
            ok: false,
            version: $version_str,
            error: $"Java version ($version_str) does not meet minimum requirement: >= 24"
        }
    }
}

# Check Maven installation and version
# Returns: record {ok: bool, version: string, error: string}
def check_maven [] {
    let mvn_check = (check_binary_exists "mvn")
    if not $mvn_check.exists {
        print "❌ Maven (mvn) not found in PATH"
        return {ok: false, version: "", error: "Maven (mvn) not found in PATH"}
    }

    # Get version - Maven outputs version info on first line: "Apache Maven X.Y.Z (...)"
    let result = (^mvn --version | complete)

    if $result.exit_code != 0 {
        print "❌ Could not determine Maven version"
        return {ok: false, version: "", error: "Could not determine Maven version"}
    }

    # Extract first line containing version
    let version_line = ($result.stdout | lines | first)

    # Validate version (require 3.9.11)
    let validation = (validate_version $version_line 3 9 "Apache Maven " "Maven")

    if $validation.valid {
        print $"✅ Maven installed: ($validation.version.full)"
        return {
            ok: true,
            version: $validation.version.full,
            error: ""
        }
    } else {
        print $"❌ Maven: ($validation.error). Required: >= 3.9.11"
        return {
            ok: false,
            version: $validation.version.full,
            error: $"($validation.error). Required: >= 3.9.11"
        }
    }
}

# Check Gradle installation and version
# Returns: record {ok: bool, version: string, error: string}
def check_gradle [] {
    let gradle_check = (check_binary_exists "gradle")
    if not $gradle_check.exists {
        print "❌ Gradle not found in PATH"
        return {ok: false, version: "", error: "Gradle not found in PATH"}
    }

    # Get version - Gradle outputs version in the format:
    # ------------------------------------------------------------
    # Gradle X.Y.Z
    # ------------------------------------------------------------
    let result = (^gradle --version | complete)

    if $result.exit_code != 0 {
        print "❌ Could not determine Gradle version"
        return {ok: false, version: "", error: "Could not determine Gradle version"}
    }

    # Extract the line containing "Gradle " (use where instead of find to avoid ANSI color codes)
    let version_line = ($result.stdout | lines | where ($it | str contains "Gradle ") | first)

    # Validate version (require 8.14.3)
    let validation = (validate_version $version_line 8 14 "Gradle " "Gradle")

    if $validation.valid {
        print $"✅ Gradle installed: ($validation.version.full)"
        return {
            ok: true,
            version: $validation.version.full,
            error: ""
        }
    } else {
        print $"❌ Gradle: ($validation.error). Required: >= 8.14.3"
        return {
            ok: false,
            version: $validation.version.full,
            error: $"($validation.error). Required: >= 8.14.3"
        }
    }
}
