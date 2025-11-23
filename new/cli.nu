#!/usr/bin/env nu

# Project Manager CLI
# A sample CLI tool demonstrating NuShell best practices
#
# Usage:
#   nu cli.nu --help
#   nu cli.nu init --name "my-project" --type python
#   nu cli.nu status
#   nu cli.nu build --env production --verbose
#   nu cli.nu deploy --target staging --dry-run

# Main entry point with command routing
def main [
    command?: string  # Command to execute (init, status, build, deploy)
    --help (-h)       # Show help message
] {
    if $help {
        show_help
        return
    }

    if ($command == null) {
        print "Error: No command specified"
        print "Run 'nu cli.nu --help' for usage information\n"
        show_help
        exit 1
    }

    match $command {
        "init" => { print "Use: nu cli.nu init --name <project> --type <type>" },
        "status" => { print "Use: nu cli.nu status" },
        "build" => { print "Use: nu cli.nu build --env <env> [--verbose]" },
        "deploy" => { print "Use: nu cli.nu deploy --target <target> [--dry-run]" },
        _ => {
            print $"Error: Unknown command '($command)'"
            print "Run 'nu cli.nu --help' for available commands\n"
            show_help
            exit 1
        }
    }
}

# Show help message
def show_help [] {
    print "Project Manager CLI"
    print "A sample CLI tool demonstrating NuShell best practices\n"
    print "Usage:"
    print "  nu cli.nu <command> [options]\n"
    print "Commands:"
    print "  init      Initialize a new project"
    print "  status    Show project status"
    print "  build     Build the project"
    print "  deploy    Deploy the project\n"
    print "Examples:"
    print "  nu cli.nu init --name my-project --type python"
    print "  nu cli.nu status --verbose"
    print "  nu cli.nu build --environment production --verbose"
    print "  nu cli.nu deploy --target staging --dry-run\n"
    print "Options:"
    print "  -h, --help     Show this help message"
    print "  -v, --verbose  Show detailed output"
}

# Initialize a new project
# Args:
#   --name: Project name (required)
#   --type: Project type (python, go, java, node)
#   --template: Use template (optional)
# Returns: record {success: bool, project_path: string, error: string}
export def "main init" [
    --name: string      # Project name (required)
    --type: string      # Project type: python, go, java, node
    --template: string  # Optional template to use
] {
    print "🚀 Initializing new project...\n"

    # Validate required arguments
    if ($name == null or $name == "") {
        print "❌ Error: --name is required"
        print "Usage: nu cli.nu init --name <project> --type <type>"
        exit 1
    }

    if ($type == null or $type == "") {
        print "❌ Error: --type is required"
        print "Usage: nu cli.nu init --name <project> --type <type>"
        exit 1
    }

    # FIXME: Make valid_types global var
    # Validate project type
    let valid_types = ["python", "go", "java", "node"]
    if ($type not-in $valid_types) {
        print $"❌ Error: Invalid type '($type)'"
        print $"Valid types: ($valid_types | str join ', ')"
        exit 1
    }

    # Check if project directory already exists
    let project_path = $name
    if ($project_path | path exists) {
        print $"❌ Error: Directory '($project_path)' already exists"
        return {
            success: false,
            project_path: "",
            error: "Directory already exists"
        }
    }

    # Create project directory
    print $"📁 Creating project directory: ($project_path)"
    mkdir $project_path

    # Initialize based on type
    match $type {
        "python" => { init_python_project $project_path $template },
        "go" => { init_go_project $project_path $template },
        "java" => { init_java_project $project_path $template },
        "node" => { init_node_project $project_path $template },
        _ => {
            print $"❌ Unsupported type: ($type)"
            exit 1
        }
    }

    print $"\n✅ Project '($name)' initialized successfully!"
    print $"📂 Location: ($project_path)"

    return {
        success: true,
        project_path: $project_path,
        error: ""
    }
}

