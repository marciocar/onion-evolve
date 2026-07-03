---
type: co-evolution-signal
direction: upstream   # sinal → core
from: instância rhilo-metagamify (dogfood ao vivo)
to: Onion core / Mestre
date: 2026-07-03
subject: Débito de processo — duas linhagens de branch divergentes (develop × rhilo/main) sem reconciliação
status: proposta-para-avaliação
maturity: diagnosticado ao vivo (git + AWS ECS); custou horas de confusão DEV↔PROD nesta sessão
---

# Sinal ao Mestre — o repo tem duas linhagens que não reconciliam

> Descoberto ao preparar o PR da cura da dose: **o motor que está em produção nunca foi para a `develop`**.
> É um débito de processo que gera o erro recorrente "ler a branch ≠ ler produção" — o mesmo que a
> governança DEV↔PROD (sinal de 2026-07-02) tenta prevenir. Proponho tornar isso um **padrão do core**.

## O diagnóstico (dado)

- Divergência desde **2026-06-15** (merge-base `c5036dfa`). Hoje: **`develop` +68 commits · `rhilo/main` +12**,
  **sem nenhum merge de reconciliação** entre as duas desde então.
- **`rhilo/main` = produção RHILO/WRR.** O motor (Modo Equilíbrio `3c4d23f3`, Fase 2/calls-cap `695e7c65`,
  level=null `39cbdd46`) entrou por PRs **direto no `rhilo/main`** (#45, #47, #52, #73, #74, #75). O HEAD
  (`05f96a05`) é **exatamente a imagem deployada** (confirmado via `aws ecs describe-task-definition`).
- **`develop`** acumulou outra coisa: ~32 commits Onion/co-evolution + ~13 de **pesquisa WRR** (sims Fase B
  on-policy, ADR-018 dose) — que **repensam** a dose que o `rhilo/main` já implementou. Não é superset: cada
  lado tem o que o outro não tem.
- **A doc mente:** o `CLAUDE.md` dizia "PRs miram `develop`". Mas o WRR sempre foi pro `rhilo/main`. Cherry-pick
  da cura na `develop` **quebra** (falta o motor); no `rhilo/main` aplica limpo (62/62 testes verdes).

## O padrão que proponho ao core (SDAAL)

1. **Declarar a linhagem de cada trilho, explicitamente, no `CLAUDE.md`** (já corrigi nesta instância):
   uma tabela `branch → papel → é-produção?` + regra de PR por trilho. Some a ambiguidade "develop=prod".
2. **Regra dura (casada com a governança DEV↔PROD):** *nunca* inferir produção de uma branch — só de
   `commit deployado (ECS/registry) + flags vivas + env`. A branch de trabalho pode estar meses atrás.
3. **Detector de divergência como gate/comando** (`/meta:branch-health`?): reporta merge-base, ahead/behind
   e "quais branches são deployadas onde", pra o agente saber a base certa de um PR **antes** de cherry-pickar.
4. **Política de sync obrigatória para linhagens de longa duração:** ou reconciliam periodicamente, ou o
   modelo multi-linhagem é documentado (qual é upstream de qual, o que sincroniza). Sem política → drift +
   reconciliação dolorosa no futuro (aqui: código shipado vs pesquisa que o contradiz).

## Evidência / impacto

Esta divergência **custou horas** nesta sessão: conclusões erradas por ler branch de trabalho (267 commits
atrás no rhilo-app; motor ausente na develop). A cura da dose está pronta numa branch `fix/wrr-dose-honest-measure`
baseada em **`rhilo/main`** (não develop) — porque é lá que o motor vive. Correção do `CLAUDE.md` já aplicada
nesta instância (tabela de linhagens + regra de PR por trilho).

## Pedido

Avaliar: (a) padronizar no core a **tabela de linhagens + regra de PR por trilho** no `CLAUDE.md` (template);
(b) um comando `/meta:branch-health`; (c) reforçar a regra "produção = deployado, nunca a branch" na spec de
governança DEV↔PROD. E, pra este repo: decidir **reconciliar `develop`↔`rhilo/main`** ou oficializar o modelo
de duas linhagens com política de sync.

*Rode `/meta:co-evolve` para gerenciar este sinal.*
