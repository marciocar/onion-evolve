---
title: 'Resíduo — a licença que não viajava, e a cura ingênua que era pior que a doença'
date: 2026-09-15
branch: fix/licenca-viaja-never-clobber
reviewed_diff_sha256: bd3ed328c4e193d597cad0b08c0b81ac92a28f3b4a5217b7b9b8c0a07627a059
findings_total: 8
findings_real: 8
findings_fixed: 7
tokens: 188367
duration_min: 16
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Fecha o aberto de maior atenção do core (12.0). O que domina este resíduo não é a cura — é que a
  PREMISSA DO PRÓPRIO NÓ caiu na medição ("quinta cópia da mesma lista" era diagnóstico por semelhança
  de forma), e que a catraca escrita ontem me pegou hoje sozinha, sem eu lembrar dela. Passada
  adversarial disparada EM PARALELO ao CI, pelo passo 6 do /engineer:pr.
---

# A licença não viajava — e a cura óbvia era pior que a doença

## O defeito

O adotante recebia **~104 arquivos de método sem uma linha de licença** e os commitava num repo que
carrega o `LICENSE` **dele**. Quatro raízes do manifesto (`.claude/rules`, `docs/meta-specs`,
`docs/knowledge-base`, `docs/sdaal`) são exatamente o material que o `LICENSE-DOCS` declara
CC BY-NC — e a §3.a exige o aviso de quem redistribui, que é a nossa máquina de transporte.

## Achado 1 — a cura ingênua era PIOR que a doença

Pôr `LICENSE` no manifesto de transporte é o movimento óbvio. Foi **tentado e revertido em
2026-09-14**, porque o passo (d) do adopt é um `cp -R` **incondicional**: a licença cairia no
`$TMP` e **sobrescreveria o LICENSE do alvo** — um aviso proprietário de cliente virando MIT em
nome do autor do core. **Relicenciamento silencioso produzido pela cura CONTRA relicenciamento
silencioso.**

A saída é o molde do `.env.example`: **fora** do manifesto, never-clobber por-arquivo, sufixo
`.onion` quando o alvo já tem o seu. O merge é decisão do maestro **do alvo**.

## Achado 2 — a premissa do próprio nó caiu na medição

O nó dizia que `ONION_PATHS` (durable-commit) era a **"quinta cópia da mesma lista"**. **Errado.**

```
SSOT (--emit-scrub-roots) : 8 raízes .claude/* + 3 docs/*
ONION_PATHS               : .claude INTEIRO + docs/onion + 3 contextos + CLAUDE.md + .githooks…
```

Ele é **superset com outro propósito**: a SSOT diz o que **COPIA**, o `ONION_PATHS` diz o que se
**COMMITA no alvo** — e inclui os **artefatos GERADOS na adoção**, que não viajam do core.
Unificá-los quebraria a durabilidade dos gerados. A cura certa era **acrescentar**.

Foi **diagnóstico por semelhança de forma**: duas listas de caminhos parecem a mesma coisa, e só a
comparação lado a lado desfez. Classe irmã da que dominou a sessão de ontem (guarda de lista falha
pelo vocabulário) — aqui o erro foi meu, não da guarda.

## Achado 3 — a catraca de ontem me pegou hoje, sozinha

O caso `(b)` que escrevi trazia `git ls-tree | grep -q .` — a **mesma forma** que ontem produziu
HARD espúrio acusando uma regra **viva** de morta. A guarda alargada para asserir a **FORMA** (não a
lista de produtores) acusou **42 > 41** no pre-commit.

**Sem eu lembrar da regra. Sem o maestro cobrar.** É o que separa cura de conselho — e a prova de que
valeu trocar lista por forma ontem, porque `git` **não estava** na lista antiga.

## A cura, em duas pernas que só valem juntas

1. **Never-clobber no adopt**, passo (e) — fundido com o `.env.example` porque os três são o mesmo
   movimento. A REGRA 5 (Limites de linhas) forçou isso: o arquivo estava a 2 linhas do teto, e em vez
   de crescer com um passo (f) duplicado, **deduplicou**.
2. **Staging no `durable-commit`** (4 grafias). Sem ele o arquivo chega **untracked** — some num
   `git clean`, e no `--update` o worktree é removido `--force`.

## Dogfood, por execução

| Alvo | Resultado |
|---|---|
| virgem | recebe `LICENSE` + `LICENSE-DOCS` |
| com LICENSE proprietário | o dele **intacto**, o nosso vira `LICENSE.onion` |

