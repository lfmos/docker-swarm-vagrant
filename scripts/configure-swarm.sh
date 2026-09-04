#!/usr/bin/env bash
set -Eeuo pipefail

MANAGER="master"
MANAGER_IP="192.168.56.10"

WORKERS=(
  "node01"
  "node02"
  "node03"
)


fail() {
  echo "[ERROR] $1" >&2
  exit 1
}


ok() {
  echo "[OK] $1"
}


require_command() {
  command -v "$1" >/dev/null 2>&1 ||
    fail "Required command not found: $1"
}


node_command() {
  local node="$1"
  shift

  vagrant ssh "$node" -c "$*"
}


swarm_state() {
  local node="$1"

  node_command \
    "$node" \
    "sudo docker info --format '{{.Swarm.LocalNodeState}}'" \
    2>/dev/null |
    tr -d '\r\n'
}


echo "Docker Swarm cluster bootstrap"
echo

require_command vagrant


echo "[1/4] Checking Vagrant machines..."

for node in "$MANAGER" "${WORKERS[@]}"; do
  if ! node_command "$node" "true" >/dev/null 2>&1; then
    fail "Unable to access '$node'. Run 'vagrant up' first."
  fi
done

ok "All Vagrant machines are reachable."


echo "[2/4] Configuring manager..."

MANAGER_STATE="$(swarm_state "$MANAGER")"

if [[ "$MANAGER_STATE" == "active" ]]; then
  ok "Manager is already part of a Swarm."

else
  node_command \
    "$MANAGER" \
    "sudo docker swarm init --advertise-addr ${MANAGER_IP}"

  ok "Swarm initialized on manager."
fi


echo "[3/4] Joining workers..."

WORKER_TOKEN="$(
  node_command \
    "$MANAGER" \
    "sudo docker swarm join-token -q worker" |
    tr -d '\r\n'
)"

[[ -n "$WORKER_TOKEN" ]] ||
  fail "Unable to obtain the worker join token."

for worker in "${WORKERS[@]}"; do
  STATE="$(swarm_state "$worker")"

  if [[ "$STATE" == "active" ]]; then
    ok "$worker is already part of a Swarm."
    continue
  fi

  node_command \
    "$worker" \
    "sudo docker swarm join --token '${WORKER_TOKEN}' '${MANAGER_IP}:2377'"

  ok "$worker joined the Swarm."
done

# Do not persist or print the join token.
unset WORKER_TOKEN


echo "[4/4] Validating cluster..."

sleep 3

node_command \
  "$MANAGER" \
  "sudo docker node ls"

READY_NODES="$(
  node_command \
    "$MANAGER" \
    "sudo docker node ls --format '{{.Status}}'" |
    tr -d '\r' |
    grep -c '^Ready$' || true
)"

if [[ "$READY_NODES" -ne 4 ]]; then
  fail "Expected 4 Ready nodes, found ${READY_NODES}."
fi

ok "Cluster has 4 Ready nodes."

echo
echo "Docker Swarm cluster configured successfully."
echo
echo "Manager:"
echo "  ${MANAGER} (${MANAGER_IP})"
echo
echo "Workers:"
for worker in "${WORKERS[@]}"; do
  echo "  ${worker}"
done