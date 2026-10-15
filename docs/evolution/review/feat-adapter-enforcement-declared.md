---
branch: feat/adapter-enforcement-declared
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: 6bca3dd7460256a5e9a0f5856c868e30cf5d1c9e68766d4517bebd330ba7a6a3
reviewed_code_sha256: eb3bb6142f207d167be2c5a3f58d89a040d6204bbb2b1f333945946a12d7ef38
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: a sessão executora (SAC-142 D); ataques por 3 mutantes e pelo lint do core inteiro
nota: "tokens e duration_min em 0 = não medidos. Decisões de forma tomadas sem o maestro (autorização noturna de 2026-10-15), listadas no corpo."
---

# Passada adversarial: `feat/adapter-enforcement-declared`

## O que muda

Esta é a parte D da SAC-142 (`D_COBRAR_NA_SAIDA_E_NO_TRANSPORTE`): virou obrigação que todo adapter SDAAL declare onde o seu contrato é cobrado.

- Cada raiz (`.claude/utils/<r>/` com `interface.md` e `adapters/`) ganha um `enforcement.tsv`. Ele tem uma linha por adapter, com a forma de cobrança `exe:`, `hook:`, `validator:` ou `none:` (esta com motivo e gatilho).
- Um arquivo de `adapters/` que não é adapter (os dois "Irmão de…") declara `<!-- adapter-auxiliar: <adapter> -->`.
- Nova REGRA 107 (Adapter SDAAL declara onde o seu contrato é cobrado), HARD. O verificador é `adapter-enforcement-check.sh`, e a lista de raízes e adapters é derivada do filesystem.
- O passivo de `none:` sai como SOFT. Hoje: 7 de 18 adapters, em 5 raízes.

## Achados

1. **Declaração fora do teto de linhas.** Na 1ª forma ela ficava num bloco dentro da `interface.md`, e o núcleo SDAAL do task-manager passou do teto da REGRA 5 (Limites de linhas (por TIPO de artefato — tamanho saudável ≠ número universal)): 518 contra 500. A declaração foi para o irmão `enforcement.tsv`, no molde do `capabilities.tsv`, e as `interface.md` não mudaram.
2. **Regra fora do registro.** A REGRA 107 nasceu sem categoria no `rules-registry.sh`, e isso derrubava o gerador da REGRA 39 (Registro de REGRAS derivado e em paridade com as guardas). Entrou em "SDAAL — abstração de provider".

## Honestidade da declaração

Cada `none:` foi declarado onde a medição não achou cobrança no ponto de uso:
- **federation-transport:** git-async e local;
- **de-identification:** regex e local-slm, só exercidos pela bancada;
- **adapters nulos:** task-manager, forge e de-identification.

Os adapters de trust declaram `validator:` porque o `trust-topology-check.sh` é chamado pelo lint. Já o github declara `hook:` pelo veto do merge: ele cobra merge e push, **mas não a criação de PR**, como mediu o estudo.

## Decisões tomadas sem o maestro

- O formato é um arquivo irmão `enforcement.tsv`, e não um bloco na `interface.md`: a medição do teto de linhas decidiu.
- A REGRA 107 é HARD, com passivo SOFT. Em repo derivado, hook não registrado e validador fora do lint descem a SOFT.

## Mutantes

- M1: a lista de adapters tirada do próprio tsv, e não do filesystem. Reprova o caso (b).
- M2: `none:` sem checar o gatilho. Reprova o caso (d).
- M3: o marcador auxiliar ignorado. Reprovam (a), (e) e (f).

## Limites declarados

- A forma é conferida, a verdade não. Um `validator:` aponta para um validador que o lint chama, mas a guarda não prova que ele cobre o contrato daquele adapter.
- Raiz SDAAL sem `adapters/` (por exemplo, a co-evolução, que é gerador) fica fora por derivação. O estudo a julgou fora do escopo SDAAL.

## Rebase com conflito (re-revisão)

O #1133 e o #1134 puseram as famílias deles na mesma âncora do `lint-selftest.sh`. Resolvi mantendo as três, uma
depois da outra, e o conflito de projeção (`testing-inventory.md`) foi regenerado pelo gerador. As três famílias
rodaram juntas: 15 casos verdes.
