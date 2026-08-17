#!/usr/bin/env bash
#
# Build every dev-hub component image and push it to a registry.
#
#   ./iac/scripts/build-push.sh --registry 1234.dkr.ecr.eu-central-1.amazonaws.com
#   ./iac/scripts/build-push.sh --registry registry.digitalocean.com/dev-hub --tag "$(git rev-parse --short HEAD)"
#   ./iac/scripts/build-push.sh --registry ghcr.io/vondacho --only dev-portal --no-push
#
# The images have to exist before a release is installed. A missing image does
# not fail the helm upgrade immediately — it fails several minutes later as an
# ImagePullBackOff, which reads like a cluster problem and is not.
#
# What gets built comes from iac/components.yaml, so this script and the
# Terraform and Ansible paths cannot disagree about what "all the components"
# means.

set -euo pipefail

REGISTRY=""
TAG="latest"
ONLY=()
PUSH=true
PLATFORM="linux/amd64"
ENGINE=""
LOGIN=""

usage() {
  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^#//;s/^ //'
  cat <<'EOF'

Options:
  --registry <prefix>  Registry, no trailing slash and no image name. Required.
  --tag <tag>          Image tag. Default: latest. Prefer a git SHA.
  --only <name>        Build one component. Repeatable. Default: all of them.
  --platform <p>       Target architecture. Default: linux/amd64.
  --engine <cmd>       docker, nerdctl or podman. Default: autodetected.
  --login <command>    Run before pushing, e.g. "doctl registry login".
  --no-push            Build only.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --registry) REGISTRY="$2"; shift 2 ;;
    --tag)      TAG="$2";      shift 2 ;;
    --only)     ONLY+=("$2");  shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --engine)   ENGINE="$2";   shift 2 ;;
    --login)    LOGIN="$2";    shift 2 ;;
    --no-push)  PUSH=false;    shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$REGISTRY" ] || { echo "--registry is required" >&2; exit 2; }

# Resolve paths from this script rather than the caller's cwd, so it runs from
# anywhere in the repository.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IAC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$IAC_ROOT/.." && pwd)"
REGISTRY_FILE="$IAC_ROOT/components.yaml"

# Rancher Desktop puts docker, nerdctl, helm and kubectl here and does not
# always add it to a non-login shell's PATH.
export PATH="$HOME/.rd/bin:$PATH"

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

# --- reading the registry --------------------------------------------------
# One of yq or PyYAML, rather than an awk parser that works until somebody
# reformats components.yaml.
read_components() {
  if command -v yq >/dev/null; then
    yq -r '.components | to_entries[] | "\(.key)\t\(.value.image)\t\(.value.source)"' "$REGISTRY_FILE"
  elif python3 -c 'import yaml' 2>/dev/null; then
    python3 - "$REGISTRY_FILE" <<'PY'
import sys, yaml
with open(sys.argv[1]) as fh:
    for name, c in yaml.safe_load(fh)["components"].items():
        print(f"{name}\t{c['image']}\t{c['source']}")
PY
  else
    cat >&2 <<'EOF'
Neither yq nor PyYAML is available, and one of them is needed to read
iac/components.yaml:

  brew install yq          # or
  python3 -m pip install pyyaml

The Ansible path (iac/ansible) reads the same file without either.
EOF
    exit 1
  fi
}

# --- build engine ----------------------------------------------------------
if [ -z "$ENGINE" ]; then
  for candidate in docker nerdctl podman; do
    if command -v "$candidate" >/dev/null; then ENGINE="$candidate"; break; fi
  done
  [ -n "$ENGINE" ] || { echo "no container build engine found (docker, nerdctl, podman)" >&2; exit 1; }
fi
command -v "$ENGINE" >/dev/null || { echo "$ENGINE not found on PATH" >&2; exit 1; }

# buildx builds and pushes in one step, and is the only way to cross-build for
# another architecture — which matters more than it sounds: a build on an Apple
# Silicon laptop otherwise produces an arm64 image that lands on an amd64 node
# and dies with "exec format error", a failure that looks nothing like its
# cause.
USE_BUILDX=false
if [ "$ENGINE" = "docker" ] && docker buildx version >/dev/null 2>&1; then
  USE_BUILDX=true
fi

if [ -n "$LOGIN" ]; then
  step "Authenticating against $REGISTRY"
  eval "$LOGIN"
fi

# Read the registry up front rather than piping it into the loop: inside a
# process substitution, read_components' exit status is the subshell's and gets
# lost, so a missing yq would report "no components matched" instead of the
# reason.
COMPONENTS="$(read_components)" || exit 1

built=0
while IFS=$'\t' read -r name image source; do
  [ -n "$name" ] || continue

  if [ ${#ONLY[@]} -gt 0 ]; then
    match=false
    for wanted in "${ONLY[@]}"; do [ "$wanted" = "$name" ] && match=true; done
    [ "$match" = true ] || continue
  fi

  ref="$REGISTRY/$image:$TAG"
  context="$REPO_ROOT/$source"
  [ -d "$context" ] || { echo "build context does not exist: $context" >&2; exit 1; }

  if [ "$USE_BUILDX" = true ]; then
    step "Building $ref for $PLATFORM"
    args=(buildx build --platform "$PLATFORM" -t "$ref")
    # Without one of these the image stays in the build cache and exists
    # nowhere a kubelet or a `docker run` can find it.
    if [ "$PUSH" = true ]; then args+=(--push); else args+=(--load); fi
    args+=("$context")
    "$ENGINE" "${args[@]}"
  else
    step "Building $ref"
    "$ENGINE" build --platform "$PLATFORM" -t "$ref" "$context"
    if [ "$PUSH" = true ]; then
      step "Pushing $ref"
      "$ENGINE" push "$ref"
    fi
  fi

  built=$((built + 1))
done <<< "$COMPONENTS"

[ "$built" -gt 0 ] || { echo "no components matched" >&2; exit 1; }

step "Done — $built image(s) at tag '$TAG'"
if [ "$PUSH" = false ]; then
  echo "Not pushed. The cluster cannot pull what is only on this machine."
fi
