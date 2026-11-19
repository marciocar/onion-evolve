---
branch: feat/private-owner-sessions-1119
pr: pendente
date: 2026-11-19
reviewed_diff_sha256: e67b2593f018bad21bf7685094c84b500ba9839b692e31292b6beb69feedd2cb
reviewed_code_sha256: 18ec0d4f5a5ffebe6e55fa79ef6b89667be913457d8ebd07096105044f4af472
findings_total: 9
findings_real: 6
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 5
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, mandato de refutar, duas passadas. 1ª: APPROVED com 2 MÉDIOS (faltava o mutante da regra 'só quando o alvo não casa remote público'; a promessa de não imprimir o slug era maior que o código fora da catraca) e 5 BAIXOS. 2ª, sobre as curas: FIXED; restos BAIXOS (rótulo do pv13, pv11b sem mutante próprio)."
nota: "tokens 0 = não medido."
---

# Passada adversarial: `feat/private-owner-sessions-1119`

## O que muda

A catraca do repo próprio (`_own_repo_gate` em `ops/pr-merge-verified.sh`) passa a ler também a lista privada de sessões
donas, fora do repo (`${ONION_PRIVATE_OWNERS_FILE:-~/.config/onion/private-owner-sessions.tsv}`), para o membro de
consultoria que no `members.yaml` tem id neutro e `remote: n/a` (D_PRIVATE_OWNER_SESSIONS_1119, decisão do maestro de
2026-11-19). A lista só é consultada quando o alvo não casa nenhum `remote:` público; exige modo sem bit de grupo e outros,
membro em origin/main com `kind: adopter` e `remote: n/a`, owner_session na linha (igual à do registro, se ele declarar),
uma linha só por slug, e o dono do slug igual ao do core. A recusa da catraca nomeia o member_id, nunca o slug. No CI a
lista não é lida.

## O que se tentou refutar

Vazamento do slug nas saídas, bypass por linha privada (porta, membro público, outro dono, ambiguidade, parsing do TSV,
normalização), regressão dos casos antigos, mutantes que não provam a causa, a bancada lendo o arquivo real do maestro,
die engolido em subshell.

## Achados e destino

1. MÉDIO, curado: a regra "só quando o alvo não casa remote público" não tinha mutante. Entraram o pv13 (linha privada que
   aponta a porta pública para o neutro recusa por PORTA) e o pv13-MUT.
2. MÉDIO, curado por escopo: fora da catraca (modo "repo sem CI", sessão do core sem `--foreign-repo`) o slug digitado no
   `--repo` ainda pode aparecer. A promessa do cabeçalho e da doutrina foi restringida à recusa da catraca, com o teto
   declarado.
3. BAIXO, curado: `remote` ausente contava como neutro. Agora só `remote: n/a` literal (pv14 + pv14-MUT).
4. BAIXO, declarado: a owner_session sai no aceite; o cabeçalho diz que ela não leva nome de cliente.
5. BAIXO, teto: o `IFS` de tab junta colunas vazias e o `awk -v` interpreta escapes; nenhum dos dois amplia além do que o
   dono do arquivo escreveu.
6. BAIXO, curado: pv11b cobre só `GITHUB_ACTIONS=true`.
7. BAIXO, teto: `- id:` aninhado no YAML, o mesmo teto do awk que já existia.

## Bancada

Família `pr_merge_verified`: 265 passaram, 0 falharam. Casos pv1 a pv14 (aceite, membro inexistente, modo 644, outro dono,
porta, remote público, owner_session divergente ou ausente, ambíguo, sem lista, CI, remote público vence, sem remote) e
um mutante por cura (pv1, pv2, pv3, pv4, pv5, pv6, pv7, pv8, pv9, pv11, pv13, pv14 e pvq, o do rótulo). A lista da
bancada é sempre fixture (`local -x ONION_PRIVATE_OWNERS_FILE` no topo da família). Lint: 0 HARD.

## Veredito

FIXED. O merge é do maestro: o PR toca a própria catraca (M1).
