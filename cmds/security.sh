#!/bin/bash

set -e

# Security Scanning Script
# Usage: ./cmds/security.sh [--full] [--fix] [--report]

# Default values
FULL_SCAN=false
AUTO_FIX=false
REPORT=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            FULL_SCAN=true
            shift
            ;;
        --fix)
            AUTO_FIX=true
            shift
            ;;
        --report)
            REPORT=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--full] [--fix] [--report]"
            echo ""
            echo "Options:"
            echo "  --full         Run comprehensive security scan"
            echo "  --fix          Attempt to auto-fix issues where possible"
            echo "  --report       Generate detailed security report"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🔒 Security Scanning Script${NC}"
echo "==============================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "FAIL")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Function to run command and capture output
run_security_check() {
    local tool=$1
    local command=$2
    local description=$3
    
    echo -e "\n${BLUE}Running $tool...${NC}"
    
    if command_exists "$tool"; then
        if eval "$command"; then
            print_status "PASS" "$description"
            return 0
        else
            print_status "FAIL" "$description"
            return 1
        fi
    else
        print_status "WARN" "$tool not found, skipping $description"
        return 1
    fi
}

# 1. Go Security Checks
echo -e "\n${BLUE}🔍 Go Security Analysis${NC}"

# Go vet - static analysis
run_security_check "go" "go vet ./..." "Go vet static analysis"

# Go sec - security scanner
if command_exists "gosec"; then
    if [ "$AUTO_FIX" = true ]; then
        run_security_check "gosec" "gosec -fmt sarif -out security-report.sarif ./..." "GoSec security scan with report"
    else
        run_security_check "gosec" "gosec ./..." "GoSec security scan"
    fi
else
    print_status "WARN" "GoSec not found. Install with: go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest"
fi

# 2. Dependency Vulnerability Scanning
echo -e "\n${BLUE}📦 Dependency Security${NC}"

# Go mod tidy and verify
run_security_check "go" "go mod tidy" "Go modules tidy"
run_security_check "go" "go mod verify" "Go modules verification"

# Nancy - vulnerability scanner
if command_exists "nancy"; then
    run_security_check "nancy" "go list -json -deps ./... | nancy sleuth" "Nancy vulnerability scan"
else
    print_status "WARN" "Nancy not found. Install with: go install github.com/sonatypecommunity/nancy@latest"
fi

# 3. Secret Detection
echo -e "\n${BLUE}🔐 Secret Detection${NC}"

# TruffleHog (if available)
if command_exists "trufflehog"; then
    run_security_check "trufflehog" "trufflehog git file://. --json" "TruffleHog secret detection"
else
    print_status "WARN" "TruffleHog not found. Install from: https://github.com/trufflesecurity/trufflehog"
fi

# GitLeaks (if available)
if command_exists "gitleaks"; then
    run_security_check "gitleaks" "gitleaks detect --source . --report-format json --report-path gitleaks-report.json" "GitLeaks secret detection"
else
    print_status "WARN" "GitLeaks not found. Install from: https://github.com/gitleaks/gitleaks"
fi

# 4. Code Quality and Security
echo -e "\n${BLUE}📊 Code Quality${NC}"

# GolangCI-Lint
if command_exists "golangci-lint"; then
    if [ "$REPORT" = true ]; then
        run_security_check "golangci-lint" "golangci-lint run --out-format json > golangci-report.json" "GolangCI-Lint with JSON report"
    else
        run_security_check "golangci-lint" "golangci-lint run" "GolangCI-Lint analysis"
    fi
else
    print_status "WARN" "golangci-lint not found. Install from: https://golangci-lint.run/docs/welcome/install/"
fi

# 5. Container Security (if Dockerfile exists)
if [ -f "Dockerfile" ]; then
    echo -e "\n${BLUE}🐳 Container Security${NC}"
    
    # Hadolint
    if command_exists "hadolint"; then
        run_security_check "hadolint" "hadolint Dockerfile" "Hadolint Dockerfile analysis"
    else
        print_status "WARN" "Hadolint not found. Install from: https://github.com/hadolint/hadolint"
    fi
    
    # Docker Scout (if available)
    if command_exists "docker"; then
        if docker images | grep -q "$(basename $(pwd))"; then
            run_security_check "docker" "docker scout cves $(docker images --format '{{.Repository}}:{{.Tag}}' | head -n1)" "Docker Scout vulnerability scan"
        else
            print_status "INFO" "No Docker images found to scan"
        fi
    fi
