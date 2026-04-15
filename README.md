# Watchdog Pulsar (PowerShell)

Script de monitoramento resiliente desenvolvido para garantir a disponibilidade das aplicações de FTP e RDS da Pulsar em ambiente Windows 10.

## 🚀 Funcionalidades
* **Verificação de Existência:** Identifica se o processo está em execução e o inicia caso esteja fechado.
* **Monitoramento de Travamento:** Detecta se a aplicação entrou em estado "Não Respondendo" (Hung).
* **Reinicialização Limpa:** Garante o fechamento total da stack antes de reabrir, evitando conflitos de arquivos ou portas.

## 🛠️ Como usar
1. Clone o repositório.
2. Altere o array `$apps` com os caminhos dos seus executáveis.
3. Execute via PowerShell com política de bypass:
   ```powershell
   powershell -ExecutionPolicy Bypass -File WatchdogPulsar.ps1