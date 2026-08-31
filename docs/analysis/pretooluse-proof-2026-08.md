---
title: "PROVA: o exit 2 de PreToolUse barra sob bypassPermissions — medido, não declarado"
category: analysis
date: 2026-08-31
kg: docs/evolution/research/maestro-vivo-2026-08/maestro-vivo-2026-08.kg.yaml
verified_at: 2026-08-31
---

# A frase-moat do CLAUDE.md, exercitada pela primeira vez

O programa MAESTRO-VIVO (F2, tema moat-gates) mediu que a capacidade citada como razão do
acoplamento — *"o exit 2 determinístico de hook, que barra a ação inclusive sob
bypassPermissions"* — tinha **ZERO PreToolUse** neste repo: era a mesma classe do `SendMessage`
(declarado e nunca exercitado) que a correção de 2026-08-16 removeu. O item `I_PROVA_PRETOOLUSE`
da Onda 6 mandava provar OU corrigir a frase. **Resultado: PROVADA.**

## O experimento (reproduzível)

Sandbox git com `.claude/settings.json` registrando um PreToolUse em `Bash`:

```json
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
  { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/deny-forbidden.sh\"" } ] } ] } }
```

```bash
#!/usr/bin/env bash
# deny-forbidden.sh — nega qualquer Bash cujo input contenha FORBIDDEN_ONION
input=$(cat)
if printf '%s' "$input" | grep -q "FORBIDDEN_ONION"; then
  echo "GUARDA-PRETOOLUSE: comando negado pelo hook (exit 2)" >&2
  exit 2
fi
exit 0
```

## As duas medições (2026-08-31, claude -p, AMBAS sob `--dangerously-skip-permissions`)

| Caso | Comando pedido | Resultado |
|---|---|---|
| Proibido | `echo FORBIDDEN_ONION_TESTE_123 > prova.txt` | **BLOQUEADO**: hook error `GUARDA-PRETOOLUSE... (exit 2)`; `prova.txt` NÃO existe — o comando não chegou a executar |
| Controle | `echo CONTROLE_OK > controle.txt` | **PASSOU**: arquivo criado com o conteúdo esperado |

A verificação é pelo **estado do filesystem**, não pela mensagem do modelo: o arquivo do caso
proibido não existe; o do controle existe. Bloqueio de AÇÃO, não conselho.

## O que muda

- A frase do CLAUDE.md **ganha lastro medido** — nenhuma reescrita necessária. O veredito ERRADO
  do F2 acertou no diagnóstico (capacidade não-exercitada) e a cura proposta (provar) foi executada
  no mesmo ciclo; o nó do confronto permanece como história.
- O sandbox acima é a **demo pública** mais barata do moat: 15 linhas reproduzem o bloqueio.
- Fica aberto (gatilho nomeado no grafo): usar PreToolUse de verdade no core — o primeiro caso de
  uso real (ex.: barrar troca de modelo via PreModelSwitch, ou push forçado) fecha a distância
  entre provado-em-sandbox e exercitado-em-produção.
