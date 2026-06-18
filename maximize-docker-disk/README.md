# Maximize Docker Disk

Maximize available disk space for Docker on GitHub Actions runners.

On **Linux**, the action:

1. Removes pre-installed APT packages (clang, dotnet, mono, php, etc.)
2. Removes large directories (/opt/hostedtoolcache, Android SDK, etc.)
3. Prunes all Docker images
4. Removes the swap file
5. Creates an LVM volume merging free space from `/` and `/mnt`
6. Bind-mounts the merged volume to `/var/lib/docker`

On **Windows**, the action:

1. Prunes all Docker images

## Usage

```yaml
steps:
  - uses: vicamo/actions-library/maximize-docker-disk@main

  # Docker now has maximum available disk space
  - run: docker build ...
```

## Inputs

| Name              | Description                                               | Default |
| ----------------- | --------------------------------------------------------- | ------- |
| `root-reserve-mb` | Space to reserve on the root filesystem (MB), Linux only. | `512`   |
| `mnt-reserve-mb`  | Space to reserve on /mnt (MB), Linux only.                | `128`   |

## Notes

- The action must run **before** any Docker builds or pulls.
- On Linux, the Docker daemon is restarted as part of the volume migration.
- The merged LVM volume is mounted at `/merged`; Docker data lives at
  `/merged/docker` (bind-mounted to `/var/lib/docker`).
