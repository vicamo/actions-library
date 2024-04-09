# Ubuntu Releases

[![Ubuntu Releases](https://github.com/vicamo/actions-library/actions/workflows/ubuntu-releases.yml/badge.svg)](https://github.com/vicamo/actions-library/actions/workflows/ubuntu-releases.yml)

## Usage

<!-- start usage -->

```yaml
- uses: vicamo/actions-library/ubuntu-releases@v1
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

<!-- markdownlint-disable MD013 -->

```json
[
  {
    "distribution": "ubuntu",
    "suite": "devel"
    "codename": "noble"
    "description": "Ubuntu Noble 24.04"
    "active": true
    "release": "24.04"
    "//": "merge from all pockets"
    "architectures": [
      "amd64", "i386", ...
    ]
    "//": "merge from all pockets"
    "components": [
      "main", "restricted", "universe", "multiverse"
    ]
    "mirrors": [
      {
        "name": "default"
        "url": "http://archive.ubuntu.com/ubuntu"
        "pockets": {
          "//": "noble-backports, noble-proposed, noble-updates, noble-security, etc."
          "noble": {
            "architectures": [
              "amd64","i386"
            ]
            "components": [
              "main","restricted","universe","multiverse"
            ]
          }
        }
      },
      {
        "name": "ports"
        "url": "http://ports.ubuntu.com/ubuntu-ports"
        "//": "same layout as the default mirror"
      }
    ]
  }
]
```

<!-- markdownlint-enable MD013 -->
