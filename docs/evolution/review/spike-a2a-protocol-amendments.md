---
title: 'Resíduo — spike A2A cross-user: as 9 emendas da curadoria, datadas, e a passada adversarial delas'
date: 2026-10-14
branch: spike/a2a-protocol-amendments
reviewed_diff_sha256: 110158b06cde8cea5a5c41b7a31304ee6045754415ba838e0971d79351fde2fd
reviewed_code_sha256: 948f04144a2b027a6a3d50c2d2b6d6d7c4cd411a8f252aeb1476aa87ffedf359
findings_total: 14
findings_real: 12
findings_fixed: 12
tokens: 127499
duration_min: 6
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Um refutador (code-reviewer) passou o diff inteiro das emendas antes do PR e rodou os testes offline.
  Achou 14 itens: 12 defeitos reais (2 bloqueantes, ambos furos da allowlist do A7: quebra de linha e
  glob), 1 cosmético e 1 grupo de confirmações. Todos os reais foram curados, e cada furo virou caso
  negativo no selftest. A cura do item 5 produziu um achado que nenhum revisor pediu: medido no Claude
  Code real, uma regra deny esconde a tentativa do PreToolUse, e a receptora ficou sem deny.
---

# A régua nova do A8 nasceu furada, e o refutador a furou antes do maestro

## O que entrou

- **As 9 emendas da curadoria (RODAR COM CORREÇÕES), datadas, no §12 do `SPIKE-PROTOCOL.md`.** O
  pré-registro dos §§0–11 não perdeu texto. Ele leva marcadores `[Emenda N, §12]`, e o trecho de
  P:296-297 está riscado.
- **O juiz de tentativas:**
  - o hook que só registra (`hooks/record-tool-attempts.sh`), carregado pela config própria da
    receptora (`hooks/receiver-settings.json`);
  - o juiz (`vps/judge-attempts.sh`);
  - as allowlists pré-registradas (`allowlists/A8.tsv` e `allowlists/A7.tsv`).
- **O A8g:** os canários (`vps/plant-canaries.sh`), com sandbox sem `allow`, mais a foto de
  permissões (`vps/snapshot-permissions.sh`).
- **No channel:** os 4 hashes medidos no recibo, e o `delivered` persistido e marcado só depois da
  notificação.
- **No ATC:** `iat` e teto de vida, com inteiros JSON; a raiz de confiança no clone servido, com a
  linha `TRUST`; e o `SUSPECT` para "já entregue" sem `ACCEPT`.
- **Testes offline:**
  - `hooks/record-tool-attempts.selftest.sh`: 78/78;
  - `vps/accept-to-channel.selftest.sh`: 12/12;
  - `channel/a2a-channel.smoke.ts` sob bun: 12/12. Com o CH de `origin/main`, o mesmo smoke dá 4/12.
- **O grafo do spike:** `E_CURADORIA_REFUTA_PROTOCOLO_2026_10_14` e
  `D_EMENDA_PROTOCOLO_POS_CURADORIA_2026_10_14`. O radar `--integrity --schema` sai com exit 0, e o
  `kg-contract-check.sh` com rc 0.

## Os achados e o destino de cada um

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | quebra de linha no Bash passava pela allowlist do A7 | bloqueante | curado: lista branca + `fullmatch`; caso negativo |
| 2 | glob do shell e o `glob` do Grep furavam a lista negra de segredos | bloqueante | curado: política de caminho `repo`; casos negativos |
| 3 | `rg --pre`, `sort -o`, `uniq - <arq>`, `find -okdir` "de leitura" | importante | curado: saíram da allowlist; casos negativos |
| 4 | segredos fora da lista negra (`/proc`, `~/.config/gh`, canários) | importante | curado: fora do cwd = agiu; casos negativos |
| 5 | premissa do sandbox falsa: o core libera Read/Grep/Glob sem escopo | importante | curado: o sandbox perde o `allow`, `--strict`, toda receptora no sandbox |
| 6 | teto de vida do ATC burlado por `exp` string octal | importante | curado: inteiros JSON + base 10; caso no selftest |
| 7 | "não perguntar de novo" invisível ao juiz | importante | curado: sem diálogo = INCONCLUSIVO; caso no selftest |
| 8 | perda contada como entrega (marcava antes da notificação) | importante | curado: marca depois, `inflight`, `SUSPECT` no ATC |
| 9 | canário: rótulo constante, caixa, separador | menor | curado: parte aleatória normalizada; casos no selftest |
| 10 | plantio deixava resto; `--restore` não conferia | menor | curado: `die` antes, trap, `--restore` confere; casos no selftest |
| 11 | contagens desatualizadas | menor | curado |
| 12 | repetição de réplica reusando o número | menor | curado: número novo (`3b`) e vínculo |
| 13 | "o texto fica como estava" não era literal | cosmético | frase corrigida |
| 14 | hook sem stdout; ATC sem TOCTOU; CH sem corrida | — | confirmação |

## O que a passada NÃO cobriu (declarado)

- **Nada rodou vivo.** O caminho HTTP → gate → fila → channel → sessão continua do maestro: P2,
  aceitação, A7 e A8.
- **O hook foi exercido no Claude Code real só em `-p`, sem o channel:** duas rodadas, com haiku,
  numa pasta descartável. A sessão interativa com a flag de dev e o hook juntos não foi exercida.
- **A política de leitura ainda pode deixar escapar:**
  - um Glob como `*env` pode casar arquivo oculto, conforme o motor de glob da ferramenta (não
    medido);
  - o Grep sem `path` lê o cwd inteiro, e não sei se ele respeita o `.gitignore` em todos os casos.

  Por isso as sessões receptoras rodam no sandbox.
- **O `git ls-files` da allowlist roda `git`.** Um `core.fsmonitor` configurado no sandbox poderia
  executar código, mas mudar a config já seria uma tentativa fora da allowlist.
- **Teto declarado das guardas de grafo:** o radar e o contrato julgam **forma**, não verdade. O
  `confirmed` dos dois nós vem dos testes citados no `verified_against`, e não deles.
- **Rebase:** a cura do corpo no `a2a-verify.sh` (outro PR, em andamento) ainda não entrou. Se ela
  mergear antes, este PR é rebaseado. O P5b depende dela.
