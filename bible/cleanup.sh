#!/bin/bash

# Set this to your Bible folder (update as needed)
BIBLE_DIR="."

# Loop over every markdown file in subfolders
find "$BIBLE_DIR" -type f -name "*.md" | while read -r file; do
    tmpfile=$(mktemp)

    echo "Processing $file..."

    awk '
    BEGIN {
        verse = ""
        num = ""
    }
    /^######[[:space:]]+[0-9]+/ {
        # If we were in a verse, print the previous one
        if (num != "") {
            gsub(/^[[:space:]]+/, "", verse)
            print num " " verse
        }
        num = $2
        verse = ""
        next
    }
    /^cssClasses:/ || /^---/ {
        next
    }
    /^#/ || /^\[\[.*\]\]/ {
        print $0
        next
    }
    {
        verse = verse " " $0
    }
    END {
        if (num != "") {
            gsub(/^[[:space:]]+/, "", verse)
            print num " " verse
        }
    }' "$file" > "$tmpfile"

    mv "$tmpfile" "$file"
done

