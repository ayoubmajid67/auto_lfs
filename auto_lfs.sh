#!/bin/bash

# Define the size limit (100MB)
SIZE_LIMIT="100M"

# 1. Get the target directory from the first argument
if [ -n "$1" ]; then
    # Check if directory exists
    if [ -d "$1" ]; then
        # Resolve to absolute path
        TARGET_DIR=$(cd "$1" && pwd)
    else
        echo "❌ Error: Directory '$1' does not exist."
        exit 1
    fi
else
    # Default to current directory
    TARGET_DIR=$(pwd)
fi

echo "🔍 Scanning '$TARGET_DIR' for files larger than $SIZE_LIMIT (ignoring .git)..."
echo "📂 Updating .gitattributes in: $TARGET_DIR/.gitattributes"

# Ensure .gitattributes exists in the TARGET directory
touch "$TARGET_DIR/.gitattributes"

# Find files larger than 100MB in the TARGET directory
find "$TARGET_DIR" -name ".git" -prune -o -type f -size +$SIZE_LIMIT -print | while read -r file; do
    
    # Calculate relative path from TARGET_DIR to the file
    # We use python for reliable cross-platform relative path calculation
    relative_path=$(python -c "import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]).replace(os.sep, '/'))" "$file" "$TARGET_DIR")
    
    # Check if the file is already in the target .gitattributes
    if grep -Fq "$relative_path" "$TARGET_DIR/.gitattributes"; then
        echo "✅ Already tracked: $relative_path"
    else
        echo "➕ Adding: $relative_path"
        # Append to the target .gitattributes
        echo "$relative_path filter=lfs diff=lfs merge=lfs -text" >> "$TARGET_DIR/.gitattributes"
        
        # Try to register with git lfs by changing directory to the target
        # This ensures 'git lfs track' modifies the correct .gitattributes if git is initialized
        (cd "$TARGET_DIR" && git lfs track "$relative_path" > /dev/null 2>&1)
    fi
done

echo "---------------------------------------------------"
echo "🎉 Scan complete!" 
echo "Please verify changes in: $TARGET_DIR/.gitattributes"
if [ -d "$TARGET_DIR/.git" ] || git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "To commit changes, run:"
    echo "  cd \"$TARGET_DIR\""
    echo "  git add .gitattributes"
    echo "  git add ."
fi

# alias auto_lfs='/e/vs-code/intellcap/erp-solutions-services/ERP-SOLUTIONS-CVS-SERVICE-DATA-AI/auto_lfs.sh'