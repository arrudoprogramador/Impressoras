# PAINEL DE IMPRESSORAS BI — LEIA ME

Sistema de Business Intelligence para monitoramento de frotas de impressoras Konica Minolta, com ingestão automatizada de dados, auditoria de SLA e gestão financeira de franquias.

---

## 1. TECH STACK

| Camada | Tecnologia |
|---|---|
| Framework | Next.js 16+ (App Router) com TypeScript |
| Estilização | Tailwind CSS (dark mode corporativo) |
| Gráficos | Recharts |
| Ícones | Lucide React |
| Banco de Dados | PostgreSQL 16.9 |
| ORM | Prisma 7 (`@prisma/client` + `@prisma/adapter-pg`) |
| CSV Parser | Papaparse |
| Build | Webpack (`next build --webpack`) |
| E-mails | Nodemailer (SMTP Gmail) |

---

## 2. ARQUITETURA DE PASTAS

```
\\192.168.68.162\desenvolvimento\Painel de impressoras BI\
├── LEIAME.md                    ← Este arquivo
├── CREDENCIAIS.md               ← Senhas e configurações (NÃO commitar!)
├── Saida/                       ← Projeto Next.js (app rodando aqui)
│   ├── app/
│   │   ├── page.tsx             ← Página principal (client-side)
│   │   ├── layout.tsx           ← Layout raiz
│   │   └── api/
│   │       ├── ingestao/        ← POST: ingestão de CSVs
│   │       ├── contagem-diaria/ ← GET: dados da aba Contagem Diária
│   │       ├── dashboard/       ← GET: KPIs + timeline + ranking
│   │       ├── impressoras/     ← GET/PATCH: lista e apelidos
│   │       ├── financeiro/      ← GET: projeções financeiras
│   │       ├── armazenamento/   ← GET/POST: gestão de arquivos
│   │       ├── contratos/       ← GET/POST: perfis de franquia
│   │       ├── configuracao/    ← GET/PATCH: config do sistema
│   │       ├── sla/             ← GET/PATCH: config de SLA
│   │       └── unidades/        ← GET/POST: gestão de unidades
│   ├── components/              ← Componentes React
│   ├── lib/
│   │   ├── business.ts          ← Lógica de negócio (cálculos, queries)
│   │   ├── types.ts             ← Interfaces TypeScript
│   │   ├── csvColumnMapper.ts   ← Auto-detecção de colunas CSV
│   │   ├── prisma.ts            ← Cliente Prisma (singleton)
│   │   ├── config.ts            ← Configurações do sistema
│   │   └── email.ts             ← Envio de e-mails
│   ├── prisma/
│   │   └── schema.prisma        ← Schema do banco de dados
│   ├── scripts/                 ← Scripts auxiliares
│   └── .env.local               ← Variáveis de ambiente
├── Ferramentas/                 ← Scripts de instalação e manutenção
│   ├── INICIAR_PAINEL.bat       ← Deploy no servidor
│   ├── PARAR.bat                ← Matar processos node
│   └── Instaladores/            ← Instaladores offline
└── Sintese/                     ← Gerador de dados sintéticos (dev)
```

---

## 3. INGESTÃO DE CSVs — FORMATO E AUTO-DETECÇÃO

### 3.1 Formato padrão do arquivo

```
relatorio_impressoras_{UNIDADE}_{YYYY-MM-DD}_{HH-mm-ss}.csv
```

Exemplo: `relatorio_impressoras_TAUBATE_2026-08-04_07-00-02.csv`

### 3.2 Formato do conteúdo CSV

O parser aceita **dois separadores** automaticamente: `;` (padrão Konica Minolta) e `,`.

**Formato C300i (correto):**
```csv
"Data";"Unidade";"IP";"Status";"Modelo";"Serial";"Paginas_Total";"Paginas_PB";"Paginas_Color"
"2026-08-04 13:00:03";"TAUBATE";"192.168.110.151";"Online";"KONICA MINOLTA bizhub C300i";"AA2K011015995";"137081";"72";"74172"
```

