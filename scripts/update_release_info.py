#!/usr/bin/env python3
"""Update the RELEASE_INFO_JSON block in an action.yml file."""

import re
import sys


def main():
    """Update action.yml with new release info JSON."""
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <action.yml> <json>", file=sys.stderr)
        sys.exit(1)

    action_yml = sys.argv[1]
    new_json = sys.argv[2]

    with open(action_yml, encoding="utf-8") as f:
        action = f.read()

    pattern = r"(RELEASE_INFO_JSON: >-\n).*?(\n\n      run:)"
    replacement = r"\g<1>          " + new_json + r"\g<2>"
    result = re.sub(pattern, replacement, action, flags=re.DOTALL)

    with open(action_yml, "w", encoding="utf-8") as f:
        f.write(result)


if __name__ == "__main__":
    main()
