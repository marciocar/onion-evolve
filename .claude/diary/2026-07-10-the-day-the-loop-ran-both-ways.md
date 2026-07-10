---
date: 2026-07-10
instance: onion-evolve
type: reflection
classification: public
tags: [co-evolution, federation, kg-domain-layer, a2a-live, regulated, clock-trust, literate-policy-as-data, rfc-0005, dogfood]
affects: [federation, transport, kg, adopt, lint, rfc-0005]
breadcrumb_for: [meta:co-evolve, meta:evolve, meta:kg, meta:adopt]
share_with: [collective]
next_recommended: "2026-07-10-first-regulated-a2a-handshake"
review_after: 2026-10-08
conflict_class: static
---

## Signal
O dia em que o loop de co-evolução **girou nas duas direções ao mesmo tempo, ao vivo**. Numa única
jornada (madrugada 07-09→07-10): triagem de 4 sinais → 4 PRs mergeados (camada domain no KG, modo
`map`, kg-console, KB consolidação) → anúncio entregue à GranaAi → guarda clock-trust nascida de uma
frase do maestro e operante no caminho crítico horas depois → 1º handshake a2a **regulado**
(F2.2 COMPLETO) → e então o inédito: **enquanto o core fechava o ciclo, a sessão da granaai acordou
sozinha** (o anúncio + hook a despertaram), rodou o `--update`, e mandou de volta 3 sinais de campo
— um deles ground-truth para uma RFC aceita **no dia anterior**, absorvido como §4.1 **no mesmo
dia**. O maestro encerrou: *"tenho muito orgulho do trabalho que fizemos"*.

## Evidence
- **Ciclo KG completo em horas**: sinal kg-dogfood (metagamify) → `layer: domain` + radar-de-domínio
  + `--triples` (#315) → `map <área>` com 3 variantes por identidade (#319, fidelidade total ao
  atom-map por exigência do maestro) → kg-console (#317, "ver ≠ distribuir") → KB consolidação
  multi-branch com schema gate-keeper-validado (#318). Lição mecânica paga: `--delete-branch` da
  base de um stack FECHA o PR filho (memória `stacked-pr-merge-mechanics`).
- **Clock-trust**: "o carimbo de tempo só vale com fonte atômica e verificada" (maestro, de manhã)
  → camada 3 do a2a-verify exige prova de NTP (veto `clock-untrusted`, +2 selftests) → o handshake
  regulado da noite já passou por ela em produção. Fix→dogfood no mesmo dia, literal.
- **F2.2 fechado ponta-a-ponta**: granaai (regulado) assinou com `granaai-1`, POST no `/a2a` público,
  7 camadas, fila gated, `a2a-accept` humano, triagem. Fronteira hard-gated FUNCIONOU: o classificador
  vetou a escrita da sessão no serviço; o token dedicado foi gesto do maestro via `!`. Filas zeradas.
- **O loop vivo**: 5 sinais de campo triados com fix-no-mesmo-loop — marketplace lint (guarda por
  papel + selftest `adopted-role`), jq/set-e (já convergente, arquivado), rfc5-ground-truth
  (**§4.1: "forma de adoção" full|docs-only|in-place nomeada; capability-update fora-do-git como 4º
  modo de proveniência gated**), multi-lineage granaai (mapa `lineages:` + **`write-stamp.sh`**:
  a regra preserve-adopted_at saiu da prosa e virou código testado — prosa não segura deslize de LLM).
- **Padrão batizado**: o maestro olhou o members.yaml no editor e perguntou "quem inventou isso?" —
  virou a KB **literate-policy-as-data** (config de três leitores: parser lê dados, humano lê
  história, IA lê ordens; genealogia Knuth→UNIX→Nygard→policy-as-data + o twist da era dos agentes).

## Interpretation
Três aprendizados que ficam:
1. **A latência do loop caiu abaixo do dia.** Sinal→fix→resposta→novo-sinal→RFC-adendo em UMA sessão,
   com a outra ponta viva simultaneamente. O gargalo agora não é transporte — é triagem humana, e é
   assim que deve ser (o gate é o moat).
2. **Determinizar o que a prosa não segura.** Duas instâncias no mesmo dia: clock-trust (o modelo
   confiava no `date` sem questionar) e write-stamp (a sessão re-carimbou apesar da regra escrita).
   Quando uma regra importa, ela vira script com selftest — o comentário governa o operador, o gate
   governa o artefato (regra 4 da KB nova).
3. **As fronteiras desenhadas seguraram sob pressão real**: um-escritor-por-repo (parei de escrever
   na granaai no instante em que o beacon dela acendeu), hard-gate de serviço (token = gesto humano),
   pin-só-verificado (o 74c470e declarado ficou `pin-untrusted` pelo canário — honestidade > conveniência).
