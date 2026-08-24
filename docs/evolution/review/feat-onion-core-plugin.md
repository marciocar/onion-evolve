---
title: "Revisao — plugin-nucleo onion + guarda de moat + materialize (Fase 1+2)"
date: 2026-08-24
branch: feat/onion-core-plugin
reviewer: "branch-code-reviewer (passada adversarial focada em BYPASS da guarda de moat) — veredito inicial 🔴, achados C1/C2 verificados e corrigidos"
reviewed_diff_sha256: 6af839e07f8f60d7835b06b8ab1cdd1da8582a87323a30c29234e259147945cc
findings_total: 5
findings_real: 5
verdict: APROVADO
tokens: 75000
duration_min: 9
---

# Residuo de revisao — REGRA 56 (publicacao de plugin: fronteira de MOAT irreversivel)

Nasce o plugin-nucleo `onion` (a capacidade operacional do Onion como plugin instalavel) + o helper
`materialize-marketplace-repo.sh` (o project-door: source → repo publico) + a guarda de MOAT (REGRA 61)
que impede publicar meta-fabrica/grafo-privado. Publicar o moat e IRREVERSIVEL — por isso a passada
adversarial foi focada em BYPASS.

## A passada adversarial pegou 2 vazamentos REAIS (veredito inicial 🔴) — verificados e corrigidos

O revisor mediu o que o commit FAZIA (nao o header), e achou que a 1a guarda VAZAVA:

- **C1 (regex fraco) — CORRIGIDO.** O regex v1 era cego a federacao (federation-*/co-deliver/co-announce),
  auto-evolucao (evolve), absorb-skill (fabrica) e a grafos FORA de docs/onion/graph/ — incl. o life-KG
  privado do maestro (marcio.kg.yaml). VERIFIQUEI ao vivo (todos passavam o regex v1). Cura: denylist por
  basename de meta-fabrica/federacao-downstream + `\.kg\.yaml` em QUALQUER lugar.
- **C2 (bypass estrutural por DIRETORIO-PAI) — CORRIGIDO.** Eu nao vira: o assembler EXPANDE dirs (cp -R),
  entao declarar `COMMANDS=(".claude/commands/meta")` arrasta a fabrica inteira SEM casar a string.
  VERIFIQUEI (commands/meta e utils passam o regex, mas contem a fabrica). Nenhum regex fecha isso. Cura:
  a guarda agora resolve cada entrada aos ARQUIVOS que o assembler copiaria (find nos dirs) e checa a
  EXPANSAO, nao a string literal.
- **R1 (declarado≠verificado) — FECHADO.** O revisor notou que a 2a guarda (materialize) e o regex forte
  estavam na WORKING TREE, nao no commit — o KG afirmava o mecanismo que o commit nao tinha. Agora tudo
  commitado (a Fase 2 traz o helper + a guarda por expansao).
- **R2 (absorb-skill/upstream) — ENDERECADO.** absorb-skill.md entrou na denylist; co-evolve/co-relay
  (UPSTREAM — sinal do adotante ao core) permanecem PERMITIDOS por desenho (documentado no comentario).
- **R3 (selftest fraco) — ENDERECADO.** run_moat_boundary_selftests agora tem casos RED reais: (a) C1
  abrangente (evolve/federacao/absorb/life-KG), (b) C2 dir-pai, (c) GREEN upstream/produto. 3/3.

## Provas por comportamento
- run_moat_boundary_selftests 3/3 (C1 + C2 + GREEN) — no pre-commit do CI.
- run_materialize_repo_selftests 2/2 (materializa 8 plugins self-contained, 0 vazamento, sem push).
- Prova por ARQUIVO: plugins/onion tem 0 fonte de meta-fabrica, 0 grafo. Repo materializado idem.
- lint 0 HARD, kg-radar exit 0.

**Veredito: APROVADO** — os 2 achados bloqueantes (C1 regex, C2 dir-pai) foram VERIFICADOS ao vivo e
corrigidos por construcao (guarda por expansao), o conserto foi COMMITADO (fecha o declarado≠verificado),
e o selftest guarda os RED contra regressao. A fronteira L1-distribui/L2-L3-moat e agora MECANISMO. O
canal de instalacao (plugin) nao tem linkage de adopt (grafo o registra). Este e um caso-modelo de
behavior-over-declaration: sem a passada adversarial, teria-se mergeado uma guarda que vazava o life-KG.
