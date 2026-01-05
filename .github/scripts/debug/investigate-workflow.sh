#!/bin/bash
# Project: Crankshaft
# This file is part of Crankshaft project.
# Copyright (C) 2025 OpenCarDev Team
#
#  Crankshaft is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Crankshaft is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Crankshaft. If not, see <http://www.gnu.org/licenses/>.

#
# Workflow Investigation Tool
# Purpose: Investigate and diagnose GitHub Actions workflow failures using gh cli
#
# Usage:
#   ./investigate-workflow.sh [RUN_ID] [--verbose] [--export] [--fix]
#   ./investigate-workflow.sh                      # Diagnose latest run on current branch
#   ./investigate-workflow.sh 20692908702          # Diagnose specific run
#   ./investigate-workflow.sh latest --verbose     # Verbose output
#   ./investigate-workflow.sh latest --export      # Export logs and generate report
#   ./investigate-workflow.sh latest --fix         # Auto-fix common issues
#
# Options:
#   --verbose           Show detailed output from gh cli commands
#   --export            Export logs and generate analysis report
#   --fix               Attempt to auto-fix common issues (requires local repo access)
#   --help              Show this help message
#

set -euo pipefail

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Colour

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
RUN_ID="${1:-latest}"
VERBOSE=false
EXPORT_LOGS=false
AUTO_FIX=false

# Parse options
while [[ $# -gt 1 ]]; do
    case "${2}" in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --export)
            EXPORT_LOGS=true
            shift
            ;;
        --fix)
            AUTO_FIX=true
            shift
            ;;
        --help)
            sed -n '/^#/p' "$0" | head -30
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Function to print coloured output
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

log_title() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}${*}${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_section() {
    echo ""
    echo -e "${CYAN}▶ $*${NC}"
    echo ""
}

# Function to check gh cli
check_gh_cli() {
    log_section "Checking GitHub CLI"
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        log_info "Install from: https://cli.github.com"
        exit 1
    fi
    log_success "GitHub CLI found"
    
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI not authenticated"
        log_info "Run: gh auth login"
        exit 1
    fi
    log_success "GitHub CLI authenticated"
}

# Function to resolve run ID
resolve_run_id() {
    log_section "Resolving Run ID"
    
    local identifier="$1"
    local run_id
    
    if [[ "$identifier" == "latest" ]]; then
        local branch
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        
        if [[ -z "$branch" ]]; then
            log_error "Not in a git repo and no explicit run ID provided"
            exit 1
        fi
        
        log_info "Getting latest run from branch: $branch"
        
        if [[ "$VERBOSE" == "true" ]]; then
            run_id=$(gh run list --branch "$branch" --limit 1 --json databaseId --jq '.[0].databaseId')
        else
            run_id=$(gh run list --branch "$branch" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null)
        fi
    elif [[ "$identifier" =~ ^[0-9]+$ ]]; then
        run_id="$identifier"
    else
        log_error "Invalid run ID: $identifier"
        exit 1
    fi
    
    if [[ -z "$run_id" ]] || [[ "$run_id" == "null" ]]; then
        log_error "Could not resolve run ID"
        exit 1
    fi
    
    log_success "Run ID: $run_id"
    echo "$run_id"
}

# Function to get run status
get_run_status() {
    local run_id="$1"
    
    log_section "Workflow Run Status"
    
    local status_output
    status_output=$(gh api "repos/{owner}/{repo}/actions/runs/$run_id" --jq '{status: .status, conclusion: .conclusion, created_at: .created_at, updated_at: .updated_at, head_branch: .head_branch, event: .event}')
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "$status_output" | jq .
    fi
    
    local status
    local conclusion
    status=$(echo "$status_output" | jq -r '.status')
    conclusion=$(echo "$status_output" | jq -r '.conclusion')
    
    case "$conclusion" in
        "success")
            log_success "Run completed successfully"
            ;;
        "failure")
            log_error "Run failed"
            ;;
        "neutral")
            log_warn "Run concluded neutrally"
            ;;
        "cancelled")
            log_warn "Run was cancelled"
            ;;
        "timed_out")
            log_error "Run timed out"
            ;;
        "action_required")
            log_warn "Action required"
            ;;
        null)
            log_info "Run status: $status (not completed)"
            ;;
        *)
            log_info "Run conclusion: $conclusion"
            ;;
    esac
}

