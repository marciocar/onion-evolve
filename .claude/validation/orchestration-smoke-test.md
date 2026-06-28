# orchestration-smoke-test — Smoke Test Reprodutível do /meta:orchestrate

**Versão:** 1.0.0  
**Data:** 2026-06-13  
**Escopo:** `.claude/commands/meta/orchestrate.md` · `.claude/skills/onion-orchestration/SKILL.md`  
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
/meta:orchestrate contar agentes por categoria em .claude/agents/ e retornar um resumo consolidado
```

### Comportamento esperado

1. O comando invoca a skill `onion-orchestration` que detecta elegibilidade de fan-out
   (uma leitura por diretório de categoria, sem dependência entre elas).
2. A skill seleciona o padrão **`fan-out-and-synthesize`**.
3. Um worker por categoria lê os arquivos dentro dela (read-only: `Read` ou
   `Glob`) — as 9 categorias atuais são: `compliance`, `deployment`,
   `development`, `git`, `meta`, `product`, `research`, `review`, `testing`.
4. O fan-in consolida numa tabela única com `categoria → contagem`.
5. A saída final apresenta **exatamente 1 resultado consolidado** — não 9 saídas
   separadas — no formato de saída documentado em `orchestrate.md` (bloco
   `━━━ ORQUESTRAÇÃO EXECUTADA ━━━`).
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
/meta:orchestrate verificar a afirmação: "todos os comandos em .claude/commands/meta/ têm campo `version` no frontmatter YAML"
```

### Comportamento esperado

1. A skill `onion-orchestration` detecta o padrão **`adversarial verification`**: uma
   afirmação a verificar com contestação independente.
2. O gerador (worker A, tier haiku) lê os arquivos de `.claude/commands/meta/`
   e lista quais têm o campo `version` no frontmatter.
