#!/usr/bin/env bash
#
# Remove the dev-portal release.
#
#   ./helm/dev-portal/uninstall.sh                 # release only
#   ./helm/dev-portal/uninstall.sh --namespace     # and the namespace with it
#
# Environment overrides:
#   NAMESPACE  (default dev-hub)
#   RELEASE    (default dev-portal)
#
# The namespace is left in place by default: it is cheap, and deleting it takes
# everything else in it, which will not be dev-portal's to delete once a second
# dev-hub component exists.

set -euo pipefail

NAMESPACE="${NAMESPACE:-dev-hub}"
RELEASE="${RELEASE:-dev-portal}"
DROP_NAMESPACE=false

for arg in "$@"; do
  case "$arg" in
    --namespace) DROP_NAMESPACE=true ;;
    -h|--help)   sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^#//'; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

export PATH="$HOME/.rd/bin:$PATH"

helm uninstall "$RELEASE" --namespace "$NAMESPACE"

if [ "$DROP_NAMESPACE" = true ]; then
  remaining=$(helm list --namespace "$NAMESPACE" --short | wc -l | tr -d ' ')
  if [ "$remaining" != "0" ]; then
    echo "refusing to delete namespace '$NAMESPACE': $remaining other release(s) still installed" >&2
    exit 1
  fi
  kubectl delete namespace "$NAMESPACE"
fi