**Formato C3300i (pode variar):**
- Colunas podem ter nomes diferentes ou ordem trocada
- O auto-detector analisa **cabeçalho + valores** para mapear corretamente

### 3.3 Auto-detecção de colunas (`lib/csvColumnMapper.ts`)

O sistema mapeia automaticamente as colunas usando:

1. **Match por nome** — procura padrões como `Paginas_Total`, `Total`, `PB`, `Color`, etc.
2. **Heurísticas de valores** — se nomes não funcionam:
   - Coluna com maior valor médio → `Paginas_Total`
   - Coluna com mais zeros → `Paginas_PB` (impressoras coloridas imprimem pouco PB)
   - Coluna restante → `Paginas_Color`
3. **Validação** — verifica se `PB + Color ≤ Total` (com margem de 10%)

### 3.4 Fluxo de ingestão

```
1. Lê CSV do diretório configurado (G:\Meu Drive\Relatorios_Impressoras)
2. Detecta separador (;  ou ,)
3. Parseia com Papaparse (header=true, dynamicTyping=true)
4. Auto-detecta mapeamento de colunas
5. Para cada linha:
   a. Extrai IP, Serial, Modelo, Data, Status
   b. Lê Total/PB/Color com fallback para nomes conhecidos
   c. Cria/atualiza Impressora (upsert por serial)
   d. Detecta reset de placa (C_final < C_inicial)
   e. Cria LeituraImpressora (chave: ip + serial + dataHora)
6. Marca arquivo como PROCESSADO no banco
```

---

## 4. CÁLCULO DE DELTA (CONSUMO REAL)

### 4.1 Regra fundamental

Os contadores de página são **acumulativos** (odômetro). O consumo é calculado por **delta**:

```
Consumo = Leitura_Final - Leitura_Inicial
```

### 4.2 Detecção de reset de placa

Se `Leitura_Final < Leitura_Inicial`, a placa foi resetada em manutenção:
- Assume `Consumo = Leitura_Final`
- Exibe badge visual: *"Placa Resetada no Período"*

### 4.3 Contagem Diária (aba "Contagem Diária")

O cálculo usa **delta entre dias** (não intra-dia):

```
Para cada dia do período:
  delta = última_leitura_do_dia - última_leitura_do_dia_anterior

Se dia anterior não tem leitura da impressora:
  delta = última_leitura_do_dia - primeira_leitura_da_impressora
```

Isso garante que o consumo **entre dias** é contabilizado corretamente.

### 4.4 Dashboard e Parque de Impressoras

Usa delta **primeira → última leitura** de todos os tempos (sem filtro de período).

---

## 5. BANCO DE DADOS

### 5.1 Tabelas principais

| Tabela | Descrição |
|---|---|
| `Unidade` | Filiais/unidades (ex: TAUBATE, Santana De Parnaiba) |
| `UnidadeAlias` | Sinônimos para unidades |
| `Impressora` | Equipamentos (serial único, vinculado a unidade) |
| `LeituraImpressora` | Leituras acumulativas (odômetro) |
| `PerfilFranquia` | Contratos e perfis de franquia |
| `ConfiguracaoSLA` | Configurações de SLA |
| `ArquivoIngerido` | Controle de arquivos CSV processados |
| `ConfiguracaoSistema` | Configurações gerais |

### 5.2 Chave composta

A tabela `LeituraImpressora` tem constraint de unicidade:
```sql
@@unique([ip, serial, dataHora])
```

### 5.3 Acesso ao banco

```
Host: 192.168.68.162:5432
Database: bi_dashboard
User: bi_user
```

Ver `CREDENCIAIS.md` para senha completa.

---

## 6. ABA "CONTAGEM DIÁRIA"

### 6.1 Modos de visualização

- **Tabela** — lista paginada com PB, Color, Total por impressora
- **Gráfico** — barras empilhadas PB + Color por impressora
- **Completo** — gráfico + tabela detalhada + resumo por unidade