# Show project status
# Returns: record {status: string, checks: list, summary: record}
export def "main status" [
    --verbose (-v)  # Show detailed information
] {
    print "📊 Project Status\n"

    mut checks = []

    # Check git repository
    let git_check = (check_git_repo)
    $checks = ($checks | append $git_check)

    # Check dependencies
    let deps_check = (check_dependencies)
    $checks = ($checks | append $deps_check)

    # Check tests
    let test_check = (check_tests)
    $checks = ($checks | append $test_check)

    # Print results
    for check in $checks {
        if $check.passed {
            print $"✅ ($check.name): ($check.message)"
        } else {
            print $"❌ ($check.name): ($check.message)"
        }
    }

    let passed = ($checks | where passed == true | length)
    let failed = ($checks | where passed == false | length)
    let total = ($checks | length)

    print $"\n📈 Summary: ($passed)/($total) checks passed"

    if $verbose {
        print "\n📋 Detailed Information:"
        print ($checks | table)
    }

    return {
        status: (if $failed == 0 { "healthy" } else { "issues" }),
        checks: $checks,
        summary: {
            total: $total,
            passed: $passed,
            failed: $failed
        }
    }
}

# Build the project
# Args:
#   --environment: Environment (development, staging, production)
#   --verbose: Show detailed build output
export def "main build" [
    --environment: string = "development"  # Environment (development, staging, production)
    --verbose (-v)                         # Show detailed build output
] {
    print $"🔨 Building project for ($environment) environment...\n"

    # Validate environment
    let valid_envs = ["development", "staging", "production"]
    if ($environment not-in $valid_envs) {
        print $"❌ Error: Invalid environment '($environment)'"
        print $"Valid environments: ($valid_envs | str join ', ')"
        exit 1
    }

    # Detect project type
    let project_type = (detect_project_type)

    if $project_type.success {
        print $"📦 Detected project type: ($project_type.type)"
    } else {
        print $"❌ Could not detect project type: ($project_type.error)"
        exit 1
    }

    # Build based on project type
    print "🏗️  Running build steps..."

    let build_result = match $project_type.type {
        "python" => { build_python $environment $verbose },
        "go" => { build_go $environment $verbose },
        "java" => { build_java $environment $verbose },
        "node" => { build_node $environment $verbose },
        _ => {
            {success: false, error: "Unsupported project type"}
        }
    }

    if $build_result.success {
        print "\n✅ Build completed successfully!"
        return {
            success: true,
            environment: $environment,
            type: $project_type.type,
            artifacts: $build_result.artifacts
        }
    } else {
        print $"\n❌ Build failed: ($build_result.error)"
        exit 1
    }
}

# Deploy the project
# Args:
#   --target: Deployment target (staging, production)
#   --dry-run: Simulate deployment without executing
export def "main deploy" [
    --target: string   # Deployment target (staging, production)
    --dry-run (-d)     # Simulate deployment without executing
] {
    print "🚀 Deploying project...\n"

    # Validate required arguments
    if ($target == null or $target == "") {
        print "❌ Error: --target is required"
        print "Usage: nu cli.nu deploy --target <target> [--dry-run]"
        exit 1
    }

    # Validate target
    let valid_targets = ["staging", "production"]
    if ($target not-in $valid_targets) {
        print $"❌ Error: Invalid target '($target)'"
        print $"Valid targets: ($valid_targets | str join ', ')"
        exit 1
    }

    if $dry_run {
        print "🔍 DRY RUN MODE - No changes will be made\n"
    }

    # Pre-deployment checks
    print "🔍 Running pre-deployment checks..."
    let checks_result = (run_deployment_checks $target)

    if not $checks_result.success {
        print $"❌ Pre-deployment checks failed: ($checks_result.error)"
        exit 1
    }

    print "✅ All pre-deployment checks passed\n"

    # Deploy
    print $"📦 Deploying to ($target)..."

    if $dry_run {
        print "  [DRY RUN] Would deploy to target"
        print "  [DRY RUN] Would update configuration"
        print "  [DRY RUN] Would restart services"
    } else {
        # Actual deployment logic would go here
        print "  ⏳ Uploading artifacts..."
        print "  ⏳ Updating configuration..."
        print "  ⏳ Restarting services..."
    }

    print $"\n✅ Deployment to ($target) completed successfully!"

    return {
        success: true,
        target: $target,
        dry_run: $dry_run,
        timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
    }
}

