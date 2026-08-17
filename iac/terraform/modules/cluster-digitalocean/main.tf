# DigitalOcean landing zone for dev-hub: a VPC, a DOKS cluster, and the account
# container registry.
#
# The counterpart of cluster-aws, and deliberately the same shape: it stops at
# the cluster boundary and hands back a kubeconfig and a registry prefix, so the
# platform and components modules on top of it do not change at all.

data "digitalocean_kubernetes_versions" "this" {
  version_prefix = var.kubernetes_version_prefix
}

resource "digitalocean_vpc" "this" {
  name     = var.name
  region   = var.region
  ip_range = var.vpc_cidr != "" ? var.vpc_cidr : null
}

resource "digitalocean_kubernetes_cluster" "this" {
  name    = var.name
  region  = var.region
  version = data.digitalocean_kubernetes_versions.this.latest_version

  vpc_uuid = digitalocean_vpc.this.id

  auto_upgrade  = var.auto_upgrade
  surge_upgrade = var.surge_upgrade
  ha            = var.ha_control_plane

  # Node pool changes are applied in place by DOKS. Without this the resource
  # is replaced whenever a size or a bound moves — and replacing a cluster
  # means new load balancers, new IPs, and DNS pointing at nothing.
  destroy_all_associated_resources = false

  # Registry credentials distributed to every namespace by DOKS. This is why
  # imagePullSecrets in iac/profiles/digitalocean.yaml only needs a name, not a
  # secret anyone here has to create.
  registry_integration = var.registry_integration

  maintenance_policy {
    day        = var.maintenance_day
    start_time = var.maintenance_start_time
  }

  node_pool {
    name = "${var.name}-default"
    size = var.node_size

    auto_scale = var.node_auto_scale
    node_count = var.node_auto_scale ? null : var.node_count
    min_nodes  = var.node_auto_scale ? var.node_min_nodes : null
    max_nodes  = var.node_auto_scale ? var.node_max_nodes : null

    labels = {
      "dev-hub.io/pool" = "default"
    }

    tags = var.tags
  }

  tags = var.tags

  lifecycle {
    # With auto_upgrade on, DOKS moves the patch version underneath us. Fighting
    # that on every plan would mean either turning the upgrades off or applying
    # a downgrade that the API refuses anyway.
    ignore_changes = [version]

    precondition {
      condition     = !var.registry_integration || var.registry_name != ""
      error_message = "registry_name is required when registry_integration is enabled."
    }
  }
}

# One registry per DigitalOcean *account*, not per cluster. Off by default:
# importing the account's existing registry is right far more often than
# creating one, and destroying this resource deletes every image in it.
resource "digitalocean_container_registry" "this" {
  count = var.create_registry ? 1 : 0

  name                   = var.registry_name
  subscription_tier_slug = var.registry_tier
  region                 = var.region
}
