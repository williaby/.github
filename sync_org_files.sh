#!/usr/bin/env bash
# sync_org_files.sh
# Copies community files from the org-level .github repo into a downstream project.
# Usage: bash sync_org_files.sh

set -euo pipefail

# SPDX header + compliance note
read -r -d '' HEADER <<'EOF'
<!-- SPDX-FileCopyrightText: © 2019–2025 Byron Williams -->
<!-- SPDX-License-Identifier: MIT -->

> **NOTE:** This file is maintained centrally in the organization’s `.github` repository.
> For the latest version, see:
> https://github.com/williaby/.github/blob/main/{{FILE_PATH}}
EOF

# List of files to sync
FILES=(
  "CODE_OF_CONDUCT.md"
  "SECURITY.md"
  "CONTRIBUTING.md"
  "SUPPORT.md"
  "GOVERNANCE.md"
  "CODEOWNERS"
  "FUNDING.yml"
  ".github/ISSUE_TEMPLATE/bug.yml"
  ".github/ISSUE_TEMPLATE/feature.yml"
)

for f in "${FILES[@]}"; do
  org_url="https://raw.githubusercontent.com/williaby/.github/main/$f"
  echo "Generating $f from org…"
  mkdir -p "$(dirname "$f")"
  {
    # 1) SPDX header + compliance pointer
    printf "%s

" "$HEADER" | sed "s|{{FILE_PATH}}|$f|g"
    # 2) The org-level version
    curl -fsSL "$org_url"
  } > "$f"
done

echo "All files generated with SPDX headers and pointers to the org repository."
