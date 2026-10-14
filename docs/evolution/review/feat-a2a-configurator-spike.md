---
branch: feat/a2a-configurator-spike
date: 2026-10-14
reviewed_diff_sha256: d6194615bf7e5c2400edf375a9fe39bc0153c88cdf544d9915df0ddb9c1645ed
reviewed_code_sha256: 9542d16d7eaa324fd157a7183b3ce11ec8ac6de192363ab9f9b341c03215bbe6
findings_total: 3
findings_real: 2
findings_fixed: 2
tokens: 415077
duration_min: 60
verdict: REPROVADO_E_CURADO
reviewer: 3 subagentes de spike (worktrees isoladas) + re-execução independente pela sessão principal dos 3 roteiros (S1/S2 12/12, S3 8/8 e mutante, S4/S5 18/18 num clone novo do bridge com o diff aplicado)
---

# F0 do configurador A2A: o grafo, as 4 decisões do maestro e o spike S1–S5

## O que entra

- O grafo `a2a-configurator-2026-10` (15 nós): a pergunta, as 4 decisões seladas pelo maestro, o manual (SAC-133),
  3 evidências do spike e 4 achados que restringem o desenho.
- Os protótipos e roteiros do spike em `docs/evolution/research/a2a-configurator-2026-10/spike/`: keygen,
  remetente canônico, doctor, e o diff do bridge (convite por membro + receptor múltiplo). NADA disto é produção:
  o bridge foi medido numa cópia local, e a VPS não foi tocada.

## Passada adversarial

1. **O veredito dos subagentes vale?** Tratado como hipótese: a sessão principal re-executou os 3 roteiros. Bateram.
   O mutante do S3 saiu rc 0 na re-execução e pareceu sobreviver; lido o roteiro, o modo `--mutant` sai 0 quando o
   mutante é morto limpo (só `priv_0644` diverge). Não real.
2. **Os achados viraram nó com o tipo certo?** Real, curado: os 4 achados nasceram como `evidence` e são afirmações;
   passaram a `claim`, com CONSTRAINS sobre a pergunta ou sobre a decisão do convite.
3. **O texto do grafo cita segredo ou caminho de máquina?** Real, curado antes do commit: a guarda do `.env` barrou
   o heredoc que citava o ambiente do bridge pelo nome do arquivo; o grafo foi escrito pela ferramenta e diz
   "ambiente do bridge".
