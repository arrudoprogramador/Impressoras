# Painel de Impressoras BI - Instruções do Projeto e Guias para Inteligências Artificiais

> [!IMPORTANT]
> Se você for uma Inteligência Artificial lendo isso para ajudar o desenvolvedor, preste MUITA ATENÇÃO a este arquivo. O ecossistema deste projeto possui peculiaridades críticas de infraestrutura em rede Windows (UNC paths) que quebram o fluxo padrão do Next.js. Não tome atitudes destrutivas (como apagar a pasta `.next`) sem entender isso.

## 1. Arquitetura e Stack
- **Framework:** Next.js (Pages / App Router) + React
- **Estilização:** CSS Vanilla / TailwindCSS
- **Banco de Dados:** PostgreSQL (acessado através do **Prisma ORM**)
- **Servidor Customizado:** O aplicativo NÃO é servido pelo `next start` padrão, e sim através de um arquivo `server.js` na raiz do projeto. O `server.js` escuta requisições na porta HTTP (3000) e opcionalmente em HTTPS (3443), manipulando a rota nativamente.

## 2. O Bug Crítico de Rede (Caminhos UNC)
O projeto está hospedado em um caminho de rede no Windows (`\\192.168.68.162\DESENVOLVIMENTO\Painel de impressoras BI\Saida`).
- **O Problema:** O Webpack e o Next.js não lidam bem com a compilação de módulos dinâmicos diretamente num caminho UNC `\\...`. Tentar rodar `npm run build` diretamente no servidor de rede irá gerar erros obscuros, como a ausência do arquivo `BUILD_ID` ou falha ao compilar o `next-flight-client-entry-loader`.
- **A Solução (Como fazer o Build):** O build **deve** ser feito localmente no SSD da máquina de desenvolvimento (ex: `C:\Projetos\Painel BI`) e, após finalizado com `npm run build`, os arquivos (em especial a pasta `.next` inteira) devem ser copiados via rede (ex: usando `robocopy /MIR`) para o servidor de produção `\\192.168.68.162\...`.
- **Regra de Ouro:** NUNCA delete a pasta `.next` no servidor de produção, a menos que você já tenha um build pronto para substituí-la. Se apagá-la, o site sairá do ar até que uma compilação local externa seja concluída e transferida novamente.

## 3. Scripts e Ferramentas Centralizados
Todos os arquivos necessários para operar o painel encontram-se nesta pasta (`Ferramentas`). Todos eles têm lógica embutida (como `pushd "%~dp0..\"`) para referenciar corretamente a raiz do projeto:

- `INICIAR_PAINEL.bat`: Derruba instâncias antigas do `node.exe` na memória e sobe o servidor usando o `server.js`.
- `PARAR.bat`: Força o encerramento dos processos do Node.
- `INSTALAR_SERVICO.bat`: Aciona o script PowerShell para registrar este painel como um Serviço Nativo no Windows chamado `PainelBI` (roda em background).
- `REMOVER_SERVICO.bat`: Desfaz o serviço nativo `PainelBI`.
- `INSTALAR_SERVICO_ROBUSTO.ps1`: O núcleo do instalador do serviço, que registra o Node e o `server.js` e adiciona regras de auto-restart (schtasks e sc.exe).
- `GERAR_CERTIFICADO.ps1`: Gera certificados PFX HTTPS locais para acesso seguro. Arquivos são salvos em `Saida\cert`.

## 4. Servidor em Produção (server.js)
Ao olhar o `server.js`, ele invoca o Next.js com a configuração `dev: false` (modo Produção). O ambiente também usa `process.env.NODE_ENV = 'production'`. Alterar para `dev: true` só é recomendado para testes temporários e lentos para pular a exigência do `BUILD_ID`, mas degradará severamente o tempo de carregamento da interface (pois o painel é pesado).

## 5. Banco de Dados e Prisma
Se fizer qualquer mudança no schema do banco (`prisma/schema.prisma`), será necessário:
1. Rodar `npx prisma generate` (ou o comando de migração se precisar) no ambiente local.
2. Copiar as mudanças para a rede UNC.

Siga estas instruções e o painel operará de forma contínua e sem gargalos.

## 6. Agente de Ingestão e Agendamento Windows
As clínicas remotas enviam os dados de impressão via HTTPS (JSON ou Multipart). Para automatizar o processo usando o `GestaoHomolog.ps1`:
- O botão "Criar / Atualizar Tarefa" programa o Agendador de Tarefas do Windows (Task Scheduler).
- **Proteções Recentes Aplicadas:** O script PowerShell utiliza as chaves `-StartWhenAvailable` e `-WakeToRun`. Isso significa que se a clínica estiver com o PC desligado no horário do agendamento (ex: 07h00), a tarefa não é perdida. Ela será disparada imediatamente assim que o PC for ligado (ex: 08h30).
- Se os dados enviados por JSON (API) não mostrarem o "Último Envio" na tela, verifique no painel, pois ele agora gera automaticamente um recibo (`ArquivoIngerido`) para rastrear o exato momento do upload do payload JSON.

## 7. Inteligência Artificial (Ollama)
A análise de dados utiliza o modelo **Llama 3.1** rodando localmente no servidor através do Ollama (localhost:11434).
- **Bug do Node.js (IPv6):** Versões recentes do Node.js (18+) resolvem `localhost` para IPv6 (`::1`), enquanto o Ollama no Windows roda apenas em IPv4. Para evitar que a tela da IA mostre o erro **"Failed to fetch"** ou que o painel receba um `ECONNREFUSED`, as chamadas da API interna foram forçadas para `127.0.0.1`.
- **Troubleshooting de Erro (Failed to fetch):** Se o botão de Gerar Análise na interface exibir um balão vermelho escrito "Failed to fetch", significa quase certamente que o aplicativo Ollama não está rodando em segundo plano no servidor `192.168.68.162`. O cliente precisará acessar o servidor, abrir o Menu Iniciar e iniciar o Ollama manualmente para restaurar a comunicação.
