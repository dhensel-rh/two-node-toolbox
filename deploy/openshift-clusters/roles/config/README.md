# Config Role

This role performs basic user configuration for the development environment.

## Description

The config role sets up essential user configuration for bare metal development environments. It:

1. Enables user lingering for systemd services (necessary for consistent functioning of the proxy container)
2. Installs SSH public key for the current user
3. Configures bash history search with inputrc
4. Sets up git user configuration by importing the git-user role

## Requirements

- SSH key pair generated (key name specified in variables must exist)
- Sudo privileges for enabling user lingering
- Git user role available

## Role Variables

This role uses runtime variables:
- Current username (detected automatically via `whoami`)
- SSH public key from `~/.ssh/id_ed25519.pub`, as noted in the general README instructions for the installation process

## Usage

This role is typically run as part of the initial setup:

```bash
ansible-playbook setup.yml
```

 