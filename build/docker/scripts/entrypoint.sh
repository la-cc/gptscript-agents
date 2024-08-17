#!/bin/bash

# Function to download files if OUTSIDE_AGENTS_FILES is set
download_outside_agent_files() {
    if [ -n "$OUTSIDE_AGENTS_FILES" ]; then
        IFS=',' read -ra URLS <<<"$OUTSIDE_AGENTS_FILES"
        for url in "${URLS[@]}"; do
            echo "Downloading agent file from $url..."
            curl -o /home/agentuser/gpt-agents/$(basename $url) "$url"
        done
    fi
}

# Download the outside agent files if specified
download_outside_agent_files

# Run the gptscript command with the specified parameters
gptscript --disable-cache /home/agentuser/gpt-agents/$AGENT_FILE "$COMMAND_STRING"
