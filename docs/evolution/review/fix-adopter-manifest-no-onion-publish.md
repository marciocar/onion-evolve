---
title: 'Resíduo — a skill onion-publish sai da adoção, e o --update passa a tirá-la de quem já a tem'
date: 2026-10-17
branch: fix/adopter-manifest-no-onion-publish
reviewed_diff_sha256: 474513b1c28f4e3a251db2f14159e63423499e3a0a1eb0cd0efe45e4c22d4c4a
reviewed_code_sha256: 30616c1a09ef8ea3476e901496201d0485b8c29105bdb57d0bd43b8c031d6cde
findings_total: 3
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 70
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Pedido do maestro: tirar a skill onion-publish do manifesto dos adotantes, porque o motor dela
  (ops/publish-door.sh) não vendoriza e a skill chegava morta. O nó E_SKILL_CORE_ONLY_VIAJOU já estava
  confirmado. (1) A cura óbvia, um corte no _role_cut para adopted|hub, estava ERRADA: um corte não vazio
  ali liga o corte de comandos do roles.yaml (_emit_command_excludes) e tiraria a meta-fábrica do
  adotante, decisão separada que ninguém tomou. A exclusão nova, _CORE_ONLY_ADOPTION_EXCLUDES, vive fora
  dele e vale só no destino adoção. Medido no bundle extraído: adopted e hub perdem só o SKILL.md (1213
  contra 1214 arquivos), a meta-fábrica fica, e a porta (--kind door) segue com a skill. Caso (v) de
  role_cut, com mutante. (2) ACHADO REAL no dogfood do --update, feito num clone descartável de
  adotante: a skill FICAVA depois do update rc=0, porque o vendor-branch.sh media o pin anterior com o
  manifesto NOVO, que já a excluía; quem já tinha a skill nunca a perderia. Curado com o lado antigo
  medido sem as exclusões de APOSENTADORIA, que o vendor-manifest.sh --retired-excludes expõe. Caso (e)
  de vendor_core_removed, com mutante, e o dogfood repetido mostra uma remoção só, a da skill.
  (3) Uma objeção minha, REFUTADA pela bancada: achei que medir o lado antigo sem NENHUMA exclusão
  apagaria arquivo próprio do adotante (chaves jwks). O mutante amplo não apagou, porque o lado antigo
  é a árvore do CORE no pin anterior, não a da vendor. Mantive a cura estreita por outro motivo: a ampla
  estenderia a remoção aos cortes de papel (um adotante que trocou de papel perderia o que o corte novo
  tira), e essa decisão também ninguém tomou. O caso que eu tinha escrito para isso não distinguia as
  duas curas e saiu. Famílias vizinhas: 17 famílias (vendor, adopt, manifest), 169/169; role_cut e
  vendor_core_removed, 55/55. Grafo: Q_MANIFESTO_SEM_SKILL_CORE_ONLY passa a done, com a evidência no
  próprio nó (a fila está no teto de 30). Confirmed do grafo editado, todos vistos:
  E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA, E_HOOK_PR_SEM_PASSADA_CURADO, E_MAPA_SEM_MERGE_ONION_HOOKS,
  E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO, E_RADAR_CEGO_A_TIPO_TROCADO,
  E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE, E_SKILL_CORE_ONLY_VIAJOU,
  D_PAPEL_DUAS_DIMENSOES, E_PR_FINALIZE_ATRITO_MEDIDO, E_CONFLITO_DE_PROJECAO_GERADA,
  E_BRAIN_MCP_PEDIDO_DE_CAMPO. Sem Elenxo, declarado: a passada adversarial foi a minha, refutando com
  mutante a própria objeção, e o efeito sobre adotantes foi medido num clone descartável antes de
  qualquer --update real.
---

# Resíduo — `fix/adopter-manifest-no-onion-publish`

Teto: a mesma classe segue aberta no comando `/meta:publish` (`.claude/commands/meta/publish.md`),
que também viaja morto ao adotante e fica fora deste PR, que é só da skill. A remoção chega a cada
adotante no próximo `--update` dele: se ele editou a skill, o merge vira conflito modify/delete (exit
10), nunca deleção calada.
