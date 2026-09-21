# Configuração do Prisma Client e Datasource PostgreSQL

> Painel de Impressoras BI — Documentação técnica de configuração do banco e ORM

**Última atualização**: 05/08/2026  
**Versão do Prisma**: 7.9.1  
**Banco**: PostgreSQL 16 (192.168.68.162:5432/bi_dashboard)

---

## 1. Prisma 7 — Mudanças Recentes

O projeto foi atualizado para **Prisma 7.9.1**, que exige um **driver adapter** para conectar ao PostgreSQL. A conexão direta (`new PrismaClient()` sem adapter) não funciona mais.

### Antes (Prisma 6 ou anterior)

```ts
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
```

### Agora (Prisma 7)

```ts
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { PrismaClient } from '@prisma/client';

const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });
```

### O que mudou

| Aspecto | Antes | Agora |
|---------|-------|-------|
| Driver | Direto (libsql/native) | Adapter (`@prisma/adapter-pg`) |
| Conexão | Prisma gerencia internamente | `pg.Pool` externo |
| Configuração | `datasource.url` no schema | `prisma.config.ts` com adapter |
| Scripts auxiliares | PrismaClient direto | `pg.Pool` direto (sem adapter) |

---

## 2. Arquivos Prisma

### 2.1 `prisma/schema.prisma`

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
}
```

**Modelos atuais:**

| Modelo | Descrição |
|--------|-----------|
| `Unidade` | Unidades organizacionais (filiais) |
| `UnidadeAlias` | Aliases para nomes de unidade |
| `Impressora` | Impressoras cadastradas (serial único) |
| `LeituraImpressora` | Leituras acumuladas (odômetro) |
| `PerfilFranquia` | Perfis de franquia com tarifas |
| `ConfiguracaoSLA` | Configuração de alertas de SLA |
| `ArquivoIngerido` | Controle de arquivos CSV processados |
| `ConfiguracaoSistema` | Path do diretório de CSVs |
| `ConfiguracaoIA` | Provedor/modelo/chave de IA *(novo)* |

### 2.2 `prisma.config.ts`

**Localização**: `W:\prisma.config.ts`

```ts
import { defineConfig, type PrismaConfig } from 'prisma/config'
import { config } from 'dotenv'
import { PrismaPg } from '@prisma/adapter-pg'
import { Pool } from 'pg'

config({ path: '.env.local' })

const connectionString = process.env.DATABASE_URL
const pool = new Pool({ connectionString })
const adapter = new PrismaPg(pool)

const configInput = {
  schema: './prisma/schema.prisma',
  datasource: {
    url: connectionString,
  },
  client: {
    output: '../node_modules/@prisma/client',
    adapter,
  },
} as PrismaConfig & { client: { output: string; adapter: unknown } }

export default defineConfig(configInput)
```

> ⚠️ **IMPORTANTE**: O `prisma.config.ts` é **obrigatório** para o Prisma 7 funcionar. Sem ele, o `PrismaClient` lança erro `"PrismaClientInitializationError: A driver adapter is required"`.

---

## 3. Datasource PostgreSQL

### 3.1 Conexão

| Campo | Valor |
|-------|-------|
| **URL** | `postgresql://bi_user:PrATO3fyhuJCQuGbMpSmvStWrwDmtj!t@192.168.68.162:5432/bi_dashboard` |
| **Host** | `192.168.68.162` |
| **Porta** | `5432` |
| **Banco** | `bi_dashboard` |
| **Usuário** | `bi_user` |
| **Senha** | `PrATO3fyhuJCQuGbMpSmvStWrwDmtj!t` |

### 3.2 Variável de ambiente (`.env.local`)

```env
DATABASE_URL=postgresql://bi_user:PrATO3fyhuJCQuGbMpSmvStWrwDmtj!t@192.168.68.162:5432/bi_dashboard
CSV_DIRECTORY_PATH=G:\Meu Drive\Relatorios_Impressoras
SMTP_HOST=<pendente>
SMTP_PORT=587
SMTP_USER=<pendente>
SMTP_PASS=<pendente>
SMTP_FROM=<pendente>
SMTP_TO=<pendente>
```

### 3.3 Estrutura do banco (DDL simplificado)

