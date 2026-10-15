---
branch: fix/a2a-veto-json-injection
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: 8d2e962a4743cc39bf72565768269d4d8cecb72ceefec9719e293cf1198bcb3d
reviewed_code_sha256: 426051da7a1200473a1c114840475cfd75390512905d0610453fbca955ceffc5
findings_total: 8
findings_real: 5
tokens: 152253
duration_min: 4
findings_fixed: 5
verdict: CORRIGIDO
elenxo: sim
reviewer: "subagente general-purpose (opus), mandato REFUTAR, sobre o diff do core e do bridge"
nota: "o refutador não refutou a cura da R1; os 5 achados reais curados são de disponibilidade e endurecimento. Par do bridge: marciocar/onion-bridge#72"
---

# Passada adversarial: `fix/a2a-veto-json-injection`

## O que muda

Este PR é a R1 da 3ª passada de refutação do A2A (SAC-150), do lado do core. O `veto()` do `a2a-verify.sh` interpolava `reason` e `layer` crus no JSON. Dois vetos levavam valor do remetente: `unknown-kid:${KID}` e `unsupported-alg:${ALG}`. Com um kid contendo aspas, o gate saía com rc 1 e imprimia `verified` duplicado, com o último valor true. Medi o mesmo resultado com os envelopes e9/e10 das fixtures da curadoria.

Curas:

1. **O `veto()` saneia todo valor na saída** (`LC_ALL=C tr -cd`, teto de 200). Vazio vira `unspecified`.
2. **O alg é julgado no jq** (`== "RS256"`), com reason fixo `unsupported-alg`. Um header com `crit`/`b64` recebe veto `unsupported-jws-crit` (RFC 7515 §4.1.11).
3. **A forma do kid é julgada no jq por explode antes de qualquer uso**: 1–160 caracteres de `[A-Za-z0-9._-]`, sem `.` no início. Se falha, `bad-kid`.
4. **O header tem de ser UM objeto** (`malformed-jws-header`) e entra na checagem de chave duplicada (`duplicate-key:jws-header`).
5. O `a2a-doctor` monta o header sintético por jq e ganhou a dica para `bad-kid`.
6. O `inbox-pull.sh` recusa nome de item do manifesto remoto que esteja fora da forma, o que fecha um path traversal anterior a este PR.
7. Docs atualizadas: as duas taxonomias R e o `jwks/README.md`.

## Achados

O refutador (opus) não conseguiu injetar nada nem no gate nem no bridge curados. Testou unicode, NUL, CR, U+2028, surrogate, kid número ou lista, alg lista, duplicata no header, header não-objeto e BOM. Achados e destino de cada um:

1. **MÉDIO-BAIXO, real, curado.** A forma `alfanumérico inicial, ≤ 64` vetava kid legítimo. O keygen gera `<membro até 128>-<N>`, e o members-validate e o a2a-send aceitam `_`/`-` no início. Cura: teto de 160 e só `.` vetado no início. Casos `kid-longo` (132 caracteres) e `kid-hifen`. O teto do `veto()` subiu para 200, porque com 120 o `kid-not-owned-by-from:<kid>` saía truncado.
2. **BAIXO, real, curado.** Docs citavam `unsupported-alg:${ALG:-none}`. Nenhum consumidor de máquina casa `unsupported-alg:`: conferi por grep no core e no bridge.
3. **BAIXO, real, curado em parte.** O gate ignorava `crit`/`b64`. Agora veta, com o caso `hdr-crit`. Ficou de fora o NUL ou os `\n` finais no header, que o `$()` normaliza. Só o dono da chave produz esse header, então não abre falsificação.
4. **INFO, não curado.** `duplicate-key:jws-header` sai com `layer_failed:"body"`. É cosmético, e o veto ocorre depois da assinatura.
5. **INFO, real, curado no bridge.** `__proto__` como chave própria passava no round-trip. Agora vira `veredito-ambiguo`, com caso e mutante.
6. **INFO, não curado.** O round-trip do bridge rejeitaria saída de `jq -c` com DEL, não-ASCII ou `\/`. O falso positivo é latente e fail-closed, porque o bridge não consome `--reverify-at`.
7. **INFO, não curado.** O `SIGKILL` do timeout do bridge mata só o bash. É vazamento de recurso, sem efeito no veredito.
8. **BAIXO, real, anterior a este PR, curado em parte.** O `inbox-pull.sh` gravava `${DEST}/${name}` com um nome vindo do manifesto remoto. Agora recusa, com o caso `inbox-pull: traversal`. Ficou de fora o `a2a-send.sh:146`, que ecoa a resposta do receptor crua no terminal local.

## Mutantes

Todos plantados por `ops/mutate-and-restore.sh` e rodados com `LC_ALL=C` na família `a2a_verify`: **11 de 11 mortos**.

| # | Mutante | Morto por |
|---|---|---|
| M1 | `veto()` sem saneamento | `veto-sanitize` |
| M2 | forma do kid sempre ok | `e9`, `kid-newline` |
| M3 | reason de alg com eco | `e10` |
| M4 | header de dois documentos aceito | `hdr-two-docs` |
| M5 | header fora da checagem de duplicata | `hdr-dup` |
| M6 | sem veto de crit | `hdr-crit` |
| M7 | teto de kid 64 | `kid-longo` |
| M8 | alfanumérico inicial | `kid-hifen` |
| M9 | ponto inicial aceito | `kid-ponto` |
| M10 | inbox-pull sem forma | `traversal` |
| M11 | teto do veto 120 | `kid-longo` |

M2 também caiu pelo bridge: são 34 de 34 mutantes, 5 deles novos, em `scripts/a2a-receivers-mutants.sh`.

**Contra origin/main:** os 5 casos da 1ª leva (e9, e10, kid-newline, hdr-dup, veto-sanitize) reprovaram com o código de main, como medido. Bancada: família `a2a_verify` com 93 passaram e 0 falharam; as 6 famílias A2A com 342 e 0 antes das curas do refutador.

**Dogfood (e2e):** rodei o handler do bridge com o gate REAL em sandbox, com remetente convidado e e9/e10 do `mkenv` da curadoria.

- core main + bridge main: **200 verified:true e o sinal enfileirado** (fila=2).
- Qualquer combinação com uma das curas: 403, fila 0.
- O envelope legítimo segue com 200.

## Limites declarados

- **Decisões da sessão, sem o maestro**, todas pela opção recomendada (nó `D_R1_VEREDITO_ESTRITO_NOS_DOIS_LADOS`):
  - curar nos dois lados;
  - forma do kid alinhada à população do keygen;
  - `crit`/`b64` vetados;
  - curar o traversal anterior no `inbox-pull`.
- **Não medido:**
  - o bridge servido em produção (o deploy é da sessão principal);
  - NUL e `\n` finais no header;
  - o eco do receptor no `a2a-send`;
  - o `-u ID:SECRET` em argv no `inbox-pull.sh`, que é anterior a este PR, está fora do escopo e fica declarado para a sessão principal.
- O teto do grafo subiu de 50 para 52 com motivo registrado no `meta:`.
