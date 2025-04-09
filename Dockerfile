## ================================================================================================
# Utility versions
## ================================================================================================
# Terraform Stuff
ARG TERRAFORM_VERSION=1.11.4@sha256:5820b87995595425074f881500a037b0ccd41158d0d9b44d78f5f120612f2d3d
ARG TFLINT_VERSION=v0.56.0@sha256:102aa738eb7af25d6e6cdf814b9301de151bf4a2bab41c7d304fddd61d6a4b6d

# Secret Encryption Stuff
ARG SOPS_VERSION=v3.10.1@sha256:20b65b6caaf3acc6f40f3a1299b148d55db9d7b983c27453c99f9cbb724c9f70
ARG AGE_VERSION=v1.2.0@sha256:7708b4bcb7315f23163eed029cc0ccfc9bc8ad8b100d8da555c812565f845da7
ARG AGE_KEYGEN_VERSION=V1.2.0@sha256:3c741e8533806a5b45e5aaf8e8b1646d1570a3c95d654752727cf9b73b59ad12

# Flux Stuff
ARG FLUX_VERSION=v2.5.1@sha256:274a179fd40225f7aaeeb8953473381fc6e16154abaa70da0f599d89a610ccee
ARG TFCTL_VERSION=v0.16.0-rc.4@sha256:5bc929e7c083e5357ea9c31716f857784a67e9371835e16357bb038378124748

# Kubectl + Plugins
ARG KUBECTL_VERSION=1.32.3@sha256:0ed36a7f6a94c1b82d70811ed03caf3df92b4b2b8f8817d0f726f0f3a26e64af
ARG KUBECOLOR_VERSION=v0.5.0@sha256:8a88ab0d5fd4e32b9e21ad4a4c2c4147617f548980a363cc84f3e1b58a3a1686
ARG KUBECTL_SWITCH_VERSION=v2.2.1@sha256:4d84c428b0836357e08128da1a0620bdfaf97f3568d040c5626d0cd60a8c065b
ARG KUBECTL_PGO_VERSION=v0.5.0

# Misc K8S Tools
ARG KUSTOMIZE_VERSION=v5.6.0@sha256:b5f56e6becd1ba93a1a775a149763e3841a177beb10191624100bed81b44d297
ARG HELM_VERSION=v3.13.3
ARG K9S_VERSION=v0.50.0@sha256:030e23fceb9a8a481817628256512ef705c0d5424d4e44a8e880439a31b3ef07
ARG STERN_VERSION=1.32.0@sha256:f0c6aad6971ec445913be9ad18248aebd0ce6352a97c26cce64e802f7d53e80c

# Talos Stuff
ARG TALOSCTL_VERSION=v1.9.5@sha256:970f109811eba88696cbeff374ad5038132326b6bae565db7d5594c8e71cb391
ARG TALSWITCHER_VERSION=v2.0.2@sha256:305d6082d658ba6bc6910b0f1c77463e8b85c6f9f4648daab2b6c29235d00520
ARG TALHELPER_VERSION=v3.0.21@sha256:17cfbef5437a8bd1aebcb229d2e1fbef2e54f71fdf6d5cc8f3b08c7f439d1563

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
FROM alpine@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c AS bitwarden-cli
ARG BITWARDEN_CLI_VERSION
RUN wget https://github.com/bitwarden/clients/releases/download/cli-v${BITWARDEN_CLI_VERSION}/bw-oss-linux-${BITWARDEN_CLI_VERSION}.zip -O bitwarden.zip && \
	unzip bitwarden.zip && \
	mv bw /bin/bw

FROM alpine@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c AS helm
ARG HELM_VERSION
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O helm.tar.gz && \
	tar xvf helm.tar.gz && \
	mv linux-amd64/helm /bin/helm

FROM alpine@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c AS kubectl-pgo
ARG KUBECTL_PGO_VERSION
RUN wget https://github.com/CrunchyData/postgres-operator-client/releases/download/${KUBECTL_PGO_VERSION}/kubectl-pgo-linux-amd64 && \
	mv kubectl-pgo-linux-amd64 /bin/kubectl-pgo && \
	chmod +x /bin/kubectl-pgo

FROM alpine@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c AS cmctl
ARG CMCTL_VERSION
RUN wget https://github.com/cert-manager/cmctl/releases/download/${CMCTL_VERSION}/cmctl_linux_amd64 && \
	mv cmctl_linux_amd64 /bin/cmctl && \
	chmod +x /bin/cmctl

## ================================================================================================
## Main image
## ================================================================================================
FROM mcr.microsoft.com/devcontainers/python:3.13-bullseye@sha256:ddfa85f6219cb344894c62351c7a16925c6b89f070c8106576095bfa14622577 AS workspace
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
