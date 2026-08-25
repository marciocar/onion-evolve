---
title: "Revisao — hooks ativam na instalacao (self-review, dogfood de install)"
date: 2026-08-25
branch: fix/plugin-hooks-registration
reviewer: "self-review (autor) — correcao achada e provada por DOGFOOD DE INSTALL real (claude 2.1.243); fix→re-dogfood no mesmo loop"
reviewed_diff_sha256: e1931516bd0fda0ac650325b6232412e0c49f35047cecc9d769f24e75b9be34f
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 800
duration_min: 4
---

# Residuo — REGRA 56 (self-review; a passada foi o DOGFOOD DE INSTALL)

O maestro pediu 'teste instalar o onion num Claude Code limpo'. O install e a passada adversarial que
lint nenhum faz — e pegou um defeito REAL:

- **Achado (dogfood):** install de onion@onion-plugins num CC limpo → skills/comandos/agente OK, mas
   mostrou **Hooks: 0**. Os 2 hooks (guarda exit-2 PostToolUse + aside-router
  UserPromptSubmit) viajavam INERTES — o assemble so copiava o .sh e deixava o registro 'a cargo do
  consumidor'. A guarda exit-2 e a capacidade que 'compra' o acoplamento ao Claude Code; chegava morta.
- **Cura:** assemble gera hooks/hooks.json (AUTO-DESCOBERTO), mapeando cada hook ao EVENTO que o core
  lhe da em settings.json, path . Nao inventa evento (hook sem registro no core
  fica de fora, com aviso). Plugin.json intocado (so 8 campos; hooks.json e auto-descoberto).
- **Re-dogfood (mesmo loop):** re-install → **Hooks (2) UserPromptSubmit, PostToolUse**. Provado por
  comportamento, nao declaracao.
- **Mecanismo:** run_plugin_hooks_json_selftests 2/2 (gera+evento correto; nao inventa evento) — guarda
  a regressao. lint 0 HARD, kg-radar exit 0. Grafo: E_HOOKS_INERT_ON_INSTALL_FIXED.

Verificado: validate do plugin passa com o hooks.json; so o onion tem hooks (os demais plugins nao
geram hooks.json — o bloco so roda com HOOKS presentes).

**Veredito: APROVADO** — dogfood de install achou o gap, a cura ativa os hooks (re-provado), o selftest
fecha contra regressao. Falta re-materializar + push do repo publico.
