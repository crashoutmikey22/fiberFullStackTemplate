#!/bin/bash

# Security Tools Installation Script
# This script installs all the security tools required by security.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VERBOSE=false
SKIP_GO=false
SKIP_DOCKER=false
INSTALL_ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --skip-go)
            SKIP_GO=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --all)
            INSTALL_ALL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--verbose] [--skip-go] [--skip-docker] [--all]"
            echo ""
            echo "Options:"
            echo "  --verbose       Show detailed installation output"
            echo "  --skip-go       Skip Go-based tools installation"
            echo "  --skip-docker   Skip Docker-based tools installation"
            echo "  --all           Install all available security tools"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🔒 Security Tools Installation Script${NC}"
echo "=================================="

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

# Function to run command with optional verbose output
run_command() {
    local cmd=$1
    local description=$2
    
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}Running: $cmd${NC}"
        eval "$cmd"
    else
        eval "$cmd" >/dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        print_status "PASS" "$description"
        return 0
    else
        print_status "FAIL" "$description"
        return 1
    fi
}

# Function to check and install Go
check_go() {
    if ! command_exists "go"; then
        print_status "WARN" "Go is not installed. Installing Go..."
        
        # Detect OS
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            GO_VERSION="1.21.5"
            GO_ARCH="amd64"
            
            if [ "$(uname -m)" = "aarch64" ]; then
                GO_ARCH="arm64"
            fi
            
            wget "https://golang.org/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf /tmp/go.tar.gz
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            export PATH=$PATH:/usr/local/go/bin
            rm /tmp/go.tar.gz
            
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command_exists "brew"; then
                brew install go
            else
                print_status "FAIL" "Please install Homebrew first or install Go manually from https://golang.org/dl/"
                return 1
            fi
        else
            print_status "FAIL" "Unsupported OS. Please install Go manually from https://golang.org/dl/"
            return 1
        fi
        
        print_status "PASS" "Go installed successfully"
    else
        print_status "PASS" "Go is already installed"
    fi
}

# Function to install Go-based tools
install_go_tools() {
    if [ "$SKIP_GO" = true ]; then
        print_status "INFO" "Skipping Go-based tools installation"
        return 0
    fi
    
    echo -e "\n${BLUE}🔧 Installing Go-based Security Tools${NC}"
    
    # Ensure GOPATH is set
    if [ -z "$GOPATH" ]; then
        export GOPATH="$HOME/go"
        export PATH=$PATH:$GOPATH/bin
    fi
    
    # Create GOPATH directory if it doesn't exist
    mkdir -p "$GOPATH/bin"
    
    # Install GoSec
    if ! command_exists "gosec" && ! [ -f "$HOME/go/bin/gosec" ]; then
        run_command "go install github.com/securego/gosec/v2/cmd/gosec@latest" "Installing GoSec"
    else
        print_status "PASS" "GoSec is already installed"
    fi
    
    # Install GolangCI-Lint
    if ! command_exists "golangci-lint"; then
        run_command "curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.54.2" "Installing GolangCI-Lint"
    else
        print_status "PASS" "GolangCI-Lint is already installed"
    fi
}

# Function to install Nancy (dependency vulnerability scanner)
install_nancy() {
    if [ "$SKIP_GO" = true ]; then
        print_status "INFO" "Skipping Nancy installation"
        return 0
    fi
    
    echo -e "\n${BLUE}📦 Installing Nancy (Vulnerability Scanner)${NC}"
    
    if ! command_exists "nancy"; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            NANCY_VERSION="latest"
            run_command "curl -L -o nancy https://github.com/sonatype-nexus-community/nancy/releases/download/${NANCY_VERSION}/nancy-${NANCY_VERSION}-linux-amd64" "Downloading Nancy"
            run_command "chmod +x nancy" "Making Nancy executable"
            run_command "sudo mv nancy /usr/local/bin/" "Installing Nancy to /usr/local/bin"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command_exists "brew"; then
                run_command "brew install sonatype-nexus-community/nancy/nancy" "Installing Nancy via Homebrew"
            else
                print_status "FAIL" "Please install Homebrew first or install Nancy manually"
                return 1
            fi
        fi
    else
        print_status "PASS" "Nancy is already installed"
    fi
}

