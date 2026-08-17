# Cluster-side platform: the pieces every dev-hub environment needs before a
# component can be reached, and which no chart under helm/ should have to own.
#
# Deliberately provider-agnostic. The one place a cloud shows through is the
# annotation set on the ingress controller's LoadBalancer Service, which the
# environment passes in — that is what lets iac/profiles/aws.yaml and
# iac/profiles/digitalocean.yaml stay almost the same file.

resource "helm_release" "ingress_nginx" {
  count = var.ingress_nginx ? 1 : 0

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_version
  namespace  = "ingress-nginx"

  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  # Waits on the cloud provisioning an actual load balancer.
  timeout = var.wait_timeout

  values = compact([
    yamlencode({
      controller = {
        replicaCount = var.ingress_nginx_replicas
        service = {
          type                  = var.ingress_service_type
          annotations           = var.ingress_service_annotations
          externalTrafficPolicy = var.ingress_external_traffic_policy
        }
        # Marked default so a chart that leaves ingress.className empty — as
        # iac/profiles/generic.yaml does — still lands here.
        ingressClassResource = {
          name    = "nginx"
          enabled = true
          default = true
        }
        # Spread the controllers, and let a rollout stay serving.
        topologySpreadConstraints = [{
          maxSkew           = 1
          topologyKey       = "kubernetes.io/hostname"
          whenUnsatisfiable = "ScheduleAnyway"
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name"      = "ingress-nginx"
              "app.kubernetes.io/component" = "controller"
            }
          }
        }]
        config = {
          # The portal is server-rendered HTML; compressing it on the edge is
          # free bandwidth.
          use-gzip = "true"
          # Trust the load balancer in front, so the client IP in the logs is
          # the client's.
          use-forwarded-headers = "true"
        }
        resources = {
          requests = { cpu = "100m", memory = "256Mi" }
        }
      }
    }),
    var.ingress_nginx_extra_values,
  ])
}

resource "helm_release" "cert_manager" {
  count = var.cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = "cert-manager"

  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = var.wait_timeout

  values = [yamlencode({
    # Let the chart own the CRDs. The alternative — applying them out of band —
    # means an upgrade silently leaves the old schema in place.
    crds = { enabled = true, keep = true }
    resources = {
      requests = { cpu = "10m", memory = "64Mi" }
    }
  })]

  lifecycle {
    precondition {
      condition     = var.acme_email != ""
      error_message = "acme_email is required when cert_manager is enabled: ACME registration fails without a contact address."
    }
  }
}

# The ClusterIssuer ships as a one-template local chart, in iac/charts so that
# the Ansible delivery path installs the same object from the same source,
# rather than as a kubernetes_manifest resource. kubernetes_manifest reads the
# CRD schema from the live API *during plan*, so on a cluster where cert-manager
# is being installed by this same apply the first plan cannot succeed — the
# familiar "two applies, and remember which one" dance. A helm_release is only
# resolved at apply time, after the release it depends on has been waited for,
# so the whole platform comes up in one go.
resource "helm_release" "cluster_issuer" {
  count = var.cert_manager ? 1 : 0

  name = "cluster-issuer"
  # modules/platform -> modules -> terraform -> iac
  chart     = "${path.module}/../../../charts/cluster-issuer"
  namespace = "cert-manager"

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 300

  values = [yamlencode({
    name    = var.cluster_issuer_name
    email   = var.acme_email
    staging = var.acme_staging
    # Solved over HTTP-01 through the controller installed above, so an
    # issuer that exists always has something to answer the challenge.
    ingressClassName = "nginx"
  })]

  depends_on = [
    helm_release.cert_manager,
    helm_release.ingress_nginx,
  ]
}

resource "helm_release" "metrics_server" {
  count = var.metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_version
  namespace  = "kube-system"

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 300
}
