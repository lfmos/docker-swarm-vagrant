# Docker Swarm Cluster com Vagrant

Laboratório local multi-VM para provisionamento e automação de um cluster Docker Swarm utilizando Vagrant, VirtualBox, Ubuntu e Docker.

O projeto cria quatro máquinas virtuais, instala o Docker, automatiza a formação do Swarm e disponibiliza uma stack de demonstração com três réplicas distribuídas entre os Worker Nodes.

> O GitHub Actions valida scripts, configuração e segurança estática. A execução completa do cluster exige Vagrant e VirtualBox em um ambiente local compatível.

---

## Objetivo

Demonstrar, de forma reproduzível:

- provisionamento de máquinas virtuais com Vagrant;
- instalação automatizada do Docker;
- configuração de um Docker Swarm;
- arquitetura Manager / Workers;
- uso de rede privada entre os nós;
- deploy de serviços com Docker Stack;
- overlay networks;
- scheduling distribuído;
- réplicas;
- rolling updates;
- rollback;
- limites de recursos;
- automação e validação com Bash;
- CI com GitHub Actions.

---

## Arquitetura

O laboratório utiliza quatro VMs:

| Nó | Papel | IP privado |
| --- | --- | --- |
| `master` | Manager | `192.168.56.10` |
| `node01` | Worker | `192.168.56.11` |
| `node02` | Worker | `192.168.56.12` |
| `node03` | Worker | `192.168.56.13` |

Fluxo:

    Host
      |
      v
    Vagrant
      |
      +--> master  192.168.56.10
      |
      +--> node01  192.168.56.11
      |
      +--> node02  192.168.56.12
      |
      +--> node03  192.168.56.13
              |
              v
        Docker Engine
              |
              v
         Docker Swarm
              |
              v
          Demo Stack

Mais detalhes:

    docs/ARCHITECTURE.md

---

## Fluxo de automação

### 1. Provisionamento

    vagrant up

O Vagrant:

- cria as quatro VMs;
- configura hostnames;
- configura IPs privados;
- define CPU e memória;
- executa `scripts/install-docker.sh`;
- instala e inicia o Docker.

### 2. Formação do Swarm

    bash scripts/configure-swarm.sh

O script:

- verifica se as VMs estão acessíveis;
- inicializa o Swarm no `master`;
- utiliza `192.168.56.10` como advertise address;
- obtém temporariamente o worker join token;
- adiciona `node01`, `node02` e `node03`;
- valida os quatro nós;
- remove o token da variável após o uso.

Resultado esperado:

    HOSTNAME   STATUS   AVAILABILITY   MANAGER STATUS
    master     Ready    Active         Leader
    node01     Ready    Active
    node02     Ready    Active
    node03     Ready    Active

### 3. Deploy da stack

    bash scripts/deploy-demo.sh

A stack utiliza três réplicas de NGINX distribuídas entre os workers:

    master
      |
      +---------------------------+
      |             |             |
      v             v             v
    node01        node02        node03
     web.1         web.2         web.3

O script confirma que as três VMs Worker receberam uma réplica.

---

## Stack de demonstração

Arquivo:

    stack/docker-stack.yml

A stack demonstra:

- 3 réplicas;
- execução apenas em Worker Nodes;
- no máximo 1 réplica por worker;
- overlay network;
- routing mesh;
- healthcheck;
- restart policy;
- CPU reservations;
- CPU limits;
- memory reservations;
- memory limits;
- rolling update;
- rollback em caso de falha.

A aplicação é publicada na porta:

    8080

Após o deploy, o serviço pode ser acessado pelo ambiente do laboratório, por exemplo:

    http://192.168.56.10:8080

---

## Tecnologias

- Vagrant
- VirtualBox
- Ubuntu Linux
- Docker Engine
- Docker Swarm
- Docker Stack
- Bash
- Git
- GitHub Actions
- ShellCheck

---

## Estrutura

    swarm-vagrant-lab/
    ├── .github/
    │   └── workflows/
    │       └── validate.yml
    ├── docs/
    │   └── ARCHITECTURE.md
    ├── scripts/
    │   ├── install-docker.sh
    │   ├── configure-swarm.sh
    │   ├── deploy-demo.sh
    │   └── validate.sh
    ├── stack/
    │   └── docker-stack.yml
    ├── .gitattributes
    ├── .gitignore
    ├── CHANGELOG.md
    ├── Vagrantfile
    └── README.md

---

## Pré-requisitos

Para executar o laboratório completo:

- Git;
- Vagrant;
- VirtualBox;
- virtualização habilitada no host;
- recursos suficientes para quatro máquinas virtuais.

Os scripts de automação utilizam Bash.

Em Windows, podem ser executados através de ambientes compatíveis, como Git Bash ou WSL, desde que o comando `vagrant` esteja acessível.

---

## Quick Start

Clone o projeto:

    git clone https://github.com/lfmos/swarm-vagrant-lab.git
    cd swarm-vagrant-lab

