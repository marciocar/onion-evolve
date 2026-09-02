---
title: "Revisão — F1 da lente de pesquisa: fragmento + rule + campos bi-temporais/tier + REGRAS 67/68 + kg-corpus-grep"
date: 2026-09-02
branch: feat/research-lens-f1
reviewer: "condutor com dogfood executado: kg-corpus-grep.sh PreModelSwitch → 8 nós de 81 grafos, 'instruction bloat' → 2, corpus vazio → exit 2; bancada run_research_lens_selftests 8/8 isolada; lint --only no corpus real rc=0/0 HARD (REGRA 67/68 caladas: os 4 grafos novos foram carimbados); radar exit 0 nos 5 grafos tocados; backlog regenerado LC_ALL=C"
reviewed_diff_sha256: e0c245cc125616863a5a09da111eda91381c48b2bda603d71c7ec8e4f784fa4b
findings_total: 6
findings_real: 6
verdict: APROVADO
tokens: 140000
duration_min: 35
---

# Resíduo — REGRA 56

F1 do plano selado pelo maestro (`D_F1_FUNDACAO_FRAGMENTO_CAMPOS_GUARDAS_CORPUS`): a diretriz de pesquisa
vira **spec carregada** (fragmento + rule por path), **campos no grafo** (`valid_from`, `source_tier`,
`source_kind`, `meta.review_after`), **duas guardas SOFT** (REGRA 67 revisita; REGRA 68 tier×confiança)
e o **passo 0** `kg-corpus-grep.sh`. Nada no CLAUDE.md, por desenho (instruction bloat em CAUTION).

## Achados

1. **Heredoc engoliu o stdin** no 1º dogfood do `kg-corpus-grep` ("0 grafos" com 81 no corpus): a lista de
   arquivos ia por pipe e o `python3 - <<'PY'` fez do heredoc o stdin. Cura: lista por arquivo temporário;
   comentário-lei no script. O caso (f) da bancada conta o corpus para não recair.
2. **"Já tinha review_after" falso**: meu check casou `review_after:` dentro de um LABEL (o grafo da pesquisa
   cita o campo em prosa). Cura: âncora `^  review_after:` no `meta:`. A REGRA 67 usa a mesma âncora.
3. **Corpus real é 81 grafos, não 27**: o glob `docs/onion/graph + docs/evolution/research` do censo é
   36% cego (a rule kg-grammar já avisava); o corpus-grep usa `git ls-files '*.kg.yaml'`.
4. **Catraca sem retro-ruído**: REGRA 67 só exige `review_after` em grafo com `baseline ≥ 2026-09-02`; nos
   antigos só acusa vencimento se a chave existir. REGRA 68 é opt-in pela presença dos campos.

5. **O gate achou 3 HARD antes do envio**: dois links vivos para caminho core-privado dentro de um fragmento
   VENDORIZADO (morto no adotante — trocados por texto + gloss) e REGRAS 67/68 sem categoria no registro
   (`rules-registry.sh` → categoria Conhecimento; `lint-rules.md` regenerado). Mecanismo, não leitura.
6. **3ª reprovação do gate, desta vez na MINHA família**: `lint` é variável LOCAL por família no runner; meu
   runner isolado a definia globalmente e passava 8/8, o runner real fazia `bash "" --only=…` (rc=1, saída
   vazia). Cura: `local lint=` na família + o runner isolado passa a NÃO predefinir nada que o real não tenha.
   Bancada-espelha-o-runner, 2ª ocorrência da classe hoje.

## Não mudou

- `kg-radar.sh` não foi alterado (ignora chaves desconhecidas; `--schema` só checa `schema_version`) — mostrar
  `source_tier` no `--freshness-tsv` fica para F2/F4.
- `docs/onion/radar-sources.yaml` (roster por eixo) é F2.
- Nenhum nó de evidência existente ganhou `source_tier` retroativamente — os campos entram nas pesquisas novas.
