- [ ] Adjust Python and Go scripts to first validate environment. These should be runnable from devbox shell
- [ ] Validate if ..pre-commit-config.yaml exists before installing pre-commit hook
- [ ] Adjust devbox.json to add support for java
- [ ] Add Java based tasks into Taskfile.yml
- [ ] Create ./java with libraries and tests based on ./go
- [ ] Renaming of template files for Java (CHANGE_ME)
- [ ] Adjust build.nu to support java

- [ ] Generate required Maven and Gradle config files
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