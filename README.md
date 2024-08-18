# GPTScript Agent Services

This repository provides everything you need to automate and manage tasks within Kubernetes clusters using GPT models. By defining agents in a simple, scriptable format, you can streamline deployments, monitor cluster health, and handle various automation tasks efficiently.

The repository includes:

- **Getting Started**: Step-by-step guide to setting up and using GPTScript.
- **GPTScript Agents**: Examples of different agents located under `gpt-agents/...`.
- **Docker**: A Dockerfile to build the necessary Docker image, or use the pre-built image from GHCR.
- **Kubernetes**: Resources for deploying GPTScript agents as Jobs in Kubernetes.
- **Failed Deployments**: Sample failed deployments for testing and validating agent capabilities.


## 0. What is GPTScript?

[GPTScript](https://github.com/gptscript-ai/gptscript) is a framework that allows Large Language Models (LLMs) to operate and interact with various systems. These systems can range from local executables to complex applications with OpenAPI schemas, SDK libraries, or any RAG-based solutions. GPTScript is designed to easily integrate any system, whether local or remote, with your LLM using just a few lines of prompts.



## 1. How to Install the CLI

To install the GPTScript CLI on your machine, follow these steps:

**MacOS and Linux (Homebrew)**:

```bash
brew install gptscript
```

**MacOS and Linux (install.sh)**:
```bash
curl https://get.gptscript.ai/install.sh | sh
```

**Verify the Installation**:
```bash
gptscript --version
```


This will ensure that the GPTScript CLI is installed and ready to use.

## 2. How to Define Your Own Agent

Defining your own GPTScript agent is straightforward. Agents are defined in `.gpt` files, which contain the logic and commands the agent will execute.

### Example Agent Definition

Here’s a simple example of how an agent can be defined:

```yaml
# gpt-agents/simple-cli-agent.gpt
Name: cli-agent
Tools: sys.exec
Description: I execute CLI commands on the local system.
Args: command: The CLI command to execute.
Chat: false

#prompt/instruction
Ensure the command is valid, modify it if needed, and then complete the task.
You can run CLI commands on the local system. You are an alpine-based or darwin-based system.
If the cli tool is not installed, then install it.
```

To create your own agent, simply follow this format and customize it based on the tasks you want the agent to perform.


### Define an alias for the agent

If you run the following command, the agent will be executed in the same directory where the agent is located. If you running it from a different directory, you have to adjust the path to the agent like `path/simple-cli-agent.gpt`.

```bash
alias gpt='gptscript --workspace "$(dirname "$0")" --disable-cache  --openai-api-key "sk-..." simple-cli-agent.gpt $0'
```


## 2. Docker: Using the Docker Image

The Docker image provides an isolated environment to run GPTScript agents with all dependencies pre-installed. Here’s how you can use it:

### Build the Docker Image

First, build the Docker image using the provided Dockerfile:

```bash
docker build -t gptscript-agent-image ./build/docker
```

### Run the Docker Container from build

To run the Docker container with the GPTScript agent, use the following command:

```bash
docker run --rm \
  -e GPTSCRIPT_DEFAULT_MODEL="gpt-4o" \
  -e OPENAI_API_KEY="your-openai-api-key" \
  -e MERGED_AGENT_FILE="simple-cli-agent.gpt" \
  -e OUTSIDE_AGENTS_FILES="https://raw.githubusercontent.com/your-repo/agent-file.gpt" \
  gptscript-agent-image
```

### Run the Docker Container from GHCR

```bash
docker run --rm \
  -e GPTSCRIPT_DEFAULT_MODEL="gpt-4o" \
  -e OPENAI_API_KEY="your-openai-api-key" \
  -e MERGED_AGENT_FILE="simple-cli-agent.gpt" \
  -e OUTSIDE_AGENTS_FILES="https://raw.githubusercontent.com/your-repo/agent-file.gpt" \
  ghcr.io/la-cc/gptscript-agents:latest
```

This will run the `simple-cli-agent.gpt` file inside the Docker container, allowing you to execute tasks defined in the agent. If you have additional agent files, you can specify them using the `OUTSIDE_AGENTS_FILES` environment variable.

## 3. Kuberntes: Deploying GPTScript Agents as Job

The project also includes resources for deploying GPTScript agents as Jobs in a Kubernetes cluster.

### Modify the ConfigMap, Secret and Deploy the Job

Deploying the GPTScript agents as a Job in Kubernetes is straightforward, with resources already provided in this repository. You only need to make minor adjustments to the ConfigMap and Secret to match your environment.

Follow these steps:
Here's a revised version of the text that better communicates the deployment process, focusing on the need to adjust the existing resources:

---

### Kubernetes: GPTScript Deployment as a Job

Deploying the GPTScript agent as a Job in Kubernetes is straightforward, with resources already provided in this repository. You only need to make minor adjustments to the `ConfigMap` and `Secret` to match your environment. Follow these steps:

1. **Adjust the ConfigMap**:
   Update the `configmap.yaml` file to configure the environment variables needed by your GPTScript agent. Here's an example:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: gptscript-agent-config
   data:
     GPTSCRIPT_DEFAULT_MODEL: "gpt-4o"
     OPENAI_BASE_URL: "https://api.openai.com/v1"
     AGENT_FILE: "simple-k8s-fix.gpt"
     COMMAND_STRING: "Does my cluster have any issues?"
     OUTSIDE_AGENTS_FILES: "https://raw.githubusercontent.com/victorgetz/gptscript-agents/main/gptscript-bot/files/devops-bot.gpt, https://github.com/victorgetz/gptscript-agents/blob/main/gptscript-bot/files/shared-context.gpt"
     # Uncomment and adjust the following paths if needed
     # GPTSCRIPT_CACHE_DIR: "/home/agentuser/.cache/gptscript"
     # GPTSCRIPT_CONFIG: "/home/agentuser/.config/gptscript/config.yaml"
     # GPTSCRIPT_WORKSPACE: "/home/agentuser/workspace"
   ```


2. **Adjust the Secret**:
   Ensure your `secret.yaml` file contains the necessary API key in Base64 format. Here's an example:

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: openai-api-key-secret
   type: Opaque
   data:
     api-key: <your-base64-encoded-api-key>
   ```


3. **Deploy all Resources**:
   Once the ConfigMap and Secret are in place, you can deploy the GPTScript agent as a Kubernetes Job. The `job.yaml` file already defines how the Job should be run. Apply the Job with the following command:

   ```bash
   kubectl apply -f k8s/deploy/
   ```

4. **Monitor the Job**:
   After deploying GPTScript as a Job, you can monitor its status and view logs to ensure everything is working as expected:

   ```bash
   kubectl get jobs
   kubectl logs <pod-name>

   #output like:
   The cluster had the following issues which have been resolved:
   - Deleted a crash-looping pod in the `default` namespace.
   - Updated the image for `faulty-image-tag-deployment` to `nginx:latest`.
   - Updated the image for `typo-image-deployment` to `nginx:latest`.
   ```



## 4. Example Deployments for Testing

The `demo-k8s-deployments` directory contains YAML files for various Kubernetes deployments that can be used to test the GPTScript agents:

- `deployment-typo-image-name.yaml`
- `deployment-wrong-env.yaml`
- `deployment-wrong-image-tag.yaml`
- `pod-crashloopback.yaml`

These files represent common issues that might occur in a Kubernetes environment. You can use them to validate and test the capabilities of your GPTScript agents.



## 5. Another Repository for GPTScript Agents

- [GPTScript Agents from Victor Getz](https://github.com/victorgetz/gptscript-agents): A collection of GPTScript agents for various tasks and to devops related tasks. Also an Helm Chart to deploy GPTScript agents in Kubernetes as job or as a cronjob.
- [Origin: GPTScript Agents](https://github.com/gptscript-ai/gptscript/tree/main/examples) that contains a few examples of GPTScript agents. Also how you can use it with Python and Golang.
- [Jenkins Example GPTScript](https://github.com/darinpope/jenkins-example-gptscript/blob/main/bob-python.gpt)