### 6.2 Períodos disponíveis

- 7 dias
- 30 dias
- Trimestre (90 dias)
- Ano (365 dias)

---

## 7. MÓDULO FINANCEIRO

### 7.1 Toggle híbrido de franquia (header)

4 funcionalidades independentes:
1. **Modo Comercial/Operacional** — alterna visão financeira vs operacional
2. **Checkboxes** — [Custos] [Projeções] [Franquia]
3. **Ocultar valores R$** — substitui por `***`
4. **Desativar cobrança franquia** — exclui cálculo de franquia

### 7.2 Perfis de franquia

Cada unidade pode ter um perfil de franquia com:
- Tarifa avulsa PB/Color (R$/página)
- Franquia fixa mensal (R$)
- Cota PB/Color inclusa
- Excedente PB/Color (R$/página)
- Preço da resma de papel (R$)

---

## 8. SLA E ALERTAS

### 8.1 Regra

Se uma unidade não enviar leitura até o horário limite (default: 17:00):
1. Badge vermelho no painel
2. E-mail automático para destinatários configurados

### 8.2 Configuração

- Horário limite: `SLA_HOUR_LIMIT` no `.env.local`
- Alertas ativos: `SLA_ALERT_ENABLED`
- Destinatários: `SLA_ALERT_EMAILS` (separados por vírgula)

---

## 9. COMANDOS ÚTEIS

### 9.1 Iniciar o painel

```bat
cd W:
INICIAR_PAINEL.bat
```

Ou manualmente:
```bash
taskkill /F /IM node.exe /T 2>nul
npm run build
npx next start -H 0.0.0.0 -p 3000
```

### 9.2 Parar o painel

```bat
PARAR.bat
```

### 9.3 Limpar banco de dados

```bash
node scripts/limpar-banco.mjs
```

### 9.4 Diagnóstico

```bash
node scripts/diagnostico.mjs
```

### 9.5 Teste de parsing CSV

```bash
node scripts/test-csv-parse.js
```

---

## 10. PROBLEMAS CONHECIDOS E SOLUÇÕES

### 10.1 CSV C3300i com PB = Color

**Problema:** Impressoras C3300i tinham `paginasPB == paginasColor` no banco.

**Causa:** Formato CSV diferente do C300i (colunas em ordem/nomes diferentes).

**Solução:** Implementado auto-detecção de colunas (`lib/csvColumnMapper.ts`) que:
- Analisa cabeçalho e valores
- Mapeia colunas por heurísticas
- Funciona para qualquer formato de impressora Konica Minolta

### 10.2 Contagem Diária mostrando zeros

**Problema:** Aba "Contagem Diária" mostrava consumo zero para todas as impressoras.

**Causa:** Cálculo usava delta **intra-dia** (última - primeira leitura do mesmo dia). Como a maioria tem 1 leitura/dia, delta = 0.

**Solução:** Reescrito para usar delta **entre dias** (leitura do dia - leitura do dia anterior).

### 10.3 Servidor roda código antigo

**Problema:** Após alterações, o servidor continua rodando código anterior.

**Solução:** Executar `INICIAR_PAINEL.bat` que faz:
1. `taskkill /F /IM node.exe /T`
2. `npm run build`
3. `npx next start -H 0.0.0.0 -p 3000`

---

## 11. SEGURANÇA

- Arquivo `CREDENCIAIS.md` **NÃO** deve ser commitado no Git
- `.gitignore` já configurado para excluir credenciais
- SMTP usa senha de app Gmail (não senha normal)
- Senha do banco: 24 bytes de entropia (192 bits)

---

## 12. PRÓXIMOS PASSOS

- [ ] Configurar SMTP com credenciais Gmail reais
- [ ] Coletar CSVs reais de todas as unidades
- [ ] Criar perfis de franquia para cada unidade
- [ ] Testar ingestão com CSVs de diferentes modelos
- [ ] Configurar alertas de SLA com e-mails reais
