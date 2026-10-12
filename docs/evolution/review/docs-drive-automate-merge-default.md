---
branch: docs/drive-automate-merge-default
date: 2026-10-12
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 15
verdict: REPROVADO_E_CURADO
reviewer: passada própria (sem subagente) — gate mecânico: lint-artifacts
---

# A doutrina do drive dizia "merge 100% humano" e o maestro decidiu o contrário para o AUTOMATE

## Achados

1. **A doutrina contradizia a decisão de 2026-10-12 (SAC-74).** No AUTOMATE, o merge é POR PADRÃO, e as 3 pré-condições abstratas do degrau ganharam nome concreto:
   - **enabler:** o `ops/pr-merge-verified.sh`, com o veto exit 2 do `merge-gate`;
   - **path-allowlist:** a REGRA 36 e a REGRA 30;
   - **política mecânica:** as paradas duras.

   O degrau **não abre** antes de as paradas duras virarem predicados executáveis com mutante (SAC-114). Merge por padrão sobre parada em prosa seria o carimbo automático que a doutrina combate. O AUDIT segue como hoje.
2. **Dois HARD pré-existentes na varredura completa do `main`**, da REGRA 16 (Contagem de inventário-TOTAL divergente da SSOT). A linha "Total" de duas tabelas de triagem em `data/` do grafo `contrato-kg-absorcao-2026-10` era lida como contagem de inventário. O rótulo virou "Soma da triagem", porque os números contam a triagem, não o inventário.

## O que NÃO cobre

- A REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela) continua HARD **só nesta máquina**: o clone local de um adotante está numa branch de trabalho sem o arquivo de carimbo. É estado local que o CI não vê, e não pertence a este diff.