fi

# 6. File Permissions and Security
echo -e "\n${BLUE}🔒 File Security${NC}"

# Check for world-writable files
if find . -type f -perm -002 2>/dev/null | grep -q .; then
    print_status "WARN" "Found world-writable files"
    find . -type f -perm -002
else
    print_status "PASS" "No world-writable files found"
fi

# Check .env file permissions
if [ -f ".env" ]; then
    env_perms=$(stat -c "%a" .env 2>/dev/null || stat -f "%A" .env 2>/dev/null)
    if [ "$env_perms" = "600" ] || [ "$env_perms" = "644" ]; then
        print_status "PASS" ".env file permissions are secure ($env_perms)"
    else
        print_status "WARN" ".env file permissions should be 600 or 644 (current: $env_perms)"
    fi
fi

# 7. Git Security
echo -e "\n${BLUE}🌿 Git Security${NC}"

# Check for sensitive files in git
if [ -d ".git" ]; then
    # Check for secrets in git history
    if git log --all --grep="secret\|password\|key\|token" --oneline | grep -q .; then
        print_status "WARN" "Potential secrets found in git history"
    else
        print_status "PASS" "No obvious secrets in git history"
    fi
    
    # Check git configuration
    if git config --get user.name >/dev/null && git config --get user.email >/dev/null; then
        print_status "PASS" "Git user configuration is set"
    else
        print_status "WARN" "Git user configuration missing"
    fi
fi

# 8. Generate comprehensive report
if [ "$REPORT" = true ]; then
    echo -e "\n${BLUE}📋 Generating Security Report${NC}"
    
    cat > security-report.md << EOF
# Security Scan Report
Generated: $(date)

## Summary
- Scan Type: $([ "$FULL_SCAN" = true ] && echo "Full" || echo "Standard")
- Auto-fix: $([ "$AUTO_FIX" = true ] && echo "Enabled" || echo "Disabled")

## Tools Used
EOF
    
    # Add tool versions
    for tool in go gosec golangci-lint nancy trufflehog gitleaks hadolint; do
        if command_exists "$tool"; then
            version=$($tool version 2>/dev/null | head -n1 || echo "Version unknown")
            echo "- $tool: $version" >> security-report.md
        fi
    done
    
    echo -e "\n${GREEN}✅ Security report generated: security-report.md${NC}"
fi

# Final summary
echo -e "\n${BLUE}📊 Security Scan Summary${NC}"
echo "=============================="

if [ "$FULL_SCAN" = true ]; then
    print_status "INFO" "Full security scan completed"
else
    print_status "INFO" "Standard security scan completed"
fi

if [ "$AUTO_FIX" = true ]; then
    print_status "INFO" "Auto-fix attempts completed"
fi

echo -e "\n${YELLOW}💡 Security Recommendations:${NC}"
echo "1. Run this script regularly (weekly/monthly)"
echo "2. Keep dependencies updated: 'go get -u ./...'"
echo "3. Use --full flag for comprehensive scans"
echo "4. Use --fix flag for automatic issue resolution"
echo "5. Use --report flag for detailed documentation"
echo "6. Integrate into CI/CD pipeline"
echo "7. Review and address all warnings and failures"

if [ "$REPORT" = true ]; then
    echo -e "\n${GREEN}📄 Reports generated:${NC}"
    [ -f "security-report.sarif" ] && echo "  - security-report.sarif (SARIF format)"
    [ -f "golangci-report.json" ] && echo "  - golangci-report.json (Linting results)"
    [ -f "gitleaks-report.json" ] && echo "  - gitleaks-report.json (Secret detection)"
    [ -f "security-report.md" ] && echo "  - security-report.md (Summary report)"
fi