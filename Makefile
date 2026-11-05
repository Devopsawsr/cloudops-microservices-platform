SERVICES := gateway web auth catalog cart orders learning labs community certificates leaderboard
K8S_OVERLAYS := dev qa staging production

.PHONY: validate validate-k8s compose-up compose-down bootstrap-dev deploy-dev status port-forward smoke

# Local checks: no AWS infrastructure or application deployment.
validate:
	python3 -m compileall -q packages services
	docker compose config --quiet
	$(MAKE) validate-k8s

validate-k8s:
	@set -eu; for env in $(K8S_OVERLAYS); do \
	  echo "Rendering Kubernetes $$env manifests"; \
	  kubectl kustomize infra/k8s/overlays/$$env >/dev/null; \
	done

compose-up:
	docker compose up -d --build

compose-down:
	docker compose down

# Our first cluster change: the namespace only, using committed YAML.
bootstrap-dev:
	kubectl apply --dry-run=server -f infra/k8s/overlays/dev/namespace.yaml
	kubectl apply -f infra/k8s/overlays/dev/namespace.yaml

# Explicit guard: prevents applying 11 workloads with placeholder ECR images.
deploy-dev:
	@if [ "$(CONFIRM_DEPLOY_DEV)" != "YES" ]; then \
	  echo "Refusing full Dev deployment. Set CONFIRM_DEPLOY_DEV=YES after review."; exit 1; \
	fi
	@if kubectl kustomize infra/k8s/overlays/dev | grep -q 'REPLACE_ECR'; then \
	  echo "Refusing: replace placeholder images with verified ECR digest references first."; exit 1; \
	fi
	@kubectl apply -k infra/k8s/overlays/dev

status:
	kubectl get all -n cloudops-dev

port-forward:
	kubectl port-forward -n cloudops-dev service/gateway 8080:80

smoke:
	BASE_URL=$${BASE_URL:-http://localhost:8080} ./scripts/smoke-test.sh
