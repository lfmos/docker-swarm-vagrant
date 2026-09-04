# frozen_string_literal: true

VAGRANT_API_VERSION = "2"

BOX = ENV.fetch("SWARM_BOX", "ubuntu/jammy64")
MANAGER_MEMORY = ENV.fetch("SWARM_MANAGER_MEMORY", "1024").to_i
WORKER_MEMORY = ENV.fetch("SWARM_WORKER_MEMORY", "768").to_i
CPUS = ENV.fetch("SWARM_CPUS", "1").to_i

NODES = {
  "master" => {
    ip: "192.168.56.10",
    role: "manager"
  },
  "node01" => {
    ip: "192.168.56.11",
    role: "worker"
  },
  "node02" => {
    ip: "192.168.56.12",
    role: "worker"
  },
  "node03" => {
    ip: "192.168.56.13",
    role: "worker"
  }
}.freeze

Vagrant.configure(VAGRANT_API_VERSION) do |config|
  config.vm.box = BOX
  config.vm.boot_timeout = 600

  NODES.each do |hostname, node_config|
    config.vm.define hostname, primary: hostname == "master" do |machine|
      machine.vm.hostname = hostname

      machine.vm.network(
        "private_network",
        ip: node_config[:ip]
      )

      machine.vm.provision(
        "shell",
        path: "scripts/install-docker.sh"
      )

      machine.vm.provider "virtualbox" do |vb|
        vb.cpus = CPUS

        vb.memory =
          if node_config[:role] == "manager"
            MANAGER_MEMORY
          else
            WORKER_MEMORY
          end
      end
    end
  end
end