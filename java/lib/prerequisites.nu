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

# Print prerequisites check results with formatted output
# Args:
#   prereqs: record - Result from check_prerequisites
export def print_prerequisites [prereqs: record] {
    print "🔍 Checking prerequisites...\n"

    # Print common prerequisites
    if $prereqs.podman {
        print $"✅ Podman installed"
    } else {
        print "❌ Podman not found"
    }

    if $prereqs.git {
        print $"✅ Git installed"
    } else {
        print "❌ Git not found"
    }

    if $prereqs.task {
        print $"✅ Task installed"
    } else {
        print "❌ Task not found"
    }

    if $prereqs.precommit {
        print $"✅ pre-commit installed"
    } else {
        print "❌ pre-commit not found"
    }

    # Print Java
    if $prereqs.java {
        print $"✅ Java installed: ($prereqs.java_version)"
    } else {
        let error = ($prereqs.errors | where {|e| $e =~ "Java"} | first?)
        if ($error | is-not-empty) {
            print $"❌ Java not found or invalid: ($error)"
        } else {
            print "❌ Java not found"
        }
    }

    # Print Maven
    if $prereqs.maven {
        print $"✅ Maven installed: ($prereqs.maven_version)"
    } else {
        let error = ($prereqs.errors | where {|e| $e =~ "Maven"} | first?)
        if ($error | is-not-empty) {
            print $"❌ Maven not found or invalid: ($error)"
        } else {
            print "❌ Maven not found"
        }
    }

    # Print Gradle
    if $prereqs.gradle {
        print $"✅ Gradle installed: ($prereqs.gradle_version)"
    } else {
        let error = ($prereqs.errors | where {|e| $e =~ "Gradle"} | first?)
        if ($error | is-not-empty) {
            print $"❌ Gradle not found or invalid: ($error)"
        } else {
            print "❌ Gradle not found"
        }
    }
}

# Check Java installation (>= 24)
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

    # Parse version from output like: openjdk version "24.0.2" or java version "24.0.2"
    let version_line = ($version_output | lines | first)
    let version_str = ($version_line | parse -r 'version "([^"]+)"' | get capture0.0? | default "")

    if ($version_str | is-empty) {
        return {ok: false, version: "", error: "Could not parse Java version"}
    }

    # Validate Java >= 24
    let validation = (validate_version $version_str 24 0)

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
            error: $"Java version ($version_str) does not meet minimum requirement: >= 24"
        }
    }
}

# Check Maven installation and version
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

    # Validate version (require 3.9.11)
    let validation = (validate_version $version_result.version 3 9 "Apache Maven " "Maven")

    if $validation.valid {
        return {
            ok: true,
            version: $version_result.version,
            error: ""
        }
    } else {
        return {
            ok: false,
            version: $version_result.version,
            error: $"($validation.error). Required: >= 3.9.11"
        }
    }
}

# Check Gradle installation and version
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

    # Validate version (require 8.14.3)
    let validation = (validate_version $version_result.version 8 14 "Gradle " "Gradle")

    if $validation.valid {
        return {
            ok: true,
            version: $version_result.version,
            error: ""
        }
    } else {
        return {
            ok: false,
            version: $version_result.version,
            error: $"($validation.error). Required: >= 8.14.3"
        }
    }
}
