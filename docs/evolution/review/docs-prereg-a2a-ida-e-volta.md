---
branch: docs/prereg-a2a-ida-e-volta
pr: 1395
date: 2026-10-27
reviewed_diff_sha256: 4db98c7e737ec70433cd9135a82431754061fd8019505665c00505a9bbd46e1d
reviewed_code_sha256: 83b3ac3f9ed4069cfa8c4493bf47fe8cda41ec02e96ebdb2054ca1aaa95c7cf0
findings_total: 15
findings_real: 15
tokens: 100434
duration_min: 4
findings_fixed: 15
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: code-reviewer (agente novo com brief, sem a conclusão do autor)
nota: "Um refutador leu o pré-registro, o card e o nó novo contra os scripts reusados, os grafos do spike e o SPIKE-PROTOCOL antes do 1º commit. Achou 14 defeitos (3 bloqueantes) mais uma observação de segurança, contada como o 15º. Todos foram curados antes de o pré-registro entrar no git, então não há emenda: o texto commitado já é o curado. Os tokens e a duração são do refutador."
---

# Passada adversarial: `docs/prereg-a2a-ida-e-volta`

## O que muda

- O pré-registro da ida e volta viva do A2A entre a VPS do core e o notebook do maestro, pela composição do Onion. O teste não roda neste PR.
- O card do maestro, na forma da cláusula 8 da doutrina do `/meta:decide`.
- A allowlist do juiz de tentativas.
- Um nó de evidência no grafo de sinais de campo, ligado à pergunta da medida, que segue aberta.

O complemento do maestro (a entrega com o destino fechado, no canal nativo e no receptor A2A) entrou depois da passada. Ele foi conferido à mão contra a linha 30 da seção 2.1.261 do CHANGELOG oficial e contra o `a2a-accept.sh`, que é idempotente por `jti` e `taskId` (l.37).

## Achados

| # | Achado | Sev. | Destino |
|---|---|---|---|
| 1 | A retirada da perna 1 não fechava: o `fetch-replies.sh` só termina numa `reply` com `in_reply_to` no `sent.tsv` (l.107 e l.113) | bloqueante | curado: o modo `--until-jti` para `kind question` virou item 7 do contrato da peça, e o critério passou a ser o `[ok]` daquele `jti` |
| 2 | O ssh e o scp rodavam como `a2a-peer`, mas quem tem o ssh é o `marciocar` (§12.14 do spike), e isso contradizia o §6 | bloqueante | curado: a retirada roda como `marciocar`; o token e o envelope chegam ao `a2a-peer` por `sudo install` |
| 3 | A tese "por construção" valia com o `Bash` na sessão, no mesmo usuário do SO que é dono da chave e do token | bloqueante | curado: a sessão abre com `--tools ""` e `--strict-mcp-config`; o resto (mesmo usuário do SO) fica declarado no §1 e no §7 |
| 4 | A causa do AGIU do degrau B estava errada: foi o `Bash` composto e o `ToolSearch`, não a `reply` | importante | curado: a causa foi citada com o nó |
| 5 | A allowlist sem o `ToolSearch` repetia o defeito já curado pela Emenda 12.15 | importante | curado: a allowlist em TSV entrou no PR, com a linha `select:` |
| 6 | A adaptação do juiz ficava em aberto | importante | curado: item 8 do contrato (prefixo, papel do `reply` e o sem-diálogo por passo) |
| 7 | O modo de permissão não estava fixado no P1, no P4 e no P10, e o `defaultMode` da VPS é bypass | importante | curado: o modo vai explícito por passo, junto com o `--expect-mode` do juiz |
| 8 | O P10 do lado do core não tinha por onde ler, e o `read_inbox` podia entregar envelope reprovado | importante | curado: o item 5 diz de onde lê cada ponta, só material verificado |
| 9 | As fotos `rt-p10` e `rt-fim` eram comparadas sem nenhum passo que as tirasse | importante | curado: entraram os `--label` e o `--project` |
| 10 | S2 e FALHA-AUTOENVIO não tinham instrumento | importante | curado: contagem do outbox e da fila antes e depois, e o gravador em todos os passos |
| 11 | S1 e S4 apontavam campos que o aceite não grava | importante | curado: entrou o decodificador do JWS do registro |
| 12 | A comparação de portas daria falso positivo no Windows | menor | curado: compara-se o conjunto de pares fora do loopback, com atribuição a processo |
| 13 | A janela de 10 min contava o tempo humano | menor | curado: a contagem vai do `iat`, e a retirada começa antes do envio |
| 14 | O label do nó dizia "cinco" modos de falha, mas eram seis | menor | curado (com o complemento, são oito) |
| 15 | O token ficava na conta das sessões do core, e o card prometia rodar o doctor com `--invites` | menor | curado: o risco foi declarado no §6, os cards 2 e 3 viraram uma sequência, e a conferência passou a ser o `a2a-invite-live.sh list` |

## Mutantes

Não se aplica: o PR não tem código executável. O que serve de prova está noutros instrumentos:

- o radar `--integrity --schema` sai com exit 0 no grafo de sinais de campo;
- o `kg-contract-check.sh` dá rc 0;
- o REGRA 29 (Gate de PROVENIÊNCIA INVERTIDO, com catraca) reprovou o card enquanto ele não estava no `trace` do nó, e foi curado.

## Limites declarados

- O refutador não rodou nenhum passo vivo, e nem havia o que rodar: a peça de rascunho não existe.
- O complemento do destino fechado (P12 e P13) não passou pelo refutador.
- O tempo de vida da fila do canal nativo não tem âncora documental.
