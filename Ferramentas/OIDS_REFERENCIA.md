# Referência e Ideias de Expansão de OIDs (SNMP)

O SNMP (Simple Network Management Protocol) utiliza uma árvore de endereços chamada MIB (Management Information Base), onde cada nó é um OID (Object Identifier). As impressoras funcionam como um banco de dados vivo dessas informações.

## 🖨️ OIDs Mapeadas da Konica Minolta (Série bizhub)

Durante a correção do Agente, validamos as seguintes OIDs oficiais da "Enterprise MIB" da Konica (`1.3.6.1.4.1.18334`) para contagem de páginas:

| Métrica | OID |
| :--- | :--- |
| **Contador Total Padrão (MIB-2)** | `.1.3.6.1.2.1.43.10.2.1.4.1.1` |
| **Contador de Impressões (Preto e Branco)** | `.1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.1.2` |
| **Contador de Impressões (Coloridas)** | `.1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.2.2` |
| **Contador de Cópias (Preto e Branco)** | `.1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.1.1` |
| **Contador de Cópias (Coloridas)** | `.1.3.6.1.4.1.18334.1.1.1.5.7.2.2.1.5.2.1` |
| **Total de Scanners (Digitalizações)** | `.1.3.6.1.4.1.18334.1.1.1.5.7.2.1.5.0` |

---

## 🚀 Ideias para Extrações Futuras via SNMP

Com a estrutura MIB, podemos transformar o Painel BI em um sistema de telemetria completa, extraindo:

### 1. Suprimentos e Consumíveis (Nível de Toner)
- Existe uma OID padrão (`.1.3.6.1.2.1.43.11.1.1.9`) que permite ler exatamente qual a porcentagem (ou quantidade de gramas/tinta) restante de Cyan, Magenta, Yellow e Black. Isso permite criar alertas automáticos: *"Trocar toner Ciano da impressora X"* antes mesmo do cliente reclamar.

### 2. Desgaste de Peças
- É possível ler o nível de vida útil do **Fusor**, **Cilindro (Drum)**, e **Rolo de Transferência**. Ideal para planejamento de manutenção preventiva.

### 3. Alertas de Status Físico e Atolamentos (Jams)
- Pode-se extrair OIDs que avisam se a máquina está em estado de "Warning" (ex: tampa aberta) ou "Error" (atolamento de papel). Em painéis avançados, você consegue até saber se o papel enroscou na bandeja inferior ou no ADF do scanner superior.

### 4. Gestão de Bandejas de Papel
- OIDs podem relatar se a "Bandeja 1" ou "Bandeja 2" está vazia, o tipo de papel que está configurado lá (A4, A3, Ofício) e se o compartimento está cheio.

### 5. Tempo de Atividade (Uptime)
- A OID `.1.3.6.1.2.1.1.3.0` informa há quantas horas/dias a impressora está ligada initerruptamente.

> **💡 Dica Técnica:** Para descobrir OIDs específicas de modelos mais difíceis, podemos utilizar ferramentas como o `snmpwalk` no servidor Linux/Windows para varrer a árvore `1.3.6.1.4.1.18334` da Konica e descobrir tudo o que ela está respondendo "escondida".
