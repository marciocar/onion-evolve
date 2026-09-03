---
title: "Revisão — adoção funde o CLAUDE.md boilerplate (D_ADOPT_ENTREGA_CLAUDE_MD_FUNDIDO, opção 1)"
date: 2026-09-03
branch: feat/adopt-claude-md-fuse
reviewer: "condutor com dogfood do helper (família claude_md_fuse 5/5: funde Astro, recusa marcador e prosa) — o dogfood da ADOÇÃO inteira fica para a próxima greenfield (gatilho no nó)"
reviewed_diff_sha256: 87923ff9735c54d698ba276ca52c8423eb2c8347017c5794622538e6b395a963
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 60000
duration_min: 30
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

Selo do maestro (opção 1 do nó): na adoção, `CLAUDE.md` pré-existente que é boilerplate de template é FUNDIDO no esqueleto
Onion-first (original preservado em seção nomeada); com regras reais, never-clobber como antes. Helper
`.claude/utils/adopt/claude-md-fuse.sh` (`--classify`, `--fuse`), família na bancada, Fase 3 do `/meta:adopt` chama o helper.

## Achados

1. **O critério de boilerplate é declarado e mecânico** (fora de código/tabela/link/título: sem marcador de regra e sem parágrafo
   ≥ 25 palavras); "não sei" classifica como regras — recusa no incerto. Testado com Astro real, marcador `NUNCA` e prosa longa.
2. **A fusão nunca apaga**: o original entra integral numa seção `## 🛠️ Desenvolvimento — conteúdo original do template (<título>)`;
   o diff da adoção mostra tudo. Recusa = exit 3 e nada escrito (never-clobber intacto).
3. **Limite declarado**: o adopt é executado por agente (prosa), então o dogfood REAL da fusão dentro de uma adoção fica para a
   próxima greenfield — o nó guarda esse gatilho. A implementação de referência (Sacola) foi feita à mão e é o molde.
4. **`kg-backlog (e)` reprovou o 1º gate deste PR (2ª ocorrência do intermitente, paralelo-só)** e a mensagem nova mostrou
   "HARD só-no-mutante: []". Causa candidata no código: a mutação fazia `cat >>` no FIM do grafo, e `fios-abertos` termina em
   `edges:` — o nó-fixture caía sob `edges`. Curado (insere antes de `edges:`); 7/7 em série. Se recorrer, a causa é outra
   (nó `Q_KG_BACKLOG_E_INTERMITENTE_EM_PARALELO` atualizado). Colateral: 49k `tmp.*` meus em /tmp — sandboxes de abortos; limpos os >1 dia.
