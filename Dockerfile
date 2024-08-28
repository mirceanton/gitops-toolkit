## ================================================================================================
# Utility versions
## ================================================================================================
# Terraform Stuff
ARG TERRAFORM_VERSION=1.9.5@sha256:79336cfbc9113f41806e7b2061b913852f11d6bdbc0e188d184e6bdee40b84a7
ARG TFLINT_VERSION=v0.53.0@sha256:50a7efe689344733a21947a6253cbca9b1a03b3f2379384ce3bf784203078002

# Secret Encryption Stuff
ARG SOPS_VERSION=v3.9.0-alpine@sha256:eb08d77bc070a0ae1042875ab563bad8d2d0eba40518c1cb68e123f47b106134
ARG AGE_VERSION=v1.1.1

# Kubernetes Stuff
ARG FLUX_VERSION=v2.3.0@sha256:b0b43636bede7fee04afa99b9ad0732eca0f1778f7ebaa99fc89d48d35ccae18
ARG KUBECTL_VERSION=1.31.0@sha256:44f99aa45e3410dae8e288f43800daa8a1bdb4cac204dad1de59c94f9c999bde
ARG KUBESWITCHER_VERSION=v1.0.2@sha256:7d05b7466344c2176bc56d6e85d91b378e27fd5b598275e3f2e674d260190f44
ARG K9S_VERSION=v0.32.4@sha256:32e0cf06b70f1b7e7576b64b378170ddda194b491ef4d04b7303f1b8ab81a771
ARG HELM_VERSION=v3.13.3
ARG KUSTOMIZE_VERSION=v5.4.3@sha256:6dd0a67e2a8634a5d1aabd9c5e888ff220663e979b55bc17fe4b3a845718bb10
ARG STERN_VERSION=1.30.0@sha256:b6b6137f4f7f9e6687457bf40c491b3bf258beeb9889e43158598226b0c331a3

# Talos Stuff
ARG TALOSCTL_VERSION=v1.7.6@sha256:c0d0c85fc25424ec8e28d7b98db5b750ab47705af44222d3ff3afc556fac52d5
ARG TALSWITCHER_VERSION=v1.1.0@sha256:f49339325112f13ee7b4d73113201522c0d40ec139477f0ec7339c9642acac99
ARG TALHELPER_VERSION=v3.0.5@sha256:1d5ea10b83e5bce0a32907ada9866267abf1854215000ead86538ffe779c1357

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
FROM alpine@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5 AS taskfile
ARG TASKFILE_VERSION
RUN wget https://raw.githubusercontent.com/go-task/task/${TASKFILE_VERSION}/completion/bash/task.bash -O /task_completion.bash
RUN wget https://github.com/go-task/task/releases/download/${TASKFILE_VERSION}/task_linux_amd64.tar.gz && \
	tar xvf task_linux_amd64.tar.gz && \
	mv task /bin/task

FROM alpine@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5 AS bitwarden-cli
ARG BITWARDEN_CLI_VERSION
RUN wget https://github.com/bitwarden/clients/releases/download/cli-v${BITWARDEN_CLI_VERSION}/bw-oss-linux-${BITWARDEN_CLI_VERSION}.zip -O bitwarden.zip && \
	unzip bitwarden.zip && \
	mv bw /bin/bw

FROM alpine@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5 AS age
ARG AGE_VERSION
RUN wget https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz -O age.tar.gz && \
	tar xvf age.tar.gz && \
	mv age/age /bin/age && \
	mv age/age-keygen /bin/age-keygen

FROM alpine@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5 AS helm
ARG HELM_VERSION
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O helm.tar.gz && \
	tar xvf helm.tar.gz && \
	mv linux-amd64/helm /bin/helm


## ================================================================================================
## Main image
## ================================================================================================
FROM mcr.microsoft.com/devcontainers/python:3.12-bullseye@sha256:d20b278aa97a5536bebfb2338d0e7814309d8fe4d28e2751bd3857e523e60b4a AS workspace
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
