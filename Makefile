# Global Vars
#############

WORKING_DIR 	= $(shell pwd)
OS 				= $(shell uname -s)
ARCH 			= $(shell uname -m)

# Main targets you should run
#############################
.DEFAULT_GOAL := help

.PHONY: help
help: ## Prints help for targets with comments
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: helm-deps
helm-deps: ## Install helm dependencies
	@echo "Installing helm dependencies"
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
	helm repo add crossplane-stable https://charts.crossplane.io/stable || true
	helm repo add bitnami https://charts.bitnami.com/bitnami || true
	helm repo update

.PHONY: k3d-up
k3d-up: ## Setup k3d cluster
	make create-k3d-cluster
	make helm-nginx

.PHONY: k3d-down
k3d-down: ## Teardown k3d cluster
	make delete-k3d-cluster

# Extended targets
##################

.PHONY: create-k3d-cluster
create-k3d-cluster: ## Create k3d cluster
	@echo "Creating k3d directory if not existing"
	mkdir .k3d || true
	@echo "Create the test cluster"
	k3d cluster create -p "80:80@loadbalancer" \
		-p "443:443@loadbalancer" \
		--k3s-arg '--disable=traefik@server:0' \
		--wait \
		--k3s-arg '--kubelet-arg=eviction-hard=imagefs.available<1%,nodefs.available<1%@agent:*' \
        --k3s-arg '--kubelet-arg=eviction-minimum-reclaim=imagefs.available=1%,nodefs.available=1%@agent:*' \
        --k3s-arg '--kubelet-arg=eviction-hard=imagefs.available<1%,nodefs.available<1%@server:0' \
        --k3s-arg '--kubelet-arg=eviction-minimum-reclaim=imagefs.available=1%,nodefs.available=1%@server:0' \
        --kubeconfig-switch-context=true \
        --kubeconfig-update-default=true \
        demo
	@echo "Add kubeconfig to .k3d/kubeconfig.yml"
	k3d kubeconfig get demo > .k3d/kubeconfig.yml
	# k3d create a kubeconfig with host `0.0.0.0`, it's a problem as
	# cluster certificate only got DSN for `localhost`
	@if [ "${UNAME_S}" = "Linux" ]; then \
		sed -i "s/0\.0\.0\.0/localhost/g" ./.k3d/kubeconfig.yml; \
    fi
	@if [ "${UNAME_S}" = "Darwin" ]; then \
  		sed -i -e "s/0\.0\.0\.0/localhost/" .k3d/kubeconfig.yml; \
    fi

.PHONY: delete-k3d-cluster
delete-k3d-cluster: ## Delete k3d cluster
	@echo "Deleting k3d cluster"
	k3d cluster delete demo || true
	rm -rf .k3d || true

.PHONY: helm-nginx
helm-nginx: ## Install nginx-ingress helm chart from ingress-nginx
	@echo "Installing nginx-ingress"
	helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
	  --namespace ingress-nginx --create-namespace
	@echo "Waiting for ingress-nginx to be ready..."
	kubectl wait deployment -n ingress-nginx \
		ingress-nginx-controller --for condition=Available=True --timeout=90s
