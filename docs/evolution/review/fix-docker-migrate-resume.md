---
branch: fix/docker-migrate-resume
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: 041cda55c4df8300f02ed17a73bc4bdae86bcaad04b793646673647df580ac4f
reviewed_code_sha256: cfeb5defae412868076fb587e7d8fa78e218b2e28b47ee752676c1f074dbfa4a
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 20
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos; hotfix rodado no vivo com ok explícito do maestro antes do merge"
---

# Passada adversarial: `fix/docker-migrate-resume`

## O que muda

- `ops/docker-engine-migrate.sh`: a subida do Engine sai do `apply` para `start_engine`, que faz `daemon-reload`,
  `reset-failed` do socket, do serviço e do containerd, e reinicia o `docker.socket` ANTES do `docker.service`.
- Subcomando novo `resume`: retoma depois de um `apply` que instalou e não subiu. Só roda com o docker-ce fixado já
  instalado (`guard:resumepin`) e nunca instala nada.

## Achados

1. O `apply` real de 2026-10-22 22:32Z instalou o docker-ce 29.9.2 e o dockerd não subiu: "failed to load
   listeners: no sockets found via socket activation". O `docker.socket` do docker.io mudou de configuração com a
   unit rodando, ficou sem descritor e bateu o limite de reinícios (`service-start-limit-hit`). O `enable --now
   docker.service` sozinho não o recupera. Os containers ficaram fora de 22:32Z até o `resume` (verify ok às
   ~22:53Z). A bancada esboçava o `systemctl` e não tinha como ver isso.

## Mutantes

- O vivo foi o mutante: o `apply` sem a cura saiu rc 2; o `resume` com a cura saiu rc 0 com verify ok (Engine 29.9.2,
  todos os containers de volta, image store e DOCKER-USER iguais ao plan, 9 rotas com o código esperado).
- `--selftest`: 19 pass, 0 fail.

## Limites declarados

- O `resume` rodou a partir desta branch antes do merge, com autorização explícita do maestro (serviços fora). O
  merge vem depois, pelo caminho verificado.
- A bancada não simula a ativação por socket do systemd; o caso fica coberto pela execução real registrada aqui.
