# First stage: Install tools as root
FROM python:3.11-alpine as builder

LABEL MAINTAINER="la-cc@github"
LABEL org.opencontainers.image.source="https://github.com/la-cc/k8s-pg-to-s3-cronjob"
LABEL EMAIL="artem@lajko.dev"

# Install build dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    && apk add --no-cache --virtual .build-deps \
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

# Install GPTScript
RUN curl https://get.gptscript.ai/install.sh | sh && \
    mkdir -p /.cache && chmod 777 /.cache

# Second stage: Setup with non-root user
FROM python:3.11-alpine

# Metadata as defined in OCI image spec annotations
LABEL MAINTAINER="la-cc@github"
LABEL org.opencontainers.image.source="https://github.com/la-cc/k8s-pg-to-s3-cronjob"
LABEL EMAIL="artem@lajko.dev"

# Set environment variables
ENV MODEL="gpt-4-turbo"
ENV OPENAI_BASE_URL=""
ENV OPENAI_API_KEY=""
ENV MERGED_AGENT_FILE="simple-cli-agent.gpt"
ENV COMMAND_STRING=""

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    libstdc++ \
    libgcc

# Copy installed binaries and libraries from the builder stage
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/gptscript /usr/local/bin/gptscript
COPY --from=builder /.cache /.cache

# Create a non-root user 'agentuser'
RUN addgroup -S agentuser && adduser -S agentuser -G agentuser

# Set work directory and switch to non-root user
WORKDIR /home/agentuser
COPY /gpt-agents/ /home/agentuser/gpt-agents

USER agentuser

# Default command to run a specific agent based on env variables
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["gptscript --workspace /home/agentuser/gpt-agents --disable-cache --default-model \"$MODEL\" --openai-base-url \"${OPENAI_BASE_URL:-https://api.openai.com/v1}\" --openai-api-key \"$OPENAI_API_KEY\" /home/agentuser/gpt-agents/$MERGED_AGENT_FILE \"$COMMAND_STRING\""]
