#!/bin/bash

set -e

update_action_yml=false
while [ $# -gt 0 ]; do
  case "$1" in
  --update-action-yml) update_action_yml=true; shift ;;
  *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly LP_SERIES_API_URL=https://api.launchpad.net/devel/ubuntu/series
readonly DEFAULT_MIRROR_URL=http://archive.ubuntu.com/ubuntu
readonly OLD_RELEASES_MIRROR_URL=https://old-releases.ubuntu.com/ubuntu
readonly PORTS_MIRROR_URL=http://ports.ubuntu.com/ubuntu-ports

declare -A mirror_pockets
function get_pockets_for_mirror() {
  local mirror_url=$1
  shift
  local content

  content="${mirror_pockets["${mirror_url}"]:-}"
  if [ -z "${content}" ]; then
    content="$(wget -q -O - "${mirror_url}/dists" |
      grep -E 'href="[A-Za-z0-9-]+/"' |
      sed 's,.* href="\([^"]\+\)/".*,\1,' | tr '\n' ' ')"
    mirror_pockets["${mirror_url}"]="${content}"
  fi

  echo "${content}"
}

function build_pockets() {
  local mirror_url=$1
  shift
  local codename=$1
  shift

  local pockets_json="{}"
  read -r -a pockets <<<"$(get_pockets_for_mirror "${mirror_url}")"

  local pockets_json="{}"
  for pocket in "${pockets[@]}"; do
    case "${pocket}" in
    "${codename}"*)
      local content
      local arches_json
      local comps_json

      content="$({ wget -q -O - "${mirror_url}/dists/${pocket}/Release" | grep -v '^ '; } || true)"

      read -r -a declared_arches <<<"$(echo "${content}" |
        awk '/^Architectures:/ {$1=""; $0=$0; print $0}')"
      arches=()
      for arch in "${declared_arches[@]}"; do
        if wget --spider -q "${mirror_url}/dists/${pocket}/main/binary-${arch}/Release"; then
          arches+=("${arch}")
        fi
      done
      arches_json="$(jq -c -M -n '$ARGS.positional' --args "${arches[@]}")"

      read -r -a comps <<<"$(echo "${content}" |
        awk '/^Components:/ {$1=""; $0=$0; print $0}')"
      comps_json="$(jq -c -M -n '$ARGS.positional' --args "${comps[@]}")"

      pockets_json="$(echo "${pockets_json}" |
        jq -c -M ". + {\"${pocket}\":{\"architectures\":${arches_json},\"components\":${comps_json}}}")"
      ;;
    esac
  done

  echo "${pockets_json}"
}

full_json="$(wget -q -O - "${LP_SERIES_API_URL}" |
  jq -c -M '[.entries[] | {"distribution":"ubuntu","codename":.name,"release":.version}]')"

stable="$(echo "${full_json}" |
          jq -r -c -M '.[1:] |
                       map(select(.release |
                                  sub("(?<r>[0-9]+).*"; "\(.r)") |
                                  tonumber | ((. % 2) == 0))) |
                       .[0].codename')"

content="$({ wget -q -O - "${DEFAULT_MIRROR_URL}/dists/devel/Release" | grep -v '^ '; } || true)"
devel="$(echo "${content}" | awk '/^Codename:/ {print $2}')"

for codename in $(echo "${full_json}" | jq -c -M -r '.[] | .codename'); do
  for m in "${DEFAULT_MIRROR_URL}" "${OLD_RELEASES_MIRROR_URL}"; do
    content="$({ wget -q -O - "${m}/dists/${codename}/Release" | grep -v '^ '; } || true)"
    if [ -n "${content}" ]; then
      mirror_url=$m
      break
    fi
  done

  active=false
  [ "${mirror_url}" != "${DEFAULT_MIRROR_URL}" ] || active=true

  suite=
  if [ "${codename}" = "${devel}" ]; then
    suite="devel"
  elif [ "${codename}" = "${stable}" ]; then
    suite="stable"
  fi

  status=Obsolete
  case "${active}/${suite}" in
  true/devel) status="Active Development" ;;
  true/stable) status="Current Stable Release" ;;
  true/*) status="Supported" ;;
  esac

  desc="$(echo "${content}" | grep -E '^Description:' | cut -d ' ' -f 2-)"
  suite_json="$(echo "${full_json}" |
    jq -c -M ".[] |
              select(.codename == \"${codename}\") |
              . + {
                \"suite\":\"${suite}\",
                \"description\":\"${desc}\",
                \"active\":${active},
                \"status\":\"${status}\"
              }")"

  pockets_json="$(build_pockets "${mirror_url}" "${codename}")"
  mirrors_json="[{\"name\":\"default\",\"url\":\"${mirror_url}\",\"pockets\":${pockets_json}}]"

  if [ "${mirror_url}" = "${DEFAULT_MIRROR_URL}" ]; then
    pockets_json="$(build_pockets "${PORTS_MIRROR_URL}" "${codename}")"
    mirrors_json="$(echo "${mirrors_json}" |
      jq -c -M ". + [{\"name\":\"ports\",\"url\":\"${PORTS_MIRROR_URL}\",\"pockets\":${pockets_json}}]")"
  fi

  suite_json="$(echo "${suite_json}" |
    jq -c -M ". + {\"mirrors\":${mirrors_json}}")"
  suite_json="$(echo "${suite_json}" |
    jq -c -M '. + {architectures: [.mirrors[].pockets[].architectures[]] | unique}')"
  suite_json="$(echo "${suite_json}" |
    jq -c -M '. + {components: [.mirrors[].pockets[].components[]] | unique}')"

  full_json="$(echo "${full_json}" |
    jq -c -M -S "[.[] | select(.codename == \"${codename}\") |= ${suite_json}]")"
done

if [ "${update_action_yml}" = true ]; then
  action_yml="${SCRIPT_DIR}/action.yml"
  python3 "${SCRIPT_DIR}/../scripts/update_release_info.py" "${action_yml}" "${full_json}"
  if command -v prettier > /dev/null 2>&1; then
    prettier --write "${action_yml}" > /dev/null 2>&1
  elif command -v npx > /dev/null 2>&1; then
    npx prettier --write "${action_yml}" > /dev/null 2>&1
  fi
fi

echo "${full_json}"
