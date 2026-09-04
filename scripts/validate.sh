#!/usr/bin/env bash
set -Eeuo pipefail

fail() {
  echo "[ERROR] $1" >&2
  exit 1
}

ok() {
  echo "[OK] $1"
}

require_file() {
  local file="$1"

  [[ -f "$file" ]] ||
    fail "Required file not found: $file"
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  grep -Fq "$pattern" "$file" ||
    fail "$description"
}


echo "Validating Docker Swarm Vagrant project..."
echo


echo "[1/6] Checking project structure..."

required_files=(
  "Vagrantfile"
  "README.md"
  ".gitattributes"
  "scripts/install-docker.sh"
  "scripts/configure-swarm.sh"
  "scripts/deploy-demo.sh"
  "scripts/validate.sh"
  "stack/docker-stack.yml"
)

for file in "${required_files[@]}"; do
  require_file "$file"
done

ok "Required project files found."


echo "[2/6] Validating Bash syntax..."

bash -n scripts/install-docker.sh ||
  fail "Syntax error in scripts/install-docker.sh"

bash -n scripts/configure-swarm.sh ||
  fail "Syntax error in scripts/configure-swarm.sh"

bash -n scripts/deploy-demo.sh ||
  fail "Syntax error in scripts/deploy-demo.sh"

bash -n scripts/validate.sh ||
  fail "Syntax error in scripts/validate.sh"

ok "All Bash scripts have valid syntax."


echo "[3/6] Validating Vagrant configuration..."

require_pattern \
  "Vagrantfile" \
  '"master"' \
  "Manager node definition was not found."

require_pattern \
  "Vagrantfile" \
  '"node01"' \
  "node01 definition was not found."

require_pattern \
  "Vagrantfile" \
  '"node02"' \
  "node02 definition was not found."

require_pattern \
  "Vagrantfile" \
  '"node03"' \
  "node03 definition was not found."

require_pattern \
  "Vagrantfile" \
  "192.168.56.10" \
  "Manager IP was not found."

require_pattern \
  "Vagrantfile" \
  "scripts/install-docker.sh" \
  "Docker provisioning script is not referenced by Vagrant."

ok "Vagrant node configuration found."


echo "[4/6] Validating Swarm bootstrap..."

require_pattern \
  "scripts/configure-swarm.sh" \
  "docker swarm init" \
  "Swarm initialization command was not found."

require_pattern \
  "scripts/configure-swarm.sh" \
  "docker swarm join-token -q worker" \
  "Worker token retrieval was not found."

require_pattern \
  "scripts/configure-swarm.sh" \
  "docker swarm join" \
  "Worker join command was not found."

require_pattern \
  "scripts/configure-swarm.sh" \
  "unset WORKER_TOKEN" \
  "Worker token is not explicitly cleared from memory."

require_pattern \
  "scripts/configure-swarm.sh" \
  "192.168.56.10" \
  "Manager advertise address was not found."

ok "Swarm bootstrap automation found."


echo "[5/6] Validating demo stack..."

require_pattern \
  "stack/docker-stack.yml" \
  "replicas: 3" \
  "Demo stack must define 3 replicas."

require_pattern \
  "stack/docker-stack.yml" \
  "driver: overlay" \
  "Overlay network was not found."

require_pattern \
  "stack/docker-stack.yml" \
  "node.role == worker" \
  "Worker placement constraint was not found."

require_pattern \
  "stack/docker-stack.yml" \
  "max_replicas_per_node: 1" \
  "Replica distribution control was not found."

require_pattern \
  "stack/docker-stack.yml" \
  "update_config:" \
  "Rolling update configuration was not found."

if ! sed -n \
  '/update_config:/,/rollback_config:/p' \
  stack/docker-stack.yml |
  grep -Fq "order: stop-first"; then

  fail "Rolling update must use stop-first with the current replica placement strategy."
fi

require_pattern \
  "stack/docker-stack.yml" \
  "failure_action: rollback" \
  "Rollback policy was not found."

require_pattern \
  "stack/docker-stack.yml" \
  "resources:" \
  "Resource limits/reservations were not found."

ok "Demo stack orchestration controls found."


echo "[6/6] Checking for persisted Swarm secrets..."

if grep -RIn \
  --exclude="validate.sh" \
  --exclude="README.md" \
  --exclude-dir=".git" \
  -E 'SWMTKN-[A-Za-z0-9_-]+' \
  .; then

  fail "A Docker Swarm join token may be persisted in the repository."
fi

ok "No persisted Docker Swarm join token detected."

echo
echo "Project validation completed successfully."