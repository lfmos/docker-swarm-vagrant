#!/usr/bin/env bash
set -Eeuo pipefail

MANAGER="master"
STACK_NAME="swarm-demo"
STACK_FILE="/vagrant/stack/docker-stack.yml"
SERVICE_NAME="${STACK_NAME}_web"
EXPECTED_REPLICAS=3

fail() {
  echo "[ERROR] $1" >&2
  exit 1
}

ok() {
  echo "[OK] $1"
}

manager_command() {
  vagrant ssh "$MANAGER" -c "$*"
}

echo "Docker Swarm demo deployment"
echo

command -v vagrant >/dev/null 2>&1 ||
  fail "Vagrant was not found."

echo "[1/4] Checking manager..."

manager_command \
  "sudo docker info --format '{{.Swarm.LocalNodeState}}'" \
  2>/dev/null |
  grep -q "active" ||
  fail "The manager is not part of an active Swarm. Run scripts/configure-swarm.sh first."

ok "Manager is connected to an active Swarm."


echo "[2/4] Deploying stack..."

manager_command \
  "sudo docker stack deploy -c '${STACK_FILE}' '${STACK_NAME}'"

ok "Stack deployment requested."


echo "[3/4] Waiting for replicas..."

for attempt in {1..30}; do
  RUNNING_REPLICAS="$(
    manager_command \
      "sudo docker service ps '${SERVICE_NAME}' --filter desired-state=running --format '{{.CurrentState}}'" \
      2>/dev/null |
      tr -d '\r' |
      grep -c '^Running' || true
  )"

  if [[ "$RUNNING_REPLICAS" -eq "$EXPECTED_REPLICAS" ]]; then
    ok "${EXPECTED_REPLICAS} replicas are running."
    break
  fi

  if [[ "$attempt" -eq 30 ]]; then
    manager_command \
      "sudo docker service ps '${SERVICE_NAME}' --no-trunc"

    fail "Expected ${EXPECTED_REPLICAS} running replicas, found ${RUNNING_REPLICAS}."
  fi

  sleep 2
done


echo "[4/4] Showing distribution..."

manager_command \
  "sudo docker stack services '${STACK_NAME}'"

echo

manager_command \
  "sudo docker service ps '${SERVICE_NAME}' --format 'table {{.Name}}\t{{.Node}}\t{{.CurrentState}}'"

echo

NODES_WITH_RUNNING_TASKS="$(
  manager_command \
    "sudo docker service ps '${SERVICE_NAME}' --filter desired-state=running --format '{{.Node}}'" |
    tr -d '\r' |
    sort -u |
    grep -c '^node' || true
)"

if [[ "$NODES_WITH_RUNNING_TASKS" -ne 3 ]]; then
  fail "Expected replicas on 3 worker nodes, found ${NODES_WITH_RUNNING_TASKS}."
fi

ok "Service is distributed across all 3 worker nodes."

echo
echo "Demo stack deployed successfully."
echo
echo "From the host, try:"
echo "  http://192.168.56.10:8080"
echo
echo "To remove the demo:"
echo "  vagrant ssh master -c \"sudo docker stack rm ${STACK_NAME}\""