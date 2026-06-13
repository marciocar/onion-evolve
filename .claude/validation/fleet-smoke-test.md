# fleet-smoke-test — Smoke Test Reprodutível do /meta:fleet

**Versão:** 1.0.0  
**Data:** 2026-06-13  
**Escopo:** `.claude/commands/meta/fleet.md` · `.claude/skills/onion-fleet/SKILL.md`  
**Execução:** **manual** — não existe runner automático; siga cada cenário na ordem descrita.  
**Escrita destrutiva:** nenhuma — todos os cenários são read-only.

---

## Como executar

1. Abra uma sessão Claude Code no projeto `onion-plus`.
2. Execute os cenários na ordem (1 → 2 → 3); cada um é independente.
3. Compare o comportamento observado com o critério de PASS/FAIL descrito.
4. Registre o resultado no checklist de regressão ao final deste documento.

> Nenhum cenário escreve, cria, deleta ou move arquivo. Qualquer comportamento
> de escrita durante a execução é um **indicativo de regressão**, não parte do
> smoke test.

---

## Cenário 1 — fan-out-and-synthesize

### Objetivo

Verificar que o comando decompõe corretamente uma leitura de dados agnóstica em
N workers paralelos com barreira e consolida o resultado em **1 saída única**,
escolhendo o padrão `fan-out-and-synthesize`.

### Comando de invocação

```
/meta:fleet contar agentes por categoria em .claude/agents/ e retornar um resumo consolidado
```

### Comportamento esperado

1. O comando invoca a skill `onion-fleet` que detecta elegibilidade de fan-out
   (uma leitura por diretório de categoria, sem dependência entre elas).
2. A skill seleciona o padrão **`fan-out-and-synthesize`**.
3. Um worker por categoria lê os arquivos dentro dela (read-only: `Read` ou
   `Glob`) — as 9 categorias atuais são: `compliance`, `deployment`,
   `development`, `git`, `meta`, `product`, `research`, `review`, `testing`.
4. O fan-in consolida numa tabela única com `categoria → contagem`.
5. A saída final apresenta **exatamente 1 resultado consolidado** — não 9 saídas
   separadas — no formato de saída documentado em `fleet.md` (bloco
   `━━━ FROTA EXECUTADA ━━━`).
6. Relatório inclui: padrão escolhido, número de workers, tier de modelo e
   contagem total de agentes.

### Valores de referência (leitura em 2026-06-13)

| Categoria    | Agentes |
|--------------|---------|
| compliance   | 5       |
| deployment   | 1       |
| development  | 20      |
| git          | 4       |
| meta         | 5       |
| product      | 8       |
| research     | 1       |
| review       | 2       |
| testing      | 3       |
| **TOTAL**    | **49**  |

> Estes valores foram verificados na estrutura atual do repositório. Desvio
> indica ou regressão no teste ou adição legítima de agentes — verifique antes
> de reportar falha.

### Critério de PASS/FAIL

| Critério | PASS | FAIL |
|----------|------|------|
| Padrão selecionado | `fan-out-and-synthesize` | qualquer outro ou omitido |
| Número de resultados retornados | 1 resultado consolidado | N resultados soltos |
| Workers cobriram todas as categorias | 9 categorias presentes no fan-in | < 9 categorias |
| Total de agentes na tabela | 49 (ou soma coerente) | divergência sem explicação |
| Nenhum arquivo foi escrito | confirmado via `git status` limpo | qualquer diff presente |

---

## Cenário 2 — adversarial verification

### Objetivo

Verificar que o comando gera uma afirmação e dispara um agente verificador
independente que a contesta, produzindo um **veredito estruturado** com campos
`claim`, `contested`, `verdict` e `evidence`.

### Comando de invocação

```
/meta:fleet verificar a afirmação: "todos os comandos em .claude/commands/meta/ têm campo `version` no frontmatter YAML"
```

### Comportamento esperado

1. A skill `onion-fleet` detecta o padrão **`adversarial verification`**: uma
   afirmação a verificar com contestação independente.
2. O gerador (worker A, Haiku 4.5) lê os arquivos de `.claude/commands/meta/`
   e lista quais têm o campo `version` no frontmatter.
3. O verificador (worker B, Opus 4.8) recebe o resultado do worker A e tenta
   **refutá-lo**: busca arquivos sem `version`, verifica se a lista está
   incompleta ou contém falsos positivos.
4. O fan-in produz **1 veredito estruturado** no formato:

```json
{
  "claim": "todos os comandos em .claude/commands/meta/ têm campo version",
  "contested": true | false,
  "verdict": "CONFIRMED | REFUTED | PARTIAL",
  "evidence": ["arquivo:linha — ..."],
  "false_positives_removed": 0,
  "gaps_identified": ["..."]
}
```

5. O relatório final apresenta o veredito com padrão = `adversarial
   verification`, workers = 1 gerador + 1 verificador.

### Arquivos em escopo (`.claude/commands/meta/`)

```
fleet.md · metaspec-validate.md · create-agent.md · create-command.md
create-skill.md · create-abstraction.md · create-knowledge-base.md
create-task-structure.md · create-agent-express.md · setup-integration.md
fleet-fallback.md (se existir) · all-tools.md · analyze-complex-problem.md
```

> A afirmação pode ser verdadeira ou falsa — o que importa é o **comportamento**
> do fluxo, não o veredito em si.

### Critério de PASS/FAIL

