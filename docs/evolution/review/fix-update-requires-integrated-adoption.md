---
title: "Revisão — o achado veio do DOGFOOD do --update, não de revisor: a base do 3-way nasce entrelaçada em todo greenfield"
date: 2026-09-05
branch: fix/update-requires-integrated-adoption
reviewer: "DOGFOOD como passada adversarial — rodar `/meta:adopt --update` de verdade num adotante greenfield recém-adotado, e medir o estado que sobrou. Sem refutador nesta rodada, e a razão está declarada nos limites: o achado é de COMPORTAMENTO (rc=11 do helper) e a mudança é 1 bloco de doc + 1 nó; a calibração desta sessão diz que a 1ª passada sobre o artefato completo rende o produto, e aqui a execução JÁ foi essa passada."
reviewed_diff_sha256: 0715e4a5f183109b40ede3132a93a6697312e8f76120e64b007fcb355558f8f7
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 0
duration_min: 14
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O achado (1, de COMPORTAMENTO)

O `vendor-branch update` recusa com **rc=11 BASE CRUZADA** em todo adotante greenfield cuja adoção
não esteja integrada — e a recusa está **CERTA**. Causa medida: o `durable-commit.sh` staja
`CLAUDE.md`, `docs/{business,technical,compliance}-context`, `.githooks`, `.prettierignore`,
`.gitattributes` e `settings.json` (**48 arquivos** no caso). É adoção legítima, mas não é *framework*
para o vendor — então `onion/vendor` semeada de `onion/adopt` (o que a Fase 5 manda) nasce
**entrelaçada por construção**, e o merge arrastaria produto para o 3-way.

**O que o comando NÃO dizia:** que o `--update` pressupõe a adoção integrada. Medido antes da cura:
`grep` por precondição no `adopt.md` = **0 hits**.

## Duas observações que o dogfood entrega e a leitura não entregaria

1. **O helper degradou no lugar certo:** avançou `onion/vendor` ao pin novo e recusou **só** o merge;
   a branch de integração ficou **INTOCADA**. Isso só se sabe olhando o estado depois da recusa.
2. **O conserto que o próprio helper sugere está ERRADO neste estado.** Ele manda renomear o vendor e
   re-semear da integração — que aqui daria uma base **sem o framework**, outro estado errado. Seguir a
   sugestão da ferramenta às cegas teria produzido um segundo defeito; a mensagem do helper é genérica
   e não distingue "vendor de outra integration branch" de "adoção ainda não integrada".

## Limites DECLARADOS

- **Sem refutador nesta rodada, por decisão declarada.** O teto que este eixo declarou no PR #807 diz
  que achado de força-de-guarda vira nó com gatilho, não nova rodada; e a calibração do PR #808 mediu
  que a 1ª passada sobre o artefato completo é a que rende produto. Aqui a **execução foi** essa
  passada, e a mudança é 1 bloco de documentação + 1 nó. Gastar 2 refutadores nisso seria trocar
  entrega por polimento — o anti-padrão que os dois PRs anteriores nomearam.
- **A cura é de DOCUMENTAÇÃO, não de mecanismo** — e isso é uma escolha, não um esquecimento. As duas
  saídas de mecanismo estão desenhadas no nó e **nenhuma foi decidida**: (a) o helper detectar
  especificamente "adoção não-integrada" e instruir o certo, ou (b) a Fase 5 semear o vendor de um
  snapshot só-framework. Decidir isso muda o comportamento de todo adotante — é chamada do maestro.
- **O `--update` do adotante segue PENDENTE.** O que o desbloqueia é o PR `onion/adopt` → `develop`
  **no repo dele**, que é integração e portanto decisão do dono. **Gatilho:** quando ele integrar,
  re-rodar `--update` e conferir que o 3-way fecha limpo.
- **`tokens: 0`** — sem run de workflow instrumentado. Declarado, não estimado.

## Fora de escopo (com gatilho nomeado)
- `Q_UPDATE_EXIGE_ADOCAO_INTEGRADA` — as duas saídas de mecanismo acima.
- O PR de integração no repo do adotante (dele).
