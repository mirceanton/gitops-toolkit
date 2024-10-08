## ================================================================================================
# Utility versions
## ================================================================================================
# Terraform Stuff
ARG TERRAFORM_VERSION=1.9.5@sha256:79336cfbc9113f41806e7b2061b913852f11d6bdbc0e188d184e6bdee40b84a7
ARG TFLINT_VERSION=v0.53.0@sha256:50a7efe689344733a21947a6253cbca9b1a03b3f2379384ce3bf784203078002

# Secret Encryption Stuff
ARG SOPS_VERSION=v3.9.0-alpine@sha256:eb08d77bc070a0ae1042875ab563bad8d2d0eba40518c1cb68e123f47b106134
ARG AGE_VERSION=v1.2.0
ARG AGE_KEYGEN_VERSION=V1.2.0@sha256:3c741e8533806a5b45e5aaf8e8b1646d1570a3c95d654752727cf9b73b59ad12

# Kubernetes Stuff
ARG FLUX_VERSION=v2.3.0@sha256:b0b43636bede7fee04afa99b9ad0732eca0f1778f7ebaa99fc89d48d35ccae18
ARG KUBECTL_VERSION=1.31.0@sha256:7779e585c588adde5c8feafd584c1ffc76ffbe8475236aa14c13b8afe18d9af6
ARG KUBESWITCHER_VERSION=v1.0.2@sha256:7d05b7466344c2176bc56d6e85d91b378e27fd5b598275e3f2e674d260190f44
ARG K9S_VERSION=v0.32.4@sha256:32e0cf06b70f1b7e7576b64b378170ddda194b491ef4d04b7303f1b8ab81a771
ARG HELM_VERSION=v3.13.3
ARG KUSTOMIZE_VERSION=v5.4.3@sha256:6dd0a67e2a8634a5d1aabd9c5e888ff220663e979b55bc17fe4b3a845718bb10
ARG STERN_VERSION=1.30.0@sha256:b6b6137f4f7f9e6687457bf40c491b3bf258beeb9889e43158598226b0c331a3

# Talos Stuff
ARG TALOSCTL_VERSION=v1.7.6@sha256:c0d0c85fc25424ec8e28d7b98db5b750ab47705af44222d3ff3afc556fac52d5
ARG TALSWITCHER_VERSION=v1.1.0@sha256:feb9de65b0952047ec6d79a524caf6ca30397408598935487ec6568041fddd3a
ARG TALHELPER_VERSION=v3.0.5@sha256:1d5ea10b83e5bce0a32907ada9866267abf1854215000ead86538ffe779c1357

# Misc Tools
ARG TASKFILE_VERSION=v3.38.0@sha256:308c4f5be86bffae3f956cbd7225c4fec69b0e7a89012120b818a10df45d7c59
ARG BITWARDEN_CLI_VERSION=2024.8.1


## ================================================================================================
# "Build" stage for utilities with docker images already present
## ================================================================================================
# Terraform Stuff
FROM docker.io/hashicorp/terraform:${TERRAFORM_VERSION} AS terraform
FROM ghcr.io/terraform-linters/tflint:${TFLINT_VERSION} AS tflint

# Secret Encryption Stuff
FROM ghcr.io/getsops/sops:${SOPS_VERSION} AS sops
FROM ghcr.io/mirceanton/age:${AGE_VERSION} AS age
FROM ghcr.io/mirceanton/age-keygen:${AGE_KEYGEN_VERSION} AS age-keygen

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
FROM ghcr.io/mirceanton/taskfile:${TASKFILE_VERSION} AS taskfile
#TODO: bw-cli container


## ================================================================================================
# Build stages for other utilities
## ================================================================================================
FROM alpine@sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d AS bitwarden-cli
ARG BITWARDEN_CLI_VERSION
RUN wget https://github.com/bitwarden/clients/releases/download/cli-v${BITWARDEN_CLI_VERSION}/bw-oss-linux-${BITWARDEN_CLI_VERSION}.zip -O bitwarden.zip && \
	unzip bitwarden.zip && \
	mv bw /bin/bw

FROM alpine@sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d AS helm
ARG HELM_VERSION
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O helm.tar.gz && \
	tar xvf helm.tar.gz && \
	mv linux-amd64/helm /bin/helm


## ================================================================================================
## Main image
## ================================================================================================
FROM mcr.microsoft.com/devcontainers/python:3.12-bullseye@sha256:d20b278aa97a5536bebfb2338d0e7814309d8fe4d28e2751bd3857e523e60b4a AS workspace
ENV EDITOR=vim

# Install tools
COPY --from=k9s /bin/k9s /usr/local/bin/k9s
COPY --from=sops /usr/local/bin/sops /usr/local/bin/sops
COPY --from=age /age /usr/local/bin/age
COPY --from=age-keygen /age-keygen /usr/local/bin/age-keygen
COPY --from=kustomize /app/kustomize /usr/local/bin/kustomize
COPY --from=stern /usr/local/bin/stern /usr/local/bin/stern
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=tflint /usr/local/bin/tflint /usr/local/bin/tflint
COPY --from=talosctl /talosctl /usr/local/bin/talosctl
COPY --from=talhelper /usr/local/bin/talhelper /usr/local/bin/talhelper
COPY --from=talswitcher /talswitcher /usr/local/bin/talswitcher
COPY --from=taskfile /task /usr/local/bin/task
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
COPY --from=kubeswitcher /kube-switcher /usr/local/bin/kubectl-switch
COPY --from=helm /bin/helm /usr/local/bin/helm
COPY --from=flux /usr/local/bin/flux /usr/local/bin/flux
COPY --from=bitwarden-cli /bin/bw /usr/local/bin/bw

# Setup bash completions
RUN kustomize completion bash | sudo tee /etc/bash_completion.d/kustomize.bash > /dev/null
RUN stern --completion=bash | sudo tee /etc/bash_completion.d/stern.bash > /dev/null
RUN talosctl completion bash | sudo tee /etc/bash_completion.d/talosctl.bash > /dev/null
RUN talhelper completion bash | sudo tee /etc/bash_completion.d/talhelper.bash > /dev/null
RUN talswitcher completion bash | sudo tee /etc/bash_completion.d/talswitcher.bash > /dev/null
RUN kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl.bash > /dev/null
RUN kubectl switch completion bash | sudo tee /etc/bash_completion.d/kubectl-switch.bash > /dev/null
RUN helm completion bash | sudo tee /etc/bash_completion.d/helm.bash > /dev/null
RUN flux completion bash | sudo tee /etc/bash_completion.d/flux.bash > /dev/null
RUN terraform -install-autocomplete

# Install additional OS packages
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
	docker-compose \
	dnsutils && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && \
	pip install -r /tmp/requirements.txt

# Enable passwordless sudo :kek:
RUN echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN usermod -aG docker vscode
USER vscode
WORKDIR /workspace
ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