```sql
-- Unidades organizacionais
CREATE TABLE "Unidade" (
  id            TEXT PRIMARY KEY,
  nome          TEXT UNIQUE NOT NULL,
  nomeSanitizado TEXT UNIQUE NOT NULL,
  perfilFranquiaId TEXT REFERENCES "PerfilFranquia"(id),
  createdAt     TIMESTAMP NOT NULL DEFAULT NOW(),
  updatedAt     TIMESTAMP NOT NULL
);

-- Impressoras (por serial único)
CREATE TABLE "Impressora" (
  id        TEXT PRIMARY KEY,
  serial    TEXT UNIQUE NOT NULL,
  modelo    TEXT NOT NULL,
  ip        TEXT NOT NULL,
  apelido   TEXT,
  unidadeId TEXT REFERENCES "Unidade"(id),
  createdAt TIMESTAMP NOT NULL DEFAULT NOW(),
  updatedAt TIMESTAMP NOT NULL
);

-- Leituras acumuladas (odômetro)
CREATE TABLE "LeituraImpressora" (
  id           TEXT PRIMARY KEY,
  dataHora     TIMESTAMP NOT NULL,
  paginasTotal INT NOT NULL DEFAULT 0,
  paginasPB    INT NOT NULL DEFAULT 0,
  paginasColor INT NOT NULL DEFAULT 0,
  status       TEXT NOT NULL DEFAULT 'Online',
  resetPlaca   BOOLEAN NOT NULL DEFAULT FALSE,
  ip           TEXT NOT NULL,
  serial       TEXT NOT NULL,
  impressoraId TEXT REFERENCES "Impressora"(id),
  unidadeId    TEXT REFERENCES "Unidade"(id),
  createdAt    TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Configuração de IA (NOVO)
CREATE TABLE "ConfiguracaoIA" (
  id           TEXT PRIMARY KEY DEFAULT 'default_ia',
  provedor     TEXT NOT NULL DEFAULT 'groq',
  modelo       TEXT NOT NULL DEFAULT 'llama-3.3-70b-versatile',
  apiKey       TEXT NOT NULL DEFAULT '',
  endpointUrl  TEXT NOT NULL DEFAULT '',
  temperatura  DOUBLE PRECISION NOT NULL DEFAULT 0.7,
  maxTokens    INT NOT NULL DEFAULT 4096,
  idioma       TEXT NOT NULL DEFAULT 'pt-BR',
  updatedAt    TIMESTAMP NOT NULL
);
```

---

## 4. Comandos Prisma

### 4.1 Gerar cliente Prisma (após mudanças no schema)

```bash
npx prisma generate
```

### 4.2 Sincronizar schema com banco (sem migration file)

```bash
npx prisma db push
```

**Quando usar:**
- O banco já existe com tabelas criadas fora do Prisma (drift)
- Quer adicionar novas tabelas/colunas sem criar migration files
- NÃO destrói dados existentes (apenas aditivo)

**Quando NÃO usar:**
- Quer criar migration files versionados
- Precisa reverter mudanças

### 4.3 Criar migration e aplicar

```bash
npx prisma migrate dev --name <nome_da_migracao>
```

Cria um arquivo em `prisma/migrations/` e aplica ao banco.

### 4.4 Resetar o banco (DESTRUTIVO)

```bash
npx prisma migrate reset
```

> ⚠️ **APENAS para desenvolvimento.** Nunca em produção. Todos os dados serão perdidos.

### 4.5 Studio (GUI para visualizar/editar dados)

```bash
npx prisma studio
```

### 4.6 Seed (dados iniciais)

```bash
npm run seed
```

---

## 5. Scripts Auxiliares com Prisma 7

Scripts `.mjs` usam `pg.Pool` diretamente (**NÃO** `PrismaClient`) porque:

- Prisma 7 requer driver adapter
- Scripts auxiliares rodam fora do contexto Next.js
- Usar `PrismaClient` sem adapter causa erro: `"PrismaClientInitializationError"`

### Exemplo de conexão em scripts `.mjs`

```js
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

const result = await pool.query('SELECT * FROM "Impressora"');
console.log(result.rows);

await pool.end();
```

### Scripts disponíveis

| Script | Descrição |
|--------|-----------|
| `scripts/fix-c3300i-data.mjs` | Migração: corrige PB=Color nas C3300i |
| `scripts/limpar-banco.mjs` | Limpa todas as tabelas |
| `scripts/reset-arquivos.mjs` | Reseta status de arquivos CSV |
| `scripts/diagnostico.mjs` | Diagnóstico do banco (unidades, impressoras, leituras) |
| `scripts/test-csv-parse.js` | Teste de parse de CSV (separador `;`) |
| `scripts/test-tab-parse2.js` | Teste de parse TAB (C3300i) |

---

## 6. Problemas Conhecidos e Soluções

### 6.1 Erro: "PrismaClient was instantiated without any options. A driver adapter is required"

