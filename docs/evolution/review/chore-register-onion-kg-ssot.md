---
title: 'Resíduo — o onion-kg-ssot no registro, a semente que executava o próprio comentário e dois achados na fila'
date: 2026-10-06
branch: chore/register-onion-kg-ssot
reviewed_diff_sha256: f49d42ed3bc33f026607a26c5a932f857e85538f7aaaa767ae590902d41dee2c
reviewed_code_sha256: 7fe77cc15d50ddb0e57bac2511f854f578b2cfaadcce7d06cfcceef81bf0c75f
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 15
verdict: CORRIGIDO
elenxo: nao
nota: >-
  (1) O onion-kg-ssot entra no members.yaml (produto independente, dogfood nos dois sentidos; pin-ok
  fe8359e38b43, members-validate válido com 26 membros). (2) DEFEITO MEU, do PR #938: o comentário novo da
  semente do /meta:adopt pôs o separador YAML entre crases DENTRO de um heredoc sem aspas, e o shell o executou
  (erro de comando não encontrado, comentário cortado no adotante). Achado pela adoção do onion-kg-ssot; a
  bancada não pegava porque o caso (a) descartava o stderr do semeador. Cura: o comentário sem crase, e o caso
  (a0) exige o stderr sem "command not found". O caso pegou na 1ª rodada MAIS UMA crase, na própria nota que
  explicava o erro — o defeito real serviu de mutante: reprova com a crase, passa sem ela. Varredura: zero crase
  não escapada no corpo do heredoc. (3) A fila-2026-10-06 ganha dois achados da adoção: a trava de merge inerte
  no adotante (sai 0 sem ops/) e a hipótese da skill core-only que viajou. Os `confirmed` de maior impacto
  do grafo editado seguem como estavam e foram relidos: E_PRECOMMIT_RECARIMBA_RESIDUO, E_ADOPT_SEM_GITIGNORE_DE_SEGREDOS
  e E_DOIS_LEITORES_DIVERGIAM (impacto 4); o PR só ACRESCENTA nós, não muda nenhum deles. Sem Elenxo, declarado.
---

# Resíduo — `chore/register-onion-kg-ssot`

Teto: a semente já entregue ao onion-curation e ao onion-kg-ssot não é reescrita; o comentário cortado lá foi
reparado à mão no onion-kg-ssot pela própria adoção.
