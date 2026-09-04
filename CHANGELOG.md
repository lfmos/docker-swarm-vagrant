# Changelog

Todas as mudanças relevantes deste projeto são registradas neste arquivo.

## [1.1.0] - 2026-09-04

### Adicionado

- Provisionamento Docker separado em script Bash.
- Automação para inicialização do Docker Swarm.
- Entrada automática de três workers no cluster.
- Validação de 4 nós em estado Ready.
- Stack de demonstração com 3 réplicas.
- Overlay network.
- Rolling update e rollback.
- Resource limits e reservations.
- Script de deploy e verificação da stack.
- Script de validação estática do projeto.
- GitHub Actions com ShellCheck e validação de sintaxe.
- Detecção de tokens Swarm persistidos no repositório.

### Alterado

- `Vagrantfile` refatorado para configuração declarativa.
- Recursos das VMs tornados configuráveis por variáveis de ambiente.
- Workers reduzidos para 768 MB por padrão.
- Provisionamento inline removido do `Vagrantfile`.
- Automação do Swarm substitui configuração manual descrita na versão inicial.
- Documentação de segurança do grupo `docker` corrigida.

### Segurança

- Worker token utilizado apenas em memória durante o bootstrap.
- Token removido da variável após utilização.
- Scan automático para detectar tokens Swarm acidentalmente versionados.
- Rede privada fixa utilizada para comunicação entre os nós.

---

## [1.0.0]

### Adicionado

- Vagrantfile com quatro máquinas Ubuntu.
- IPs privados fixos.
- Instalação automática do Docker.
- Manager e três workers planejados para laboratório Docker Swarm.