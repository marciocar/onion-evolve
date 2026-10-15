---
branch: feat/a2a-configurator-f1
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 15
findings_real: 15
tokens: 167893
duration_min: 7
findings_fixed: 14
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente refutador (general-purpose) + mutantes da sessão
nota: "15 = 14 do refutador + 1 achado pelo mutante K2 (suíte abortava); tokens e duração são do refutador; 1 parcial (date -d GNU-only) declarado em Limites"
---

# Passada adversarial: `feat/a2a-configurator-f1`

## O que muda

F1a do configurador A2A (SAC-122): os motores saem do spike F0 para `.claude/utils/federation-transport/`
e o registro passa a validar o bloco `a2a`.

- `a2a-keygen.sh`: par RS256 3072, `kid` `<membro>-<N>`, privada 0600 num diretório 0700 da conta, nunca
  sobrescreve, recusa gerar dentro de repo git sem `.gitignore` cobrindo a privada.
- `a2a-send.sh`: o remetente canônico (envelope com `body_sha256` e `thread`), bearer só por arquivo de
  cabeçalho, recusa segredo legível por outros, `http://` só em loopback, corpo UTF-8 válido de até 8192 bytes.
- `a2a-doctor.sh`: lado do membro (a–h) e do receptor (r, d, c, t, f, g), rc 0/1/2/3, `--json`,
  `--selftest` (classificação pura). "Não pude medir" é rc 2, nunca saudável.
- `members-validate.sh`: bloco `a2a` (forma e dono único do `kid`, pública RSA ≥ 2048 no JWKS, `sends_to`
  receptor e não porta); já é HARD pela REGRA 66, que existia desde 2026-09-01 (o cabeçalho dizia o contrário).
- Bancada `run_federation_a2a_selftests` (53 casos), reusando os ajudantes JWS extraídos da `a2a_verify`.
- Grafo do programa: 5 nós novos (evidência da bancada, 3 achados, 1 decisão da sessão).

## Achados

Do refutador (14, todos reais, nenhum bloqueante) e da sessão (1):

| # | achado | desfecho |
|---|---|---|
| 1 | keygen gravava a privada versionável dentro de repo git | curado: recusa sem `.gitignore` cobrindo (caso + mutante K7) |
| 2 | send mandava o bearer em `http://` para qualquer host | curado: `http` só loopback (S9) |
| 3 | convite com data relativa ou epoch gigante virava "válido" | curado: forma estrita (D21, D22) |
| 4 | caso decorativo na escolha do kid (pinar a 1ª da ordem) | curado: pina só a acme-2; caso de duas pinadas → rc 2 (D3b, D20) |
| 5 | validador quebrava com traceback em `sends_to` não-texto | curado (V10) |
| 6 | corpo UTF-8 inválido saía rc 0 e o gate vetava | curado: recusa (S10) |
| 7 | rc de uso/erro local saía 1 (o rc da recusa do receptor) | curado: `need()` e `|| die` (S11) |
| 8 | `--out` gravava o envelope com a umask do ambiente | curado: 0600 (S12) |
| 9 | doctor lia o texto da privada para medir os bits | curado: mede sobre a pública derivada |
| 10 | GNU-ismos (`stat -c`, `find -printf`, `/usr/bin/grep`, `date -d`) | curado parcial: `stat` GNU ou BSD, glob no lugar do `find`, `grep` do PATH; `date -d` fica como limite |
| 11 | `stat` sem `-L` acusava symlink 0600 como 777 | curado: `stat -L` |
| 12 | receptor sem `--fingerprint` saía "saudável" sem dizer que não conferiu | mitigado: o resumo diz "SEM conferir a impressão" (D23); ver Decisões |
| 13 | `A2A_JWKS_DIR` do ambiente vazava para a REGRA 66 | curado: o validador não lê mais a variável (só `--jwks` ou a raiz do registro) |
| 14 | kid repetido no mesmo membro; teto de corpo por caractere; texto do piso | curados (V11; teto em bytes; cabeçalho corrigido) |
| 15 | (sessão, mutante K2) atribuição que falha sob o `set -e` do runner abortava a suíte | curado: a família roda com `local -` e `set +e` |

## Mutantes

54 mutantes plantados por `ops/mutate-and-restore.sh`, um ou mais por caso, cada um rodando
`LC_ALL=C bash .claude/validation/lint-selftest.sh --families federation_a2a`. Morto = rc ≠ 0 **e** o caso
nomeado aparece como ✗. Todos morreram, nenhum abortou a suíte, e os hashes dos motores foram conferidos
depois da rodada (restaurados).

