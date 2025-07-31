# Git-User Role

This role configures git environment and user settings for development. It is necessary to use the dev-scripts repository to install the cluster.

## Description

The git-user role sets up a complete git development environment. It:

1. Installs git package via DNF
2. Creates git configuration directory structure
3. Installs global gitignore file
4. Installs global gitattributes file
5. Configures git user settings from template

## Requirements

- DNF package manager
- Sudo privileges for package installation
- Local git configuration with user.name and user.email set

## Role Variables

This role uses template variables for git configuration:
- Git user name and email (configured via template, see [Local Git Config Source](#notes))
- Custom git attributes and ignore patterns (from files)

## File Structure

- `files/ignore`: Global gitignore patterns
- `files/attributes`: Global gitattributes configuration
- `templates/config.j2`: Git configuration template
- `lookup_plugins/gitconfig.py`: Custom lookup plugin for git configuration

## Usage

This role is typically imported by other roles:

```yaml
- name: Set up for git user
  import_role:
    name: git-user
```

## Notes

- **Lookup Plugin**: Includes custom lookup plugin for advanced git configuration
- **Local Git Config Source**: The git user name and email are retrieved from the **local git configuration** of the machine running the ansible playbook (equivalent to running `git config user.name` and `git config user.email`). Ensure your local git is configured before running this role. 