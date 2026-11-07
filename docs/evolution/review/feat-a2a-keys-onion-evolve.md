---
branch: feat/a2a-keys-onion-evolve
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: 4423648f86e8c86c5b45f4555948d637c1d96ea2f3d8899a35723200c11316c1
reviewed_code_sha256: 735861ddb256df0c7fb349b82951d57fb53d78e1148d5c63c78df6ee8346248a
findings_total: 3
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução da sessão do core (passada própria, não independente; o brief proibiu subagente)
nota: "tokens 0 = não medido. A privada não foi lida, impressa nem copiada: só o keygen a tocou."
---

# Passada adversarial: `feat/a2a-keys-onion-evolve`

## O que muda

- O par A2A do core nasce pelo `a2a-keygen.sh --member onion-evolve` (kid `onion-evolve-1`, RSA 3072). A
  privada ficou em `~/.config/onion/a2a/onion-evolve-1.key.pem`, modo 0600, num diretório 0700. A pública
  está pinada em `.claude/utils/federation-transport/jwks/onion-evolve-1.pem` com `git add -f`.
- Impressão SHA-256 da pública (sobre o DER SPKI):
  `sha256:bd9f5b6b6491a6b887d994318ce1b04e534053b2b473ecc4db215a07d2eec18d`. O maestro a confere fora de
  banda antes do merge.
- `members.yaml`: `keys: [onion-evolve-1]` vai DENTRO do bloco `a2a:` que o core já tinha (o do endpoint),
  e o arquivo foi editado como TEXTO.
- `members-validate.sh`: a fonte (`kind: source`) com `a2a.keys` dispensa `sends_to`, porque ela assina a
  volta para vários receptores. Há caso e mutante na `run_federation_a2a_selftests` (124/0).

## Achados

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | um 2º `a2a:` no bloco do core seria ignorado em silêncio: o YAML fica com a última chave, e o kid sumiria do leitor do gate | real | curado: a chave vai dentro do bloco existente, e o `yaml.safe_load` devolve `['onion-evolve-1']` |
| 2 | o validador reprovava a fonte com chave, porque exigia `sends_to` (receptor único) | real | curado: a exceção vale só para `kind: source`, com caso e mutante |
| 3 | a chave da curadoria: gerar aqui faria a sessão do core ser a autora da identidade de outro membro | limite | não gerada: a curadoria roda o keygen ela mesma (ver o relatório ao maestro) |

## Teto

- O core e a curadoria rodam com o mesmo uid e o mesmo HOME, e o diretório default do keygen é o mesmo
  (`~/.config/onion/a2a`). O 0600 não separa as duas sessões: separa as contas. A fronteira "a privada
  nasce no membro" é de autoria e de custódia declarada, não de isolamento criptográfico.
