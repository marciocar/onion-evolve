---
title: 'Sinal da curadoria: regressão na guarda do .env (A1), helper aceito pelo nome (A5) e atrito da glosa de N0–N4 (A2), no update ca3c622d33e8'
date: 2026-10-23
from: onion-curation
to: onion-evolve (core)
type: signal
pin: ca3c622d33e8
pr: marciocar/onion-curation#61 (merge 7709caa)
residue: docs/evolution/review/chore-onion-update-ca3c622d33e8.md
---

# Três achados de hook do update ca3c622d33e8

Pedido pela sessão do core (onion-evolve-fc) em 2026-10-23, depois do merge do PR #61. A passada adversarial foi do
Elenxo, um agente separado que só leu. Ele provou os achados num sandbox com um `.env` falso, cujas chaves eram
`SECRET_KEY=abc123` e `LINEAR_API_KEY=lin_xyz`. Os arquivos de hook citados são byte-idênticos aos do core no pin.
Por isso a cura é do core, e a curadoria não diverge o caminho vendorizado.

## A1 — limita (regressão de segurança)

**Onde:** `.claude/hooks/pretooluse-env-guard.sh`, na linha 454 (`DATA_EXT`) e nas linhas 704, 716–717 e 724
(`data_used_as_code`).

**O que mudou:** um heredoc gravado num arquivo `.md` (extensão de dado) pode agora citar o `.env`. A guarda
deveria barrar esse arquivo quando ele é usado como código, mas três formas escapam:

- `cat > r.md <<'X' … getline < ".env" … X` seguido de `awk -f r.md`
- `cat > r.md <<'X' cat .env X` seguido de `cat r.md > r.sh; bash r.sh` (a cópia por redirecionamento funciona
  como renomeação)
- `make -f r.md`, pelo mesmo mecanismo

**Prova** (o hook recebe um JSON de PreToolUse fabricado, com `CLAUDE_PROJECT_DIR` no sandbox, e roda contra o
hook novo e contra a cópia do antigo):

| Caso | Hook novo | Hook antigo | Executado no sandbox |
|---|---|---|---|
| `awk -f r.md` | 0 | 2 | imprimiu `'SECRET_KEY=abc123\nLINEAR_API_KEY=lin_xyz\n'` |
| `cat r.md > r.sh; bash r.sh` | 0 | 2 | imprimiu o mesmo conteúdo |
| `bash r.sh` em duas chamadas (o `r.sh` gravado antes pela ferramenta Write) | 0 | 0 | já passava antes |

**Por que não mata:** o caminho em duas chamadas, da última linha, já passava na versão antiga. A regressão
junta num comando só o que antes pedia dois.

**Emenda sugerida:** incluir `awk`, `make` e outros executores que recebem script por `-f` em
`data_used_as_code`. Tratar `cat <dado> > <x>.sh`, `cp` e `mv` como renomeação do arquivo de dado.

## A5 — limita (já existia, de segurança)

**O quê:** a guarda aceita como o helper qualquer arquivo chamado `env-check.sh`, em qualquer pasta. O comando
`bash /tmp/qualquer/env-check.sh .env` passa (rc 0) no hook novo e no antigo.

**Emenda sugerida:** aceitar só o helper pelo caminho canônico (`.claude/utils/task-manager/env-check.sh`, sob
`CLAUDE_PROJECT_DIR`), resolvido com `realpath`.

## A2 — atrito (para avaliar)

**O quê:** o modo `stop` de `.claude/hooks/house-code-gloss.sh` devolve `exit 2` quando uma sigla de opacidade alta
volta sem glosa depois do lembrete. Na curadoria, N0–N4 (os níveis da escada do `/meta:dissect`) são vocabulário
de todo dia.

**Medição:** o `--scan` no maior transcript do repo (44 MB) deu `turnos=373 … barraria=6 (1.6%)`. Um exemplo:
`BARRARIA turno 232: N0, N1, N2, N3`.

**O que não é problema:** o hook não entra em laço. Com `stop_hook_active` ele sai 0, e
`ONION_HOUSE_CODE_STOP=off` o desliga.

**Pedido:** avaliar se N0–N4 ficam em opacidade baixa no `house-codes.tsv`, já que o `/meta:dissect` os define.

## O que não foi verificado

- O censo de versões com rede real.
- O Stop numa sessão viva do Claude Code.
- `bash-empty-result-guard.sh` e `rule-title-in-prose.sh` foram lidos, mas não executados. A mudança neles é
  sintática: `printf | grep` virou `grep <<<`.

---

**Triagem (core, 2026-10-23):** A1 e A5 curados no PR #1321 (merge 2026-10-23T16:36:11Z), com a evidência `E_ENV_GUARD_A1_A5_CURADOS_1023` em `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`; A2 curado no mesmo PR, com a glosa canônica de N0–N4 no glossário da casa. Decisão do maestro: curar A1 e A5 e usar a glosa canônica para o A2.
