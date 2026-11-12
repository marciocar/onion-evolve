---
branch: feat/vertical-company-brain-context
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: 858eee6057a6e89074db589433838664a2ebf5191bb582a31f4a403eb6633e6d
reviewed_code_sha256: 202d2b3f6abeace56c852cd9a871cc865f8dfde5122064ed75696e8260376b55
findings_total: 7
findings_real: 7
findings_blocking: 1
tokens: 138365
duration_min: 105
findings_fixed: 4
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "refutador independente (subagente opus, sessão principal, 2026-11-12); cura pela sessão principal"
nota: "duration_min inclui cerca de 1h40 em que o refutador ficou preso num tool_use sem resultado"
---

# Passada adversarial: `feat/vertical-company-brain-context`

## O que muda

Nasce a vertical **company-brain-context** pelo `/meta:create-vertical`:

- o resolver `onion-company-brain-context` e o hub `company-brain`;
- a persona carregada por warm-up (`/company-brain:persona`, `/company-brain:help`);
- o contrato de voz e conduta: o esquema `onion/voice-conduct/v1`, o exemplo e o validador `voice-conduct-check.sh`, com saída rc 0/1/2;
- `resolve-context-dir.sh` passa a conhecer a dimensão;
- a família de bancada `voice_conduct`.

O CLAUDE.md vai a 121 comandos (com a categoria `company-brain`) e 16 skills.

## Achados

1. **Bloqueante, curado.** A skill diz que aprovar é "só o dono", mas o validador só recusava uma lista fixa de curingas. `approve.who=["estagiario"]`, `["all"]` e `["todo-mundo"]` passavam com rc 0. Cura: a regra virou positiva, e `approve.who` precisa ser exatamente o `owner` (`VC-APPROVER-NOT-OWNER`). Prova: casos (r) e (s) e o mutante (u).
2. **Limite, curado.** Uma bomba de alias YAML travava o validador (rc 124 no `timeout 60`). Cura: um alias no arquivo sai rc 2 antes de carregar. Prova: caso (t).
3. **Limite, curado.** Não havia teto de tamanho (um arquivo de 50 MB não terminava). Cura: acima de 256 KB sai rc 2. Prova: caso (t).
4. **Limite, curado indiretamente.** Os curingas fora da lista fixa caem na regra positiva do achado 1.
5. **Limite.** Uma chave YAML duplicada vence em silêncio: fica a última.
6. **Limite.** Chave desconhecida só é barrada no topo e no `send_gate`; dentro das seções e das regras passa.
7. **Limite.** O histórico com data no futuro e a versão maior que a atual não são conferidos.

Resistiram ao refutador:
- seção faltando, revisão vencida, aprovação no futuro, aprovador diferente do dono, `--today` inválido e arquivo que é lista;
- o `resolve-context-dir.sh`, sem regressão nas quatro dimensões antigas;
- o molde dos `onion-*-context` e o "contexto ≠ dimensão", que mantém as 3 dimensões peer;
- a varredura de vazamento sem nome de cliente nem caminho de máquina.

## Mutantes

- **Do refutador:** m1 (sem a checagem de data futura) e m2 (sem a de ação nos dois lados) calam o caso que a cura pega.
- **Da família:** (q) traz 3 mutantes, e (u) é o mutante novo da regra positiva do aprovador.

`--families voice_conduct` dá 21 casos, 0 falhas.

## Limites declarados

- Os achados 5 a 7 ficam abertos.
- O texto das regras não é executado: a persona o assume como conduta. Nada impede uma regra que contradiga os `limits`, e isso fica para o gate pré-envio, que é a próxima peça.
