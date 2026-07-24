Vagrant.configure("2") do |config|

  # Imagem base Ubuntu
  config.vm.box = "ubuntu/jammy64"


  # Configuração comum para todas as máquinas
  machines = {
    "master" => "192.168.56.10",
    "node01" => "192.168.56.11",
    "node02" => "192.168.56.12",
    "node03" => "192.168.56.13"
  }


  machines.each do |hostname, ip|

    config.vm.define hostname do |machine|

      machine.vm.hostname = hostname

      machine.vm.network "private_network", ip: ip


      # Instala Docker automaticamente
      machine.vm.provision "shell", inline: <<-SHELL

        apt-get update -y

        apt-get install -y docker.io

        systemctl enable docker
        systemctl start docker

        usermod -aG docker vagrant

      SHELL


      # Configuração de recursos
      machine.vm.provider "virtualbox" do |vb|

        vb.memory = 1024
        vb.cpus = 1

      end

    end

  end


end