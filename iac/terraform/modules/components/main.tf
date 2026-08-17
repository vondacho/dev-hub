# Delivery of the dev-hub components, from the charts under helm/.
#
# The module owns exactly one idea: take the registry in iac/components.yaml,
# take the charts it points at, and install each one with the profile stack
# described in iac/profiles/README.md. It knows nothing about which cloud it is
# running on — that arrives as the profile name, the registry prefix and the
# base domain.

locals {
  registry = yamldecode(file(var.components_file)).components

  components = {
    for name, c in local.registry : name => c
    if length(var.only) == 0 || contains(var.only, name)
  }

  namespaces = toset([for c in local.components : c.namespace])

  # Layer 2 and 3 of the stack. Layer 1 is the chart's own values.yaml, which
  # Helm reads on its own; layer 4 is computed below.
  common_profile   = "${var.profiles_dir}/common.yaml"
  provider_profile = "${var.profiles_dir}/${var.profile}.yaml"

  # Layer 4 — everything that is true of this environment and no other.
  overlay = {
    for name, c in local.components : name => yamlencode(merge(
      {
        image = {
          repository = "${var.registry}/${c.image}"
          tag        = var.image_tag
        }

        imagePullSecrets = [for s in var.image_pull_secrets : { name = s }]

        # Spread a component's replicas over nodes. Soft, so a single-node
        # cluster or a drained zone can still place the pod — and selecting on
        # the release, because app.kubernetes.io/instance is the one selector
        # label that is certainly this component's own.
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [{
              weight = 100
              podAffinityTerm = {
                topologyKey = "kubernetes.io/hostname"
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/instance" = c.release
                  }
                }
              }
            }]
          }
        }

        ingress = merge(
          {
            enabled = true
            hosts = [{
              host  = "${c.host}.${var.base_domain}"
              paths = [{ path = "/", pathType = "Prefix" }]
            }]
            tls = var.tls_enabled ? [{
              secretName = "${c.release}-tls"
              hosts      = ["${c.host}.${var.base_domain}"]
            }] : []
          },
          # Left out entirely when empty, so the profile's className survives.
          # A merge here would overwrite it with "".
          var.ingress_class_name != "" ? { className = var.ingress_class_name } : {},
          # Merged by Helm over the profile's annotations rather than replacing
          # them, so the cert-manager issuer the profile asks for survives.
          length(var.ingress_annotations) > 0 ? { annotations = var.ingress_annotations } : {},
        )
      },
      # Browser-facing links to the neighbouring components, resolved under the
      # same base domain. Omitted when a component declares none, so the chart's
      # own defaults stay in force rather than being overwritten with {}.
      length(try(c.links, {})) > 0 ? {
        app = { for key, host in c.links : key => "${var.url_scheme}://${host}.${var.base_domain}" }
      } : {},
    ))
  }
}

resource "kubernetes_namespace_v1" "this" {
  for_each = var.create_namespaces ? local.namespaces : toset([])

  metadata {
    name = each.value
    labels = merge(
      { "app.kubernetes.io/part-of" = "dev-hub" },
      var.namespace_labels,
    )
  }

  # The namespace outlives any single release: a second dev-hub component
  # installed into it must not be taken down by removing the first.
  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "component" {
  for_each = local.components

  name      = each.value.release
  chart     = "${var.repo_root}/${each.value.chart}"
  namespace = each.value.namespace

  # Ordered: last file wins on any key it sets.
  values = compact([
    file(local.common_profile),
    file(local.provider_profile),
    local.overlay[each.key],
    lookup(var.component_values, each.key, ""),
  ])

  atomic          = var.atomic
  cleanup_on_fail = true
  wait            = true
  timeout         = var.wait_timeout

  # Namespaces are created above rather than by Helm, so that removing a
  # release never proposes removing the namespace its neighbours live in.
  create_namespace = false

  depends_on = [kubernetes_namespace_v1.this]
}
