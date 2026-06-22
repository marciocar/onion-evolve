---
title: 'Sinal de campo — prettier do adotante quebra o SSOT do inventário (causa raiz + fix)'
date: 2026-06-22
from: rhilo-metagamify (adotante standalone)
to: onion-evolve (core / "mestre")
re: update vendorizado `.claude/` → source_commit 06f7232 + causa raiz do drift de prettier (3ª reincidência)
type: federation-doc-bridge (feedback de adoção — não-solicitado)
status: aplicado e mergeado neste adotante (PR #62, develop, merge commit 18479ce)
---

# Sinal de campo ao core — update 06f7232 + causa raiz do drift de prettier (2026-06-22)

> Doc-bridge derivado→core. Confirmação de adoção + **um achado acionável que fecha um sinal reincidente**.
> Modo `standalone`: o core consome este doc quando rodar a co-evolução do seu lado (humano-no-loop transporta).

## O que foi adotado

- **06f7232fe861** aplicado via `/meta:adopt --update`, mergeado em `develop` via **PR #62**
  (2026-06-22, merge commit `18479ce`). `.onion-version` → `source_commit: 06f7232fe861`.
- **Superfície do delta (29 arquivos):** comandos novos `catch-up`, `meta/co-announce`; utils C4
  (`.claude/utils/c4-*.md`); lint reforçado (`lint-selftest.sh`, regras **r16** count-drift + **r18**
  `.claude/docs` proibido, fixtures novas); KBs `decision-snapshot-retention`, `onion-dogfooding-doctrine`;
  ajustes em `@onion`, `meta:all-tools`/`inventory`/`co-evolve`, `architecture.md`.

## 🔴 Achado principal (acionável) — o drift de prettier NÃO é só cosmético: quebra o lint HARD

O sinal de drift de prettier já foi reportado **2×** (2026-06-17 e 2026-06-19, item 3 do sinal `a0fdf35`)
como "ruído cosmético". **Este update revelou que ele escala para fail de CI:**

1. **Causa raiz identificada.** O `.prettierignore` deste adotante já declara a intenção de preservar a
   formatação upstream dos arquivos vendorizados — mas listava só `.claude/`, `docs/meta-specs/`,
   `docs/sdaal/`. **Faltavam `docs/knowledge-base/` e `docs/onion/inventory.md`** — ambos copiados pelo
   manifesto do `/meta:adopt`. O `lint-staged` reformatava esses paths a cada commit.
2. **Consequência grave (nova):** `docs/onion/inventory.md` é **SSOT gerado por máquina** (`inventory.sh
--markdown`) e o lint o compara **byte-a-byte** (`check_inventory_sync`). O prettier reformatou a tabela
   → o match quebrou → **violação HARD** ("inventário desatualizado vs filesystem"). Ou seja: rodar
   `/meta:inventory` corretamente e depois **commitar** reintroduz a violação que ele acabou de corrigir,
   por causa do hook. Laço vicioso silencioso.
3. **Fix aplicado neste adotante:** adicionados `docs/knowledge-base/` + `docs/onion/inventory.md` ao
   `.prettierignore`. Eliminou de uma vez **o churn dos 65 KBs** E o fail HARD do SSOT.

## Recomendação ao core (candidato a evoluir o /meta:adopt)

O `/meta:adopt` **copia** `docs/knowledge-base/`, `docs/meta-specs/`, `docs/sdaal/` e gera o SSOT
`docs/onion/inventory.md` — mas **não provisiona** a proteção de formatação correspondente. Sugestão:

- Na **Fase 3 (install)** e no **`--update`**, o Procedimento de Configuração pós-cópia deveria
  **provisionar/mesclar (never-clobber) um `.prettierignore`** cobrindo TODOS os paths que o manifesto
  escreve no alvo, incluindo explicitamente o SSOT `docs/onion/inventory.md`.
- Generaliza para qualquer adotante com formatador (prettier/dprint/biome) + hook de pre-commit — hoje
  cada adotante redescobre o problema (3× neste, e o de 2026-06-17 já apontava o sintoma).
- É o mesmo princípio dos hooks: o comando não pode assumir que o alvo "sabe" preservar o vendor; tem de
  **provisionar a proteção explicitamente**.

## Reincidência confirmada — anúncio core→derivado segue sem operar

Como em `a0fdf35`: o **06f7232 chegou cego**, via `/meta:adopt --update` **manual e deliberado**. O core
**não deixou anúncio no inbound** classificando o delta/bump. Reforça (3ª evidência) que o **inbound
core→derivado é a lacuna real** — o adotante continua dependente do humano puxar o update. (Nota: o delta
**inclui** o novo `/meta:co-announce`, que é justamente o lado producer desse anúncio — mas ele não foi
**exercido** para entregar este próprio delta. O recurso existe; a operação ainda não.)

## NÃO pedido (deliberado)

- Nenhuma ação obrigatória ao core. Feedback voluntário de um adotante real.
- O `.prettierignore` corrigido é **local do adotante** (o core não tem prettier) — o que se pede ao core
  é só **provisionar a proteção** no fluxo de adoção, não adotar prettier.

## Premissa que o mestre PRECISA internalizar — o adotante é cego (inalterada)

Vale o mesmo bloco do sinal `a0fdf35`: sem comunicação viva, sem o repo do core no escopo, o adotante só
"vê" o que for commitado neste `inbox/` E transportado por humano. **Silêncio do core = invisível.** Toda
mudança que o adotante deva saber — inclusive **a resposta a este sinal** — precisa ser anúncio explícito
no `inbound/`.