# Function to install secret detection tools
install_secret_tools() {
    echo -e "\n${BLUE}🔐 Installing Secret Detection Tools${NC}"
    
    # Install TruffleHog
    if ! command_exists "trufflehog"; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            run_command "wget -O /tmp/trufflehog.tar.gz https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_Linux_x86_64.tar.gz" "Downloading TruffleHog"
            run_command "tar -xzf /tmp/trufflehog.tar.gz -C /tmp" "Extracting TruffleHog"
            run_command "sudo mv /tmp/trufflehog /usr/local/bin/" "Installing TruffleHog"
            rm /tmp/trufflehog.tar.gz
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            run_command "wget -O /tmp/trufflehog.tar.gz https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_Mac_x86_64.tar.gz" "Downloading TruffleHog"
            run_command "tar -xzf /tmp/trufflehog.tar.gz -C /tmp" "Extracting TruffleHog"
            run_command "sudo mv /tmp/trufflehog /usr/local/bin/" "Installing TruffleHog"
            rm /tmp/trufflehog.tar.gz
        fi
    else
        print_status "PASS" "TruffleHog is already installed"
    fi
    
    # Install GitLeaks
    if ! command_exists "gitleaks"; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            GITLEAKS_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": ?"v?([^"]+).*/\1/')
            run_command "wget -O /tmp/gitleaks.tar.gz https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" "Downloading GitLeaks"
            run_command "tar -xzf /tmp/gitleaks.tar.gz -C /tmp" "Extracting GitLeaks"
            run_command "sudo mv /tmp/gitleaks /usr/local/bin/" "Installing GitLeaks"
            rm /tmp/gitleaks.tar.gz
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command_exists "brew"; then
                run_command "brew install gitleaks" "Installing GitLeaks via Homebrew"
            else
                GITLEAKS_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": ?"v?([^"]+).*/\1/')
                run_command "wget -O /tmp/gitleaks.tar.gz https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_${GITLEAKS_VERSION}_darwin_x64.tar.gz" "Downloading GitLeaks"
                run_command "tar -xzf /tmp/gitleaks.tar.gz -C /tmp" "Extracting GitLeaks"
                run_command "sudo mv /tmp/gitleaks /usr/local/bin/" "Installing GitLeaks"
                rm /tmp/gitleaks.tar.gz
            fi
        fi
    else
        print_status "PASS" "GitLeaks is already installed"
    fi
}

# Function to install Docker tools
install_docker_tools() {
    if [ "$SKIP_DOCKER" = true ]; then
        print_status "INFO" "Skipping Docker-based tools installation"
        return 0
    fi
    
    echo -e "\n${BLUE}🐳 Installing Docker Security Tools${NC}"
    
    # Install Hadolint
    if ! command_exists "hadolint"; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            HADOLINT_VERSION=$(curl -s https://api.github.com/repos/hadolint/hadolint/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": ?"v?([^"]+).*/\1/')
            run_command "wget -O /tmp/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64" "Downloading Hadolint"
            run_command "chmod +x /tmp/hadolint" "Making Hadolint executable"
            run_command "sudo mv /tmp/hadolint /usr/local/bin/" "Installing Hadolint"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command_exists "brew"; then
                run_command "brew install hadolint" "Installing Hadolint via Homebrew"
            else
                HADOLINT_VERSION=$(curl -s https://api.github.com/repos/hadolint/hadolint/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": ?"v?([^"]+).*/\1/')
                run_command "wget -O /tmp/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Darwin-x86_64" "Downloading Hadolint"
                run_command "chmod +x /tmp/hadolint" "Making Hadolint executable"
                run_command "sudo mv /tmp/hadolint /usr/local/bin/" "Installing Hadolint"
            fi
        fi
    else
        print_status "PASS" "Hadolint is already installed"
    fi
    
    # Check Docker
    if ! command_exists "docker"; then
        print_status "WARN" "Docker is not installed. Docker Scout will not be available."
        print_status "INFO" "Install Docker from: https://docs.docker.com/get-docker/"
    else
        print_status "PASS" "Docker is already installed"
    fi
}

# Function to install additional security tools
install_additional_tools() {
    if [ "$INSTALL_ALL" = false ]; then
        return 0
    fi
    
    echo -e "\n${BLUE}🛡️ Installing Additional Security Tools${NC}"
    
    # Install semgrep (if requested)
    if ! command_exists "semgrep"; then
        run_command "python3 -m pip install semgrep" "Installing Semgrep"
    else
        print_status "PASS" "Semgrep is already installed"
    fi
    
    # Install bandit (Python security linter)
    if ! command_exists "bandit"; then
        run_command "python3 -m pip install bandit" "Installing Bandit"
    else
        print_status "PASS" "Bandit is already installed"
    fi
    
    # Install safety (Python dependency scanner)
    if ! command_exists "safety"; then
        run_command "python3 -m pip install safety" "Installing Safety"
    else
        print_status "PASS" "Safety is already installed"
    fi
}

# Function to verify installations
verify_installations() {
    echo -e "\n${BLUE}🔍 Verifying Installations${NC}"
    
    local tools=("go" "gosec" "golangci-lint" "nancy" "trufflehog" "gitleaks" "hadolint")
    local installed=0
    local total=${#tools[@]}
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool" || ([ "$tool" = "gosec" ] && [ -f "$HOME/go/bin/gosec" ]); then
            print_status "PASS" "$tool is installed"
            ((installed++))
        else
            print_status "FAIL" "$tool is not installed"
        fi
    done
    
    echo -e "\n${BLUE}📊 Installation Summary${NC}"
    echo "=============================="
    echo "Installed: $installed/$total tools"
    
    if [ $installed -eq $total ]; then
        print_status "PASS" "All security tools installed successfully!"
        echo -e "\n${GREEN}🎉 You can now run: ./cmds/security.sh${NC}"
    else
        print_status "WARN" "Some tools failed to install. Check the output above."
        echo -e "\n${YELLOW}💡 You can still run: ./cmds/security.sh --bypass${NC}"
    fi
}

# Main installation flow
main() {
    # Check for required dependencies
    if ! command_exists "curl"; then
        print_status "FAIL" "curl is required but not installed"
        exit 1
    fi
    
    if ! command_exists "wget"; then
        print_status "FAIL" "wget is required but not installed"
        exit 1
    fi
    
    # Check and install Go if needed
    if [ "$SKIP_GO" = false ]; then
        check_go
    fi
    
    # Install tool categories
    install_go_tools
    install_nancy
    install_secret_tools
    install_docker_tools
    install_additional_tools
    
    # Verify installations
    verify_installations
    
    echo -e "\n${YELLOW}💡 Next Steps:${NC}"
    echo "1. Run security scan: ./cmds/security.sh"
    echo "2. Generate reports: ./cmds/security.sh --report"
    echo "3. Auto-fix issues: ./cmds/security.sh --fix"
    echo "4. Full scan: ./cmds/security.sh --full"
    echo "5. Add to CI/CD: ./cmds/security.sh --full --report"
}

# Run main function
main "$@"
