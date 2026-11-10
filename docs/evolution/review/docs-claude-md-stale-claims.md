---
branch: docs/claude-md-stale-claims
pr: pendente
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_blocking: 0
findings_fixed: 0
tokens: 0
duration_min: 15
verdict: APPROVED
elenxo: true
reviewer: "o próprio agente de execução, uma passada adversarial curta (o brief proíbe criar agentes)"
nota: >-
  Corrige uma frase do CLAUDE.md: o «zero uso» do SendMessage foi medido em 2026-08 e hoje não vale.
  A segunda afirmação pedida (o set -a; source .env do Task Manager) NÃO muda: a decisão do Vaultwarden
  não cobre os tokens do Task Manager. tokens: 0 = não medido (passada do próprio agente, sem contador).
---

# Passada adversarial: `docs/claude-md-stale-claims`

## O que muda

- `CLAUDE.md` l.24: «caiu: zero uso.» vira «caiu: zero uso em 2026-08; hoje é usado, mas uso não é
  exclusividade.». A conclusão (o `SendMessage` não compra o acoplamento) fica igual.
- `.claude/validation/claude-md-size-ceiling.txt`: teto de 26246 para 26301 B (+55, exatamente o
  crescimento), com `raise:` que cita `E_OBJECAO_OPTION_B_NO_MEASURED_SUBSTITUTE`.

## Conferências

- Origem do «zero uso»: `claude-code-2.1-onion-2026-08/SYNTHESIS.md` l.49 —
  `grep -rn SendMessage .claude --include=*.md --include=*.sh --include=*.json` devolveu ZERO na
  maquinaria viva em 2026-08.
- Hoje, `git grep -l SendMessage -- .claude` devolve 4 arquivos: o hook `house-code-gloss.sh` (julga a
  mensagem do `SendMessage`), o `settings.json` (matcher `SendMessage|Write|Edit`), o preâmbulo
  `execution-agent-preamble.md` (manda pedir à sessão principal por `SendMessage`) e o selftest. O nó
  `E_OBJECAO_OPTION_B_NO_MEASURED_SUBSTITUTE` (2026-11-04) já media «SendMessage 4» e registra que
  contagem mede uso, não exclusividade.
- `.env` do Task Manager: a decisão `D_MESSAGING_SEGREDOS_VAULTWARDEN_SYSTEMD_1106`
  (messaging-standards-2026-11) cobre «os tokens do Slack, do bridge e da mensageria», copiados para
  credencial do systemd por `LoadCredential`. Não nomeia o Task Manager nem os adotantes. Sem mudança.
- `claude-md-size-check.sh` sai 0 com o teto novo.

## Achados

| # | Severidade | Achado | Destino |
|---|---|---|---|
| 1 | baixa | revisor = autor (sem leitura independente); o diff é de uma frase, conferido por grep | aceito e declarado |
| 2 | média | o próprio `tm.sh` (l.28) diz que o `.env` «NÃO é carregado nem executado aqui» e é lido como dado; o `set -a; source .env` do CLAUDE.md executa o arquivo. Contradição real, mas fora do escopo pedido | reportado à sessão principal, não corrigido aqui |
