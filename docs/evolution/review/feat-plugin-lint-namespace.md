---
title: "Revisão — REGRA 72: namespace de comando em plugin é /<plugin>:<cmd> (helper + cura no assembler + bancada)"
date: 2026-09-04
branch: feat/plugin-lint-namespace
reviewer: "condutor com dogfood EXECUTADO: helper --selftest 6/6; família plugin_namespace 5/5 (com mutante); 8 plugins regenerados, scan 531→0; lint completo 0 HARD"
reviewed_diff_sha256: 9c5f6f69b18c17432ddd00b519e024506250a2eef28f386f80c2e3977921378a
findings_total: 5
findings_real: 5
verdict: APROVADO
tokens: 120000
duration_min: 50
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados

1. **Regex fixa de namespaces cegava a bancada** — a lista `meta|engineer|…` não casava `alpha/beta` da fixture; namespaces agora = core ∪ derivados do mapa.
2. **Mapa recursivo mentia sobre o que viaja** — o assembler copia `dir/*.md` (não recursivo); o mapa usava `find` recursivo e listava `/validate:collab:*` como distribuído. Corrigido com `-maxdepth 1`.
3. **Glob em prosa virava referência** — `/docs:build-*` casava como `/docs:build-`; o token agora termina em `[a-z0-9]` e não precede `*`/`-`.
4. **O README gerado reintroduzia o dangling** — o texto fixo "não é adoção (`/meta:adopt`)" era escrito DEPOIS da cura; 8 residuais. O gerador agora escreve sem barra e com glosa.
5. **REGRA 59 e REGRA 39 pegaram o próprio PR** — a bancada precisava exercitar `--format tsv` (modo consumido) e o registro de regras é gerado (`rules-registry.sh`), não editado à mão.

## Fora de escopo declarado

- Dependência implícita cross-plugin criada pela reescrita → REGRA 77.
- Verificar no binário se `/cmd` nu resolve quando um só plugin o provê (nó de evidência em F5).
