## ================================================================================================
# Utility versions
## ================================================================================================
# Terraform Stuff
ARG TERRAFORM_VERSION=1.10.5@sha256:679ac5e095bf550bc726742cd12efa6050f0913080df479fdabfeb202953af28
ARG TFLINT_VERSION=v0.55.1@sha256:4136a6ec3d6659551f2b8f63be8bd413c8c1d842506a5597a26bf4e8bc1eac16

# Secret Encryption Stuff
ARG SOPS_VERSION=v3.9.4@sha256:64901dd14125bd141a3f8d2413bdfc912e3f6ca8560fe44d905de0e840bf0ca0
ARG AGE_VERSION=v1.2.0@sha256:7708b4bcb7315f23163eed029cc0ccfc9bc8ad8b100d8da555c812565f845da7
ARG AGE_KEYGEN_VERSION=V1.2.0@sha256:3c741e8533806a5b45e5aaf8e8b1646d1570a3c95d654752727cf9b73b59ad12

# Flux Stuff
ARG FLUX_VERSION=v2.4.0@sha256:a9cb966cddc1a0c56dc0d57dda485d9477dd397f8b45f222717b24663471fd1f
ARG TFCTL_VERSION=v0.16.0-rc.4@sha256:5bc929e7c083e5357ea9c31716f857784a67e9371835e16357bb038378124748

# Kubectl + Plugins
ARG KUBECTL_VERSION=1.32.1@sha256:49d20448fd06913877158ff07dfa05fc0504946439974214863e1a8ae99bf60f
ARG KUBECOLOR_VERSION=v0.5.0@sha256:8a88ab0d5fd4e32b9e21ad4a4c2c4147617f548980a363cc84f3e1b58a3a1686
ARG KUBECTL_SWITCH_VERSION=v2.0.1@sha256:88207a0b2a54c61fcb6107b46a81ec6686b650129eb09d7557e91f57da05e3da
ARG KUBECTL_PGO_VERSION=v0.5.0

# Misc K8S Tools
ARG KUSTOMIZE_VERSION=v5.6.0@sha256:b5f56e6becd1ba93a1a775a149763e3841a177beb10191624100bed81b44d297
ARG HELM_VERSION=v3.13.3
ARG K9S_VERSION=v0.32.7@sha256:a967991e635dc8327c25c9d20ea71089a9cad66793013c5675c81a1f6c79292b
ARG STERN_VERSION=1.32.0@sha256:f0c6aad6971ec445913be9ad18248aebd0ce6352a97c26cce64e802f7d53e80c

# Talos Stuff
ARG TALOSCTL_VERSION=v1.9.3@sha256:d1d324131e46d915ab16a24aba8e5aabd3361c0749f78fb2cf16703eafae8a2f
ARG TALSWITCHER_VERSION=v1.1.4@sha256:b543f8b885f99f5c35acbbd3708ed636fdfd67143041253afd92705e9a605c9a
ARG TALHELPER_VERSION=v3.0.18@sha256:268cb1edef420539b6acaf6872cfb80a39455ff7fee73a6d2606bfc5b493c9c6

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
FROM alpine@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099 AS bitwarden-cli
ARG BITWARDEN_CLI_VERSION
RUN wget https://github.com/bitwarden/clients/releases/download/cli-v${BITWARDEN_CLI_VERSION}/bw-oss-linux-${BITWARDEN_CLI_VERSION}.zip -O bitwarden.zip && \
	unzip bitwarden.zip && \
	mv bw /bin/bw

FROM alpine@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099 AS helm
ARG HELM_VERSION
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O helm.tar.gz && \
	tar xvf helm.tar.gz && \
	mv linux-amd64/helm /bin/helm

FROM alpine@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099 AS kubectl-pgo
ARG KUBECTL_PGO_VERSION
RUN wget https://github.com/CrunchyData/postgres-operator-client/releases/download/${KUBECTL_PGO_VERSION}/kubectl-pgo-linux-amd64 && \
	mv kubectl-pgo-linux-amd64 /bin/kubectl-pgo && \
	chmod +x /bin/kubectl-pgo

FROM alpine@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099 AS cmctl
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
