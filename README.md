# GitOps Toolkit

> [!IMPORTANT]  
> **Repository Deprecation Notice**
> 
> This repository will be **archived on June 1st, 2025** and the associated Docker images will be **removed from GHCR on August 1st, 2025**.
>
> The GitOps Toolkit was originally created to serve as a base for my DevContainer setups. I have since migrated to using [`mise`](https://mise.jdx.dev/) as a package manager, which has effectively replaced this solution with a more flexible approach.
>
> If you're currently using this image, please plan your migration to alternative solutions before the deprecation dates or fork this repository to maintain your own version.
> 
> For an alternative approach to managing developer environments, I recommend exploring [`mise`](https://mise.jdx.dev/) or other devtool management solutions.

---

GitOps Toolkit is a Docker image that contains a collection of tools necessary for me to manage my GitOps infrastructure. This image is designed to simplify the setup and management of a development environment for infrastructure as code (IaC), Kubernetes management, secret encryption, and other related tasks.

## Tools Included

| Tool/Dependency | Version |
|----------------|---------|
| Terraform | 1.11.4 |
| Tflint | v0.57.0 |
| Sops | v3.10.2 |
| Age | v1.2.0 |
| Age Keygen | V1.2.0 |
| Flux | v2.5.1 |
| Tfctl | v0.16.0-rc.4 |
| Kubectl | 1.33.0 |
| Kubecolor | v0.5.0 |
| Kubectl Switch | v2.2.3 |
| Kubectl Pgo | v0.5.0 |
| Kustomize | v5.6.0 |
| Helm | v3.13.3 |
| K9S | v0.50.4 |
| Stern | 1.32.0 |
| Talosctl | v1.10.0 |
| Talswitcher | v2.0.3 |
| Talhelper | v3.0.23 |
| Taskfile | v3.38.0 |
| Minio Cli | RELEASE.2024-10-08T09-37-26Z |
| Bitwarden Cli | 2024.8.1 |
| Cmctl | v2.1.1 |
| yamllint | 1.37.1 |
| jq | 1.8.0 |
| yq | 3.4.3 |

## UseCase

This image is mainly intended to be the base for DevContainer setups (hence the `devcontainers/python` base image) or to be the base image for CI runs.

### Sample DevContainer Configuration

Here is an example of a devcontainer configuration using this image.

```json5
{
  "name": "GitOps Toolkit",
  "image": "ghcr.io/mirceanton/gitops-toolkit:latest",
  "containerEnv": {
    "KUBECONFIG": "/home/vscode/.kube/config",
    "KUBECONFIG_DIR": "/home/vscode/.kube/configs/",
    "TALOSCONFIG": "/home/vscode/.talos/config",
    "TALOSCONFIG_DIR": "/home/vscode/.talos/configs/"
  },
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
    "source=${localEnv:HOME}${localEnv:USERPROFILE}/.age.key,target=${containerWorkspaceFolder}/.age.key,type=bind,consistency=cached",
    "source=${localEnv:HOME}${localEnv:USERPROFILE}/.kube/,target=/home/vscode/.kube/,type=bind,consistency=cached",
    "source=${localEnv:HOME}${localEnv:USERPROFILE}/.talos/,target=/home/vscode/.talos/,type=bind,consistency=cached"
  ],
  "remoteUser": "vscode",
  "containerUser": "vscode",
  "updateRemoteUserUID": true
}
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.