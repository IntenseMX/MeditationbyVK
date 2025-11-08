#!/bin/bash
# Session end hook - logs your progress when Claude Code session ends

# Check for session note
if [ -f .session-note ]; then
    NOTE=$(cat .session-note)
    rm .session-note
else
    NOTE=""
fi

if [ -n "$(git status --porcelain)" ]; then
    # WORK SESSION - You made changes
    echo "" >> dev-log.md
    echo "## 🔨 $(date '+%Y-%m-%d %H:%M')" >> dev-log.md
    
    # Calculate duration if we have start time
    if [ -f .session-start-time ]; then
        START=$(cat .session-start-time)
        END=$(date +%s)
        DURATION=$((END - START))
        HOURS=$((DURATION / 3600))
        MINUTES=$(((DURATION % 3600) / 60))
        echo "**Duration:** ${HOURS}h ${MINUTES}m" >> dev-log.md
        rm .session-start-time
    fi
    
    # Add note if exists
    if [ -n "$NOTE" ]; then
        echo "_${NOTE}_" >> dev-log.md
    fi
    
    # Show what changed
    echo "### Changes:" >> dev-log.md
    git diff --stat | head -5 >> dev-log.md
    echo "---" >> dev-log.md
else
    # READ SESSION - only log if there's a note
    if [ -n "$NOTE" ]; then
        echo "📖 $(date '+%m/%d %H:%M') - ${NOTE}" >> dev-log.md
    fi
    [ -f .session-start-time ] && rm .session-start-time
fi