| Campo | Valor |
|-------|-------|
| **Causa** | Prisma 7 não encontra o adapter |
| **Solução** | 1. Verifique se `prisma.config.ts` existe e está correto<br>2. Execute `npx prisma generate`<br>3. Em scripts `.mjs`, use `pg.Pool` diretamente |

### 6.2 Erro: "Drift detected" ao rodar `prisma migrate dev`

| Campo | Valor |
|-------|-------|
| **Causa** | O banco tem tabelas que não foram criadas por migrations do Prisma |
| **Solução** | Use `npx prisma db push` para sincronizar sem reset<br>Ou: `npx prisma migrate resolve --applied <nome_migration>` para marcar como aplicada |

### 6.3 Erro: "NÃO há suporte para caminhos UNC" ao rodar scripts

| Campo | Valor |
|-------|-------|
| **Causa** | `CMD.EXE` não suporta paths UNC (`\\server\share`) |
| **Solução** | Use `subst W: \\192.168.68.162\desenvolvimento\Painel de impressoras BI\Saida` antes de rodar comandos, ou use `W:` no início do comando |

### 6.4 Build com cache turbopack antigo

| Campo | Valor |
|-------|-------|
| **Causa** | `.next` directory tem cache de modo dev |
| **Solução** | SEMPRE faça `Remove-Item .next -Recurse -Force` antes de `npm run build` |

---

## 7. Fluxo de Trabalho Recomendado

```
1. Edite prisma/schema.prisma
2. Execute: npx prisma generate
3. Execute: npx prisma db push  (ou migrate dev se quiser migration file)
4. Rebuild: Remove-Item .next -Recurse -Force && npm run build
5. Reinicie: taskkill /F /IM node.exe /T && npx next start -H 0.0.0.0 -p 3000
```

---

## 8. Notas sobre o `.env.local`

### Localização
`W:\.env.local`

### Conteúdo atual

```env
DATABASE_URL=postgresql://bi_user:PrATO3fyhuJCQuGbMpSmvStWrwDmtj!t@192.168.68.162:5432/bi_dashboard
CSV_DIRECTORY_PATH=G:\Meu Drive\Relatorios_Impressoras
SMTP_HOST=<pendente>
SMTP_PORT=587
SMTP_USER=<pendente>
SMTP_PASS=<pendente>
SMTP_FROM=<pendente>
SMTP_TO=<pendente>
```

> ⚠️ As credenciais SMTP estão com placeholders. Os alertas de e-mail não funcionam até que credenciais reais sejam configuradas.

### Variáveis de ambiente do Prisma 7

| Variável | Obrigatória | Descrição |
|----------|:-----------:|-----------|
| `DATABASE_URL` | ✅ | URL de conexão PostgreSQL |
| `CSV_DIRECTORY_PATH` | ✅ | Path da pasta de CSVs |
| `SMTP_HOST` | ⬜ | Host do servidor SMTP (Gmail) |
| `SMTP_PORT` | ⬜ | Porta SMTP (587) |
| `SMTP_USER` | ⬜ | E-mail remetente |
| `SMTP_PASS` | ⬜ | Senha de app do Gmail |
| `SMTP_FROM` | ⬜ | E-mail de envio de alertas |
| `SMTP_TO` | ⬜ | E-mail(s) destinatário(s) |

---

## 9. Configuração da IA (novo)

O painel inclui um assistente de IA que analisa os dados do dashboard e gera relatórios executivos.

### Tabela `ConfiguracaoIA`

| Campo | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `id` | TEXT | `default_ia` | ID fixo |
| `provedor` | TEXT | `groq` | Provedor de IA |
| `modelo` | TEXT | `llama-3.3-70b-versatile` | Modelo selecionado |
| `apiKey` | TEXT | `''` | Chave da API |
| `endpointUrl` | TEXT | `''` | Endpoint customizado (opcional) |
| `temperatura` | FLOAT | `0.7` | Criatividade da IA |
| `maxTokens` | INT | `4096` | Máximo de tokens |
| `idioma` | TEXT | `pt-BR` | Idioma da resposta |

### Provedores gratuitos pré-definidos

| Provedor | Modelo grátis | Onde conseguir a chave |
|----------|---------------|------------------------|
| **Groq** | Llama 3.3 70B | console.groq.com |
| **Google Gemini** | Gemini 2.0 Flash | aistudio.google.com |
| **OpenRouter** | Llama 3.1 8B (free) | openrouter.ai |

---

*Documentação mantida atualizada com as últimas alterações do projeto.*
