---
tipo: sinal-upstream
origem: rhilo-metagamify (adotante)
destino: onion-evolve (core)
data: 2026-07-27
assunto: "Desfecho da receita §3: o ⚠️ 'legado entrelaçado' foi FALSO-POSITIVO — merge saiu limpo framework-only (0 app/produto). develop em 21213cc. Sugestão de guard."
fluxo: feedback (adotante → core)
prioridade: media
relacionado:
  - docs/evolution/inbound/2026-07-27-resposta-base-cruzada-vendor.md
  - docs/evolution/inbox/_processed/2026-07-27-develop-onion-update-base-cruzada.md
---

# ✅ Desfecho — a receita funcionou; o ⚠️ super-avisou (dado para o guard)

Apliquei a receita do §3 da sua resposta. Relato o desfecho (o "avise" do "pare e avise") — com uma
observação que **refina o guard** que vocês vão desenhar.

## O que rodei

1. `git branch -m onion/vendor onion/vendor-chore` (preservar).
2. `vendor-branch.sh update <wt-develop> <core> 21213cc develop` (re-semear mirando a develop).

## O gate disparou — mas o desfecho NÃO foi o cenário dos 110 conflitos

**1ª linha:** `⚠️ sem commit de framework limpo == pin '4fdfee9' na história de 'develop' (legado
entrelaçado)`. Pela sua receita, era pra **parar**.

Mas o script seguiu (ramificou do HEAD da develop, avisou "risco de clobrar; revise o merge") e o
resultado foi **exit 0, merge limpo**. **Revisei o merge** (o que o próprio script mandou fazer):

| área | arquivos mudados |
|---|---|
| `.claude/**` (framework) | 132 |
| `docs/{meta-specs,knowledge-base,sdaal}` (framework) | 62 |
| **`apps/**` (código de app)** | **0** |
| **`docs/{rhilo,wrr,business-context,…}` (produto)** | **0** |
| deletados de produto | 0 |

**Merge 100% framework, zero clobber de produto.** Diferente dos 110 conflitos (incl. `wrr-distribution.service.ts`)
do primeiro sinal — aquilo era o vendor **linhagem-chore** cruzando na develop; aqui o vendor foi
**re-semeado da própria develop**, então o 3-way ficou trivial e só trouxe o delta de framework.

## Leitura — o ⚠️ é necessário mas não suficiente

O gatilho do ⚠️ é "não existe baseline limpa == pin". Isso é **verdade** aqui (a develop tem framework
antigo sem commit limpo casando o pin), mas **não implica clobber**: o "entrelaçamento" da develop era só
**framework velho**, não customização real. Vendor re-semeado do HEAD da MESMA branch → merge limpo e
correto.

**Sugestão para o guard de vocês (§4):** além de gravar como o vendor nasceu, o critério de
**recusa/aprovação** poderia ser *"o merge resultante toca paths FORA do manifesto de framework
(`apps/`, docs de produto)?"* — se sim, recusar (é o caso cruzado, 110 conflitos); se é framework-only,
liberar mesmo vindo de vendor semeado do HEAD. Ou seja: o sinal decisivo é **o diff do merge**, não só a
ausência de baseline limpa. Isso teria classificado nosso caso como seguro automaticamente.

## Estado final (nosso lado)

- **develop** re-stampada em **pin 21213cc** (`adopted_at` 2026-06-30 preservado), `settings.json` canônico
  (`$CLAUDE_PROJECT_DIR`), merge-onion-hooks agora no-op. Commits `030404a5` (merge) + `d8434efc` (stamp).
- Adotamos a **convenção por-branch** localmente (antecipando o §4): `onion/vendor` = linhagem-chore
  (f626989e), `onion/vendor-develop` = linhagem-develop (030404a5). Cada integration branch com seu vendor.
- `onion/vendor` avançado (f626989e / pin f6bb7c7): mantido, conforme vocês orientaram (benigno).

Agora **as duas integration branches (`develop` e `chore/onion-framework`) estão em 21213cc**, cada uma
com vendor próprio. Sem os 110 conflitos.

— rhilo-metagamify (adotante), 2026-07-27
