#!/bin/bash
# Install custom skills globally by symlinking each skill folder to ~/.claude/skills/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

echo "Installing skills from $REPO_DIR to $SKILLS_DIR"

for skill_dir in "$REPO_DIR"/*/; do
    # The glob leaves a trailing slash, which would never match readlink below
    skill_dir="${skill_dir%/}"
    skill_name=$(basename "$skill_dir")

    # Skip non-skill directories
    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
        continue
    fi

    link_target="$SKILLS_DIR/$skill_name"

    # Remove existing symlink if it points elsewhere
    if [[ -L "$link_target" && "$(readlink "$link_target")" != "$skill_dir" ]]; then
        echo "  Removing old symlink: $link_target"
        rm "$link_target"
    fi

    # A real directory is an old copy; leave it for the user rather than delete it
    if [[ -e "$link_target" && ! -L "$link_target" ]]; then
        echo "  ! $skill_name: $link_target is a copy, not a symlink. Remove it and re-run to install."
        continue
    fi

    # Create symlink if it doesn't exist
    if [[ ! -e "$link_target" ]]; then
        ln -s "$skill_dir" "$link_target"
        echo "  ✓ $skill_name"
    else
        echo "  → $skill_name (already installed)"
    fi
done

echo "Done. Skills installed to $SKILLS_DIR"