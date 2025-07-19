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
import getpass

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

def create_github_issue(issue_data, token):
    """Create issue on GitHub"""
    headers = {
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json'
    }
    
    payload = {
        'title': issue_data['title'],
        'body': create_issue_body(issue_data),
        'labels': issue_data.get('labels', [])
    }
    
    try:
        response = requests.post(f'{API_BASE}/issues', headers=headers, json=payload, timeout=30)
        
        if response.status_code == 201:
            issue_url = response.json()['html_url']
            print(f"✅ Created issue: {issue_data['title']} - {issue_url}")
            return True
        else:
            print(f"❌ Failed to create issue: {issue_data['title']}")
            print(f"Status: {response.status_code}")
            if response.status_code == 401:
                print("Authentication failed. Please check your GitHub token.")
            elif response.status_code == 403:
                print("Permission denied. Please check your token has 'repo' permissions.")
            else:
                print(f"Response: {response.text}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Network error creating issue: {issue_data['title']}")
        print(f"Error: {e}")
        return False

def main():
    # Get token securely
    token = GITHUB_TOKEN
    if not token:
        print("🔐 GitHub Token Required")
        print("=======================")
        print("For security, please enter your GitHub Personal Access Token.")
        print("The token will NOT be saved or logged.")
        print("")
        token = getpass.getpass("Enter your GitHub token: ")
    
    if not token:
        print("❌ No token provided. Exiting.")
        sys.exit(1)
    
    # Validate token format (basic check)
    if len(token) < 20:
        print("❌ Token appears to be too short. Please check your GitHub Personal Access Token.")
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
        if create_github_issue(issue, token):
            success_count += 1
    
    print(f"\n🎉 Successfully created {success_count}/{len(issues)} issues!")
    
    # Clear token from memory
    token = None

if __name__ == '__main__':
    main() 