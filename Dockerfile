FROM mcr.microsoft.com/devcontainers/base:debian-11

# Set environment variables
ENV EDITOR=vim

# Install mise
RUN sudo apt update -y && sudo apt install -y gpg sudo wget curl && \
	sudo install -dm 755 /etc/apt/keyrings && \
	wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null && \
	echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list && \
	sudo apt update && sudo apt install -y mise
RUN echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

# Copy over mise config
WORKDIR /workspace
COPY mise.toml .
RUN mise trust mise.toml && mise install -y

RUN echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER vscode
ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
