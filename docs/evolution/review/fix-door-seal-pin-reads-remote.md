---
title: 'Resíduo — o cache do pin das portas lê o carimbo no remoto, pela leitura do --status'
date: 2026-10-14
branch: fix/door-seal-pin-reads-remote
reviewed_diff_sha256: 17f4c5d1b9bef71e2d993467ee5023f54d3ade1f5078a04db76a9a451c0f4809
reviewed_code_sha256: 1815f5be500aa764572a039741bb34484f200af65b148c762db4ac1eb574a828
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 70
verdict: CORRIGIDO
elenxo: sim
nota: >-
  O ops/door-seal-pin.sh lia o carimbo do clone local da porta, que a publicação da F3 não atualiza, e
  recusou as quatro portas no PR #1100. A leitura do carimbo publicado saiu do --status para
  ops/door-published-stamp.sh, e as duas pontas fazem source dela, sem fallback ao clone local. Três
  achados, os três curados aqui. Dois vieram do dogfood e da passada própria: o ref de 40 caracteres dos
  plugins e o prompt de credencial do git. O terceiro veio do lint: a REGRA 100 nas citações novas da
  doutrina. O refutador independente (subagente code-reviewer) foi disparado sobre o diff e NÃO devolveu
  veredito em cerca de 25 minutos. A passada que conta aqui é a minha, e isso fica declarado.
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O defeito, medido

Em 2026-10-14 (PR #1100), `bash ops/door-seal-pin.sh <porta> --dry-run` recusou as quatro portas, e
`publish-door.sh --status` dava as quatro em dia. A razão é que o carimbador lia o **clone local** de
cada porta, e o `publish-door.sh` publica a partir de um clone descartável. No momento da recusa:

- o clone do onion-mini tinha um arquivo não commitado;
- os clones do standalone e do core estavam atrás do remoto;
- o clone do plugins não tinha carimbo.

O cache acabou carimbado à mão.

## A cura

- A leitura do carimbo publicado ficou num lugar só, a lib `ops/door-published-stamp.sh`. Ela traz
  `_url_of`, `_stamp_field`, `_stamp_pin` e `door_read_published`, que devolve `DPS_STATE`, `DPS_PIN`,
  `DPS_ROLE` e `DPS_RELEASE`. O `--status` e o `door-seal-pin.sh` fazem `source` dela, e nenhum dos dois
  tem mais uma leitura própria.
- No `door-seal-pin.sh`, as guardas de árvore limpa e de clone igual ao remoto (por `gh api`) saíram,
  porque o que vem do remoto já é o publicado. Continuam as checagens do core: o pin é commit dele e é
  ancestral de `origin/main`. O `local_path` deixou de ser lido.
- **Sem fallback ao clone local, por decisão declarada no cabeçalho.** Com um fallback, a leitura
  errada voltaria justamente quando o remoto estivesse fora do ar. Remoto ilegível recusa com rc 2, e a
  mensagem diz que o clone não é consultado.
- O `--push` termina imprimindo `Cache do registro (opcional, numa leva própria): bash
  ops/door-seal-pin.sh <porta> --dry-run`. O motor não escreve no registro nem abre PR, por causa da
  regra da ponte.

## Achados

1. **Real, curado.** No onion-plugins o carimbo é o `ref` de 40 caracteres do `provenance.json`, e o
   cache guarda 12. A comparação literal reescreveria um cache que o `--status`, que compara 12, já dá
   como em dia. O 1º dogfood (`--dry-run` no onion-plugins) mostrou isso. Cura: normalizar com
   `rev-parse --short=12`. Caso (n) na bancada; o mutante que tira a normalização reprova (n).
2. **Real, curado (passada própria).** Com url https inexistente ou privada, o `git ls-remote`/`clone`
   pede credencial, e numa sessão de agente sem TTY isso trava em vez de falhar. Antes o `--status` tinha
   o mesmo risco. Cura: `GIT_TERMINAL_PROMPT=0` na lib.
3. **Real, curado (lint).** A REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o
   tivesse) pegou como `[NEW]` as duas citações `ops/...` que eu escrevi em `publish-doctrine.md`.
   Reescrevi pelo nome do script, marcado como core-only.

Suspeitas checadas e descartadas:

- regressão de estado no `--status`: NÃO-MEDIDO, SEM-CARIMBO e a contagem de `measured` foram
  comparados linha a linha com o bloco antigo, e os casos (c), (c2) e (c3) do publish estão verdes;
- colisão dos `DPS_*`: os dois consumidores leem os valores logo depois da chamada;
- `rm -rf` com caminho vazio: está guardado por `${work:?}`.

## Bancada (LC_ALL=C)

- `door_seal_pin` foi refeita sobre um mundo falso sem rede. O remoto é um bare local, e o clone
  registrado em `local_path` está no pin velho e sujo. São 13 casos, entre eles:
  - (a) remoto com carimbo e clone local defasado: carimba o pin do remoto;
  - (c) remoto ilegível: rc 2, registro intacto, recusa declarada;
  - (j) remoto sem carimbo;
  - (n) marketplace;
  - (o) lib ausente.
- `publish` ganhou o caso (b2), que confere a dica do `--push`.
- Mutantes, todos plantados com `ops/mutate-and-restore.sh`, todos reprovam:
  - voltar a ler o clone local: 8 casos vermelhos;
  - tirar a normalização a 12: o caso (n);
  - ignorar `source_commit` na lib: 6 casos;
  - tirar a dica: o caso (b2);
  - tirar a leitura da lib no `--status`: os casos (c), (c2) e (c3).
- As 19 famílias afetadas (`--affected` com os três arquivos de `ops/`): 147 aprovados, 0 falhas.
- Dogfood real em `--dry-run` nas quatro portas: rc 0, pin `668cac66a12b` lido do remoto, cache em dia.

## Fora do diff, declarado

O lint local sai com 1 HARD, a REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela). Ela
acusa o clone `granaai` desta máquina sem `.claude/.onion-version`. É estado da máquina, não está neste
diff, e o CI não tem esse clone.