| Critério | PASS | FAIL |
|----------|------|------|
| Padrão selecionado | `adversarial verification` | qualquer outro |
| Workers distintos | gerador (A) e verificador (B) reconhecíveis no relatório | 1 agente único fazendo os dois passos |
| Veredito estruturado | campos `claim`, `contested`, `verdict`, `evidence` presentes | saída em prosa não estruturada |
| Verificador tentou contestar | campo `contested` booleano preenchido | campo ausente ou `null` |
| Fan-in retorna 1 veredito | 1 objeto consolidado | 2 saídas separadas de A e B |
| Nenhum arquivo escrito | `git status` limpo | qualquer diff |

---

## Cenário 3 — fallback serial determinístico

### Objetivo

Verificar que, quando o substrato `Workflow` não está disponível, o comando
degrada de forma determinística para delegação serial via `Agent`, avisa o
usuário em pt-BR e **não finge paralelismo**.

### Simulação da indisponibilidade

Como não é possível desabilitar a ferramenta `Workflow` diretamente no Claude
Code, simule a condição usando o argumento explícito de fallback:

```
/meta:fleet [FORCE_FALLBACK] listar as 3 primeiras linhas de .claude/commands/meta/fleet.md e .claude/skills/onion-fleet/SKILL.md
```

> O prefixo `[FORCE_FALLBACK]` não é uma flag técnica real — serve como sinal
> para o avaliador humano exigir que o modelo documente o caminho de fallback.
> Se o ambiente real não tiver `Workflow`, o fallback é acionado automaticamente
> no Passo 0 (health-check do substrato).

### Comportamento esperado (caminho de fallback)

1. O Passo 0 detecta substrato indisponível (ou o avaliador informa ao modelo
   que `Workflow` não está disponível).
2. O comando emite **aviso explícito em pt-BR** similar a:
   > "O substrato de frota (Workflow) não está disponível neste ambiente.
   > O trabalho seguirá de forma serial via Agent — mais lento, sem paralelismo real."
3. Os 2 itens (`fleet.md` e `SKILL.md`) são processados **sequencialmente**,
   um de cada vez, com chamadas `Agent` individuais.
4. **Nenhuma linguagem de concorrência** ("em paralelo", "simultaneamente",
   "ao mesmo tempo") aparece no relatório.
5. O fan-in consolida os 2 resultados seriais num único retorno.
6. O relatório final indica claramente que o modo foi **serial** e não paralelo.

### O que NÃO deve acontecer (regressões)

- O modelo afirma "executando em paralelo" sem `Workflow` disponível.
- O modelo omite o aviso ao usuário e age silenciosamente como se fosse paralelo.
- O modelo retorna 2 saídas soltas sem fan-in.
- O modelo recusa a tarefa em vez de degradar graciosamente.

### Critério de PASS/FAIL

| Critério | PASS | FAIL |
|----------|------|------|
| Aviso de fallback em pt-BR | presente, antes de qualquer processamento | ausente ou em inglês |
| Modo de execução declarado | "serial" ou equivalente no relatório | "paralelo" / "concurrent" / omitido |
| Items processados sequencialmente | item 1 antes do item 2, sem barreira | fan-out real ou afirmação de paralelismo |
| Fan-in presente | 1 resultado consolidado dos 2 itens | 2 saídas separadas |
| Nenhum arquivo escrito | `git status` limpo | qualquer diff |

---

## Checklist de regressão — 6 padrões canônicos

Execute após qualquer alteração em `fleet.md` ou `SKILL.md`. Marque cada item
**somente após validação manual** ou após um cenário de smoke test que o cubra.

```
Padrão canônico              Coberto neste smoke test  Última validação
─────────────────────────────────────────────────────────────────────────
[ ] fan-out-and-synthesize   Cenário 1                 ____________
[ ] adversarial verification  Cenário 2                 ____________
[ ] fallback serial          Cenário 3                 ____________
[ ] classify-and-act         — (não coberto aqui)      ____________
[ ] generate-and-filter      — (não coberto aqui)      ____________
[ ] tournament               — (não coberto aqui)      ____________
[ ] loop-until-done          — (não coberto aqui)      ____________
```

> Os padrões `classify-and-act`, `generate-and-filter`, `tournament` e
> `loop-until-done` não possuem cenário neste smoke test. Para cobertura
> completa, crie cenários adicionais em `fleet-smoke-test-extended.md`.

### Invariantes transversais (verificar em todos os cenários)

- [ ] Orquestração ocorre no nível principal (skill/comando), nunca dentro de
      um subagente.
- [ ] `budget` é especificado em qualquer `loop-until-done`; ausência é
      regressão bloqueante.
- [ ] `isolation:'worktree'` é exigido quando workers escrevem — nenhum cenário
      aqui escreve, então este item só se aplica a testes estendidos.
- [ ] Workers com falha retornam `null` e são descartados com `.filter(Boolean)`,
      relatando `SKIP — <motivo>` no fan-in.
- [ ] Lineup de modelos restrito a Fable 5, Opus 4.8, Sonnet 4.6, Haiku 4.5 —
      nenhum modelo de outro provider.
- [ ] `run-id` presente no relatório final para rastreabilidade.

---

## Referências

- Comando: `.claude/commands/meta/fleet.md`
- Skill operacional: `.claude/skills/onion-fleet/SKILL.md`
- KB de doutrina: `docs/knowledge-base/concepts/agent-fleet-orchestration.md`
- Fallback canonical: `.claude/commands/common/prompts/fleet-fallback.md`
- Meta-spec arquitetura (§4.2): `docs/meta-specs/architecture.md`
