---
title: 'Resíduo — F5 das portas: o onion-mini gerado do core por allowlist'
date: 2026-10-10
branch: feat/doors-mini-f5
reviewed_diff_sha256: a9ab5df93161bac31572ab614d267898fe5441eae6dfc848eb502136d903dd69
reviewed_code_sha256: f5b7b339083a442667b38f320490f290aa66dda2d86db053d8051684fdb0aa08
findings_total: 11
findings_real: 11
findings_fixed: 9
tokens: 157206
duration_min: 7
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: "passada adversarial (branch-code-reviewer, default reprovado) achou 1 bloqueador, 2 importantes e 8 menores; curados no mesmo laço o bloqueador, o I1 e 7 menores, com caso de bancada e mutante; declarados o I2 (pin n/a do mini depois da 1ª publicação, nó com gatilho F6) e o menor 1 (known_absent por citação, não por arquivo citante — só os arquivos próprios do mini são estritos)"
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O que o PR faz

É a F5 do plano das portas (SAC-94), pela matriz `D_MATRIZ_DE_PORTAS_2026_10`.

- **O onion-mini nasce do core pela allowlist.** O `ops/materialize-door.sh --role mini` monta o
  manifesto do papel e escreve por cima os arquivos próprios do mini: README, CLAUDE.md e skill onion
  didáticos (`ops/door-templates/mini/`), mais as duas KBs do contrato de sessão, cópia fiel do core.
- **Verificação de quem não leva o lint.** `.claude/validation/door-mini-check.sh`: allowlist exata,
  ponteiro morto em sete formas e caminho de máquina, com as ausências declaradas no `known_absent` do
  `roles.yaml` (catraca nos dois sentidos). O `vendor-manifest --list mini` usa o mesmo detector.
- **O motor deixa de recusar o mini.** `ops/publish-door.sh --replace-foreign` faz a 1ª materialização
  sobre a destilação antiga: arquiva a ponta numa tag anotada, empurra e confere a tag ANTES da porta,
  e só então publica por cima. O passo (5c) do mini chama o checador.
- **A F2 corrigida.** README e CLAUDE.md genéricos mandavam o mini rodar o lint e o `/meta:inventory`,
  que ele não leva.
- **KG.** Nós `E_MINI_GERADO_F5`, `E_DESTILACAO_DO_MINI_VIRA_ARTEFATO_ARQUIVADO` e três perguntas ao
  maestro com gatilho, no `door-role-parity`. O lote da F4 foi selado no 1º commit.

## A passada adversarial

Veredito: **REPROVADO**, curado no mesmo laço.

| # | Severidade | Achado | Desfecho |
|---|---|---|---|
| B1 | bloqueador | o detector não via link relativo, `docs/` nem comando de raiz; o bundle real saía "sem ponteiro morto" com o contrato de sessão do ciclo apontando para documentos que não viajavam | **curado**: três formas novas no detector, casos (c4), (c5), (c6) com mutante; as duas KBs viajam como overlay; 23 citações declaradas |
| I1 | importante | a instalação do README sobrescrevia o CLAUDE.md do iniciante e levava o carimbo de porta para o projeto dele | **curado**: `cp -n`, o carimbo copiado é apagado quando é o do mini |
| I2 | importante | o `n/a` do mini no registro fica permanente depois da 1ª publicação | **declarado**: nó `Q_PIN_NA_DO_MINI_DEPOIS_DA_PUBLICACAO`, gatilho no 1º `--push` (F6) |
| m1 | menor | `known_absent` vale por citação, não por arquivo citante | **parcial**: nos arquivos próprios do mini nenhuma ausência vale, caso (c7) com mutante; nos compartilhados, declarado |
| m2 | menor | o ramo MISSING não tinha caso | **curado**: caso (b2) com mutante |
| m3 | menor | disco × HEAD do `roles.yaml` no checador | **curado**: `roles.yaml` com edição não commitada é rc 2 |
| m4 | menor | `/Users/`, `/root/` e home com maiúscula escapavam | **curado**: caso (d) planta dois, mutante |
| m5 | menor | `--replace-foreign` com `--clone` esvaziava o clone do maestro | **curado**: recusado, caso (k5) com mutante |
| m6 | menor | overlay com destino `.git/` era aceito | **curado**: recusado |
| m7 | menor | o (5c) mostrava só 15 achados | **curado**: imprime o total |
| m8 | menor | número divergente no nó (47 × 46) | **curado**: narrative diz os dois e por quê |

## Mutantes

20 plantados por `ops/mutate-and-restore.sh`, 19 reprovando o caso nomeado. O 20º (rc 2 de fonte sem
`roles.yaml`) sobrevive por defesa em duas camadas: sem a guarda de existência do resolvedor, a leitura
do `known_absent` sai 2. Declarado.

## O que fica para o maestro

- A 1ª publicação do mini é a F6 (`/meta:publish onion-mini --replace-foreign`). Antes dela, confira se a
  vitrine ou o GPT dependem da ponta do repo (`Q_VITRINE_E_GPT_DO_MINI_DEPOIS_DA_PORTA`).
- O mini sem `/meta:setup-integration` é o literal da matriz (`Q_MINI_CONFIGURA_INTEGRACAO_PELO_ENV`).