Família `license_travels`, 5 casos, com **mutante**: a cópia cega **clobra**, provando que `(b)`
mede algo.

## A passada adversarial REPROVOU — e o desenho mudou por causa dela

Disparada em paralelo ao CI (passo 6), lente do **adotante**. Devolveu **5 HARD**, e três mudaram o
desenho, não só o código. Os achados abaixo foram **re-medidos por mim** antes de agir.

### HARD-1 — a cura não alcançava NENHUM adotante existente

`grep -in 'licenç'` no `adopt.md` devolvia **uma** ocorrência: o passo (e), que vive no *Procedimento
de cópia segura* — e **o `--update` não invoca esse procedimento**. Os 9 adotantes que já existem,
que eram a **justificativa inteira do commit**, ficavam de fora.

**Cura:** a emissão virou `emit-licenses.sh`, chamado da *Configuração pós-cópia* — o único bloco que
a **Fase 3 E o `--update`** invocam. Um implementador, dois chamadores: a segunda cópia não pode
driftar porque não existe.

### HARD-2 — o que chegava declarava titularidade sobre o repo do cliente

O adotante virgem recebia `LICENSE` com `MIT © Marcio Carvalho` **na raiz**. Um `LICENSE` na raiz é,
por convenção universal, o instrumento que rege **o repositório inteiro** — inclusive o código que o
cliente ainda vai escrever. E o `LICENSE-DOCS` abre com *"**Este repositório** tem DUAS licenças"*,
que lido no repo dele afirma o oposto do pretendido.

É a **imagem espelhada** da catástrofe revertida em 2026-09-14: lá o cliente perdia o dele por
sobrescrita; aqui ele nunca teve um, e o que ganha reivindica o trabalho dele.

**Selado pelo maestro:** chega como **`LICENSE-ONION`** e `LICENSE-ONION-DOCS`. O nome próprio
resolve os dois lados de uma vez — não reivindica nada e **não colide**, então **dispensa o
never-clobber inteiro**. Some junto o sidecar `.onion` que a 2ª adoção sobrescrevia em silêncio
(SOFT-1 do refutador). O desenho ficou **mais simples e mais seguro**.

### HARD-3 e HARD-4 — a bancada era FAIL-OPEN para o risco primário

O refutador trocou o never-clobber por **cópia cega** — exatamente o relicenciamento que o PR existe
para impedir — e a família deu **5/5 verde**. Duas causas medidas:

- **`(b)` era tautologia:** reimplementava o laço **dentro do teste**, em vez de exercer o `adopt.md`.
- **`(c)` era quase-verdade:** exigia `grep -q '\.onion'`, e **9 das 14** linhas que casam são
  `.onion-version`. O predicado sobrevivia à remoção do ramo inteiro.
- **`(d)` casava substring:** `grep -F LICENSE` casa dentro de `LICENSE.onion`, então remover a
  grafia nua passava verde.

**Reescrita:** o mutante agora ataca o **emissor real** (`sed` sobre o arquivo), `(c)` assere o
**chamado no bloco compartilhado**, e `(d)` usa **token exato** (`grep -qxF`) sobre o array.

### Correção de baseline que o refutador trouxe

O nó `A_ADOTANTE_GREENFIELD_NASCE_COM_HARD` afirma 4 HARD. **Medido: 0 HARD** — seguindo a Fase 3
como escrita, o adotante nasce verde. **O nó merece re-medição antes de seguir aberto**, e isso é fio
próprio, não deste PR.

### O que fica ABERTO, declarado

- **SOFT-3 do refutador:** o comentário-SSOT do `vendor-manifest.sh` ainda anuncia a ausência de
  licença como defeito aberto e repete a premissa da "quinta cópia" que o próprio nó já declara
  refutada. **Curado neste PR** — mas registro que o achado veio de fora.
- **`.env.example` é escrito e não é stajado** (HARD-5): pré-existente, e a fusão o tornou visível.
  Some num `git clean`. Fio próprio, com gatilho: a próxima adoção que perder o arquivo.

## Gate

```
bancada completa : 1237 pass · 0 fail · 0 skip   (1232 + 5 da família nova)
lint (LC_ALL=C)  : 0 HARD
radar / realign  : exit 0 / ALINHADO
o nó SAI do backlog : prova de fechamento, não declaração
commit           : SEM --no-verify
```