# Function to analyse failed jobs
analyse_failed_jobs() {
    local run_id="$1"
    
    log_section "Analysing Failed Jobs"
    
    local jobs_data
    jobs_data=$(gh api "repos/{owner}/{repo}/actions/runs/$run_id/jobs" --jq '.jobs[] | select(.conclusion != "success" and .conclusion != null and .conclusion != "skipped")')
    
    if [[ -z "$jobs_data" ]]; then
        log_success "No failed jobs detected"
        return 0
    fi
    
    local failed_count
    failed_count=$(echo "$jobs_data" | jq -s 'length')
    
    log_warn "Found $failed_count failed/incomplete job(s)"
    echo ""
    
    echo "$jobs_data" | jq -r '"  Job: \(.name) (ID: \(.id))\n    Status: \(.status), Conclusion: \(.conclusion)\n    URL: \(.html_url)"' | while read -r line; do
        echo "$line"
    done
}

# Function to get detailed error info from logs
get_error_details() {
    local run_id="$1"
    
    log_section "Extracting Error Information"
    
    # Get all jobs
    local jobs_data
    jobs_data=$(gh api "repos/{owner}/{repo}/actions/runs/$run_id/jobs" --jq '.jobs[] | select(.conclusion == "failure")')
    
    if [[ -z "$jobs_data" ]]; then
        log_info "No failed jobs to analyse"
        return 0
    fi
    
    local job_count=0
    
    echo "$jobs_data" | jq -r '.id' | while read -r job_id; do
        ((job_count++))
        
        local job_name
        job_name=$(echo "$jobs_data" | jq -r "select(.id == $job_id) | .name")
        
        log_info "Getting logs for: $job_name"
        
        local logs
        if logs=$(gh api "repos/{owner}/{repo}/actions/jobs/$job_id/logs" 2>&1); then
            # Extract last error context (last 20 lines with errors)
            local errors
            errors=$(echo "$logs" | grep -iE 'error|Error|ERROR|failed|Failed|FAILED|cannot|Cannot|permission denied|not found|no such' | tail -15)
            
            if [[ -n "$errors" ]]; then
                echo ""
                log_warn "Error messages from: $job_name"
                echo "$errors" | sed 's/^/    /'
            fi
        else
            log_warn "Could not retrieve logs for job: $job_name"
        fi
    done
}

# Function to suggest fixes
suggest_fixes() {
    local run_id="$1"
    
    log_section "Suggested Fixes"
    
    # Try to detect common issues
    local jobs_data
    jobs_data=$(gh api "repos/{owner}/{repo}/actions/runs/$run_id/jobs")
    
    local failed_jobs
    failed_jobs=$(echo "$jobs_data" | jq -r '.jobs[] | select(.conclusion == "failure") | .name' | head -5)
    
    if [[ -z "$failed_jobs" ]]; then
        log_success "No failed jobs to fix"
        return 0
    fi
    
    # Common issue detection
    if echo "$failed_jobs" | grep -q "code-quality\|Quality\|Lint\|Format"; then
        log_warn "Quality check failure detected"
        echo "  1. Run locally: ./scripts/format.sh"
        echo "  2. Check formatting: ./scripts/format_cpp.sh check"
        echo "  3. Run linters: ./scripts/lint_cpp.sh clang-tidy"
        echo "  4. Commit and push fixes"
    fi
    
    if echo "$failed_jobs" | grep -q "build\|Build\|cmake\|CMake"; then
        log_warn "Build failure detected"
        echo "  1. Check CMakeLists.txt for syntax errors"
        echo "  2. Verify dependencies are installed"
        echo "  3. Try local build: ./scripts/build.sh --build-type Debug"
        echo "  4. Review error logs above for specific issues"
    fi
    
    if echo "$failed_jobs" | grep -q "test\|Test\|TEST"; then
        log_warn "Test failure detected"
        echo "  1. Run tests locally: ./scripts/build.sh --component tests"
        echo "  2. Review test output for failures"
        echo "  3. Fix failing tests"
        echo "  4. Re-run: ctest --test-dir build --output-on-failure"
    fi
    
    if echo "$failed_jobs" | grep -q "Permission denied\|permission denied"; then
        log_warn "Permission denied error"
        echo "  1. Check script execute bits: git ls-files -s | grep 100644"
        echo "  2. Fix: git update-index --chmod=+x scripts/*.sh"
        echo "  3. Commit: git add . && git commit -m 'fix: Make scripts executable'"
    fi
}

