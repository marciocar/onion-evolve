---
branch: feat/one-touch-approval-1118
pr: pendente
date: 2026-11-18
reviewed_diff_sha256: 2a2f5fa881940d59a025a5f3c1393bcf841b27493cecbb61661b47a12d8ef934
reviewed_code_sha256: 89c729dc1c4b7ed0f466ef022145a73523a3afef471d1348c229a957357c0756
findings_total: 8
findings_real: 5
tokens: 0
duration_min: 6
findings_fixed: 5
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "agente revisor isolado (code-reviewer), só leitura, com mandato de refutar; duas passadas sobre o diff da worktree"
nota: "tokens = 0: não medido. 1ª passada APPROVED com 4 LIMITE, todos curados no mesmo laço com caso e mutante; 2ª passada APPROVED com 2 LIMITE declarados; 3ª passada (delta do hash do executor, TTY, efeito e plano) APPROVED com 2 LIMITE, 1 curado na mensagem."
---

# Passada adversarial: `feat/one-touch-approval-1118`

## O que muda

O «pode rodar», autorização de um toque de nível 1. O `ops/pr-merge-verified.sh` ganha `--one-touch-request`: ele roda
todos os gates e, no lugar do merge, grava o pedido canônico. Ganha também `--one-touch`, que confere a autorização
viva e substitui só a exigência do `--maestro` no PR de guarda. O hook `UserPromptSubmit`
(`.claude/hooks/userprompt-one-touch-approval.sh`) grava a aprovação quando o prompt é a frase sozinha. O motor e o
esquema compartilhado de ato ficam em `.claude/utils/approval/`. A bancada são os casos `ot0`–`ot13` da família
`pr_merge_verified`, com mutante por cura.

## Achados

### 1ª passada: APPROVED, com 4 LIMITE, todos curados

1. **REAL, corrigido: a autorização podia ser reaproveitada.** O livro guardava só o hash da aprovação. Rodar o hook de
   novo com o mesmo payload gerava hash novo e renovava o prazo. Correção: o livro guarda também o `prompt_id`, e o
   TTL passa a contar do horário da palavra no transcript. Casos `ot5c` e `ot7b`, com mutantes.
2. **REAL, corrigido: falso positivo na auto-compactação.** A compactação disparada no envio grava o resumo com o
   mesmo `promptId`, antes da entrada humana (o revisor mediu isso em 3 sessões reais). Agora o executor julga a
   entrada que traz a frase. Caso `ot12`, com mutante.
3. **REAL, corrigido: a mensagem do hook prometia o que o executor nega.** Para sugestão aceita, o hook dizia
   «autorizado» e o executor recusava. Agora a linha do hook é condicional e diz que a sugestão aceita não autoriza.
   O executor segue recusando `suggestion_accepted`. Caso `ot13`.
4. **REAL, corrigido: pontuação.** «Pode rodar.» era recusado. Um ponto ou uma exclamação no fim passam a ser
   tolerados.

### 2ª passada: APPROVED, com 2 LIMITE declarados

5. **LIMITE: o TTL tem dois relógios.** Um é o `expires_at` da gravação, o outro é o horário da palavra. O mais
   restritivo vence. A mensagem de vencimento de um deles cita o horário da gravação. Isso afeta só o diagnóstico.
6. **LIMITE: a ordem no harness interativo foi suposta, não medida.** A igualdade entre o `prompt_id` e o `promptId` e o
   `promptId` próprio do `queued` foram medidos em `-p` e em transcripts reais, mas a bancada usa transcript
   sintético. O nó `C_TETO_ORDEM_INTERATIVA_SUPOSTA` traz o gatilho: o 1º uso real. Uma recusa com «não está no
   transcript» é o sinal para medir de novo.

### 3ª passada (delta: hash do executor, `requires_tty`, `effect`, plano): APPROVED, com 2 LIMITE

7. **REAL, curado na mensagem: falso positivo entre checkouts.** Se a sessão pede de uma worktree e usa a partir de
   outra, o sha256 do script diverge, e a recusa não dizia a causa. Agora ela pede para rodar do mesmo checkout em
   que pediu. A recusa continua fechada.
8. **LIMITE: `--requires-tty` sem valor é ignorado.** Hoje nenhum chamador passa a flag. Quando entrar o primeiro ato
   com TTY, ela vira booleana.

## Limites (teto da peça)

- É camada de **conformidade, não fronteira**: no mesmo usuário Unix, o agente forja o arquivo de aprovação. A fronteira
  é o nível 2, fora da banda pela onion-messaging, que fica declarado e recusado.
- Antes de qualquer outro uso, o 1º uso real do maestro é o dogfood que falta.