| mutante | caso que reprova | estado |
|---|---|---|
| K1 | keygen saída | MORTO |
| K2 | keygen modos | MORTO |
| K3 | keygen bits/impressão | MORTO |
| K4 | keygen sobrescrita | MORTO |
| K5 | keygen piso | MORTO |
| K6 | keygen member | MORTO |
| S1 | send→gate | MORTO |
| S2 | body-file | MORTO |
| S3 | sem body_sha256 | MORTO |
| S4 | kid não pinado | MORTO |
| S5 | bearer fora de argv | MORTO |
| S6 | token 0644 | MORTO |
| S7 | chave 0644 | MORTO |
| S8 | URL com credencial | MORTO |
| D1 | doctor saudável | MORTO |
| D2 | doctor sem chave | MORTO |
| D3 | doctor escolha do kid | MORTO |
| D4 | doctor privada 0644 | MORTO |
| D5 | doctor kid fora do registro | MORTO |
| D6 | doctor convite vencido | MORTO |
| D7 | doctor sem token do canal | MORTO |
| D8 | doctor sem fonte de relógio | MORTO |
| D9 | doctor relógio que diz não sincronizado | MORTO |
| D10 | doctor endpoint fora | MORTO |
| D11 | doctor sem o registro do receptor | MORTO |
| D12 | doctor h sem registro | MORTO |
| D13 | doctor --selftest | MORTO |
| D14 | doctor uso | MORTO |
| D15 | doctor receptor saudável | MORTO |
| D16 | doctor receptor com impressão divergente | MORTO |
| D17 | doctor receptor com topologia que não autoriza | MORTO |
| D18 | doctor receptor com a pública pinada ausente | MORTO |
| D19 | doctor receptor r | MORTO |
| V1 | validador válido | MORTO |
| V2 | validador kid fora da forma | MORTO |
| V3 | validador kid pinado sem a pública | MORTO |
| V4 | validador pública não-RSA | MORTO |
| V5 | validador pública RSA abaixo | MORTO |
| V6 | validador keys sem sends_to | MORTO |
| V7 | validador sends_to que é porta | MORTO |
| V8 | validador sends_to fora do registro | MORTO |
| V9 | validador kid de dois donos | MORTO |
| K7 | keygen em repo git | MORTO |
| S9 | http fora do loopback | MORTO |
| S10 | corpo UTF-8 inválido | MORTO |
| S11 | flag sem valor | MORTO |
| S12 | --out 0600 | MORTO |
| D3b | doctor escolha do kid | MORTO |
| D20 | doctor duas chaves pinadas no dir | MORTO |
| D21 | doctor convite com data relativa | MORTO |
| D22 | doctor convite com epoch gigante | MORTO |
| D23 | receptor sem fingerprint | MORTO |
| V10 | validador sends_to que não é texto | MORTO |
| V11 | validador kid repetido | MORTO |

## Decisões tomadas sem o maestro

O maestro autorizou decidir sem ele, escolhendo a opção recomendada e registrando aqui:

1. **A F1 em dois PRs seriais** (F1a motores + validador + bancada; F1b comando, doutrina, lente, register,
   corte por papel). O recomendado pela própria tarefa para manter o PR revisável.
2. **Piso de 2048 bits no registro, 3072 no keygen** (nó `D_PISO_2048_NO_REGISTRO_3072_NO_KEYGEN`, aberto
   para ratificação): os pinos vivos `metagamify-1` e `granaai-1` têm 2048, e a rotação está parada por ordem.
3. **`kid` na forma `<id>-<N>` com dono único**, cobrado pelo validador: o JWKS é um espaço de nomes só.
4. **Doctor com dois lados** (`--side member|receiver`), porque o spike mediu que o pino só se mede no receptor.
5. **Receptor sem `--fingerprint` segue rc 0**, com o resumo dizendo que não conferiu (achado 12): tornar a
   conferência crítica faria toda revisita de diagnóstico sair rc 2. A conferência é obrigatória na trilha do
   pino (F1b).
6. **O validador deixa de ler `A2A_JWKS_DIR`** (achado 13): o gate do lint não pode depender de variável de shell.

## Limites declarados

- **NÃO MEDIDO:** a bancada completa (`--jobs auto`) e o CI rodam no pré-voo e no PR; aqui rodaram as famílias
  `federation_a2a` e `a2a_verify`, mais o lint inteiro (a única HARD era o inventário do harness, regenerado).
- `date -d` (ISO-8601 do convite) é GNU-only: no BSD o convite sai "fora da forma" (falha, nunca saudável).
- O dogfood ponta a ponta (sandbox, bridge local de teste, dois HOMEs) rodou e passou, mas não com duas
  contas de sistema (criar contas mexeria na VPS) nem contra o bridge vivo (MOAT).
- O gate `a2a-verify.sh` não mudou e não confere tamanho de chave: o piso vive só no validador e no doctor.
