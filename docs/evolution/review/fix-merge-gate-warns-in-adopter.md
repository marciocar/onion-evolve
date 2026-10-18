---
title: 'Resíduo — a trava de merge avisa no adotante em vez de sair calada'
date: 2026-10-18
branch: fix/merge-gate-warns-in-adopter
reviewed_diff_sha256: c02cb45b651ca7733ae0413e164e2db5e5e5801077a61fb8e35f01399707d9d9
reviewed_code_sha256: 5410823a874db3e7778f99d0688f90a3be8c8032720cb0425b73fcb2d5cffe11
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 35
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Pedido do maestro: curar Q_MERGE_GATE_AVISA_NO_ADOTANTE. Medido em 2026-10-17: no adotante (sem o
  caminho verificado de merge, que não viaja), o pretooluse-merge-gate.sh saía com exit 0 calado logo
  depois de ler o comando. A sessão do adotante mergeava sem saber que a trava que a doutrina cita não
  existe ali (E_MERGE_GATE_INERTE_NO_ADOTANTE). Vetar no adotante seria errado, porque bloquearia o
  único caminho de merge da casa. Por isso a cura é avisar: cada caso que vetaria no core vira JSON de
  PreToolUse com additionalContext e exit 0, o mesmo canal que o kg-read-leg.sh já usa ao vivo, dizendo
  que nada conferiu o CI e mandando ler `gh pr checks`. Sem python3, a mesma recusa conservadora vira
  aviso com texto fixo. O aviso não cita o caminho do script do core, porque ele não viaja (seria um
  ponteiro para o que não existe), e não diz "negado". ACHADO no dogfood, curado: a 1ª redação levava
  o motivo do veto ("… negado") para dentro de um aviso que se declara "não veto", e agora o verbo sai.
  Dogfood num repo de adotante sintético: gh pr merge e git push origin main avisam com rc=0, e push de
  branch de trabalho segue calado. No core o veto exit 2 não mudou. Bancada pretooluse_veto: 258/258,
  com os casos (adv-a), (adv-b) e (adv-c) e o mutante (adv-MUT), que reprova quando o ramo do adotante
  volta a exit 0. Grafo: Q_MERGE_GATE_AVISA_NO_ADOTANTE passa a done, com a evidência no nó (a fila está
  no teto). Confirmed do grafo editado, todos vistos: E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA,
  E_HOOK_PR_SEM_PASSADA_CURADO, E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM,
  E_NARRATIVA_NO_ROTULO_VAZA_GABARITO, E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO,
  E_MERGE_GATE_INERTE_NO_ADOTANTE, E_SKILL_CORE_ONLY_VIAJOU, D_PAPEL_DUAS_DIMENSOES,
  E_PR_FINALIZE_ATRITO_MEDIDO, E_CONFLITO_DE_PROJECAO_GERADA, E_BRAIN_MCP_PEDIDO_DE_CAMPO.
  Sem Elenxo, declarado: no core o veto é o mesmo e só o ramo do adotante muda, de silêncio para aviso,
  sem poder de bloquear. O falso positivo possível está nomeado no teto abaixo.
---

# Resíduo — `fix/merge-gate-warns-in-adopter`

Teto: num adotante que trabalha direto na main (trunk-based, ou o push do commit do `--update`), todo
`git push` para a main recebe o aviso. A frase é verdadeira, porque nada conferiu o CI, mas repetida
pode virar ruído. Se o campo medir fadiga, o próximo passo é deixar o adotante declarar a política de
merge dele no carimbo e o aviso se calar quando ela for "push direto".
