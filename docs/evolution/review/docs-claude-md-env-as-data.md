---
branch: docs/claude-md-env-as-data
pr: pendente
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: FIXED
elenxo: false
reviewer: passada própria do agente de execução sobre o próprio diff, sem subagente (o brief proíbe criar agentes); gate claude-md-size-check (REGRA 109) e execução do env-check.sh contra um arquivo falso fora do repo
nota: "tokens e duração não medidos (0). Uma linha do CLAUDE.md trocada e uma frase redundante tirada; sem código."
---

# Passada adversarial: `docs/claude-md-env-as-data`

## O que muda

- `CLAUDE.md`, bloco «Fluxo obrigatório antes de operar com tasks»: o passo 1 deixa de mandar `set -a; source .env; set +a`
  (que EXECUTA o arquivo) e passa a apontar o `env-check.sh --provider|--check|--get`, que lê o `.env` como dado. É a
  decisão `D_ENV_FOLLOW_TMSH_1110` (grafo `maestro-decisions-1110`, PR irmão).
- A frase de abertura da seção perdeu «lendo `TASK_MANAGER_PROVIDER` em `.env`», que repetia o passo 2, para caber no
  teto sem subi-lo.

## Achados

1. TETO (curado): a primeira redação passava 87 B do teto de 26246 B (REGRA 109, CLAUDE.md dentro do teto de tamanho).
   Encolhida e com a frase redundante fora: 26243 B, rc 0, teto intocado.
2. COMPORTAMENTO MEDIDO, NÃO DECLARADO (curado): conferido contra um arquivo falso fora do repo (o `.env` real não foi
   aberto nem lido), com um valor `$(touch PWNED)`: `--provider` devolve o provider, `--check` só nomes, `--get` de chave
   não-secreta devolve o valor e de segredo sai rc 2; o `PWNED` não nasceu, logo o arquivo não foi executado.
3. OUTRAS INSTRUÇÕES DE `source .env` (declarado, fora do escopo): seguem em superfícies que viajam e ficam listadas no
   corpo do PR, sem correção aqui. Entre elas a mensagem do próprio veto `pretooluse-env-guard.sh`, que oferece
   `set -a; source .env; set +a` como alternativa.
