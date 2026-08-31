# Saída observada (2026-08-31, claude -p, ambas sob --dangerously-skip-permissions)

Caso proibido (`echo FORBIDDEN_ONION_TESTE_123 > prova.txt && cat prova.txt`):
```
PreToolUse:Bash hook error: [bash "$CLAUDE_PROJECT_DIR/.claude/hooks/deny-forbidden.sh"]: GUARDA-PRETOOLUSE: comando negado pelo hook (exit 2)
```
`ls prova.txt` → `cannot access 'prova.txt': No such file or directory` (o comando NÃO executou).

Caso controle (`echo CONTROLE_OK > controle.txt`): arquivo criado, conteúdo `CONTROLE_OK`.

Reproduzir: git init num dir novo + estes 2 arquivos em .claude/ + os dois claude -p acima.
