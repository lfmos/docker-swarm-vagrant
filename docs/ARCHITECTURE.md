# Arquitetura — Docker Swarm com Vagrant

## Visão geral

Este projeto cria um laboratório local multi-VM para estudo de Docker Swarm, automação de infraestrutura e orquestração distribuída.

A arquitetura utiliza Vagrant e VirtualBox para provisionar quatro máquinas Ubuntu conectadas por uma rede privada.

O cluster é composto por:

| Nó | Papel | IP |
| --- | --- | --- |
| master | Manager | 192.168.56.10 |
| node01 | Worker | 192.168.56.11 |
| node02 | Worker | 192.168.56.12 |
| node03 | Worker | 192.168.56.13 |

---

## Fluxo de provisionamento

    Host
      |
      v
    Vagrant
      |
      +--> master
      |
      +--> node01
      |
      +--> node02
      |
      +--> node03
              |
              v
      install-docker.sh
              |
              v
         Docker Engine

O `Vagrantfile` é responsável por:

- definir as máquinas;
- configurar hostnames;
- configurar IPs privados;
- definir CPU e memória;
- executar o provisionamento Docker.

A instalação do Docker é separada em:

    scripts/install-docker.sh

Isso mantém o `Vagrantfile` mais simples e permite validar a lógica Bash de forma independente.

---

## Formação do cluster

Após o provisionamento das máquinas, o cluster é configurado com:

    bash scripts/configure-swarm.sh

Fluxo:

    master
      |
      v
    docker swarm init
      |
      v
    worker join token
      |
      +--> node01
      |
      +--> node02
      |
      +--> node03
      |
      v
    docker node ls
      |
      v
    4 nós Ready

O manager utiliza explicitamente:

    192.168.56.10

como `advertise-addr`.

Isso garante que os outros nós utilizem a interface privada do laboratório para comunicação com o manager.

---

## Tratamento do worker token

O token de entrada dos workers não é salvo em arquivo.

Durante o bootstrap:

    manager
      |
      v
    docker swarm join-token -q worker
      |
      v
    variável temporária
      |
      v
    workers entram no cluster
      |
      v
    unset WORKER_TOKEN

O projeto também inclui validação para detectar possíveis tokens Swarm persistidos acidentalmente no repositório.

---

## Stack de demonstração

A stack está definida em:

    stack/docker-stack.yml

Ela cria um serviço NGINX com:

- 3 réplicas;
- uma réplica por worker;
- overlay network;
- routing mesh;
- healthcheck;
- resource reservations;
- resource limits;
- restart policy;
- rolling update;
- rollback automático em falha.

A distribuição esperada é:

    master
      |
      +----------------------------+
      |              |             |
      v              v             v
    node01         node02        node03
     web.1          web.2         web.3

O manager coordena o cluster, mas a workload de demonstração é restrita aos workers.

---

## Deploy da demonstração

O deploy é realizado por:

    bash scripts/deploy-demo.sh

O script:

1. verifica se o manager pertence a um Swarm ativo;
2. executa `docker stack deploy`;
3. aguarda as 3 réplicas entrarem em execução;
4. exibe os serviços;
5. exibe a distribuição das tasks;
6. confirma que as três VMs worker receberam uma réplica.

---

## Networking

A rede privada do laboratório utiliza:

    192.168.56.0/24

IPs:

    master  192.168.56.10
    node01  192.168.56.11
    node02  192.168.56.12
    node03  192.168.56.13

O Docker Swarm utiliza comunicação entre os nós para control plane, discovery e overlay networking.

A rede privada do VirtualBox mantém essa comunicação restrita ao ambiente do laboratório.

---

## Recursos das máquinas

Os valores padrão são:

    Manager:
      1024 MB RAM
      1 CPU

    Workers:
      768 MB RAM
      1 CPU cada

Eles podem ser alterados através das variáveis:

    SWARM_MANAGER_MEMORY
    SWARM_WORKER_MEMORY
    SWARM_CPUS
    SWARM_BOX

Exemplo:

    SWARM_MANAGER_MEMORY=1536 SWARM_WORKER_MEMORY=1024 vagrant up

Isso permite adaptar o laboratório aos recursos disponíveis no host.

---

## Segurança

### Grupo Docker

O usuário `vagrant` é adicionado ao grupo `docker` para permitir uso da CLI sem `sudo`.

Isso não significa ausência de privilégios elevados.

O acesso ao socket Docker através do grupo `docker` oferece capacidades equivalentes a root em muitos cenários.

Por isso, essa configuração é adequada apenas para este ambiente controlado de laboratório.

### Swarm token

O worker token:

- não é versionado;
- não é gravado em arquivo;
- permanece apenas temporariamente em memória;
- é removido após a configuração dos workers.

### Rede

A comunicação entre os nós utiliza a rede privada do laboratório.

O ambiente não foi projetado para exposição pública.

---

## Validação estática

O script:

    bash scripts/validate.sh

valida:

- estrutura do projeto;
- sintaxe dos scripts Bash;
- definição dos quatro nós;
- configuração do manager;
- comandos de bootstrap do Swarm;
- uso temporário do worker token;
- configuração da stack;
- overlay network;
- réplicas;
- rolling update;
- rollback;
- resource limits;
- ausência de tokens persistidos.

---

## GitHub Actions

O workflow:

    .github/workflows/validate.yml

executa validações que não exigem VirtualBox:

- ShellCheck;
- sintaxe Bash;
- validação estrutural;
- sintaxe Ruby do Vagrantfile;
- sintaxe YAML da stack;
- verificação de tokens Swarm persistidos.

O CI não cria máquinas virtuais nem executa um cluster Swarm real.

---

## Limitações de validação

A execução completa depende de:

- Vagrant;
- VirtualBox;
- suporte a virtualização no host;
- recursos suficientes para quatro VMs.

Por isso, o GitHub Actions valida apenas os componentes estáticos e scripts.

A comprovação do cluster em execução exige um ambiente local compatível com VirtualBox.

---

## Fluxo completo

    Vagrantfile
        |
        v
    install-docker.sh
        |
        v
    4 VMs com Docker
        |
        v
    configure-swarm.sh
        |
        v
    1 Manager + 3 Workers
        |
        v
    deploy-demo.sh
        |
        v
    Docker Stack
        |
        v
    3 réplicas distribuídas