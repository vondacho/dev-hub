#!/usr/bin/env bash
#
# Check that this machine can actually deliver to a provider, before an apply
# finds out for you halfway through creating a VPC.
#
#   ./iac/scripts/preflight.sh aws
#   ./iac/scripts/preflight.sh digitalocean
#   ./iac/scripts/preflight.sh generic
#
# Reports everything it finds rather than stopping at the first problem — one
# run should tell you the whole list.

set -uo pipefail

PROVIDER="${1:-}"
case "$PROVIDER" in
  aws | digitalocean | generic) ;;
  *) echo "usage: $(basename "$0") <aws|digitalocean|generic>" >&2; exit 2 ;;
esac

export PATH="$HOME/.rd/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IAC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$IAC_ROOT/.." && pwd)"

failures=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; failures=$((failures + 1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

need() {
  local tool="$1" why="$2"
  if command -v "$tool" >/dev/null; then
    ok "$tool"
  else
    bad "$tool is missing — $why"
  fi
}

echo "Tools"
need terraform "the environments under iac/terraform are Terraform roots"
need helm      "the charts under helm/ are installed with it, by every path"
need kubectl   "not used by the delivery, but you will want it the moment it fails"

case "$PROVIDER" in
  aws)
    need aws "the Kubernetes provider authenticates with 'aws eks get-token'"
    ;;
  digitalocean)
    need doctl "the Kubernetes provider authenticates with 'doctl ... exec-credential'"
    ;;
esac

echo
echo "Credentials"
case "$PROVIDER" in
  aws)
    if aws sts get-caller-identity >/dev/null 2>&1; then
      ok "AWS: $(aws sts get-caller-identity --query Arn --output text)"
    else
      bad "AWS credentials are not usable — check AWS_PROFILE or run 'aws sso login'"
    fi
    ;;
  digitalocean)
    if [ -n "${DIGITALOCEAN_TOKEN:-}" ]; then
      ok "DIGITALOCEAN_TOKEN is set"
    else
      bad "DIGITALOCEAN_TOKEN is not set — the provider reads it from the environment, not from tfvars"
    fi
    if doctl account get >/dev/null 2>&1; then
      ok "doctl is authenticated"
    else
      warn "doctl is not authenticated — needed for the kubeconfig and the registry login, not for the apply"
    fi
    ;;
  generic)
    if kubectl config current-context >/dev/null 2>&1; then
      ok "kubeconfig context: $(kubectl config current-context)"
    else
      bad "no current kubeconfig context — this environment delivers to a cluster that already exists"
    fi
    ;;
esac

echo
echo "Repository"
[ -f "$IAC_ROOT/components.yaml" ] \
  && ok "iac/components.yaml" \
  || bad "iac/components.yaml is missing — it is the registry both delivery paths read"

[ -f "$IAC_ROOT/profiles/$PROVIDER.yaml" ] \
  && ok "iac/profiles/$PROVIDER.yaml" \
  || bad "iac/profiles/$PROVIDER.yaml is missing"

# Every chart the registry points at has to exist, or the delivery fails on the
# one component nobody checked.
if command -v helm >/dev/null; then
  for chart in "$REPO_ROOT"/helm/*/Chart.yaml; do
    [ -e "$chart" ] || continue
    dir="$(dirname "$chart")"
    if helm lint "$dir" >/dev/null 2>&1; then
      ok "helm lint $(basename "$dir")"
    else
      bad "helm lint $(basename "$dir") failed — run it by hand for the reason"
    fi
  done
fi

if [ -f "$IAC_ROOT/terraform/envs/$PROVIDER/terraform.tfvars" ]; then
  ok "terraform.tfvars for $PROVIDER"
else
  warn "no iac/terraform/envs/$PROVIDER/terraform.tfvars — copy terraform.tfvars.example"
fi

echo
if [ "$failures" -eq 0 ]; then
  printf '\033[32mReady.\033[0m\n'
else
  printf '\033[31m%d problem(s).\033[0m\n' "$failures"
  exit 1
fi
