# 🚀 Pulsar Watchdog (PowerShell)

Um watchdog robusto em PowerShell para monitoramento e recuperação automática de aplicações críticas no Windows.

Projetado para ambientes de produção, esse script garante que processos essenciais estejam sempre em execução, reiniciando automaticamente em caso de falhas, travamentos ou encerramentos inesperados.

---

## 📌 ✨ Principais Funcionalidades

* ✅ Monitoramento contínuo de múltiplos processos
* ✅ Reinício automático de aplicações que pararam
* ✅ Detecção de travamento (`Not Responding`) com tolerância a falso positivo
* ✅ Estratégia de recuperação inteligente (individual → total)
* ✅ Controle de múltiplas falhas por aplicação
* ✅ Reinício completo da stack quando necessário
* ✅ Sistema de logs persistentes para auditoria
* ✅ Proteção contra múltiplas instâncias do watchdog
* ✅ Preparado para execução como **Serviço do Windows**

---

## 🧠 ⚙️ Como Funciona

O script executa um loop contínuo que:

1. Verifica se os processos estão em execução
2. Caso não estejam → inicia automaticamente
3. Caso estejam travados → tenta recuperação com retry
4. Se falhar repetidamente → reinicia apenas o processo
5. Se atingir limite de falhas → reinicia toda a stack

---

## 📁 📄 Estrutura de Configuração

No início do script, configure os aplicativos monitorados:

```powershell
$apps = @(
    @{ Path = "C:\App1\App1.exe"; Name = "App1" },
    @{ Path = "C:\App2\App2.exe"; Name = "App2" }
)
```

---

## ⏱️ 🔧 Parâmetros Ajustáveis

```powershell
$checkInterval = 60                  # Intervalo entre verificações (segundos)
$retryCount = 3                     # Tentativas antes de considerar travado
$retryDelay = 5                     # Tempo entre tentativas
$maxFailuresBeforeFullRestart = 3   # Limite para reinício total
```

---

## 📝 📊 Logs

O watchdog gera logs automaticamente em:

```
C:\Logs\watchdog_pulsar.log
```

Exemplo:

```
2026-04-15 10:00:01 - App1 não está rodando. Iniciando...
2026-04-15 10:02:10 - ALERTA: App2 travado.
2026-04-15 10:02:12 - App2 reiniciado.
```

---

## 🛡️ 🔒 Segurança e Estabilidade

* Evita múltiplas execuções simultâneas (Mutex global)
* Valida existência dos executáveis antes de iniciar
* Retry antes de considerar travamento (reduz falso positivo)
* Isola falhas por aplicação
* Evita reinício desnecessário de toda a stack

---

## 🚀 ▶️ Como Executar

### 🔹 Execução manual

```powershell
powershell -ExecutionPolicy Bypass -File C:\Scripts\watchdog_pulsar.ps1
```

---

### 🔹 Executar como Serviço (Recomendado)

Utilize o **NSSM (Non-Sucking Service Manager)**:

```cmd
nssm install PulsarWatchdog
```

Configuração:

* **Path:** `powershell.exe`
* **Arguments:**

```cmd
-ExecutionPolicy Bypass -File "C:\Scripts\watchdog_pulsar.ps1"
```

Iniciar serviço:

```cmd
net start PulsarWatchdog
```

---

## 📈 🔥 Melhorias Implementadas

* ✔ Correção de bugs no controle de processos
* ✔ Estrutura de log profissional
* ✔ Sistema de retry para travamentos
* ✔ Estratégia de falha progressiva
* ✔ Controle de instância única
* ✔ Separação de responsabilidades no código
* ✔ Preparado para ambiente enterprise

---

## 🧩 🧠 Possíveis Evoluções

* 📊 Monitoramento de CPU e memória (detecção de leak)
* 📧 Alertas por e-mail ou webhook
* 📡 Integração com sistemas de observabilidade
* 🌐 Dashboard de status em tempo real

---

## ⚠️ ⚙️ Requisitos

* Windows com PowerShell 5.1 ou superior
* Permissão para executar scripts (`ExecutionPolicy`)
* Permissões para iniciar/parar processos

---

## 👨‍💻 Autor

Projeto desenvolvido para garantir alta disponibilidade de aplicações críticas em ambiente Windows.

---

## 📄 Licença

Uso livre para fins pessoais e corporativos.
Adapte conforme sua necessidade.

---

## 💡 Dica Final

Se isso é crítico para operação:

👉 Rode como serviço
👉 Monitore os logs
👉 Não confie só no “está rodando” — valide comportamento

---

**Esse watchdog não só reinicia processos — ele protege sua operação.**
