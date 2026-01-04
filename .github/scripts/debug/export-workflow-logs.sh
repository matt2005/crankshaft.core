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
# Workflow Logs Exporter
# Purpose: Export GitHub Actions workflow run logs for analysis and debugging
#
# Usage:
#   ./export-workflow-logs.sh <RUN_ID> [OUTPUT_DIR]
#   ./export-workflow-logs.sh latest [OUTPUT_DIR]
#   ./export-workflow-logs.sh <BRANCH> [OUTPUT_DIR]
#
# Examples:
#   ./export-workflow-logs.sh 20692908702                    # Export specific run
#   ./export-workflow-logs.sh latest                         # Export latest run on current branch
#   ./export-workflow-logs.sh 003-github-actions-cicd        # Export latest run on specific branch
#   ./export-workflow-logs.sh latest ./debug-logs            # Export to custom directory
#
# Environment:
#   GH_REPO             GitHub repository (owner/repo) - auto-detected if in git repo
#

set -euo pipefail

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Colour

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
OUTPUT_DIR="${2:-./.github/debug-logs}"
RUN_IDENTIFIER="${1:-latest}"

# Ensure output directory exists
mkdir -p "${OUTPUT_DIR}"

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

# Function to check gh cli
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed or not in PATH"
        log_info "Install from: https://cli.github.com"
        exit 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI not authenticated"
        log_info "Run: gh auth login"
        exit 1
    fi
    
    log_success "GitHub CLI authenticated"
}

# Function to get run ID from identifier
get_run_id() {
    local identifier="$1"
    local run_id
    
    if [[ "$identifier" == "latest" ]]; then
        # Get latest run from current branch
        local branch
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        
        if [[ -z "$branch" ]]; then
            log_error "Not in a git repository and no branch specified"
            exit 1
        fi
        
        log_info "Getting latest run from branch: $branch"
        run_id=$(gh run list --branch "$branch" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null)
    elif [[ "$identifier" =~ ^[0-9]+$ ]]; then
        # Numeric ID - use directly
        run_id="$identifier"
        log_info "Using run ID: $run_id"
    else
        # Assume it's a branch name
        log_info "Getting latest run from branch: $identifier"
        run_id=$(gh run list --branch "$identifier" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null)
    fi
    
    if [[ -z "$run_id" ]] || [[ "$run_id" == "null" ]]; then
        log_error "Could not find workflow run"
        exit 1
    fi
    
    echo "$run_id"
}

# Function to export run details
export_run_details() {
    local run_id="$1"
    local output_file="${OUTPUT_DIR}/run-${run_id}-details.json"
    
    log_info "Exporting run details..."
    
    if gh run view "$run_id" --json status,conclusion,createdAt,updatedAt,startedAt,completedAt,name,headBranch,headSha,event --pretty >> "$output_file" 2>&1; then
        log_success "Run details exported to: $output_file"
    else
        log_warn "Could not export run details via --pretty format, trying API export..."
        
        # Try API export
        if gh api "repos/{owner}/{repo}/actions/runs/$run_id" >> "$output_file" 2>&1; then
            log_success "Run details exported (API) to: $output_file"
        else
            log_error "Failed to export run details"
            return 1
        fi
    fi
}

# Function to export jobs list
export_jobs_list() {
    local run_id="$1"
    local output_file="${OUTPUT_DIR}/run-${run_id}-jobs.json"
    
    log_info "Exporting jobs list..."
    
    if gh api "repos/{owner}/{repo}/actions/runs/$run_id/jobs" >> "$output_file" 2>&1; then
        log_success "Jobs list exported to: $output_file"
        
        # Extract failed jobs
        local failed_jobs
        failed_jobs=$(jq -r '.jobs[] | select(.conclusion == "failure") | "\(.id):\(.name)"' "$output_file" 2>/dev/null || echo "")
        
        if [[ -n "$failed_jobs" ]]; then
            log_warn "Failed jobs detected:"
            while IFS=':' read -r job_id job_name; do
                echo "  - Job ID: $job_id, Name: $job_name"
            done <<< "$failed_jobs"
        else
            log_success "All jobs passed or were skipped"
        fi
    else
        log_error "Failed to export jobs list"
        return 1
    fi
}

