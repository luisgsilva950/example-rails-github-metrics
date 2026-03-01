#!/usr/bin/env bash
#
# Push this repository to GitHub (Luisgsilva950/example-rails-github-metrics)
#
# Usage:
#   ./script/push_to_github.sh
#
# Prerequisites:
#   - git installed
#   - GitHub CLI (gh) installed and authenticated: brew install gh && gh auth login
#     OR a GitHub personal access token configured for HTTPS
#
set -euo pipefail

REPO_NAME="example-rails-github-metrics"
GITHUB_USER="Luisgsilva950"
REMOTE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
BRANCH="main"

echo "==> Checking for GitHub CLI..."
if ! command -v gh &> /dev/null; then
  echo "ERROR: GitHub CLI (gh) not found. Install it with: brew install gh"
  exit 1
fi

echo "==> Checking GitHub authentication..."
if ! gh auth status &> /dev/null; then
  echo "ERROR: Not authenticated. Run: gh auth login"
  exit 1
fi

echo "==> Checking if repository ${GITHUB_USER}/${REPO_NAME} exists..."
if ! gh repo view "${GITHUB_USER}/${REPO_NAME}" &> /dev/null; then
  echo "==> Repository not found. Creating public repository..."
  gh repo create "${REPO_NAME}" --public --source=. --remote=origin --push
  echo "==> Done! Repository created and code pushed."
  echo "    https://github.com/${GITHUB_USER}/${REPO_NAME}"
  exit 0
fi

echo "==> Repository exists. Configuring remote..."
if git remote get-url origin &> /dev/null; then
  CURRENT_REMOTE=$(git remote get-url origin)
  if [ "$CURRENT_REMOTE" != "$REMOTE_URL" ]; then
    echo "    Updating origin from ${CURRENT_REMOTE} to ${REMOTE_URL}"
    git remote set-url origin "$REMOTE_URL"
  fi
else
  git remote add origin "$REMOTE_URL"
fi

echo "==> Ensuring we are on branch ${BRANCH}..."
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
  git checkout -B "$BRANCH"
fi

echo "==> Pushing to origin/${BRANCH}..."
git push -u origin "$BRANCH"

echo "==> Done!"
echo "    https://github.com/${GITHUB_USER}/${REPO_NAME}"
