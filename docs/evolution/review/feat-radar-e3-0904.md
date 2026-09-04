---
title: "Revisão — radar E3 rodada 3: 2.1.259 → 2.1.260 (0 erros de citação; 1 ação local no forge)"
date: 2026-09-04
branch: feat/radar-e3-0904
reviewer: "juiz adversarial opus/high (mandato REFUTAR, re-executou as medições): 3 aprovados, 9 emendados, 1 reprovado, 8 omissões — tudo incorporado ao grafo; rascunho pré-juiz preservado em data/"
reviewed_diff_sha256: 4acdccdf9339490c6eca5ea37a27e77432c1080a2d73de081bbc9a973d28da4d
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 1400000
duration_min: 25
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

Rodada 3 do E3, gatilho REGRA 65 (Radar de mundo com baseline DATADA por eixo): processo 2.1.260 vs rodada 2.1.259. Fonte verbatim em
`data/`; grafo com 15 nós, `review_after` (REGRA 67), tier 9 vendor-on-self (REGRA 68); baseline E3 selada em 2.1.260 no mesmo commit.

## Achados

1. **A cura de ontem funcionou**: `l.N` só por `grep -n` no arquivo salvo ⇒ 13/13 citações corretas na primeira rodada seguinte
   (ontem: 6/11 erradas). As emendas do juiz foram de medição e inferência, não de leitura.
2. **Ação local que a plataforma expôs** (F12): o `parseRepoIdentity` do forge SDAAL descarta subgrupos aninhados do GitLab — o mesmo
   defeito corrigido em 2.1.260. Aberto como `I_FORGE_PARSE_GITLAB_SUBGRUPOS` (fios-abertos), com a cura e o caso de bancada nomeados.
3. **Superação PARCIAL registrada sem flip** (F1): o revert de l.42 supera só a metade "deny rule é opção" do E_F5 da rodada 2; a metade do
   allow `Bash(grep * .env)` segue viva — o nó antigo ganha ressalva em comentário (append-only), status fica `confirmed`.
4. **Nada de 2.1.260 foi OBSERVADO** — declarado nas lacunas (ladder=restored nunca visto; `/reload-plugins` com hooks; cota do Fable).
   Omissões que importam: `Skill(name)` deny sem a forma aninhada (l.16), `claudeMd` gerenciado sem diálogo (l.55), org pode desligar
   marketplaces de usuário (l.8 — toca a Fase 5).