3. O verificador (worker B, tier opus) recebe o resultado do worker A e tenta
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
orchestrate.md · metaspec-validate.md · create-agent.md · create-command.md
create-skill.md · create-abstraction.md · create-knowledge-base.md
create-agent-express.md · setup-integration.md
orchestration-fallback.md (se existir) · all-tools.md · analyze-complex-problem.md
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
/meta:orchestrate [FORCE_FALLBACK] listar as 3 primeiras linhas de .claude/commands/meta/orchestrate.md e .claude/skills/onion-orchestration/SKILL.md
```

> O prefixo `[FORCE_FALLBACK]` não é uma flag técnica real — serve como sinal
> para o avaliador humano exigir que o modelo documente o caminho de fallback.
> Se o ambiente real não tiver `Workflow`, o fallback é acionado automaticamente
> no Passo 0 (health-check do substrato).

### Comportamento esperado (caminho de fallback)

1. O Passo 0 detecta substrato indisponível (ou o avaliador informa ao modelo
   que `Workflow` não está disponível).
2. O comando emite **aviso explícito em pt-BR** similar a:
   > "O substrato de orquestração (Workflow) não está disponível neste ambiente.
   > O trabalho seguirá de forma serial via Agent — mais lento, sem paralelismo real."
3. Os 2 itens (`orchestrate.md` e `SKILL.md`) são processados **sequencialmente**,
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

## Cenário 4 — orquestração mutante (partição-primeiro)

### Objetivo

Validar a **orquestração que ESCREVE** arquivos em paralelo: partição-primeiro (sem
worktree quando os alvos são disjuntos), detecção de colisão de paths no fan-in,
consolidação numa **única branch** e gate humano em conflito.

### Comando de invocação

```
/meta:orchestrate adicionar `version: "1.0.0"` ao frontmatter dos comandos sem o campo
```

### Comportamento esperado

1. **Levantamento** dos alvos (comandos sem `version:`) via `Glob`/`Grep`.
2. **Partição por arquivos disjuntos** — cada worker recebe um subconjunto que
   **nenhum outro** toca → o relatório declara "partição-primeiro, sem worktree".
3. Workers retornam `DiffSchema`; o fan-in **cruza os `files[].path` em JS** e
   confirma **partição limpa** (zero paths repetidos).
4. **Consolidação numa única branch** (ex.: `orchestration/add-version-field`) — não N
   branches soltas; a branch entra no fluxo normal (`/git:flow feature finish` ou
   `/engineer:pr`).
5. Worker morto → `null` → `.filter(Boolean)` + `SKIP — <motivo>` no relatório.

### Variante worktree (sobreposição) + gate

Se a partição **não** for possível (workers tocam o mesmo arquivo), o esperado é:
`isolation:'worktree'` por worker **OU** colisão detectada → **gate humano**
(reportar os paths em conflito, **não** auto-merge). Operação irreversível →
gate humano.

### Critério de PASS/FAIL

| Critério | PASS | FAIL |
|----------|------|------|
| Decisão partição-vs-worktree explícita | declara "partição-primeiro, sem worktree" quando alvos disjuntos | usa worktree sem necessidade, ou não decide |
| Detecção de colisão no fan-in | cruza paths em JS antes de consolidar | aplica diffs às cegas |
| Saída = 1 branch | uma branch de consolidação → fluxo de PR | N branches soltas / bypass do gate de PR |
| Gate em conflito/irreversível | pausa e pede confirmação humana | auto-merge de conflito |
| Invariante de fase | não funde `engineer/*`/`product/*` | propõe fusão de fases |

---

## Cenário 5 — classify-and-act

### Objetivo
Validar que a orquestração executa UM passo de classificação centralizado antes de qualquer roteamento, e que cada item é entregue exclusivamente ao handler do seu bucket correto (`bug`, `feature` ou `docs`), com fan-in em um único relatório consolidado.

### Comando de invocação
```
/meta:orchestrate triar as issues abaixo em buckets bug | feature | docs e rotear cada uma ao handler especializado: ["Login falha com OAuth", "Adicionar exportação CSV", "Atualizar guia de instalação", "NullPointerException no checkout", "Documentar endpoint /health", "Permitir login por magic link"]
```

### Comportamento esperado
1. O orquestrador (opus) instancia UM agente classificador (sonnet) que recebe todas as 6 issues e retorna um mapa `{ issue -> bucket }` antes de qualquer handler ser disparado.
2. O resultado da classificação é inspecionado em JavaScript (0 tokens) para agrupar as issues por bucket e construir as filas de roteamento.
3. Os handlers especializados (workers sonnet/haiku, um por bucket) são disparados em paralelo via `parallel()`, cada um recebendo somente as issues do seu bucket.
4. Workers que falham retornam `null` e são descartados com `.filter(Boolean)`, registrando `SKIP — <motivo>` no relatório.
5. Os resultados dos handlers convergem em UM único relatório consolidado com `run-id` rastreável, listando o bucket e o resultado de cada issue.

### Critério de PASS/FAIL
| Critério | PASS | FAIL |
|----------|------|------|
| Classificação única e anterior ao roteamento | O classificador roda uma vez e conclui antes de qualquer handler iniciar | Handlers disparam antes/junto da classificação, ou há mais de um classificador |
| Roteamento por bucket correto | Cada issue chega só ao handler do seu bucket (ex.: "NullPointerException" → bug, nunca docs) | Issue entregue ao handler errado ou a múltiplos handlers |
| Model tiering | Orquestrador opus; classificador e handlers em sonnet/haiku | Workers em opus sem necessidade, ou modelo de outro provider |
| Fan-in obrigatório | Um único artefato consolidado cobrindo todos os buckets | N saídas soltas, uma por handler |
| `run-id` presente | Relatório final contém o `run-id` da execução | `run-id` ausente |

---

## Cenário 6 — generate-and-filter

### Objetivo
Validar que o padrão generate-and-filter gera N candidatos em paralelo e aplica o critério de aceitação em JavaScript puro (0 tokens), descartando reprovados e reportando a contagem de aprovados e rejeitados.

### Comando de invocação
```
/meta:orchestrate gere 5 variações de esquema JSON para o recurso "Pedido" e filtre apenas as que passam na validação de schema (ajv); reporte aprovados, reprovados e run-id
```

### Comportamento esperado
1. O orquestrador (opus) emite um `parallel([...])` com 5 workers sonnet, cada um gerando uma variação distinta do schema JSON para "Pedido".
2. Cada worker retorna seu candidato (string JSON) ou `null` em caso de falha (com log `SKIP — <motivo>`). **Após o `parallel()` retornar**, os `null` são descartados via `.filter(Boolean)` em JavaScript — **sem nenhuma chamada de modelo adicional** (0 tokens).
3. O filtro JavaScript executa a validação de schema (ajv ou equivalente) sobre os candidatos restantes, sem consumir tokens, separando aprovados de reprovados.
4. O orquestrador consolida em UM único relatório de fan-in: schemas aprovados, contagem de reprovados (com motivo) e o `run-id`.
5. O relatório final é a saída única; nenhuma saída solta por candidato é exposta.

### Critério de PASS/FAIL
| Critério | PASS | FAIL |
|----------|------|------|
| Filtro de aceitação | Executado em JavaScript (0 chamadas de modelo adicionais) | Candidato enviado a um agente/modelo para ser julgado |
| Candidatos reprovados | Descartados com contagem e motivo no relatório final | Reprovados silenciados ou contados como aprovados |
| Workers com falha | Retornam `null` + `SKIP — <motivo>`, descartados via `.filter(Boolean)` | Falha propaga erro não tratado ou trava o fan-out |
| Fan-in | Exatamente 1 relatório consolidado | N saídas soltas ou nenhuma |
| `run-id` | Presente e único no relatório final | Ausente ou duplicado |

---

## Cenário 7 — tournament

### Objetivo
Validar que o padrão tournament reduz o campo pela metade a cada rodada eliminatória par-a-par, com **barreira entre rodadas** (a Final depende dos vencedores), convergindo em UM único vencedor consolidado.

### Comando de invocação
```
/meta:orchestrate comparar as 4 abordagens de cache (in-memory, Redis, CDN edge, banco de dados) em rodadas eliminatórias 2-a-2 e eleger a melhor para um contexto de alta leitura
```

### Comportamento esperado
1. O orquestrador (opus) monta o chaveamento e dispara a Rodada 1 com `parallel([par A, par B])` (**barreira por rodada**): par A (in-memory vs Redis) e par B (CDN edge vs banco), cada confronto avaliado por um worker sonnet. A coordenação JavaScript aplica `.filter(Boolean)` e retém os 2 vencedores.
2. Worker que falhar num confronto retorna `null`, é descartado com `.filter(Boolean)` e o adversário avança; o motivo vira `SKIP — <motivo>` no relatório parcial.
3. Rodada 2 (Final): os 2 vencedores se enfrentam num confronto único, avaliado por um juiz adversarial opus.
4. O orquestrador consolida fan-in único: relatório com `run-id`, placar por rodada, justificativa do vencedor e recomendação — nunca 4 saídas soltas.
5. Toda coordenação (filtros, roteamento de rodadas, agregação) roda em JavaScript = 0 tokens, no nível principal; nenhum subagente orquestra rodadas.

### Critério de PASS/FAIL
| Critério | PASS | FAIL |
|----------|------|------|
| Redução por rodada | Campo cai de 4 → 2 → 1 a cada rodada | Rodada termina com nº inesperado de finalistas |
| Primitivo correto | Rodadas usam `parallel()` com barreira (a Final depende dos vencedores) | Uso de `pipeline()` (sem barreira) entre rodadas dependentes |
| Fan-in único | Exatamente 1 relatório consolidado com `run-id` | Múltiplos relatórios soltos ou `run-id` ausente |
| Descarte de falhas | Worker falho → `null`, adversário avança, `SKIP — <motivo>` presente | Falha interrompe o torneio ou avança sem registrar motivo |
| Orquestração no nível principal | Nenhum subagente coordena rodadas | Subagente age como "worker-orchestrator" interno |

---

## Cenário 8 — loop-until-done

### Objetivo
Validar que `loop-until-done` corrige erros de lint em lotes sucessivos até zerar ou atingir o teto de budget, e que a **ausência de budget é regressão bloqueante**.

### Comando de invocação
```
/meta:orchestrate corrigir o próximo lote de erros de lint repetidamente até zerar (loop-until-dry), com teto de 8 iterações e budget máximo de 200 000 tokens
```

### Comportamento esperado
1. O orquestrador (nível principal, opus) lê o relatório de lint inicial e registra o `run-id` no cabeçalho do relatório final.
2. A cada iteração, um worker sonnet recebe o lote de erros restantes, aplica as correções e retorna `{ errosRestantes, tokensUsados }` — ou `null` em caso de falha (descartado via `.filter(Boolean)`, reportado como `SKIP — <motivo>`).
3. O orquestrador avalia em JavaScript (0 tokens) se `errosRestantes === 0` (parada por conclusão) ou se `iterações >= 8` / `tokensAcumulados >= 200000` (parada por budget).
4. O loop encerra pelo primeiro critério atingido; consolida UM único relatório final com erros corrigidos, iterações, tokens consumidos e `run-id`.
5. Se invocado **sem** teto de iterações ou budget, a skill **recusa a execução** com erro bloqueante antes de criar qualquer agente.

### Critério de PASS/FAIL
| Critério | PASS | FAIL |
|----------|------|------|
| Budget obrigatório | Execução recusada com erro explícito quando o teto está ausente | Loop iniciado sem teto de iterações/tokens |
| Parada por condição | Loop encerra quando `errosRestantes === 0` antes do teto | Loop continua após zerar os erros |
| Parada por budget | Loop encerra ao atingir 8 iterações ou 200 000 tokens, o que vier primeiro | Loop ultrapassa o teto |
| Fan-in consolidado | Relatório único com `run-id`, erros corrigidos e tokens consumidos | N relatórios soltos ou `run-id` ausente |
| Worker com falha | Worker falho → `null`, descartado com `.filter(Boolean)`, `SKIP — <motivo>` | Falha aborta todo o loop ou é silenciada |

---

## Checklist de regressão — 6 padrões canônicos

Execute após qualquer alteração em `orchestrate.md` ou `SKILL.md`. Marque cada item
**somente após validação manual** ou após um cenário de smoke test que o cubra.

```
Padrão canônico              Coberto neste smoke test  Última validação
─────────────────────────────────────────────────────────────────────────
[ ] fan-out-and-synthesize   Cenário 1                 ____________
[ ] adversarial verification  Cenário 2                 ____________
[ ] fallback serial          Cenário 3 (transversal)   ____________
[ ] orquestração mutante (worktree) Cenário 4 (transversal)   ____________
[ ] classify-and-act         Cenário 5                 ____________
[ ] generate-and-filter      Cenário 6                 ____________
[ ] tournament               Cenário 7                 ____________
[ ] loop-until-done          Cenário 8                 ____________
```

> **Cobertura completa (6/6 padrões canônicos).** Os 6 padrões canônicos têm
> cenário (1, 2, 5, 6, 7, 8); `fallback serial` (3) e `orquestração mutante` (4) são
> cenários transversais adicionais. Cenários 5-8 foram **autorados pela própria
> orquestração** (`/meta:orchestrate`, fan-out-and-synthesize + verificação adversarial) —
> dogfooding em 2026-06-14.

### Invariantes transversais (verificar em todos os cenários)

- [ ] Orquestração ocorre no nível principal (skill/comando), nunca dentro de
      um subagente.
- [ ] `budget` é especificado em qualquer `loop-until-done`; ausência é
      regressão bloqueante.
- [ ] Mutação: **partição-primeiro** (sem worktree p/ alvos disjuntos);
      `isolation:'worktree'` só p/ sobreposição real; saída = **1 branch**
      consolidada → fluxo de PR; conflito/irreversível → gate humano. Coberto
      pelo **Cenário 4**.
- [ ] Workers com falha retornam `null` e são descartados com `.filter(Boolean)`,
      relatando `SKIP — <motivo>` no fan-in.
- [ ] Lineup de modelos restrito a tiers Claude (fable, opus, sonnet, haiku) —
      nenhum modelo de outro provider (GPT, Gemini, Llama etc.).
- [ ] `run-id` presente no relatório final para rastreabilidade.

---

## Referências

- Comando: `.claude/commands/meta/orchestrate.md`
- Skill operacional: `.claude/skills/onion-orchestration/SKILL.md`
- KB de doutrina: `docs/knowledge-base/concepts/agent-orchestration.md`
- Fallback canonical: `.claude/commands/common/prompts/orchestration-fallback.md`
- Meta-spec arquitetura (§4.2): `docs/meta-specs/architecture.md`
