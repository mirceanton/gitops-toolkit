# GitOps Toolkit

GitOps Toolkit is a Docker image that contains a collection of tools necessary for me to manage my GitOps infrastructure. This image is designed to simplify the setup and management of a development environment for infrastructure as code (IaC), Kubernetes management, secret encryption, and other related tasks.

## Tools Included

| Tool | Version |
|------|---------|
| Terraform	| 1.9.5	|
| Tflint	| v0.53.0	|
| Sops	| v3.9.0	|
| Age	| v1.1.1	|
| Flux	| v2.3.0	|
| Kubectl	| 1.31.0	|
| Kubeswitcher	| v1.0.2	|
| K9S	| v0.32.4	|
| Helm	| v3.13.3	|
| Kustomize	| v5.4.3	|
| Stern	| 1.30.0	|
| Talosctl	| v1.7.6	|
| Talswitcher	| v1.1.0	|
| Talhelper	| v3.0.5	|
| Taskfile	| v3.32.0	|
| Bitwarden Cli	| 2024.8.1	|


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
		"source=${localEnv:HOME}${localEnv:USERPROFILE}/.config/sops/age/keys.txt,target=/home/vscode/.config/sops/age/keys.txt,type=bind,consistency=cached",
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