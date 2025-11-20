# Environment Validation Module for Java
#
# This module validates the complete Java development environment setup
#
# Public Functions:
# - validate_environment: Run all validation checks

use ../../common/lib/common.nu *

# Validate the complete development environment
# Args:
#   local_env_path: string - Path to local Java environment (default: .java)
#   project_type: string - Project type (microservice or library) - optional, unused but kept for compatibility
# Returns: record {success: bool, passed: int, failed: int, checks: list}
export def validate_environment [
    local_env_path: string = ".java"
    project_type: string = "microservice"  # Unused, but kept for API compatibility
] {
    print "\n🔍 Validating environment...\n"

    mut checks = []
    mut passed = 0
    mut failed = 0

    # Check 1: Java version
    let java_check = (validate_java_version)
    $checks = ($checks | append $java_check)
    if $java_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    # Check 2: Project file (pom.xml or build.gradle)
    let project_check = (validate_project_file)
    $checks = ($checks | append $project_check)
    if $project_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    # Check 3: Local Java workspace
    let workspace_check = (validate_java_workspace $local_env_path)
    $checks = ($checks | append $workspace_check)
    if $workspace_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    # Check 4: .env file
    let env_check = (validate_env_file)
    $checks = ($checks | append $env_check)
    if $env_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    # Check 5: Pre-commit hooks
    let hooks_check = (validate_precommit_hooks)
    $checks = ($checks | append $hooks_check)
    if $hooks_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    # Check 6: Java compilation
    let compile_check = (validate_java_compile)
    $checks = ($checks | append $compile_check)
    if $compile_check.passed {
        $passed = ($passed + 1)
    } else {
        $failed = ($failed + 1)
    }

    let success = ($failed == 0)

    if $success {
        print $"\n✅ Environment validation passed: ($passed)/($passed) checks"
    } else {
        print $"\n⚠️  Environment validation: ($passed)/($passed + $failed) checks passed, ($failed) failed"
    }

    return {
        success: $success,
        passed: $passed,
        failed: $failed,
        checks: $checks
    }
}

# Validate Java version (>= 17)
def validate_java_version [] {
    print "  Checking Java version..."

    let version_result = (^java -version | complete)
    let version_output = if ($version_result.stderr | is-empty) {
        $version_result.stdout
    } else {
        $version_result.stderr
    }

    let version_line = ($version_output | lines | first)
    let version_str = ($version_line | parse -r 'version "([^"]+)"' | get capture0.0? | default "")

    if ($version_str | is-empty) {
        print "  ❌ Could not parse Java version"
        return {name: "java-version", passed: false, message: "Could not parse Java version"}
    }

    let validation = (validate_version $version_str 17 0)

    if $validation.valid {
        print $"  ✅ Java ($version_str) >= 17"
        return {name: "java-version", passed: true, message: $"Java ($version_str) >= 17"}
    } else {
        print $"  ❌ Java ($version_str) < 17"
        return {name: "java-version", passed: false, message: $"Java ($version_str) does not meet minimum requirement (>= 17)"}
    }
}

# Validate project file exists
def validate_project_file [] {
    print "  Checking project file..."

    let has_maven = ("pom.xml" | path exists)
    let has_gradle = ("build.gradle" | path exists) or ("build.gradle.kts" | path exists)

    if $has_maven or $has_gradle {
        let project_type = if $has_maven { "pom.xml" } else { "build.gradle" }
        print $"  ✅ ($project_type) found"
        return {name: "project-file", passed: true, message: $"($project_type) found"}
    } else {
        print "  ❌ No pom.xml or build.gradle found"
        return {name: "project-file", passed: false, message: "No pom.xml or build.gradle found"}
    }
}

# Validate local Java workspace exists
# Args:
#   local_env_path: string - Path to local Java environment
def validate_java_workspace [local_env_path: string] {
    print $"  Checking ($local_env_path) workspace..."

    if not ($local_env_path | path exists) {
        print $"  ❌ ($local_env_path) workspace not found"
        return {name: "java-workspace", passed: false, message: $"($local_env_path) workspace not found"}
    }

    # Check required subdirectories
    let m2_exists = (($local_env_path | path join "m2") | path exists)
    let gradle_exists = (($local_env_path | path join "gradle") | path exists)

    if $m2_exists or $gradle_exists {
        print $"  ✅ ($local_env_path) workspace configured"
        return {name: "java-workspace", passed: true, message: $"($local_env_path) workspace configured"}
    } else {
        print $"  ⚠️  ($local_env_path) workspace incomplete"
        return {name: "java-workspace", passed: false, message: $"($local_env_path) workspace missing subdirectories"}
    }
}

# Validate .env file exists
def validate_env_file [] {
    print "  Checking .env file..."

    if (".env" | path exists) {
        print "  ✅ .env file exists"
        return {name: ".env", passed: true, message: ".env file exists"}
    } else {
        print "  ⚠️  .env file not found"
        return {name: ".env", passed: false, message: ".env file not found"}
    }
}

# Validate pre-commit hooks are installed
def validate_precommit_hooks [] {
    print "  Checking pre-commit hooks..."

    if (".git/hooks/pre-commit" | path exists) {
        print "  ✅ Pre-commit hooks installed"
        return {name: "pre-commit", passed: true, message: "Pre-commit hooks installed"}
    } else {
        print "  ⚠️  Pre-commit hooks not installed"
        return {name: "pre-commit", passed: false, message: "Pre-commit hooks not installed"}
    }
}

# Validate Java compilation works
def validate_java_compile [] {
    print "  Checking Java compilation..."

    let has_maven = ("pom.xml" | path exists)
    let has_gradle = ("build.gradle" | path exists) or ("build.gradle.kts" | path exists)

    if $has_maven {
        let result = (^mvn compile | complete)
        if $result.exit_code == 0 {
            print "  ✅ Maven compilation successful"
            return {name: "java-compile", passed: true, message: "Maven compilation successful"}
        } else {
            print "  ❌ Maven compilation failed"
            return {name: "java-compile", passed: false, message: "Maven compilation failed"}
        }
    } else if $has_gradle {
        let result = (^gradle build | complete)
        if $result.exit_code == 0 {
            print "  ✅ Gradle build successful"
            return {name: "java-compile", passed: true, message: "Gradle build successful"}
        } else {
            print "  ❌ Gradle build failed"
            return {name: "java-compile", passed: false, message: "Gradle build failed"}
        }
    } else {
        print "  ⚠️  Skipping compilation (no project file)"
        return {name: "java-compile", passed: true, message: "Skipped (no project file)"}
    }
}
