## ================================================================================================
# Utility versions
## ================================================================================================
# Terraform Stuff
ARG TERRAFORM_VERSION=1.10.3@sha256:460267841b38628514b75c6b0eb1cebb2d2fb5d6b596087a9c277551c801e5f1
ARG TFLINT_VERSION=v0.54.0@sha256:325daf865d3b7b3ed66189963c68fd9000ae5922d3489623d0eee8f753f7fc41

# Secret Encryption Stuff
ARG SOPS_VERSION=v3.9.3-alpine@sha256:3fe2b435663d6907164186b20ee3120b769a7c51cfc11aee791464eaf964d55b
ARG AGE_VERSION=v1.2.0@sha256:7708b4bcb7315f23163eed029cc0ccfc9bc8ad8b100d8da555c812565f845da7
ARG AGE_KEYGEN_VERSION=V1.2.0@sha256:3c741e8533806a5b45e5aaf8e8b1646d1570a3c95d654752727cf9b73b59ad12

# Flux Stuff
ARG FLUX_VERSION=v2.4.0@sha256:a9cb966cddc1a0c56dc0d57dda485d9477dd397f8b45f222717b24663471fd1f
ARG TFCTL_VERSION=v0.16.0-rc.4@sha256:5bc929e7c083e5357ea9c31716f857784a67e9371835e16357bb038378124748

# Kubectl + Plugins
ARG KUBECTL_VERSION=1.32.0@sha256:493d1b871556d48d6b25d471f192c2427571cd6f78523eebcaf4d263353c7487
ARG KUBECOLOR_VERSION=v0.4.0@sha256:f87c8893a1ae6e031fcb96af6901d146a0542d7ec1a27025d4d9f05e4c18232d
ARG KUBECTL_SWITCH_VERSION=v2.0.0@sha256:d4a04dbadb6dec078db12aff547add28af18a3e2e5951e430e33cce03e9aa8c3
ARG KUBECTL_PGO_VERSION=v0.5.0

# Misc K8S Tools
ARG KUSTOMIZE_VERSION=v5.4.3@sha256:6dd0a67e2a8634a5d1aabd9c5e888ff220663e979b55bc17fe4b3a845718bb10
ARG HELM_VERSION=v3.13.3
ARG K9S_VERSION=v0.32.7@sha256:a967991e635dc8327c25c9d20ea71089a9cad66793013c5675c81a1f6c79292b
ARG STERN_VERSION=1.31.0@sha256:6d4bc0513326811f8375da3a86e4ae3a4719412414c54d1b3409bddf1a183ac4

# Talos Stuff
ARG TALOSCTL_VERSION=v1.9.1@sha256:170d484156912ecb8791da1e038fe6cc6c47508d1af543f2cfafb6368b496341
ARG TALSWITCHER_VERSION=v1.1.2@sha256:992edc9595db9d543f92eb7349c4db5d9359906a91a54383b9bd9525b3d760ce
ARG TALHELPER_VERSION=v3.0.14@sha256:2edfa8cad70e017975bb7fcebb80c7e178e46eb7f0306ecb2a1a472c24ee50b4

# Misc Tools
ARG TASKFILE_VERSION=v3.38.0@sha256:308c4f5be86bffae3f956cbd7225c4fec69b0e7a89012120b818a10df45d7c59
ARG MINIO_CLI_VERSION=RELEASE.2024-10-08T09-37-26Z@sha256:c0d345a438dcac5677c1158e4ac46637069b67b3cc38e7b04c08cf93bdee4a62
ARG BITWARDEN_CLI_VERSION=2024.8.1
ARG CMCTL_VERSION=v2.1.1

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

# Flux Stuff
FROM ghcr.io/fluxcd/flux-cli:${FLUX_VERSION} AS flux
FROM ghcr.io/mirceanton/tfctl:${TFCTL_VERSION} AS tfctl

# Kubectl + Plugins
FROM docker.io/bitnami/kubectl:${KUBECTL_VERSION} AS kubectl
FROM ghcr.io/kubecolor/kubecolor:${KUBECOLOR_VERSION} as kubecolor
FROM ghcr.io/mirceanton/kubectl-switch:${KUBECTL_SWITCH_VERSION} AS kubectl-switch

# Misc K8S Tools
FROM registry.k8s.io/kustomize/kustomize:${KUSTOMIZE_VERSION} AS kustomize
#TODO: helm container
FROM docker.io/derailed/k9s:${K9S_VERSION} AS k9s
FROM ghcr.io/stern/stern:${STERN_VERSION} AS stern

# Talos Stuff
FROM ghcr.io/siderolabs/talosctl:${TALOSCTL_VERSION} AS talosctl
FROM ghcr.io/mirceanton/talswitcher:${TALSWITCHER_VERSION} AS talswitcher
FROM ghcr.io/budimanjojo/talhelper:${TALHELPER_VERSION} AS talhelper

