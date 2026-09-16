---
title: 'Resíduo — a doutrina não listava um repo público, e por isso não o protegia'
date: 2026-09-16
branch: docs/codex-is-a-live-line
reviewed_diff_sha256: 95756dd8cc6f0944301ef3dd19ef0825def74b4de013324f0cadb16631a71919
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Mudança de DOUTRINA selada pelo maestro, não achado de revisão — por isso sem refutador: não há
  o que refutar numa decisão dele. Os três "achados" são fatos que a decisão obrigou a medir, e
  dois deles são omissões antigas que ninguém tinha visto porque ninguém tinha olhado a lista.
---

# Doutrina que não lista um repo não o protege

## A decisão

O maestro selou em 2026-09-16: **`onion-codex` é linha viva**, não congelado.

## Os três fatos que a decisão obrigou a medir

### 1. O repo nunca esteve na lista

O `CLAUDE.md` declarava a família como `onion`, `onion-cursor`, `onion-antigravity`,
`onion-copilot`, `onion-architect`, `onion-mini`, `onion-standalone`. O `onion-codex` **não
aparecia** — repo público, ativo, com 49 subagentes e 82 skills.

E a omissão não é cosmética. A REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente)
deriva os termos do `members.yaml` **e ignora nomes começados em `onion-`**. Um repo público com
esse prefixo, fora do registro, fica **sem varredura nenhuma** — é a migalha `vendor-scrub-blind-spot`
acontecendo em silêncio. Ele também **não está** no `members.yaml`; registrar segue pendente e é
ato de segurança, não burocracia.

### 2. "Linha viva" parecia revogar uma decisão de 2026-05-18, e não revoga

O `CLAUDE.md` declara, três linhas abaixo, que o multi-IDE foi *"formalmente abandonado em
2026-05-18"*. Deixar as duas afirmações lado a lado sem explicação seria plantar uma contradição
na constituição.

A diferença é de **objeto**: aquela decisão abandonou o **agnosticismo como direção de produto do
core** — parar de gastar energia em portabilidade para poder usar recursos de fronteira. Manter
**um** porte vivo é outra coisa: prova de portabilidade **executável**. O texto novo diz isso
explicitamente, para que a próxima leitura não conclua que uma linha cancela a outra.

### 3. A prova de portabilidade se pagou no primeiro dia

O porte revelou um buraco que o core não via: a REGRA 3 (Campo model: restrito à allowlist
sonnet|opus|haiku|fable) lê `model:` em **frontmatter** — e não enxergaria `model = "gpt-5.4"`
fixado em **TOML**, que foi exatamente o que quebrou o `@onion` lá. **Substrato diferente é o
único lugar onde se descobre o que a guarda do core assume sem dizer.**

Isto é o argumento mais forte a favor de manter o porte vivo, e ele é empírico, não retórico.

## Aufhebung no grafo

`C_CORE_NAO_E_FAMILIA` foi para `superseded` — **sem perder o label**, que continua correto sobre
o que era verdade em 2026-08-02. O nó novo `D_FAMILIA_TEM_DOIS_REGIMES_2026_09` carrega a decisão
e a aresta `SUPERSEDES`. Radar `--integrity --schema` exit 0 (93 nós / 108 arestas).

## Fica aberto

Registrar `onion-codex` no `members.yaml` — o que fecha o buraco da REGRA 36 (Superfície
VENDORIZADA sem nome comercial de cliente). Não entrou aqui porque mexe no registro da federação,
que tem validador e projeções próprias, e merece o seu próprio PR.

E o **contra-fluxo**: o `R-MODELO` que nasceu no porte não tem equivalente no core. Vira REGRA nova
aqui quando o maestro quiser — a lacuna está nomeada, não curada.
