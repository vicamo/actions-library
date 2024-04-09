#!/bin/bash

set -e

readonly DEFAULT_MIRROR_URL=https://deb.debian.org/debian
readonly ARCHIVE_MIRROR_URL=https://archive.debian.org/debian
readonly PORTS_MIRROR_URL=http://ftp.ports.debian.org/debian-ports

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
      read -r -a arches <<<"$(echo "${content}" |
        awk '/^Architectures:/ {$1=""; $0=$0; print $0}')"
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

full_json=$(
  cat <<EOL
[
  {"distribution":"debian","codename":"experimental","release":""},
  {"distribution":"debian","codename":"sid","release":""},
  {"distribution":"debian","codename":"trixie","release":"13"},
  {"distribution":"debian","codename":"bookworm","release":"12"},
  {"distribution":"debian","codename":"bullseye","release":"11"},
  {"distribution":"debian","codename":"buster","release":"10"},
  {"distribution":"debian","codename":"stretch","release":"9"},
  {"distribution":"debian","codename":"jessie","release":"8"},
  {"distribution":"debian","codename":"wheezy","release":"7"},
  {"distribution":"debian","codename":"squeeze","release":"6"},
  {"distribution":"debian","codename":"lenny","release":"5"}
]
EOL
)

for codename in $(echo "${full_json}" | jq -c -M -r '.[] | .codename'); do
  for m in "${DEFAULT_MIRROR_URL}" "${ARCHIVE_MIRROR_URL}"; do
    content="$({ wget -q -O - "${m}/dists/${codename}/Release" | grep -v '^ '; } || true)"
    if [ -n "${content}" ]; then
      mirror_url=$m
      break
    fi
  done

  active=false
  [ "${mirror_url}" != "${DEFAULT_MIRROR_URL}" ] || active=true

  suite="$(echo "${content}" | awk '/^Suite:/ {print $2}')"
  sc="$({ wget -q -O - "${mirror_url}/dists/${suite}/Release" | grep -v '^ '; } || true)"
  sc_codename="$(echo "${sc}" | awk '/^Codename:/ {print $2}')"
  if [ "${codename}" != "${sc_codename}" ]; then
    suite=
  fi

  desc="$(echo "${content}" | grep -E '^Description:' | cut -d ' ' -f 2-)"
  suite_json="$(echo "${full_json}" |
    jq -c -M ".[] | select(.codename == \"${codename}\") | . + {\"suite\":\"${suite}\",\"description\":\"${desc}\",\"active\":${active}}")"

  pockets_json="$(build_pockets "${mirror_url}" "${codename}")"
  mirrors_json="[{\"name\":\"default\",\"url\":\"${mirror_url}\",\"pockets\":${pockets_json}}]"

  if [ "${codename}" = "sid" ]; then
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
    jq -c -M "[.[] | select(.codename == \"${codename}\") |= ${suite_json}]")"
done

echo "${full_json}"
