# First stage: Install tools as root
FROM python:3.11-alpine as builder

LABEL maintainer="la-cc@github"
LABEL org.opencontainers.image.source="https://github.com/la-cc/gptscript-agents"
LABEL email="artem@lajko.dev"

# Install build dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    openssh-client && apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    python3-dev \
    cargo

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Install helm
RUN curl -LO https://get.helm.sh/helm-v3.10.0-linux-amd64.tar.gz && \
    tar -zxvf helm-v3.10.0-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 helm-v3.10.0-linux-amd64.tar.gz

# Install GPTScript (the script handles placing the binary in /usr/local/bin)
RUN curl https://get.gptscript.ai/install.sh | sh

# Second stage: Setup with non-root user
FROM python:3.11-alpine

# Metadata as defined in OCI image spec annotations
LABEL maintainer="la-cc@github"
LABEL org.opencontainers.image.source="https://github.com/la-cc/gptscript-agents"
LABEL email="artem@lajko.dev"

# Set environment variables
ENV GPTSCRIPT_DEFAULT_MODEL="gpt-4o"
ENV OPENAI_BASE_URL=""
ENV OPENAI_API_KEY=""
ENV AGENT_FILE="simple-cli-agent.gpt"
ENV COMMAND_STRING=""
ENV GPTSCRIPT_CACHE_DIR="/home/agentuser/.cache/gptscript"
ENV GPTSCRIPT_CONFIG="/home/agentuser/.config/gptscript/config.yaml"
ENV GPTSCRIPT_WORKSPACE="/home/agentuser/workspace"
ENV OUTSIDE_AGENTS_FILES=""

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    libstdc++ \
    libgcc \
    openssh-client

# Copy installed binaries and libraries from the builder stage
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/gptscript /usr/local/bin/gptscript

# Create a non-root user 'agentuser' with specific UID and GID
RUN addgroup -g 1000 agentuser && adduser -u 1000 -G agentuser -S agentuser

# Create necessary directories with appropriate permissions
RUN mkdir -p $GPTSCRIPT_CACHE_DIR $GPTSCRIPT_WORKSPACE /home/agentuser/.config/gptscript && \
    chown -R agentuser:agentuser $GPTSCRIPT_CACHE_DIR $GPTSCRIPT_WORKSPACE /home/agentuser/.config/gptscript

# Ensure all directories under /home/agentuser are owned by the non-root user
RUN chown -R agentuser:agentuser /home/agentuser

# Set work directory and switch to non-root user
WORKDIR /home/agentuser

# Copy agent files and scripts, and change ownership
COPY /gpt-agents/ /home/agentuser/gpt-agents
COPY /build/docker/scripts/entrypoint.sh /home/agentuser/entrypoint.sh
RUN chown -R agentuser:agentuser /home/agentuser/gpt-agents /home/agentuser/entrypoint.sh

USER agentuser

# Set the entrypoint script
ENTRYPOINT ["/bin/bash", "/home/agentuser/entrypoint.sh"]
