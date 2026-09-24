# Python Versions

[![Python Versions](https://github.com/vicamo/actions-library/actions/workflows/python-versions.yml/badge.svg)](https://github.com/vicamo/actions-library/actions/workflows/python-versions.yml)

Parses [`actions/python-versions`][upstream]'s `versions-manifest.json` and
emits a filtered JSON summary suitable for feeding into a job matrix that uses
`actions/setup-python`.

[upstream]:
  https://raw.githubusercontent.com/actions/python-versions/refs/heads/main/versions-manifest.json

## Usage

<!-- start usage -->

```yaml
jobs:
  discover:
    runs-on: ubuntu-latest
    outputs:
      versions: ${{ steps.pv.outputs.versions }}
    steps:
      - uses: vicamo/actions-library/python-versions@v1
        id: pv
        with:
          version-range: '>=3.9,<3.14'
          latest-only: 'true'

  build:
    needs: discover
    strategy:
      matrix:
        python-version: ${{ fromJSON(needs.discover.outputs.versions) }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: python --version
```

<!-- end usage -->

## Inputs

| Name               | Default          | Description                                                                                                 |
| :----------------- | :--------------- | :---------------------------------------------------------------------------------------------------------- |
| `stable`           | `true`           | Keep only manifest entries with `stable: true`. Set to `false` to also include prereleases.                 |
| `version-range`    | `''`             | PEP440-style specifier(s) joined by commas, e.g. `>=3.9,<3.13`. Empty = no range.                           |
| `latest-only`      | `false`          | Collapse to the latest patch per major.minor (X.Y) series.                                                  |
| `platform`         | `''`             | CSV of platforms to keep: `linux`, `darwin`, `win32`, `rhel`.                                               |
| `arch`             | `''`             | CSV of arches to keep: `x64`, `arm64`, `x86`, `arm64-freethreaded`, `x64-freethreaded`, `x86-freethreaded`. |
| `platform-version` | `''`             | CSV of `platform_version` values to keep (e.g. `22.04,24.04`). Only applies to platforms that carry one.    |
| `freethreaded`     | `any`            | `any` = no filter, `only` = keep freethreaded arches only, `exclude` = drop them.                           |
| `exclude-eol`      | `false`          | Drop X.Y series past their end-of-life date (fetched from `eol-url`).                                       |
| `limit`            | `''`             | Keep at most N entries after sort. Empty / `0` = no limit.                                                  |
| `sort`             | `desc`           | Version order: `desc` (newest first) or `asc`.                                                              |
| `manifest-url`     | _upstream_       | Override the versions-manifest.json URL (pin to a fork/tag).                                                |
| `eol-url`          | _endoflife.date_ | Override the EOL JSON URL (endoflife.date format). Only fetched when `exclude-eol=true`.                    |

The `platform` / `arch` / `platform-version` / `freethreaded` filters also
**prune** the `platforms` array of each entry so the `json` output only contains
matching combinations; a version whose platforms all get pruned is dropped
entirely.

## Outputs

| Name       | Type   | Description                                                            |
| :--------- | :----- | :--------------------------------------------------------------------- |
| `json`     | String | Filtered array of version entries (see shape below).                   |
| `versions` | String | JSON array of version strings, suitable for `fromJSON(...)` in matrix. |

### `json` shape

```json
[
  {
    "version": "3.13.0",
    "stable": true,
    "release_url": "https://github.com/actions/python-versions/releases/tag/3.13.0-...",
    "platforms": [
      {
        "platform": "linux",
        "platform_version": "24.04",
        "arches": ["arm64", "x64"]
      },
      { "platform": "darwin", "arches": ["arm64", "x64"] }
    ]
  }
]
```

`platform_version` is omitted for platforms that don't carry one (darwin,
win32).
