# Fixture de drift — caso GOOD (Regra 16, guarda anti-FP: 'Knowledge Bases (N arquivos, ...)' não é a forma canônica)

- `docs/knowledge-base/` - Knowledge Bases (__ONION_KBS_DRIFT__ arquivos, incl. index)

'N arquivos, incl. index' é uma métrica DIFERENTE (contagem de arquivo físico, +1 pelo
index.md) — não o total de KBs do inventário. A âncora exige 'documentos', não
'arquivos', justamente para não colidir com essa semântica distinta (forma real:
.claude/commands/warm-up.md e docs/INDEX.md usam 'arquivos' com significados
diferentes entre si — o 2º inclui deliberadamente o index.md, o 1º não). Mesmo com o
número divergindo, a Regra 16 NÃO deve citar este arquivo.
