## ================================================================================================
# Utility versions
## ================================================================================================
# Terraform Stuff
ARG TERRAFORM_VERSION=1.9.5
ARG TFLINT_VERSION=v0.53.0

# Secret Encryption Stuff
ARG SOPS_VERSION=v3.9.0-alpine
ARG AGE_VERSION=v1.1.1

# Kubernetes Stuff
ARG FLUX_VERSION=v2.3.0
ARG KUBECTL_VERSION=1.31.0
ARG KUBESWITCHER_VERSION=v1.0.2
ARG K9S_VERSION=v0.32.4
ARG HELM_VERSION=v3.13.3
ARG KUSTOMIZE_VERSION=v5.4.3
ARG STERN_VERSION=1.30.0

# Talos Stuff
ARG TALOSCTL_VERSION=v1.7.6
ARG TALSWITCHER_VERSION=v1.1.0
ARG TALHELPER_VERSION=v3.0.5

# Misc Tools
ARG TASKFILE_VERSION=v3.32.0
ARG BITWARDEN_CLI_VERSION=2024.8.1


## ================================================================================================
# "Build" stage for utilities with docker images already present
## ================================================================================================
# Terraform Stuff
FROM docker.io/hashicorp/terraform:${TERRAFORM_VERSION} AS terraform
FROM ghcr.io/terraform-linters/tflint:${TFLINT_VERSION} AS tflint

# Secret Encryption Stuff
FROM ghcr.io/getsops/sops:${SOPS_VERSION} AS sops
#TODO: AGE container

# Kubernetes Stuff
FROM ghcr.io/fluxcd/flux-cli:${FLUX_VERSION} AS flux
FROM docker.io/bitnami/kubectl:${KUBECTL_VERSION} AS kubectl
FROM ghcr.io/mirceanton/kube-switcher:${KUBESWITCHER_VERSION} AS kubeswitcher
FROM docker.io/derailed/k9s:${K9S_VERSION} AS k9s
#TODO: helm container
FROM registry.k8s.io/kustomize/kustomize:${KUSTOMIZE_VERSION} AS kustomize
FROM ghcr.io/stern/stern:${STERN_VERSION} AS stern

# Talos Stuff
FROM ghcr.io/siderolabs/talosctl:${TALOSCTL_VERSION} AS talosctl
FROM ghcr.io/mirceanton/talswitcher:${TALSWITCHER_VERSION} AS talswitcher
FROM ghcr.io/budimanjojo/talhelper:${TALHELPER_VERSION} AS talhelper

# Misc Tools
#TODO: Taskfile container
#TOOD: bw-cli container


## ================================================================================================
# Build stages for other utilities
## ================================================================================================
FROM alpine AS taskfile
ARG TASKFILE_VERSION
RUN wget https://raw.githubusercontent.com/go-task/task/${TASKFILE_VERSION}/completion/bash/task.bash -O /task_completion.bash
RUN wget https://github.com/go-task/task/releases/download/${TASKFILE_VERSION}/task_linux_amd64.tar.gz && \
	tar xvf task_linux_amd64.tar.gz && \
	mv task /bin/task

FROM alpine AS bitwarden-cli
ARG BITWARDEN_CLI_VERSION
RUN wget https://github.com/bitwarden/clients/releases/download/cli-v${BITWARDEN_CLI_VERSION}/bw-oss-linux-${BITWARDEN_CLI_VERSION}.zip -O bitwarden.zip && \
	unzip bitwarden.zip && \
	mv bw /bin/bw

FROM alpine AS age
ARG AGE_VERSION
RUN wget https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz -O age.tar.gz && \
	tar xvf age.tar.gz && \
	mv age/age /bin/age && \
	mv age/age-keygen /bin/age-keygen

FROM alpine AS helm
ARG HELM_VERSION
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O helm.tar.gz && \
	tar xvf helm.tar.gz && \
	mv linux-amd64/helm /bin/helm


## ================================================================================================
## Main image
## ================================================================================================
FROM mcr.microsoft.com/devcontainers/python:3.12-bullseye AS workspace
ENV EDITOR=vim

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && apt-get upgrade -y && \
	apt-get install -y \
	sudo \
	git \
	bash-completion \
	vim \
	curl \
	wget \
	unzip \
	htop \
	net-tools \
	iputils-ping \
	dnsutils && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && \
	pip install -r /tmp/requirements.txt

# Enable passwordless sudo :kek:
RUN echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install tools with no bash completion
COPY --from=k9s /bin/k9s /usr/local/bin/k9s
COPY --from=sops /usr/local/bin/sops /usr/local/bin/sops
COPY --from=age /bin/age /usr/local/bin/age
COPY --from=age /bin/age-keygen /usr/local/bin/age-keygen

# Install kustomize and set up bash completion
COPY --from=kustomize /app/kustomize /usr/local/bin/kustomize
RUN kustomize completion bash | sudo tee /etc/bash_completion.d/kustomize.bash > /dev/null

# Install stern and set up bash completion
COPY --from=stern /usr/local/bin/stern /usr/local/bin/stern
RUN stern --completion=bash | sudo tee /etc/bash_completion.d/stern.bash > /dev/null

# Install terraform and set up bash completion
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
RUN terraform -install-autocomplete

# Install tflint
COPY --from=tflint /usr/local/bin/tflint /usr/local/bin/tflint

# Install talosctl and set up bash completion
COPY --from=talosctl /talosctl /usr/local/bin/talosctl
RUN talosctl completion bash | sudo tee /etc/bash_completion.d/talosctl.bash > /dev/null

# Install talhelper and set up bash completion
COPY --from=talhelper /usr/local/bin/talhelper /usr/local/bin/talhelper
RUN talhelper completion bash | sudo tee /etc/bash_completion.d/talhelper.bash > /dev/null

# Install talswitcher and set up bash completion
COPY --from=talswitcher /talswitcher /usr/local/bin/talswitcher
RUN talswitcher completion bash | sudo tee /etc/bash_completion.d/talswitcher.bash > /dev/null

# Install taskfile and set up bash completion
COPY --from=taskfile /bin/task /usr/local/bin/task
COPY --from=taskfile /task_completion.bash /etc/bash_completion.d/task.bash

# Install kubectl and set up bash completion
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
RUN kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl.bash > /dev/null

# Install kubeswitcher as a kubectl plugin
COPY --from=kubeswitcher /kube-switcher /usr/local/bin/kubectl-switch
RUN kubectl switch completion bash | sudo tee /etc/bash_completion.d/kubectl-switch.bash > /dev/null

# Install helm and set up bash completion
COPY --from=helm /bin/helm /usr/local/bin/helm
RUN helm completion bash | sudo tee /etc/bash_completion.d/helm.bash > /dev/null

# Install flux and set up bash completion
COPY --from=flux /usr/local/bin/flux /usr/local/bin/flux
RUN flux completion bash | sudo tee /etc/bash_completion.d/flux.bash > /dev/null

# Install bitwarden CLI
COPY --from=bitwarden-cli /bin/bw /usr/local/bin/bw

USER vscode
WORKDIR /workspace
ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