Crie as VMs:

    vagrant up

Configure o cluster:

    bash scripts/configure-swarm.sh

Faça o deploy da demonstração:

    bash scripts/deploy-demo.sh

Verifique os nós:

    vagrant ssh master -c "sudo docker node ls"

Verifique os serviços:

    vagrant ssh master -c "sudo docker service ls"

---

## Recursos das VMs

Valores padrão:

| Tipo | RAM | CPU |
| --- | ---: | ---: |
| Manager | 1024 MB | 1 |
| Worker | 768 MB | 1 por VM |

Total padrão reservado às VMs:

    aproximadamente 3,25 GB de RAM

Os valores podem ser personalizados através de:

    SWARM_MANAGER_MEMORY
    SWARM_WORKER_MEMORY
    SWARM_CPUS
    SWARM_BOX

Exemplo em Bash:

    SWARM_MANAGER_MEMORY=1536 SWARM_WORKER_MEMORY=1024 vagrant up

Exemplo no Windows CMD:

    set SWARM_MANAGER_MEMORY=1536
    set SWARM_WORKER_MEMORY=1024
    vagrant up

---

## Networking

Rede privada utilizada:

    192.168.56.0/24

O Docker Swarm utiliza comunicação entre os nós para:

- gerenciamento do cluster;
- descoberta dos nós;
- overlay networking.

Portas normalmente utilizadas pelo Swarm:

| Porta | Protocolo | Finalidade |
| --- | --- | --- |
| 2377 | TCP | gerenciamento do cluster |
| 7946 | TCP/UDP | comunicação entre nós |
| 4789 | UDP | overlay network / VXLAN |

Neste laboratório, a comunicação ocorre através da rede privada do VirtualBox.

O ambiente não foi projetado para exposição pública.

---

## Segurança

### Docker group

O usuário `vagrant` é adicionado ao grupo `docker` para permitir o uso da CLI sem digitar `sudo`.

Isso não significa que o Docker esteja sendo utilizado sem privilégios elevados.

O acesso ao Docker daemon através do grupo `docker` oferece capacidades equivalentes a root em muitos cenários.

Essa decisão é aceitável apenas dentro deste laboratório controlado.

### Worker join token

O token usado para adicionar workers:

- não é versionado;
- não é salvo em arquivo;
- existe temporariamente durante o bootstrap;
- é removido da variável após o uso.

O projeto também possui uma checagem automática para detectar tokens Swarm persistidos acidentalmente no repositório.

---

## Validação local

Sem iniciar nenhuma VM, é possível verificar a estrutura e os scripts:

    bash scripts/validate.sh

A validação cobre:

- arquivos obrigatórios;
- sintaxe Bash;
- configuração dos quatro nós;
- definição do manager;
- bootstrap do Swarm;
- tratamento do worker token;
- configuração da stack;
- réplicas;
- overlay network;
- placement;
- rolling update;
- rollback;
- limites de recursos;
- presença acidental de tokens Swarm.

---

## GitHub Actions

O workflow:

    .github/workflows/validate.yml

executa automaticamente:

- ShellCheck;
- sintaxe Bash;
- validação estrutural;
- sintaxe Ruby do `Vagrantfile`;
- sintaxe YAML da stack;
- busca por tokens Swarm persistidos.

O GitHub Actions não executa VirtualBox nem cria quatro VMs.

Essa limitação é intencional: a execução completa do cluster depende de um host com suporte a virtualização.

---

## Operações úteis

Ver o estado das VMs:

    vagrant status

Acessar o manager:

    vagrant ssh master

Acessar um worker:

    vagrant ssh node01

Listar nós:

    docker node ls

Listar stacks:

    docker stack ls

Listar serviços:

    docker service ls

Inspecionar distribuição das tasks:

    docker service ps swarm-demo_web

Remover apenas a stack:

    docker stack rm swarm-demo

Parar as VMs:

    vagrant halt

Remover todo o laboratório:

    vagrant destroy -f

---

## Limitações

O CI público não comprova:

- inicialização real das quatro VMs;
- comunicação real entre os nós;
- formação efetiva do cluster;
- scheduling real das três réplicas;
- funcionamento do routing mesh.

Esses pontos dependem de execução local com Vagrant e VirtualBox.

O repositório contém a automação e as validações estáticas necessárias para reproduzir esse ambiente em um host compatível.

---

## Possíveis evoluções

- manager adicional para testar alta disponibilidade;
- secrets e configs do Swarm;
- rolling update demonstrado com troca real de versão;
- constraints adicionais de placement;
- volumes persistentes;
- teste automatizado de failover em laboratório.

O projeto não pretende substituir Kubernetes nem evoluir para uma plataforma de produção.

Seu foco é demonstrar fundamentos de orquestração, infraestrutura multi-VM e Docker Swarm.

---

## Autor

Luís Filipe Medeiros de Oliveira e Silva

GitHub: github.com/lfmos