---
title: "/meta:setup-integration — três defeitos achados no dogfood do Zoho"
date: 2026-10-05
from: gmill (hub)
to: core (onion-evolve)
type: bug-report
flow: upstream
relates_to:
  - .claude/commands/meta/setup-integration.md
  - .env.example
---

# `/meta:setup-integration`: três defeitos achados no dogfood do Zoho

Medido neste repo em 2026-10-05, no pin `ab08cde675fa`, ao configurar `TASK_MANAGER_PROVIDER=zoho`.
Segui os passos do comando sobre um `.env` que já existia. Os três defeitos estão no framework, não no
uso local, então a correção é do core.

O adapter (`.claude/utils/task-manager/adapters/zoho.md`) **está bom**: um teste de 12 passos contra um
portal real (projeto descartável, tasklist, task, subtask aninhada, comentário, leitura, edição, filtro de
subtask no cliente, exclusão e limpeza conferida) passou 12 de 12. Os problemas são do comando de setup.

## 1. O passo 2 manda ler o `.env` com `Read` e diz que isso "não expõe valores". Expõe. (severidade alta)

`setup-integration.md`, passo 2:

> **CRÍTICO:** Usar `Read` para ler `.env` sem expor valores sensíveis
> **SEMPRE** usar `Read` que permite análise sem exposição

`Read` devolve o arquivo inteiro ao modelo. Os segredos entram no contexto e no transcript da sessão,
que é exatamente o que a regra quer impedir. A doutrina afirma o contrário do que a ferramenta faz.

**O que funcionou aqui:** checar presença pelo nome, sem ler o valor:

```bash
for k in TASK_MANAGER_PROVIDER ZOHO_CLIENT_ID ZOHO_CLIENT_SECRET ZOHO_PORTAL_ID; do
  grep -q "^$k=." .env && echo "✅ $k" || echo "❌ $k"
done
```

Só o valor de `TASK_MANAGER_PROVIDER` precisa ser mostrado, e ele não é segredo.

## 2. O passo 4 pode deixar o provider errado ativo, e o `.env.example` não conhece o Zoho (severidade média)

Sem `.env`, o passo 4 faz `cp .env.example .env`. O `.env.example` vem com `TASK_MANAGER_PROVIDER=jira`,
e o próprio passo 4 manda **nunca sobrescrever** um valor existente. Resultado: quem escolhe Zoho (ou
ClickUp, Asana, Linear) termina com `jira` ativo e as variáveis do provider escolhido adicionadas no fim,
sem efeito.

Além disso, o `.env.example` está atrás do comando:

- a linha de opções diz `jira | clickup | asana | linear | none`, sem `zoho`;
- não há nenhuma variável `ZOHO_*` (`grep -c ZOHO .env.example` dá 0), embora o comando e o adapter já
  as documentem.

**Sugestão:** `.env.example` com `TASK_MANAGER_PROVIDER=none` (ou comentado), e o passo 4 tratando
`TASK_MANAGER_PROVIDER` como a única chave que o setup **deve** escrever com o valor escolhido, avisando
se havia outro. Incluir o bloco `ZOHO_*` no `.env.example`.

## 3. O passo 5 não testa a conexão (severidade baixa)

O passo 5 só tem comentários ("Verificar se variáveis obrigatórias do provedor estão presentes",
"Teste de conexão específico da integração"). Nada roda. Para o Zoho, o teste é barato e não escreve
nada no portal:

```bash
TOKEN=$(curl -s -X POST "$ZOHO_ACCOUNTS_HOST/oauth/v2/token" \
  -d grant_type=client_credentials -d "client_id=$ZOHO_CLIENT_ID" \
  -d "client_secret=$ZOHO_CLIENT_SECRET" -d scope=ZohoProjects.portals.READ | jq -r .access_token)
curl -s -H "Authorization: Zoho-oauthtoken $TOKEN" https://projects.zoho.com/api/v3/portals \
  | jq --arg p "$ZOHO_PORTAL_ID" '[.[] | select((.id|tostring) == $p) | .name]'
```

Isso prova três coisas de uma vez: a credencial vale, o data center está certo e o `ZOHO_PORTAL_ID` é um
portal que a credencial enxerga. Foi assim que descobrimos aqui que a credencial disponível era de um
portal pessoal, e não do portal da empresa.

## Observação lateral

O hook `task-manager-provider-hook.sh` acertou: avisou que `TASK_MANAGER_PROVIDER=zoho` estava no `.env`
mas não no ambiente da sessão. O setup poderia terminar com essa mesma instrução
(`set -a; source .env; set +a`).
