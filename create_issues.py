#!/usr/bin/env python3
"""
Script to create GitHub issues from ISSUES.md file
Requires: requests library and GitHub token
"""

import requests
import json
import re
import os
import sys

# GitHub API configuration
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
REPO_OWNER = 'zhefano'
REPO_NAME = 'hellotetris'
API_BASE = f'https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}'

def parse_issues_file(filename):
    """Parse ISSUES.md file and extract issue data"""
    with open(filename, 'r') as f:
        content = f.read()
    
    issues = []
    issue_blocks = content.split('---\n')
    
    for block in issue_blocks:
        if not block.strip():
            continue
            
        issue = {}
        
        # Extract title
        title_match = re.search(r'\*\*Title\*\*: (.+)', block)
        if title_match:
            issue['title'] = title_match.group(1).strip()
        
        # Extract type
        type_match = re.search(r'\*\*Type\*\*: (.+)', block)
        if type_match:
            issue['type'] = type_match.group(1).strip()
        
        # Extract priority
        priority_match = re.search(r'\*\*Priority\*\*: (.+)', block)
        if priority_match:
            issue['priority'] = priority_match.group(1).strip()
        
        # Extract labels
        labels_match = re.search(r'\*\*Labels\*\*: (.+)', block)
        if labels_match:
            labels_str = labels_match.group(1).strip()
            issue['labels'] = [label.strip() for label in labels_str.split(',')]
        
        # Extract description
        desc_match = re.search(r'### Description\n(.+?)(?=\n###|\n---|\Z)', block, re.DOTALL)
        if desc_match:
            issue['description'] = desc_match.group(1).strip()
        
        # Extract problem statement
        problem_match = re.search(r'### Problem Statement\n(.+?)(?=\n###|\n---|\Z)', block, re.DOTALL)
        if problem_match:
            issue['problem'] = problem_match.group(1).strip()
        
        # Extract proposed solution
        solution_match = re.search(r'### Proposed Solution\n(.+?)(?=\n###|\n---|\Z)', block, re.DOTALL)
        if solution_match:
            issue['solution'] = solution_match.group(1).strip()
        
        # Extract implementation ideas
        impl_match = re.search(r'### Implementation Ideas\n(.+?)(?=\n###|\n---|\Z)', block, re.DOTALL)
        if impl_match:
            issue['implementation'] = impl_match.group(1).strip()
        
        if issue.get('title'):
            issues.append(issue)
    
    return issues

def create_issue_body(issue):
    """Create GitHub issue body from issue data"""
    body_parts = []
    
    if issue.get('description'):
        body_parts.append(f"## Feature Description\n{issue['description']}")
    
    if issue.get('problem'):
        body_parts.append(f"## Problem Statement\n{issue['problem']}")
    
    if issue.get('solution'):
        body_parts.append(f"## Proposed Solution\n{issue['solution']}")
    
    if issue.get('implementation'):
        body_parts.append(f"## Implementation Ideas\n{issue['implementation']}")
    
    return '\n\n'.join(body_parts)

def create_github_issue(issue_data):
    """Create issue on GitHub"""
    headers = {
        'Authorization': f'token {GITHUB_TOKEN}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json'
    }
    
    payload = {
        'title': issue_data['title'],
        'body': create_issue_body(issue_data),
        'labels': issue_data.get('labels', [])
    }
    
    response = requests.post(f'{API_BASE}/issues', headers=headers, json=payload)
    
    if response.status_code == 201:
        issue_url = response.json()['html_url']
        print(f"✅ Created issue: {issue_data['title']} - {issue_url}")
        return True
    else:
        print(f"❌ Failed to create issue: {issue_data['title']}")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return False

def main():
    if not GITHUB_TOKEN:
        print("❌ Error: GITHUB_TOKEN environment variable not set")
        print("Please set your GitHub Personal Access Token:")
        print("export GITHUB_TOKEN=your_token_here")
        sys.exit(1)
    
    if not os.path.exists('ISSUES.md'):
        print("❌ Error: ISSUES.md file not found")
        sys.exit(1)
    
    print("📋 Parsing ISSUES.md file...")
    issues = parse_issues_file('ISSUES.md')
    
    print(f"📝 Found {len(issues)} issues to create")
    
    success_count = 0
    for i, issue in enumerate(issues, 1):
        print(f"\n🔄 Creating issue {i}/{len(issues)}: {issue['title']}")
        if create_github_issue(issue):
            success_count += 1
    
    print(f"\n🎉 Successfully created {success_count}/{len(issues)} issues!")

if __name__ == '__main__':
    main() 