# Misc Tools
FROM ghcr.io/mirceanton/taskfile:${TASKFILE_VERSION} AS taskfile
#TODO: bw-cli container
FROM docker.io/minio/mc:${MINIO_CLI_VERSION} AS minio-cli


## ================================================================================================
# Build stages for other utilities
## ================================================================================================
FROM alpine@sha256:21dc6063fd678b478f57c0e13f47560d0ea4eeba26dfc947b2a4f81f686b9f45 AS bitwarden-cli
ARG BITWARDEN_CLI_VERSION
RUN wget https://github.com/bitwarden/clients/releases/download/cli-v${BITWARDEN_CLI_VERSION}/bw-oss-linux-${BITWARDEN_CLI_VERSION}.zip -O bitwarden.zip && \
	unzip bitwarden.zip && \
	mv bw /bin/bw

FROM alpine@sha256:21dc6063fd678b478f57c0e13f47560d0ea4eeba26dfc947b2a4f81f686b9f45 AS helm
ARG HELM_VERSION
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O helm.tar.gz && \
	tar xvf helm.tar.gz && \
	mv linux-amd64/helm /bin/helm

FROM alpine@sha256:21dc6063fd678b478f57c0e13f47560d0ea4eeba26dfc947b2a4f81f686b9f45 AS kubectl-pgo
ARG KUBECTL_PGO_VERSION
RUN wget https://github.com/CrunchyData/postgres-operator-client/releases/download/${KUBECTL_PGO_VERSION}/kubectl-pgo-linux-amd64 && \
	mv kubectl-pgo-linux-amd64 /bin/kubectl-pgo && \
	chmod +x /bin/kubectl-pgo

FROM alpine@sha256:21dc6063fd678b478f57c0e13f47560d0ea4eeba26dfc947b2a4f81f686b9f45 AS cmctl
ARG CMCTL_VERSION
RUN wget https://github.com/cert-manager/cmctl/releases/download/${CMCTL_VERSION}/cmctl_linux_amd64 && \
	mv cmctl_linux_amd64 /bin/cmctl && \
	chmod +x /bin/cmctl

## ================================================================================================
## Main image
## ================================================================================================
FROM mcr.microsoft.com/devcontainers/python:3.13-bullseye@sha256:71f720b19b88465475ccf71206c52cede6495bf42992250c41d2ec320ee4d119 AS workspace
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
COPY --from=talhelper /bin/talhelper /usr/local/bin/talhelper
COPY --from=talswitcher /talswitcher /usr/local/bin/talswitcher
COPY --from=taskfile /task /usr/local/bin/task
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
COPY --from=kubectl-switch /kubectl-switch /usr/local/bin/kubectl-switch
COPY --from=helm /bin/helm /usr/local/bin/helm
COPY --from=flux /usr/local/bin/flux /usr/local/bin/flux
COPY --from=tfctl /tfctl /usr/local/bin/tfctl
COPY --from=bitwarden-cli /bin/bw /usr/local/bin/bw
COPY --from=kubecolor /usr/local/bin/kubecolor /usr/local/bin/kubecolor
COPY --from=minio-cli /usr/bin/mc /usr/local/bin/mc
COPY --from=kubectl-pgo /bin/kubectl-pgo /usr/local/bin/kubectl-pgo
COPY --from=cmctl /bin/cmctl /usr/local/bin/cmctl

# Setup bash completions
RUN kustomize completion bash | sudo tee /etc/bash_completion.d/kustomize.bash > /dev/null
RUN stern --completion=bash | sudo tee /etc/bash_completion.d/stern.bash > /dev/null
RUN talosctl completion bash | sudo tee /etc/bash_completion.d/talosctl.bash > /dev/null
RUN talhelper completion bash | sudo tee /etc/bash_completion.d/talhelper.bash > /dev/null
RUN kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl.bash > /dev/null
RUN kubectl switch completion bash | sudo tee /etc/bash_completion.d/kubectl-switch.bash > /dev/null
RUN kubectl pgo completion bash | sudo tee /etc/bash_completion.d/kubectl-pgo.bash > /dev/null
RUN helm completion bash | sudo tee /etc/bash_completion.d/helm.bash > /dev/null
RUN flux completion bash | sudo tee /etc/bash_completion.d/flux.bash > /dev/null
RUN tfctl completion bash | sudo tee /etc/bash_completion.d/tfctl.bash > /dev/null
RUN cmctl completion bash | sudo tee /etc/bash_completion.d/cmctl.bash > /dev/null
RUN terraform -install-autocomplete
RUN echo "complete -C /usr/local/bin/mc mc" | sudo tee /etc/bash_completion.d/mc.bash > /dev/null

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