# Function to export logs
export_logs_for_run() {
    local run_id="$1"
    
    log_section "Exporting Logs"
    
    local export_script="${SCRIPT_DIR}/export-workflow-logs.sh"
    
    if [[ ! -f "$export_script" ]]; then
        log_warn "Export script not found at: $export_script"
        return 1
    fi
    
    log_info "Running: $export_script $run_id"
    bash "$export_script" "$run_id"
}

# Function to auto-fix common issues
auto_fix_issues() {
    log_section "Auto-Fix Common Issues"
    
    local fixed=false
    
    # Check for script permissions
    log_info "Checking script execute bits..."
    if git ls-files -s scripts/*.sh 2>/dev/null | grep -q '100644'; then
        log_warn "Found scripts without execute bit"
        
        if [[ "$AUTO_FIX" == "true" ]]; then
            log_info "Fixing script permissions..."
            git update-index --chmod=+x scripts/*.sh .github/scripts/**/*.sh 2>/dev/null || true
            log_success "Script permissions fixed"
            fixed=true
        fi
    else
        log_success "Script permissions are correct"
    fi
    
    # Check for unformatted code
    log_info "Checking code formatting..."
    if ! ./scripts/format_cpp.sh check &>/dev/null; then
        log_warn "Found formatting issues"
        
        if [[ "$AUTO_FIX" == "true" ]]; then
            log_info "Fixing formatting..."
            ./scripts/format.sh
            log_success "Code formatting fixed"
            fixed=true
        fi
    else
        log_success "Code formatting is correct"
    fi
    
    if [[ "$fixed" == "true" ]]; then
        log_info "Fixed issues - commit changes with: git add . && git commit -m 'fix: Resolve workflow issues'"
    fi
}

# Main execution
main() {
    log_title "Workflow Investigation Tool"
    
    # Check prerequisites
    check_gh_cli
    
    # Resolve run ID
    local run_id
    run_id=$(resolve_run_id "$RUN_ID")
    
    # Get run status
    get_run_status "$run_id"
    
    # Analyse failed jobs
    analyse_failed_jobs "$run_id"
    
    # Get error details
    get_error_details "$run_id"
    
    # Suggest fixes
    suggest_fixes "$run_id"
    
    # Export logs if requested
    if [[ "$EXPORT_LOGS" == "true" ]]; then
        export_logs_for_run "$run_id"
    fi
    
    # Auto-fix if requested
    if [[ "$AUTO_FIX" == "true" ]]; then
        auto_fix_issues
    fi
    
    log_title "Investigation Complete"
    
    log_info "Next steps:"
    echo "  1. Review the error information above"
    echo "  2. Apply suggested fixes or manual corrections"
    echo "  3. Test locally: ./scripts/build.sh && ctest"
    echo "  4. Commit and push changes"
    echo "  5. Run investigation again with: ./.github/scripts/debug/investigate-workflow.sh latest"
    echo ""
    log_info "For more details, run with: --export flag to generate full analysis report"
    echo "   ./.github/scripts/debug/investigate-workflow.sh $run_id --export"
}

# Run main
main
