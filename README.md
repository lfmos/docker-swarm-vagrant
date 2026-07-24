# Docker Swarm Cluster com Vagrant

Projeto de laboratório para criação automatizada de um **cluster Docker Swarm local** utilizando **Vagrant** e **VirtualBox**.

A proposta é criar um ambiente reproduzível com múltiplas máquinas virtuais, onde o Docker é instalado automaticamente e uma das máquinas atua como **Manager Node**, enquanto as demais funcionam como **Worker Nodes**.

---

## 🚀 Tecnologias utilizadas

* Vagrant
* VirtualBox
* Docker
* Docker Swarm
* Ubuntu Linux

---

## 🏗️ Arquitetura do Cluster

O projeto cria automaticamente 4 máquinas virtuais:

| Máquina | Função       | IP            |
| ------- | ------------ | ------------- |
| master  | Manager Node | 192.168.56.10 |
| node01  | Worker Node  | 192.168.56.11 |
| node02  | Worker Node  | 192.168.56.12 |
| node03  | Worker Node  | 192.168.56.13 |

Representação:

```text
                 Docker Swarm Cluster

                    MASTER
                (Manager Node)
                       |
        --------------------------------
        |              |               |
      NODE01         NODE02          NODE03
      Worker         Worker          Worker
```

---

## ⚙️ Funcionamento

O arquivo `Vagrantfile` automatiza:

* Criação das máquinas virtuais
* Configuração de hostname
* Definição dos IPs fixos
* Instalação do Docker
* Inicialização do serviço Docker
* Configuração do usuário para utilizar Docker sem privilégios de administrador

---

## 📋 Pré-requisitos

Antes de iniciar, tenha instalado:

* [Vagrant](https://www.vagrantup.com/)
* [VirtualBox](https://www.virtualbox.org/)
* Git

---

## ▶️ Como executar

Clone o repositório:

```bash
git clone https://github.com/lfmos/docker-swarm-vagrant-cluster.git
```

Entre na pasta:

```bash
cd docker-swarm-vagrant-cluster
```

Inicialize as máquinas:

```bash
vagrant up
```

O processo irá criar as 4 máquinas e instalar o Docker automaticamente.

---

## 🔑 Acessando as máquinas

Acessar o Manager:

```bash
vagrant ssh master
```

Acessar um Worker:

```bash
vagrant ssh node01
```

---

## 🐳 Configurando o Docker Swarm

Dentro da máquina `master`, inicialize o cluster:

```bash
docker swarm init --advertise-addr 192.168.56.10
```

O Docker irá gerar um comando para adicionar os Workers.

Exemplo:

```bash
docker swarm join --token TOKEN 192.168.56.10:2377
```

Execute esse comando dentro das máquinas:

```text
node01
node02
node03
```

---

## 🔎 Verificando o Cluster

No `master`, execute:

```bash
docker node ls
```

Resultado esperado:

```text
HOSTNAME   STATUS   AVAILABILITY   MANAGER STATUS

master     Ready    Active         Leader
node01     Ready    Active
node02     Ready    Active
node03     Ready    Active
```

---

## 🧹 Comandos úteis

Desligar as máquinas:

```bash
vagrant halt
```

Remover as máquinas:

```bash
vagrant destroy
```

Recriar o ambiente:

```bash
vagrant up
```

---

## 📚 Conceitos praticados

Este projeto demonstra conhecimentos em:

* Virtualização
* Linux
* Containers
* Docker Swarm
* Clusterização
* Infraestrutura como Código (IaC)
* Automação de ambientes

---

## 🎯 Objetivo

Criar um ambiente local de estudos para praticar conceitos de orquestração de containers e automação de infraestrutura, reduzindo configurações manuais e tornando o ambiente facilmente reproduzível.

---

## 👨‍💻 Autor

**Luís Filipe Medeiros**

GitHub:
https://github.com/lfmos
