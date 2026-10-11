---
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 10
tokens: 170004
duration_min: 6
verdict: APROVADO
elenxo: sim
nota: >
  O refutador (general-purpose, opus) começou pelo default REPROVADO. O mandato era achar afirmação não
  medida nos quatro nós novos do SAC-100, e ele re-mediu todas as afirmações de produção: as linhas do
  código, o hash do identity.ts, ss, iptables-save, a config viva do Caddy, o TLS, a contraprova do
  /console e a sonda do JWKS, que ele rodou de novo. Saiu REPROVADO por um único bloqueante, o
  SUPERSEDES com o alvo aberto, e por 9 achados menores. Os 10 foram tratados no mesmo laço. O
  bloqueante foi respondido por escrito, porque o flip do nó selado é do maestro. APROVADO descreve o
  estado depois das curas.
  Depois do PR aberto, o maestro selou os três flips (console → superseded, JWKS → done, bypass →
  drifted) e o contexto principal os aplicou e rebaseou sobre a main; revisto, só status nos 3 nós.
---

# Resíduo — `docs/kg-security-remeasure-sac100`

O SAC-100 re-mede contra o vivo os três nós de segurança que a O4 tirou de PROD como testemunho
datado. A medição foi feita por comportamento e código, sem ler `.env` nem segredo.

| # | achado | desfecho |
|---|---|---|
| 1 | BLOQUEANTE: `E_CONSOLE_… SUPERSEDES I_CONSOLE_DO_LOGTO_ESTA_PUBLICO`, e o alvo seguiu `open` | Justificado por escrito no nó novo. O alvo já está selado na base, então o flip para `superseded` não cabe na exceção §4.1 e vai como proposta ao maestro. O aviso do radar é o estado esperado até o selo. |
| 2 | o mtime de 08-10 foi lido como data do desligamento | Curado. O nó cita o stat: Modify 08-10 e Change 09-06. O `mv` preserva o mtime, e o reverify de 08-23 ainda via o console ligado, então o desligamento é de 08-23 a 09-06, provavelmente 09-06. |
| 3 | "HOST não está definida" era inferência | Curado: o texto agora diz "HOST não é 127.0.0.1 (ausente ou 0.0.0.0; .env não lido)". |
| 4 | a narrative dizia "DERRUBA" com aresta CONSTRAINS | Curado: o texto agora diz "RESTRINGE". O CONSTRAINS fica justificado pelo nó composto com a parte (1) não medida, e o flip para `drifted` vai como proposta ao maestro. |
| 5 | o 4º item da contenção ("sem credencial de outro tenant") ficou sem declarar | Curado: o item entrou como parcial, citando o código (chat.ts l.307-323 e l.488, agentEnv com a isenção declarada da ANTHROPIC_API_KEY). O conteúdo do ambiente não foi lido. |
| 6 | o método do journal não dizia que usou sudo | Curado: o texto diz `sudo -n journalctl`, e o nó registra que sem sudo o vazio é falso. |
| 7 | a janela de 60 s foi arredondada para cima (a sonda cobria ~5 s) | Curado com medição: uma 2ª sonda deu 1 fetch em t=59 s e 2 fetches em t=61,5 s. O piso libera a tentativa e não trava. |
| 8 | o Q_BYPASS afirmava ausência absoluta de medida | Curado: o texto agora diz "nenhuma das medidas tentadas" e lista uma candidata não medida (o argv do subprocesso `claude`). |
| 9 | a renomeação para `x_reverify_note` deixou 3 rótulos com "ver reverify_note" | Curado: os 3 ponteiros foram atualizados. A renomeação fica no PR porque era MUST herdado do contrato no grafo tocado: sem ela, `kg-contract-check` saía rc 1. |
| 10 | o /health público expõe o `onionCwd`, um caminho absoluto | Registrado na narrative do E_BYPASS, com cura proposta no relatório. |

Gates finais nos três grafos tocados: `kg-radar --integrity --schema` com rc 0, `kg-contract-check` com rc 0
e `kg-machine-path-check` com 0 acusações. A catraca `.kg-ssot/gate.json` trava o ganho do grafo do M2,
que agora passa no MUST.
