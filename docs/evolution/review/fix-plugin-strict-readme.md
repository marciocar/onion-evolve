---
title: "Revisão — o README de categoria não é comando; e o gerador é insumo do sinal de mudança"
date: 2026-09-07
branch: fix/plugin-strict-readme
reviewer: "Elenxo adversarial com mandato de REFUTAR (worker `elenxo-pr01`, veredito APROVADO-COM-RESSALVA), com re-medição independente do condutor sobre a alegação de maior impacto (versão e tree_sha parados). Gate no SHA final: lint 0 HARD rc=0 · bancada 1104/0 rc=0 · `claude plugin validate --strict` rc=0 nos 5"
reviewed_diff_sha256: cbb81c6409c73b5621632294bea6932617307bece7ce02b858a30d48a31ead23
findings_total: 6
findings_real: 5
verdict: APROVADO-COM-RESSALVA
tokens: 700000
duration_min: 40
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados

1. **O achado que quase deixou o PR inútil — e que eu re-medi antes de aceitar.** `tree_sha` e a
   versão derivada eram calculados **só sobre as fontes do manifesto**; o assembler, o
   `plugin-readme.sh` e a `public-face.sh` não estavam em conjunto nenhum. Medido: a cura mudou o
   conteúdo publicado de 3 plugins e **os dois sinais ficaram idênticos** (`0.1.22`, `0.1.92`,
   `0.1.53`; tree_sha `56e2fddc`, `2ed62794`, `7773f2f9`). `claude plugin update` responderia
   *"already at the latest version"* e o instalador ficaria com o artefato que reprova — **o mesmo
   modo de falha que a versão derivada nasceu para curar**, por um flanco que ela não cobria.
   Curado: os geradores entram nas duas listas, e os cinco plugins passam a andar.
2. **Assimetria com a camada de geração.** `plugin-readme.sh:56` e `:61` já decidiam
   "README em commands/ não é comando", com `base.lower()=="readme"`. Meu skip era `README.md`
   exato — um `readme.md` minúsculo passaria pelo assembler e seria ignorado pelo gerador. Duas
   metades do mesmo pipeline concordando em **formas diferentes** é o defeito que volta calado.
   Agora casa pelo radical, case-insensitive, igual à prior art.
3. **O ramo de arquivo avulso não tinha o skip** — e é caminho vivo (`onion-product.manifest.sh`
   faz cherry-pick de `.claude/commands/docs/help.md` por ali). Assimetria entre ramos é como se
   inverte um argumento sem ninguém ver. Agora vale nos dois, por um predicado só.
4. **A tese foi REFUTADA a favor: o que saía era net-negativo.** O README de `product` embarcava
   20+ invocações `/product/task` — namespace que **não existe no plugin** (lá é
   `/onion-product:task`) e que o `plugin-namespace-check.sh` não reescreve. O de `engineering`
   documentava **só `engineer/`**, enquanto o plugin empacota engineer+test+validate+git. Não era
   documentação perdida; era documentação errada saindo.
5. **Conteúdo narrativo sem substituto (fica em aberto).** Os "Cenários de uso" e a política de
   auto-update do task-manager (`.claude/commands/product/README.md` l.79-178) não têm equivalente
   no README gerado. Só não vira objeção porque todo comando citado ali estava errado para o
   plugin — mas o instalador de `onion-product` segue sem esse how-to em lugar nenhum.
6. **Não se sustentou como formulado:** o revisor listou "sem catraca" como risco do PR. É
   verdadeiro, mas não é deste PR — pôr `claude plugin validate` no gate é o
   `D_PR03_GATE_VALIDATE_NA_CASA`, que o plano já separou. O que **cabia** aqui eu fiz: 3 casos de
   bancada (o skip; o predicado case-insensitive sem superreação; o gerador como insumo das duas
   listas).

## Fora de escopo, com nó e gatilho

- `Q_TREE_SHA_ENDERECA_ENTRADA_NAO_SAIDA` — o campo se chama *content-addressed* mas endereça a
  ENTRADA. A cura de hoje fecha o flanco conhecido e deixa os desconhecidos abertos; endereçar a
  SAÍDA fecharia a classe inteira, ao custo de mudar a semântica da REGRA 19 (SSOT anti-drift).
  Redesenho de contrato, não correção de bug — decisão do maestro.
- `Q_MERGE_VERIFICADO_DA_FALSO_NEGATIVO` — `ops/pr-merge-verified.sh` declarou "NÃO declaro merge"
  para o merge do #814, que **tinha acontecido**. Ele morre no rc do `gh` e nunca chega ao passo 4,
  que é a prova pelo estado. Achado desta sessão, outro artefato, outro escopo.

## Limitação declarada do que eu testei

O caso de bancada do "gerador é insumo" é **estrutural**: prova que `_GEN` alimenta as duas listas,
não que o hash muda quando o gerador muda — isso exigiria mutar o gerador vivo. A prova behavioral
existe, mas é a medição manual do achado 1, registrada no grafo, não um caso que roda sozinho.
