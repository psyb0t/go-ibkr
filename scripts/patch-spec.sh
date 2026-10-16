#!/bin/bash
# Writes api/openapi.patched.json, a copy of the downloaded IBKR spec with the
# defects that stop oapi-codegen fixed. Run by gen.go after fetch-spec.sh.
#
# Path parameters that the path template does not contain: oapi-codegen refuses
# the operation. When the template has exactly one placeholder that no declared
# parameter covers, the orphan was meant to be that placeholder and is renamed
# to it. Otherwise it is dropped, since there is nowhere in the URL to put it.
# A placeholder that still has no parameter is declared as a required string.
set -euo pipefail
trap 'on_error "$?" "$LINENO"' ERR

LOG_FILE="${LOG_FILE:-/tmp/$(basename "$0" .sh).log}"
exec > >(tee -a "$LOG_FILE") 2>&1

SPEC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/api"
readonly SPEC_DIR
readonly SPEC_IN="${SPEC_DIR}/openapi.json"
readonly SPEC_OUT="${SPEC_DIR}/openapi.patched.json"

on_error() {
	local exit_code="$1"
	local line="$2"

	printf '{"level":"ERROR","file":"%s","line":%d,"msg":"command failed","exit_code":%d}\n' \
		"${BASH_SOURCE[1]}" "$line" "$exit_code" >&2
}

log() {
	local level="$1"
	shift

	jq -nc \
		--arg time "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
		--arg level "$level" \
		--arg file "${BASH_SOURCE[1]##*/}" \
		--arg line "${BASH_LINENO[0]}" \
		--arg func "${FUNCNAME[1]:-main}" \
		--arg msg "$*" \
		'{time:$time,level:$level,file:$file,line:($line|tonumber),func:$func,msg:$msg}' >&2
}

# shellcheck disable=SC2016 # jq program, not shell expansion
readonly FIX_PATH_PARAMS='
.components.parameters as $shared
| def resolve: if has("$ref") then $shared[."$ref" | split("/")[-1]] else . end;
  def placeholders($path): [$path | scan("\\{([^}]+)\\}")[0]];
  def fix($path):
    (placeholders($path)) as $holes
    | ([.[] | resolve | select(.in == "path") | .name]) as $declared
    | ($holes - $declared) as $missing
    | map(
        (resolve) as $p
        | if $p.in != "path" or ($holes | index($p.name)) != null then .
          elif ($missing | length) == 1 then $p + {name: $missing[0]}
          else empty
          end
      )
    | . + [
        ($holes - [.[] | resolve | select(.in == "path") | .name])[]
        | {name: ., in: "path", required: true, schema: {type: "string"}}
      ];
.paths |= with_entries(
  .key as $path
  | .value |= with_entries(
      if (.value | type) == "object" and (.key | IN("get", "put", "post",
        "delete", "options", "head", "patch", "trace"))
      then .value.parameters = ((.value.parameters // []) | fix($path))
      else .
      end
    )
)
'

# Operation IDs used by more than one operation: oapi-codegen emits the same
# type twice. The first use, in spec order, keeps the ID; later ones get a
# numeric suffix (getThing, getThing2, getThing3).
# shellcheck disable=SC2016 # jq program, not shell expansion
readonly DEDUPE_OPERATION_IDS='
reduce (paths(objects) | select(length == 3 and .[0] == "paths")) as $op
  ({doc: ., seen: {}};
    (.doc | getpath($op) | .operationId) as $id
    | if $id == null then .
      elif .seen[$id] == null then .seen[$id] = 1
      else .seen[$id] += 1
        | (.seen[$id] | tostring) as $n
        | .doc |= setpath($op + ["operationId"]; $id + $n)
      end
  )
| .doc
'

main() {
	if [[ ! -f "$SPEC_IN" ]]; then
		log ERROR "spec not found path=${SPEC_IN}, run fetch-spec.sh first"
		exit 1
	fi

	local tmp
	tmp="$(mktemp "${SPEC_DIR}/.openapi.patched.XXXXXX")"
	# shellcheck disable=SC2064 # expand tmp now, the local is gone when EXIT fires
	trap "rm -f -- '${tmp}'" EXIT

	jq "$FIX_PATH_PARAMS | $DEDUPE_OPERATION_IDS" "$SPEC_IN" >"$tmp"
	chmod 0644 "$tmp"
	mv -- "$tmp" "$SPEC_OUT"
	log INFO "patched spec written path=${SPEC_OUT}"
}

main "$@"
