# Debian Releases

[![Debian Releases](https://github.com/vicamo/actions-library/actions/workflows/debian-releases.yml/badge.svg)](https://github.com/vicamo/actions-library/actions/workflows/debian-releases.yml)

## Usage

<!-- start usage -->

```yaml
- uses: vicamo/actions-library/debian-releases@v1
  id: dr
- env:
    RELEASE_INFO_JSON: ${{ steps.dr.outputs.json }}
  run: echo "${RELEASE_INFO_JSON}" | jq
```

<!-- end usage -->

## Customizing

### outputs

The following outputs are available:

| Name   | Type   | Description                       |
| :----- | ------ | :-------------------------------- |
| `json` | String | A JSON-formatted string in below. |

Output `json` object format:

```json
[
  {
    "distribution": "debian",
    "suite": "unstable"
    "codename": "sid"
    "description": "Debian x.y Unstable - Not Released"
    "release": "98"
    "mirrors": {
      "default": {
        "url": "https://deb.debian.org/debian"
        "pockets": {
          "//": "trixie, trixie-updates, etc"
          "sid": {
            "architectures": [
              "all", "amd64", "arm64", "armel", "armhf", "i386", "mips64el",
              "ppc64el", "riscv64", "s390x"
            ]
            "components": [
              "main", "contrib", "non-free-firmware", "non-free"
            ]
          }
        }
      }
      "ports": {
        "url": "http://ftp.ports.debian.org/debian-ports"
        "//": "same layout as the default mirror"
      }
    }
  }
]
```
