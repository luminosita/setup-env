- [x] Adjust Python and Go scripts to first validate environment. These should be runnable from devbox shell
  - Added `--validate` flag to python/setup.nu and go/setup.nu
  - Created validate_env.nu orchestrator script that runs on devbox startup
  - Added user confirmation prompt before running full setup
- [x] Validate if .pre-commit-config.yaml exists before installing pre-commit hook
  - Updated common/lib/config_setup.nu to check for config file before installation
- [x] Adjust devbox.json to add support for java
  - Added jdk@latest, maven@latest, gradle@latest to packages
  - Updated init_hook to display Java, Maven, and Gradle versions
  - Added Java setup instructions to quick start
- [x] Add Java based tasks into Taskfile.yml
  - Added java:test, java:test:unit, java:test:integration, java:build tasks
  - Updated build and test tasks to include Java
- [x] Create ./java with libraries and tests based on ./go. Do not install tools from Java scripts (tools should come from devbox packages)
  - Created java/setup.nu main script with --validate flag
  - Created java/lib/ modules: prerequisites.nu, venv_setup.nu, deps_install.nu, validation.nu
  - Created java/tests/ with unit and integration tests
  - No tool installation - all tools come from devbox packages
  - Updated validate_env.nu to include Java validation
- [x] Renaming of template files for Java (CHANGE_ME)
  - Java setup.nu handles placeholders in pom.xml, build.gradle, and build.gradle.kts
  - Uses common template_config.nu module for replacement
- [x] Adjust build.nu to support java
  - Added "java" to valid base_dir options
  - Updated usage documentation
- [x] Generate required Maven and Gradle config files
  - Created .m2/settings.xml with local repository path pointing to .java/m2/repository
  - Created gradle/gradle.properties with local cache and user home pointing to .java/gradle
  - Updated .gitignore to exclude Java build artifacts and local environments

- [x] Generate required Maven and Gradle config files thru script if missing from the local environment
  - Created java/lib/config_files.nu module with generate_config_files function
  - Integrated into java/lib/venv_setup.nu to auto-generate config files
  - Generates .m2/settings.xml with local repository path
  - Generates gradle/gradle.properties with local cache and user home
  - Created java/tests/test_config_files.nu with comprehensive tests (4 tests, all passing)
  - Config files are idempotent - won't recreate if they already exist

```./.m2/settings.xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              https://maven.apache.org/xsd/settings-1.0.0.xsd">

    <!-- Force Maven to use a project-local repository -->
    <localRepository>${user.home}/repository</localRepository>

    <!-- Optional: Mirror config can speed up builds -->
    <!--
    <mirrors>
        <mirror>
            <id>central</id>
            <name>Maven Central Proxy</name>
            <url>https://repo.maven.apache.org/maven2</url>
            <mirrorOf>*</mirrorOf>
        </mirror>
    </mirrors>
    -->
</settings>
```
```./gradle/gradle.properties
# Store Gradle caches locally inside the project directory
org.gradle.caching=true
org.gradle.caching.path=$PWD/.gradle/caches

# Force Gradle to use project-local user home
gradle.user.home=$PWD/.gradle

# Improve reproducibility
org.gradle.parallel=true
org.gradle.daemon=true
```
