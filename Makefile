SERVICES := gateway web auth catalog cart orders learning labs community certificates leaderboard

.PHONY: validate compose-up compose-down deploy-dev status port-forward smoke

validate:
	python3 -m compileall -q packages services
	docker compose config --quiet
	kubectl kustomize infra/k8s/overlays/dev >/tmp/cloudops-dev.yaml

compose-up:
	docker compose up -d --build

compose-down:
	docker compose down

deploy-dev:
	kubectl apply -k infra/k8s/overlays/dev

status:
	kubectl get all -n cloudops-dev

port-forward:
	kubectl port-forward -n cloudops-dev service/gateway 8080:80

smoke:
	BASE_URL=$${BASE_URL:-http://localhost:8080} ./scripts/smoke-test.sh