# Function to export logs for specific job
export_job_logs() {
    local run_id="$1"
    local job_id="$2"
    local job_name="$3"
    
    # Clean job name for filename
    local clean_name=$(echo "$job_name" | tr ' /' '_' | tr -cd '[:alnum:]._-')
    local output_file="${OUTPUT_DIR}/run-${run_id}-job-${job_id}-${clean_name}.log"
    
    log_info "Exporting logs for job: $job_name ($job_id)"
    
    if gh api "repos/{owner}/{repo}/actions/jobs/$job_id/logs" > "$output_file" 2>&1; then
        log_success "Job logs exported to: $output_file"
        
        # Analyse logs for errors
        local error_count
        error_count=$(grep -c -iE "error|failed|cannot|no such file|permission denied|not found" "$output_file" 2>/dev/null || echo "0")
        
        if [[ "$error_count" -gt 0 ]]; then
            log_warn "Found $error_count potential error patterns in logs"
        fi
    else
        log_error "Failed to export logs for job: $job_name"
        return 1
    fi
}

# Function to export all failed job logs
export_failed_job_logs() {
    local run_id="$1"
    local jobs_file="${OUTPUT_DIR}/run-${run_id}-jobs.json"
    
    # Check if jobs file exists
    if [[ ! -f "$jobs_file" ]]; then
        log_warn "Jobs file not found, skipping failed job logs export"
        return 0
    fi
    
    # Extract failed jobs
    local failed_jobs
    failed_jobs=$(jq -r '.jobs[] | select(.conclusion == "failure") | "\(.id)|\(.name)"' "$jobs_file" 2>/dev/null || echo "")
    
    if [[ -z "$failed_jobs" ]]; then
        log_success "No failed jobs to export logs for"
        return 0
    fi
    
    log_info "Exporting logs for failed jobs..."
    
    local job_count=0
    while IFS='|' read -r job_id job_name; do
        if [[ -n "$job_id" ]] && [[ -n "$job_name" ]]; then
            export_job_logs "$run_id" "$job_id" "$job_name"
            ((job_count++))
        fi
    done <<< "$failed_jobs"
    
    if [[ $job_count -gt 0 ]]; then
        log_success "Exported logs for $job_count failed job(s)"
    fi
}

