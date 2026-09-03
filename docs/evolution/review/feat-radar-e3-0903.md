---
title: "Revisão — radar E3 rodada 2: delta Claude Code 2.1.257 → 2.1.259 (juiz reprovou 2 de 11 e achou 8 omissões)"
date: 2026-09-03
branch: feat/radar-e3-0903
reviewer: "juiz adversarial opus/high (mandato REFUTAR, abriu a fonte, re-executou os greps): 1 aprovado, 8 emendados, 2 reprovados, 8 omissões — tudo incorporado ao grafo; rascunho pré-juiz preservado em data/"
reviewed_diff_sha256: bcf530c77657f292a950ff4cb6a9929386c545103b0d2f04fda6d6e63b9b22d2
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 2600000
duration_min: 35
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

Rodada 2 do eixo E3 (gatilho: REGRA 65 (Radar de mundo com baseline DATADA por eixo) SOFT — processo 2.1.259 vs rodada 2.1.257).
Fonte primária verbatim em `data/`; grafo com 15 nós e `review_after` (REGRA 67); evidências com `source_tier: 9` `vendor-on-self`
(REGRA 68); baseline E3 selada no mesmo commit (`cc_version: "2.1.259"`).

## Achados

1. **O que muda estratégia** (F1, l.17): `model:` de frontmatter passa a valer em sessão interativa; 109 comandos do core (96 `sonnet`)
   passam a pedir troca de modelo — a guarda PreModelSwitch veta. Decisão proposta `D_COMANDOS_SEM_MODEL_OU_NO_LINEUP`
   (recomendada: remover `model:` dos comandos; tiering fica nos agentes). **Depende de medição humana** (o que acontece ao comando
   após o veto) — lacuna declarada com o procedimento.
2. **Meu defeito de classe**: 6 de 11 citações erradas (5 linhas contadas de olho, 1 `allow` lido como `deny`) e 2 medições
   superestimadas (`grep '^model:'` contava exemplos no corpo: 111/1/163 → real 109/0/51). Memória nova `cite-lines-by-grep-never-by-eye`.
3. **Reprovados**: F5 (o core não tem deny rule; a linha 12 do settings é um allow de `grep * .env`) e F8 (não há hook Stop no core).
4. **8 omissões do juiz** incorporadas num nó (Stop em sessão remota l.26, URL de marketplace l.28, MCP "conectado sem tools" l.22,
   `--resume` l.16, identidade de repo l.24, `/workflows` JSON l.33, sessões agendadas l.39/2.1.258 l.44, `MAX_CONTEXT_TOKENS` l.13).

Lacunas humanas (sessão NOVA em 2.1.259): `/warm-up` no picker → 2ª linha de `.claude/sessions/model-switch.jsonl`; o comando roda ou
quebra após o veto; mesmo probe para `model: haiku`; `--permission-prompts none` × `bypassPermissions`; versão do processo das sessões da VPS.
