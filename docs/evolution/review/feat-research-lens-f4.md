---
title: "Revisão — F4 da lente: revisita (--revisit + cadenceDays) e REGRA 69 (roster); dogfood no grafo do WhatsApp; fio do CLAUDE.md fundido"
date: 2026-09-03
branch: feat/research-lens-f4
reviewer: "condutor com dogfood EXECUTADO em 3 rodadas (wf_0375d930 0 vencidos/76k · wf_d88a345c 1,37M invalidada pelo placeholder de citação, grafo revertido · wf_9487391f 1,32M: 1 reconfirmado, 5 SUPERSEDES, radar exit 0, 61 nós); bancadas research-lens 9/9 e research-workflow 9/9 (caso (i) executa o corpo com stubs — pegou 2 TDZ); pre-gate limpo (contagens, vendor-scrub, registro, projeções, lint --only, base = origin/main); radar exit 0 nos 3 grafos tocados; backlog LC_ALL=C"
reviewed_diff_sha256: 4697ee7e2109420d81b45eb64d6f3ea08bf7d548d78d2b561dd457aafca97669
findings_total: 6
findings_real: 6
verdict: APROVADO
tokens: 2900000
duration_min: 110
---

# Resíduo — REGRA 56

F4 do plano `meta-research-lens-2026-09` (`D_F4`, selo do maestro): REGRA 69 (fonte do roster com `last_checked`
vencido pela cadência ⇒ SOFT; opt-in por presença), `--revisit <kg>` no workflow (seleciona nós de evidência vencidos,
re-mede pela mesma votação, apenda `SUPERSEDES` datado, avança `review_after`) + `cadenceDays` ("revisite agora"),
seção na skill. Carona pequena: sinal upstream do adotante processado como `D_ADOPT_ENTREGA_CLAUDE_MD_FUNDIDO`.

## Achados

1. **Placeholder de citação virou refutação falsa**: no 1º desenho da revisita o verificador recebia "(revisita:
   re-buscar a fonte…)" como citação e refutou 4 claims de páginas oficiais da Meta por "citação não sustenta". Grafo
   revertido (`git checkout`), cura: o verificador **re-busca a fonte e extrai a citação atual**; 1,37 M gastos na
   rodada invalidada — declarado.
2. **Dois TDZ** (`REVISIT` e `webText` usados antes da declaração): `node --check` aprova; **executar o corpo com
   stubs** pega. Caso (i) da bancada agora percorre Scope→write com dados sintéticos e reprova só em
   `ReferenceError|SyntaxError`.
3. **Seletor honesto**: com cadência de mercado (90 d) nada estava vencido — 76 k e parou. `cadenceDays` é o override
   explícito; sem ele a revisita é barata quando não há nada a fazer.
4. **A revisita erodiu o corpus de julho**: 5 claims seladas sobre blog tier 4 caíram — achado de método (a REGRA 68
   teria barrado); o SYNTHESIS ganhou apêndice datado dizendo isso.
5. **Sinal do adotante** ("o core deveria mandar o CLAUDE.md fundido, pronto e resolvido" — maestro verbatim) virou
   nó `D_ADOPT_ENTREGA_CLAUDE_MD_FUNDIDO` no `fios-abertos` (3 opções, gatilho nomeado).

6. **A bancada nova reprovou no runner real e passava isolada (3ª ocorrência da classe *bancada espelha o runner*)**: o stub JS do caso (i) tinha aspas simples dentro de `printf '…'` — o shell as consumia, o JS via `label:a` e o `ReferenceError` na linha 1 só apareceu sob `set -euo pipefail` do runner. Cura: `printf '%s\n'` com o stub como argumento (aspas duplas dentro), reproduzido com as opções do runner antes de commitar, e o modo-de-falha provado (TDZ injetado ⇒ rc=3).

## Não mudou

- REGRA 65 não varre o roster (a REGRA 69 é a irmã dedicada); cron/routines seguem MOAT W7.
- Nenhum nó do WhatsApp foi apagado — só `superseded` com o novo ao lado (Aufhebung).
- O selo das decisões abertas (poda do CLAUDE.md; CLAUDE.md fundido na adoção) é do maestro.