# Function to generate analysis report
generate_analysis_report() {
    local run_id="$1"
    local report_file="${OUTPUT_DIR}/run-${run_id}-analysis.md"
    
    log_info "Generating analysis report..."
    
    {
        echo "# Workflow Run Analysis Report"
        echo ""
        echo "**Run ID:** \`$run_id\`"
        echo "**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo ""
        echo "## Overview"
        echo ""
        
        # Parse run details
        local details_file="${OUTPUT_DIR}/run-${run_id}-details.json"
        if [[ -f "$details_file" ]]; then
            local status
            local conclusion
            status=$(jq -r '.status // "unknown"' "$details_file" 2>/dev/null || echo "unknown")
            conclusion=$(jq -r '.conclusion // "unknown"' "$details_file" 2>/dev/null || echo "unknown")
            
            echo "- **Status:** \`$status\`"
            echo "- **Conclusion:** \`$conclusion\`"
            echo ""
        fi
        
        echo "## Job Summary"
        echo ""
        
        # Parse jobs
        local jobs_file="${OUTPUT_DIR}/run-${run_id}-jobs.json"
        if [[ -f "$jobs_file" ]]; then
            local total_jobs
            local passed_jobs
            local failed_jobs
            local skipped_jobs
            
            total_jobs=$(jq '.jobs | length' "$jobs_file" 2>/dev/null || echo "0")
            passed_jobs=$(jq '[.jobs[] | select(.conclusion == "success")] | length' "$jobs_file" 2>/dev/null || echo "0")
            failed_jobs=$(jq '[.jobs[] | select(.conclusion == "failure")] | length' "$jobs_file" 2>/dev/null || echo "0")
            skipped_jobs=$(jq '[.jobs[] | select(.conclusion == "skipped")] | length' "$jobs_file" 2>/dev/null || echo "0")
            
            echo "| Status | Count |"
            echo "|--------|-------|"
            echo "| ✓ Passed | $passed_jobs |"
            echo "| ✗ Failed | $failed_jobs |"
            echo "| ⊘ Skipped | $skipped_jobs |"
            echo "| **Total** | **$total_jobs** |"
            echo ""
            
            # List failed jobs with details
            if [[ $failed_jobs -gt 0 ]]; then
                echo "## Failed Jobs Details"
                echo ""
                
                local failed_job_details
                failed_job_details=$(jq -r '.jobs[] | select(.conclusion == "failure") | "- \(.name) (ID: \(.id))\n  - Status: \(.status)\n  - Conclusion: \(.conclusion)\n  - Logs: \(.html_url)"' "$jobs_file" 2>/dev/null)
                
                echo "$failed_job_details"
                echo ""
            fi
        fi
        
        echo "## Log Files"
        echo ""
        echo "Exported log files:"
        echo ""
        find "${OUTPUT_DIR}" -name "run-${run_id}*" -type f | sort | while read -r file; do
            echo "- \`$(basename "$file")\`"
        done
        echo ""
        
        echo "## Error Analysis"
        echo ""
        
        # Search for errors in all logs
        local error_files
        error_files=$(find "${OUTPUT_DIR}" -name "run-${run_id}-job-*-*.log" -type f 2>/dev/null)
        
        if [[ -z "$error_files" ]]; then
            echo "No job logs available for error analysis."
            echo ""
        else
            local error_patterns=(
                "error"
                "Error"
                "ERROR"
                "failed"
                "Failed"
                "FAILED"
                "cannot"
                "Cannot"
                "no such file or directory"
                "permission denied"
                "Permission denied"
                "not found"
                "Not found"
            )
            
            echo "Detected errors by pattern:"
            echo ""
            
            for pattern in "${error_patterns[@]}"; do
                local count=0
                while IFS= read -r file; do
                    local file_count
                    file_count=$(grep -c "$pattern" "$file" 2>/dev/null || echo "0")
                    count=$((count + file_count))
                done <<< "$error_files"
                
                if [[ $count -gt 0 ]]; then
                    echo "- **$pattern**: $count occurrences"
                fi
            done
            echo ""
        fi
        
        echo "## Next Steps"
        echo ""
        echo "1. Review the detailed logs in this directory"
        echo "2. Check failed job logs for specific error messages"
        echo "3. Run \`gh run view $run_id --log-failed\` for quick failed logs"
        echo "4. Visit: https://github.com/${GH_REPO:-}/actions/runs/$run_id"
        echo ""
        
    } > "$report_file"
    
    log_success "Analysis report generated: $report_file"
}

# Function to print summary
print_summary() {
    local run_id="$1"
    
    log_info "Export Summary:"
    echo ""
    echo "Output directory: ${OUTPUT_DIR}"
    echo "Files exported:"
    find "${OUTPUT_DIR}" -name "run-${run_id}*" -type f | sort | sed 's/^/  /'
    echo ""
    log_success "All logs exported successfully!"
}

# Main execution
main() {
    log_info "Workflow Logs Exporter"
    echo ""
    
    # Check gh cli
    check_gh_cli
    echo ""
    
    # Get run ID
    log_info "Resolving run identifier: $RUN_IDENTIFIER"
    local run_id
    run_id=$(get_run_id "$RUN_IDENTIFIER")
    log_success "Run ID: $run_id"
    echo ""
    
    # Export run details
    export_run_details "$run_id"
    echo ""
    
    # Export jobs list
    export_jobs_list "$run_id"
    echo ""
    
    # Export logs for failed jobs
    export_failed_job_logs "$run_id"
    echo ""
    
    # Generate analysis report
    generate_analysis_report "$run_id"
    echo ""
    
    # Print summary
    print_summary "$run_id"
}

# Run main
main
