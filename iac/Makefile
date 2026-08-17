# Delivery of the dev-hub components to a cloud.
#
#   make preflight PROVIDER=aws
#   make up        PROVIDER=aws
#   make images    PROVIDER=aws TAG=$(git rev-parse --short HEAD)
#   make deploy    PROVIDER=aws TAG=$(git rev-parse --short HEAD)
#
# PROVIDER selects both the Terraform environment and the Helm profile:
# aws, digitalocean, or generic for a cluster this repository did not create.
#
# Nothing here is required — every target is one or two commands you can also
# type by hand, and the recipes print them. The Makefile exists so the order
# and the two-apply bootstrap are not folklore.

PROVIDER ?= generic
TAG      ?= latest

TF        := terraform
ENV_DIR   := terraform/envs/$(PROVIDER)
ANSIBLE   := ansible-playbook -i ansible/inventories/$(PROVIDER)
HELM_ARGS :=

# Rancher Desktop keeps helm, kubectl, docker and nerdctl here and does not
# always put it on a non-login shell's PATH.
export PATH := $(HOME)/.rd/bin:$(PATH)

# Read back from the environment once it exists, so `make images` does not need
# the registry spelled out again.
REGISTRY ?= $(shell $(TF) -chdir=$(ENV_DIR) output -raw registry 2>/dev/null)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@echo "Targets (PROVIDER=$(PROVIDER)):"
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[1m%-12s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "  PROVIDER  aws | digitalocean | generic   (currently: $(PROVIDER))"
	@echo "  TAG       image tag to deliver           (currently: $(TAG))"

.PHONY: preflight
preflight: ## Check tools, credentials and charts before anything is created
	@./scripts/preflight.sh $(PROVIDER)

.PHONY: init
init: ## terraform init for this provider's environment
	$(TF) -chdir=$(ENV_DIR) init

.PHONY: fmt
fmt: ## Format every Terraform file
	$(TF) fmt -recursive terraform

.PHONY: validate
validate: ## Validate the environment without touching a cloud
	$(TF) -chdir=$(ENV_DIR) init -backend=false
	$(TF) -chdir=$(ENV_DIR) validate

.PHONY: plan
plan: ## Show what an apply would do
	$(TF) -chdir=$(ENV_DIR) plan

.PHONY: up
up: ## Create the cluster, then the platform and the components
ifeq ($(PROVIDER),generic)
	@echo "==> No cluster to create — delivering to the one in the kubeconfig"
	$(TF) -chdir=$(ENV_DIR) apply
else
	@echo "==> 1/2  cluster only"
	@# The Kubernetes and Helm providers are configured from the cluster this
	@# same root module creates, so their configuration is unknown until it
	@# exists. Terraform allows that only while no resource of theirs is in the
	@# plan — which is what these two flags buy. Every later apply is one pass.
	$(TF) -chdir=$(ENV_DIR) apply \
	  -var deploy_platform=false -var deploy_components=false
	@echo "==> 2/2  platform and components"
	$(TF) -chdir=$(ENV_DIR) apply
endif

.PHONY: apply
apply: ## Single apply — right for every run after the first
	$(TF) -chdir=$(ENV_DIR) apply

.PHONY: output
output: ## Show the environment's outputs — URLs, DNS names, registry
	$(TF) -chdir=$(ENV_DIR) output

.PHONY: images
images: ## Build and push every component image at TAG
	@test -n "$(REGISTRY)" || { \
	  echo "REGISTRY is empty: pass REGISTRY=... or apply the environment first"; exit 2; }
	./scripts/build-push.sh --registry "$(REGISTRY)" --tag "$(TAG)"

.PHONY: deploy
deploy: ## Deliver the components with Ansible instead of Terraform
	cd ansible && $(ANSIBLE) playbooks/deploy.yml -e image_tag=$(TAG)

.PHONY: platform
platform: ## Install ingress-nginx, cert-manager and the issuer with Ansible
	cd ansible && $(ANSIBLE) playbooks/platform.yml

.PHONY: verify
verify: ## Run the charts' own helm tests against the delivered releases
	cd ansible && $(ANSIBLE) playbooks/verify.yml

.PHONY: uninstall
uninstall: ## Remove the releases, leaving the cluster and the platform
	cd ansible && $(ANSIBLE) playbooks/uninstall.yml

.PHONY: destroy
destroy: ## Destroy everything this environment created, cluster included
	@echo "This destroys the $(PROVIDER) cluster and every release on it."
	$(TF) -chdir=$(ENV_DIR) destroy
