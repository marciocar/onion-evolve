---
branch: fix/adopt-registry-fetch-timeout
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 30
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada própria do agente de execução (Opus 5.5); as duas ressalvas vêm da 5ª refutação externa do #1533
nota: "tokens não medidos (0); passada própria, sem refutador externo neste seguimento"
---

# Passada adversarial: `fix/adopt-registry-fetch-timeout`

## O que muda

Seguimento do #1533, com as duas ressalvas da 5ª refutação, que o aprovou com ressalvas.

- O fetch de `origin/main` do core, que decide o consentimento do push da `onion/vendor`, roda sob `timeout -k 5 <prazo>` (30 s; `ONION_REGISTRY_FETCH_TIMEOUT` encurta na bancada), com `http.lowSpeedLimit`/`http.lowSpeedTime`. Prazo vencido ou falta do comando `timeout` = recusa (falha fechada), com o motivo dito.
- A recusa de remote dividido só roda com 2 membros ou mais; o membro único que não consentiu recebe "não tem vendor_push: true".

## Achados

1. (real, curado) A 1ª redação forçava `GIT_SSH_COMMAND="ssh -o BatchMode=yes …"` quando o ambiente não o tinha. Isso passaria por cima do `core.sshCommand` do checkout do core, porque o env vence a config, e trocaria a chave que o usuário escolheu. Tirei: o prazo do `timeout` já cobre um prompt de senha parado, porque mata o grupo do git.
2. (real, limite) O ls-remote e o push para o adotante seguem sem prazo próprio. Lá um remoto lento prende o update à vista do operador, mas nada é decidido por consentimento.
3. (real, limite) Sem o comando `timeout` (macOS sem coreutils), o push da vendor é recusado, e o update segue sem tocar a remota.

## Mutantes

- (D3): o upload-pack do registro dorme 20 s com prazo de 2 s. A recusa sai em menos de 15 s, com "passou do prazo de 2s", e nada é empurrado. O mutante `mut:no-timeout` (fetch sem prazo) espera, consente, empurra e morre.
- (f): membro único sem consentimento sai com "não tem vendor_push: true", sem "dividido por". O mutante do bloco de consentimento segue morrendo.
- Nenhum `sleep` órfão ficou depois da rodada (conferido com `ps`). Famílias `vendor_push_trailer,shell_pipefail_robustness`: 42 passaram, 0 falharam, com `LC_ALL=C`.

## Limites declarados

- Achados 2 e 3.