# Helper Functions (Private - not exported)

# Initialize Python project
def init_python_project [path: string, template: any] {
    print "  🐍 Initializing Python project..."

    cd $path
    ^touch "README.md"
    ^touch "requirements.txt"
    ^mkdir "src"
    ^mkdir "tests"

    if ($template != null and $template != "") {
        print $"  📋 Using template: ($template)"
    }

    print "  ✅ Python project structure created"
}

# Initialize Go project
def init_go_project [path: string, template: any] {
    print "  🔵 Initializing Go project..."

    cd $path
    ^go mod init $path
    ^mkdir "cmd"
    ^mkdir "pkg"
    ^mkdir "internal"

    if ($template != null and $template != "") {
        print $"  📋 Using template: ($template)"
    }

    print "  ✅ Go project structure created"
}

# Initialize Java project
def init_java_project [path: string, template: any] {
    print "  ☕ Initializing Java project..."

    cd $path
    ^touch "pom.xml"
    ^mkdir -p "src/main/java"
    ^mkdir -p "src/test/java"

    if ($template != null and $template != "") {
        print $"  📋 Using template: ($template)"
    }

    print "  ✅ Java project structure created"
}

# Initialize Node.js project
def init_node_project [path: string, template: any] {
    print "  💚 Initializing Node.js project..."

    cd $path
    ^npm init -y
    ^mkdir "src"
    ^mkdir "tests"

    if ($template != null and $template != "") {
        print $"  📋 Using template: ($template)"
    }

    print "  ✅ Node.js project structure created"
}

# Check if directory is a git repository
def check_git_repo [] {
    if (".git" | path exists) {
        let branch = (^git branch --show-current | complete)
        if $branch.exit_code == 0 {
            let branch_name = ($branch.stdout | str trim)
            return {
                name: "Git Repository",
                passed: true,
                message: $"On branch ($branch_name)"
            }
        }
    }

    return {
        name: "Git Repository",
        passed: false,
        message: "Not a git repository"
    }
}

# Check dependencies
def check_dependencies [] {
    # Check for common dependency files
    let dep_files = [
        "requirements.txt",
        "package.json",
        "go.mod",
        "pom.xml",
        "build.gradle"
    ]

    let found = ($dep_files | where {|file| $file | path exists})

    if ($found | length) > 0 {
        let count = ($found | length)
        return {
            name: "Dependencies",
            passed: true,
            message: $"Found ($count) dependency files"
        }
    } else {
        return {
            name: "Dependencies",
            passed: false,
            message: "No dependency files found"
        }
    }
}

# Check tests
def check_tests [] {
    if ("tests" | path exists) or ("test" | path exists) {
        return {
            name: "Tests",
            passed: true,
            message: "Test directory exists"
        }
    } else {
        return {
            name: "Tests",
            passed: false,
            message: "No test directory found"
        }
    }
}

# Detect project type based on files
def detect_project_type [] {
    if ("requirements.txt" | path exists) or ("pyproject.toml" | path exists) {
        return {success: true, type: "python"}
    } else if ("go.mod" | path exists) {
        return {success: true, type: "go"}
    } else if ("pom.xml" | path exists) or ("build.gradle" | path exists) {
        return {success: true, type: "java"}
    } else if ("package.json" | path exists) {
        return {success: true, type: "node"}
    } else {
        return {success: false, type: "", error: "Unknown project type"}
    }
}

# Run pre-deployment checks
def run_deployment_checks [target: string] {
    # Check git status
    let git_result = (^git status --porcelain | complete)

    if ($git_result.stdout | str trim | str length) > 0 {
        return {
            success: false,
            error: "Uncommitted changes in working directory"
        }
    }

    # Additional checks for production
    if $target == "production" {
        let branch = (^git branch --show-current | str trim)
        if $branch != "main" and $branch != "master" {
            return {
                success: false,
                error: "Production deployment must be from main/master branch"
            }
        }
    }

    return {success: true, error: ""}
}
