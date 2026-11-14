#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_JSON="$SCRIPT_DIR/versions.json"
APP_MANIFEST="https://releases.herdr.dev/app/latest.json"
CORE_MANIFEST="https://releases.herdr.dev/core/latest.json"
TARGETS=("x86_64-linux" "aarch64-linux")

# The release manifests use upstream's target names; versions.json is keyed
# by Nix system.
manifest_target() {
    case "$1" in
        x86_64-linux) echo "linux-x86_64" ;;
        aarch64-linux) echo "linux-aarch64" ;;
        *) echo "unsupported target: $1" >&2; exit 1 ;;
    esac
}

current_version() {
    jq -r ".$1.version" "$VERSIONS_JSON"
}

update_channel() {
    local name="$1" manifest="$2"
    local version current

    version=$(jq -r '.version' <<<"$manifest")
    current=$(current_version "$name")

    echo "Current $name: $current"
    echo "Latest $name:  $version"

    if [ "$current" = "$version" ]; then
        echo "$name is already up to date!"
        return
    fi

    local -A hashes=()
    for target in "${TARGETS[@]}"; do
        local entry url want have expected

        entry=$(jq -r --arg t "$(manifest_target "$target")" '.targets[$t] | select(.) | "\(.url) \(.sha256)"' <<<"$manifest")
        if [ -z "$entry" ]; then
            echo "No $target build in the $name manifest" >&2
            exit 1
        fi

        url=${entry% *}
        want=${entry#* }

        echo "Fetching $name $version for $target..."
        have=$(nix store prefetch-file --json "$url" | jq -r '.hash')
        expected=$(nix hash convert --hash-algo sha256 --to sri "$want")

        if [ "$have" != "$expected" ]; then
            echo "Hash mismatch for $url" >&2
            echo "  manifest: $expected" >&2
            echo "  download: $have" >&2
            exit 1
        fi

        hashes["$target"]="$have"
        echo "  $target: $have"
    done

    # Only touch versions.json once every platform has been fetched and
    # verified, so a failed run leaves the pinned versions intact.
    local tmp="$VERSIONS_JSON.tmp"
    jq --arg v "$version" ".$name.version = \$v" "$VERSIONS_JSON" > "$tmp"
    for target in "${TARGETS[@]}"; do
        jq --arg t "$target" --arg h "${hashes[$target]}" \
            ".$name.hashes[\$t] = \$h" "$tmp" > "$tmp.next"
        mv "$tmp.next" "$tmp"
    done
    mv "$tmp" "$VERSIONS_JSON"

    echo "Updated $name to version $version"
}

app_json=$(curl -fsSL "$APP_MANIFEST")
core_json=$(curl -fsSL "$CORE_MANIFEST")

update_channel app "$app_json"
update_channel core "$core_json"
