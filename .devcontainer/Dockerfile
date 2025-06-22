# syntax=docker/dockerfile:1.4
# Universal Dev Container - Base for all projects
FROM ubuntu:22.04 AS base

# Build arguments for customization
ARG TIMEZONE=UTC
ARG LOCALE=en_US.UTF-8
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Prevent interactive prompts during apt install
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=$TIMEZONE

# Set locale
ENV LANG=$LOCALE
ENV LANGUAGE=en_US:en
ENV LC_ALL=$LOCALE

# Install essential packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y \
    # Essential tools
    curl \
    wget \
    git \
    gnupg2 \
    jq \
    less \
    locales \
    lsb-release \
    man-db \
    nano \
    procps \
    psmisc \
    sudo \
    unzip \
    vim \
    zip \
    # Build essentials
    build-essential \
    ca-certificates \
    software-properties-common \
    # Network tools
    dnsutils \
    iputils-ping \
    net-tools \
    openssh-client \
    # Shell and terminal
    zsh \
    tmux \
    # Search and find
    fzf \
    ripgrep \
    fd-find \
    # Development tools
    gh \
    htop \
    tree \
    # Security tools (optional)
    iptables \
    ipset \
    iproute2 \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y

# Generate locale
RUN sed -i "/${LOCALE}/s/^# //g" /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=${LOCALE}

# Create non-root user
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Create common directories
RUN mkdir -p /workspace /home/$USERNAME/.config && \
    chown -R $USERNAME:$USERNAME /workspace /home/$USERNAME

# Install git-delta for better diffs
RUN ARCH=$(dpkg --print-architecture) && \
    DELTA_VERSION="0.18.2" && \
    wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${ARCH}.deb" && \
    dpkg -i "git-delta_${DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${DELTA_VERSION}_${ARCH}.deb"

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Set up shell
ENV SHELL=/bin/zsh

# Install Oh My Zsh with plugins
RUN sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

# Configure zsh
RUN echo 'export ZSH="$HOME/.oh-my-zsh"' >> ~/.zshrc && \
    echo 'ZSH_THEME="agnoster"' >> ~/.zshrc && \
    echo 'plugins=(git docker docker-compose sudo history dirhistory zsh-autosuggestions zsh-syntax-highlighting zsh-completions)' >> ~/.zshrc && \
    echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc && \
    echo 'export EDITOR=vim' >> ~/.zshrc

# Git configuration
RUN git config --global core.editor "vim" && \
    git config --global init.defaultBranch main && \
    git config --global pull.rebase false && \
    git config --global fetch.prune true && \
    git config --global diff.colorMoved zebra && \
    git config --global core.pager "delta" && \
    git config --global interactive.diffFilter "delta --color-only" && \
    git config --global delta.navigate true && \
    git config --global delta.light false && \
    git config --global delta.side-by-side true && \
    git config --global merge.conflictstyle diff3 && \
    git config --global diff.colorMoved default

# Create command history volume mount point
RUN sudo mkdir -p /commandhistory && \
    sudo touch /commandhistory/.zsh_history && \
    sudo chown -R $USERNAME:$USERNAME /commandhistory

# Set up persistent history
RUN echo 'export HISTFILE=/commandhistory/.zsh_history' >> ~/.zshrc && \
    echo 'export HISTSIZE=10000' >> ~/.zshrc && \
    echo 'export SAVEHIST=10000' >> ~/.zshrc && \
    echo 'setopt SHARE_HISTORY' >> ~/.zshrc

# Environment marker
ENV DEVCONTAINER=true
ENV DEVCONTAINER_TYPE=universal

WORKDIR /workspace

# VS Code directories (will be populated by extension installer)
RUN mkdir -p ~/.vscode-server/extensions ~/.vscode-server/bin

# Final stage for runtime
FROM base AS runtime

# Copy scripts to container (if they exist)
COPY scripts/ /usr/local/bin/devcontainer-scripts/

# Make scripts executable and create symlinks
RUN if [ -d /usr/local/bin/devcontainer-scripts ]; then \
        chmod +x /usr/local/bin/devcontainer-scripts/*.sh && \
        chown -R $USERNAME:$USERNAME /usr/local/bin/devcontainer-scripts/ && \
        ln -sf /usr/local/bin/devcontainer-scripts/install-extensions.sh /usr/local/bin/install-extensions && \
        ln -sf /usr/local/bin/devcontainer-scripts/update-tools.sh /usr/local/bin/dev-update && \
        ln -sf /usr/local/bin/devcontainer-scripts/security-scan.sh /usr/local/bin/dev-scan && \
        ln -sf /usr/local/bin/devcontainer-scripts/dev-setup.sh /usr/local/bin/dev-setup; \
    fi

# Set up sudo for scripts
RUN echo "$USERNAME ALL=(root) NOPASSWD: ALL" >> /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD command -v git && command -v zsh || exit 1

# Labels for metadata
LABEL maintainer="Your Name"
LABEL version="1.0.0"
LABEL description="Universal Development Container"