# Planejamento: Sistema de Envio Forçado Nativamente (Polling)

Este documento descreve a arquitetura e os passos necessários para implementar um botão de "Forçar Envio" no painel central, capaz de comandar as unidades (clínicas) remotas a executarem a leitura das impressoras instantaneamente, sem a necessidade de VPNs ou instalação de softwares de terceiros.

## 🔴 O Problema Atual (Limitação de Rede)
Atualmente as clínicas acessam o servidor através de um **IP Público**. Como as clínicas estão por trás de roteadores de operadoras (NAT) e Firewalls, a internet bloqueia qualquer tentativa de conexão que venha "de fora para dentro".
Se o painel central tentasse enviar uma ordem HTTP direta para o IP da clínica, o roteador bloquearia a requisição.

## 🟢 A Solução: Arquitetura de Long Polling (O Agente Pergunta)
Para furar o bloqueio dos roteadores sem instalar nada, vamos inverter a lógica. O Painel Central não vai "empurrar" a ordem, é a Clínica que vai "puxar" a pergunta.

### Como vai funcionar na prática:
1. **Verificação Leve (A cada 5 minutos):** 
   O Agendador de Tarefas do Windows na clínica será configurado para rodar a cada 5 minutos.
   O script `.ps1` vai realizar uma requisição super leve para o painel: `GET /api/comandos?unidade=CLINICA_X`.
2. **Resposta Negativa (99% do tempo):** 
   O painel responde `{"acao": "nenhuma"}`. O script encerra a execução na mesma hora. O consumo de recursos e internet da clínica é virtualmente zero.
3. **Comando Forçado (Ação do Usuário):**
   Quando você clicar no botão **"Forçar Envio"** no painel central, o banco de dados anotará uma ordem pendente.
   Na próxima vez que a clínica perguntar (em no máximo 5 minutos), o painel responderá: `{"acao": "enviar_dados"}`.
   O script, ao ler isso, executará as leituras SNMP e fará o envio completo (POST) imediatamente.

## ⚙️ O que precisará ser desenvolvido no futuro:

### 1. Modificações no Banco de Dados (Prisma)
- Criar uma nova tabela/modelo chamada `ComandoUnidade` com os campos: `id`, `unidadeId`, `comando` (ex: "enviar_dados"), `status` (PENDENTE, EXECUTADO), `criadoEm`, `executadoEm`.

### 2. Modificações no Backend (Painel Central)
- **Criar rota `GET /api/comandos`:** Endpoint que os scripts das unidades chamarão a cada 5 minutos. Ele vai olhar no banco se há comandos `PENDENTE` para aquela unidade. Se houver, retorna a ação e marca como `EXECUTADO`.
- **Rotina Automática (3x ao dia):** Criar um mecanismo interno (um *Cron Job* em Node.js ou via API route agendada) que insira automaticamente comandos "enviar_dados" às 08:00, 13:00 e 18:00 para todas as unidades.
- **Botão na Interface (Frontend):** Na tela de monitoramento, o botão "Atualizar" ou "Forçar Envio" fará um POST interno inserindo uma ordem `PENDENTE` para aquela unidade específica.

### 3. Modificações no Agente Remoto (Script PowerShell .ps1)
- Atualizar a lógica do `.ps1` para iniciar fazendo um `Invoke-RestMethod` no novo endpoint `/api/comandos`.
- Envolver a rotina de leitura (SNMP) dentro de um bloco `if ($resposta.acao -eq "enviar_dados") { ... }`.
- Fornecer um `.bat` ou `.xml` para o Agendador de Tarefas do Windows (Task Scheduler) configurando o "Gatilho" (*Trigger*) da tarefa para repetir a cada **5 minutos** indefinidamente.

---

**Resumo da Vantagem:** Esta estratégia mantém 100% da segurança nativa de rede e não exige instalação de nenhum aplicativo de terceiros na clínica, resolvendo a questão do acionamento sob demanda em tempo quase real (delay máximo de 5 min).
