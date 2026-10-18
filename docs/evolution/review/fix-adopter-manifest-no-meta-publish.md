---
title: 'Resíduo — o /meta:publish e as duas peças que só existem por ele saem da adoção'
date: 2026-10-18
branch: fix/adopter-manifest-no-meta-publish
reviewed_diff_sha256: 1fc5d08b6e9bdf5177fc6ed5543f542d5156bbc4c3ffdaa55b37b2bbc07da555
reviewed_code_sha256: d2427224ff97347e7b6fc51affba2d2551c5321e286d0eb5d5466d0ca531f41c
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 25
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Pedido do maestro, continuação do #1189: o comando /meta:publish chegava morto ao adotante, do mesmo
  jeito que a skill que o conduz. A exclusão de adoção (_CORE_ONLY_ADOPTION_EXCLUDES, fora do _role_cut
  para não ligar o corte de comandos) passa a cobrir o comando. ACHADO, curado no mesmo PR: tirar só o
  comando deixaria órfãs a lente .claude/rules/publish-lens.md, que linka o publish.md e tem paths: só de
  ops/, e a doutrina publish-doctrine.md, citada só pelo comando, pela skill e pela lente. A própria lente
  declara que as duas "seguem o comando". O derivador de companheiros (_emit_companion_excludes) não as
  pegaria, porque só roda quando há corte de PAPEL. Por isso as quatro estão listadas explicitamente.
  Medido: o bundle de adoção perde exatamente os 4 arquivos (1210 contra 1214), não sobra link para
  nenhum deles nos arquivos que viajam, e a porta segue com os quatro. O caso (v) de role_cut cobre os
  quatro nas duas polaridades e mantém o mutante. Dogfood num clone descartável de adotante: o --update
  saiu rc=0 com as 4 remoções nomeadas, e o lint do adotante deu 0 HARD antes e depois. role_cut e
  vendor_core_removed, 55/55. Grafo: o nó Q_MANIFESTO_SEM_SKILL_CORE_ONLY ganha a evidência (a fila está
  no teto). Confirmed do grafo editado, todos vistos: E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA,
  E_HOOK_PR_SEM_PASSADA_CURADO, E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM,
  E_NARRATIVA_NO_ROTULO_VAZA_GABARITO, E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO,
  E_MERGE_GATE_INERTE_NO_ADOTANTE, E_SKILL_CORE_ONLY_VIAJOU, D_PAPEL_DUAS_DIMENSOES,
  E_PR_FINALIZE_ATRITO_MEDIDO, E_CONFLITO_DE_PROJECAO_GERADA, E_BRAIN_MCP_PEDIDO_DE_CAMPO. Sem Elenxo,
  declarado: mesma exclusão do #1189, estendida e medida pelo lint de um adotante real (clonado).
---

# Resíduo — `fix/adopter-manifest-no-meta-publish`

Teto: a lista é explícita. Peça nova que nascer só para o /meta:publish tem de entrar nela à mão,
porque o derivador de companheiros não roda neste corte.
