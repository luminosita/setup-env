# Prerequisites Check Module for Java
#
# This module validates all required tools for Java development
#
# Public Functions:
# - check_prerequisites: Check all required tools

use ../../common/lib/common.nu *
use ../../common/lib/prerequisites_base.nu *

# Check all prerequisites for Java development
# Returns: record {java: bool, java_version: string, maven: bool, maven_version: string, gradle: bool, gradle_version: string, podman: bool, git: bool, task: bool, precommit: bool, errors: list}
export def check_prerequisites [] {
    print "🔍 Checking prerequisites...\n"

    # Check common prerequisites (Podman, Git, Task, pre-commit)
    let common = (check_common_prerequisites)

    # Check Java
    let java_result = (check_java)
    if $java_result.ok {
        print $"✅ Java installed: ($java_result.version)"
    } else {
        print $"❌ Java not found or invalid: ($java_result.error)"
    }

    # Check Maven
    let maven_result = (check_maven)
    if $maven_result.ok {
        print $"✅ Maven installed: ($maven_result.version)"
    } else {
        print $"❌ Maven not found or invalid: ($maven_result.error)"
    }

    # Check Gradle
    let gradle_result = (check_gradle)
    if $gradle_result.ok {
        print $"✅ Gradle installed: ($gradle_result.version)"
    } else {
        print $"❌ Gradle not found or invalid: ($gradle_result.error)"
    }

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

# Check Java installation (>= 17)
# Returns: record {ok: bool, version: string, error: string}
def check_java [] {
    let java_check = (check_binary_exists "java")
    if not $java_check.exists {
        return {ok: false, version: "", error: "Java not found in PATH"}
    }

    # Get version from java -version (outputs to stderr)
    let version_result = (^java -version | complete)
    let version_output = if ($version_result.stderr | is-empty) {
        $version_result.stdout
    } else {
        $version_result.stderr
    }

    # Parse version from output like: openjdk version "17.0.2" or java version "17.0.2"
    let version_line = ($version_output | lines | first)
    let version_str = ($version_line | parse -r 'version "([^"]+)"' | get capture0.0? | default "")

    if ($version_str | is-empty) {
        return {ok: false, version: "", error: "Could not parse Java version"}
    }

    # Validate Java >= 17
    let validation = (validate_version $version_str 17 0)

    if $validation.valid {
        return {
            ok: true,
            version: $version_str,
            error: ""
        }
    } else {
        return {
            ok: false,
            version: $version_str,
            error: $"Java version ($version_str) does not meet minimum requirement: >= 17"
        }
    }
}

# Check Maven installation
# Returns: record {ok: bool, version: string, error: string}
def check_maven [] {
    let mvn_check = (check_binary_exists "mvn")
    if not $mvn_check.exists {
        return {ok: false, version: "", error: "Maven (mvn) not found in PATH"}
    }

    let version_result = (get_binary_version "mvn" "--version")

    if ($version_result.version | is-empty) {
        return {ok: false, version: "", error: "Could not determine Maven version"}
    }

    return {
        ok: true,
        version: $version_result.version,
        error: ""
    }
}

# Check Gradle installation
# Returns: record {ok: bool, version: string, error: string}
def check_gradle [] {
    let gradle_check = (check_binary_exists "gradle")
    if not $gradle_check.exists {
        return {ok: false, version: "", error: "Gradle not found in PATH"}
    }

    let version_result = (get_binary_version "gradle" "--version")

    if ($version_result.version | is-empty) {
        return {ok: false, version: "", error: "Could not determine Gradle version"}
    }

    return {
        ok: true,
        version: $version_result.version,
        error: ""
    }
}
