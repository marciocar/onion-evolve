---
branch: chore/inbox-triage-1108
pr: 1555
date: 2026-11-09
reviewed_diff_sha256: 69c1ef331c059858c53da0b0ae83d0fa1dcbe41f9ac3cea1e10efe15f9767829
reviewed_code_sha256: 5e624934e929bcd2f97c69b338c1cfb099fa572eeda04b2fbba6d5ab20bc1ffb
findings_total: 12
findings_real: 12
findings_blocking: 1
tokens: 0
duration_min: 40
findings_fixed: 12
verdict: FIXED
elenxo: false
elenxo_isolado: false
reviewer: "1ª passada: o próprio agente de execução; 2ª passada: refutador separado, que não escreveu o diff, com 1 bloqueio e 6 ressalvas, curados pelo agente"
nota: "tokens = 0: não medido. O refutador não é o Elenxo de workflow, por isso elenxo: false. Medidos: --selftest do check 20/20, família relay_public da bancada verde com 8 mutantes novos no check e 2 no portão de papel, radar 0, contrato ok."
---

# Passada adversarial: `chore/inbox-triage-1108`

## O que muda

- Triagem dos 9 sinais do inbox do core; tratados em `_processed/`, os dois do sandbox como forma-resumo.
- REGRA 113 (Sinal relayado a destino público só se commita revisado): no papel source, sinal novo sem a chave
  passa a ser HARD (`sem-marca`), a partir do corte de 2026-11-09.
- Doutrina de dissecação: o campo `onion` é julgamento, o `min_count` útil com `--around`, os três checadores.
- Grafo `inbox-triage-1108` com 2 selos e 8 perguntas, com espelho SAC-374 a SAC-381.

## Veredito por sinal

| Sinal | Veredito |
|---|---|
| WAHA | já tratado, PR #1553 |
| Quatro campos e REGRA 113 | feature selada em parte; a lacuna entregue aqui |
| Codex e MCP por arquivo | já tratado no anúncio; o nó ganhou as duas lacunas aqui |
| Quadro e operação | fix aqui (doutrina) e backlog (guarda de resíduo); o resto informativo |
| Lacunas da campainha | já tratado, PR #1544 e PRs #9 e #10 do onion-messaging |
| Vigia | já tratado, PR #8 do onion-messaging |
| Fila e campainha | backlog, 3 perguntas e 1 do maestro |
| Sandbox F8 | fix em backlog (`Q_IT_SYNC_MAIN_WRITE_PREFLIGHT`); adoção é do maestro |
| Re-medida do sandbox | informativo |

## Achados

1. BANCADA NO ADOTANTE: a família `relay_public` não é core-only, e o caso (j2) reprovaria na cópia vendorizada, onde
   o dispatcher não liga a exigência. O caso passou a esperar o silêncio fora do papel source.
2. RESPOSTA SEM LASTRO: o anúncio anterior disse que as lacunas do Codex e do MCP iam para a
   `Q_ONION_CORE_PORTS_MULTI_MODEL_2026_11`, e o nó não as citava. Escritas no nó.
3. VAZAMENTO AO RE-COMMITAR: o sinal do hub trazia caminho de máquina, e dois sinais o id do membro hub. Trocados.
4. CONTAGEM ERRADA: a evidência dizia 3 atendidos e 5 com trabalho; a tabela dá 4 e 4. Corrigido.
5. CONTRATO: `provenance.method` dos dois selos fora do padrão. Corrigido.

## Achados do refutador (2ª passada)

6. BLOQUEIO: o anúncio ao hub dizia «dois PRs abertos» e mandava testar branches que não existem mais; os #9 e #10 entraram. Reescrito para a main do onion-messaging.
7. Notas de triagem com «em aberto» desatualizado. Corrigidas nas linhas do core; o texto do remetente ficou intacto. Os 4 `Q_DB_*` fechados pelo merge das curas, e a metade do core da lacuna 2 virou `Q_DB_EXPIRED_CORE_HALF`.
8. Portão de papel do dispatcher sem mutante. Caso (j3), com dispatcher extraído e dois mutantes.
9. Falsos negativos por extensão: `.MD`, `.markdown`, `.txt` e sem extensão. Todos julgados agora, caso (xvi).
10. Corpo com NUL e frontmatter sem `---` de fecho. Casos (xvii) e (xviii).
11. `README.md` do inbox virava HARD. Isento só no inbox e no `_processed/`, caso (xix).
12. O selo decidia dois itens que a curadoria pôs em «Para o Maestro decidir», sem dizer. O nó diz agora o que foi decidido em nome dele.

## Limites

- O corte é pelo nome do arquivo: nome com data antiga escapa.
- A guarda vê a marca, não o conteúdo.
- Medidas do sandbox, do quadro e da fila são da curadoria, não refeitas.
- Os 4 `Q_DB_*` fecharam pelo merge das curas e leitura do código; a reprodução pelo hub não foi medida pelo core.
