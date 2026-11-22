---
branch: docs/a2a-roundtrip-measure
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 9
findings_blocking: 4
tokens: 143581
duration_min: 4
findings_fixed: 9
verdict: FIXED
elenxo: true
reviewer: "subagente general-purpose (opus), mandato REFUTAR, só leitura, reproduziu o ensaio num diretório próprio"
nota: "O refutador revisou o 1º commit. As curas reescreveram o bridge simulado, o rehearsal.sh (agora com asserções) e o nó de evidência, e o ensaio foi rodado de novo: 55 asserções passam e 0 falham, e o mutante do guard reprova com 5."
---

# Passada adversarial: `docs/a2a-roundtrip-measure`

## O que muda

O PR traz um ensaio local da composição A2A do core, com os scripts em
`docs/evolution/research/a2a-composition-roundtrip-local-2026-11/rehearsal/` e as saídas versionadas como `.txt`.
No grafo `sinais-de-campo-2026-09`, ganha dois nós e duas arestas:

- `E_COMPOSICAO_ENSAIO_LOCAL_SEM_CODEX_1122`, a evidência por etapa;
- `Q_COMPOSICAO_PERNA_CODEX_LACUNA_1122`, a lacuna da ponta Codex, com o pedido pronto ao maestro.

O PR não muda motor, guarda nem hook.

## Achados

1. **(média, bloqueava) O bridge citado como espelho não era o certo.** A cópia local 7e736ba é anterior à F3 e não tem o convite por membro. Contra o bridge atual, os vetos N2a e N2b sairiam no guard, com 401.
   - **Cura:** o `bridge_sim.py` agora espelha o 5c1ba8d: guard de convite por membro, veredito estrito com exit 0 e eco do receptor. O convite é criado pelo `a2a-invite.sh` real, e o aceite roda com `--invites`.
   - Os negativos ficaram assim: N2a e N2b dão 401 no guard, e o gate é medido à parte como defesa em profundidade. Entrou um negativo novo, a N3d (convite revogado).
   - O que a simulação não espelha está declarado no cabeçalho do script e no nó.
2. **(média, bloqueava) O motivo da N2b estava errado.** O veto vem da regra de papel ("standalone não tem canal lateral"), não da falta de aresta.
   - **Cura:** a asserção confere esse texto no `trust-topology-check.sh`. A aresta isolada está na lista "NÃO medido".
3. **(média, bloqueava) A N2a passava por um caminho de erro.** O trust-check saía com rc 2 (membro não encontrado), e o "pior caso" do JWKS era inócuo.
   - **Cura:** a asserção confere o rc 2, e o nó diz que é caminho de erro, não negação de política. O pino do JWKS ficou só na N2c.
4. **(média, bloqueava) O rótulo generalizava "duas pernas".** A perna B não passa pela composição. Além disso, a thread vinha de um arquivo do par.
   - **Cura:** o rótulo e o cabeçalho distinguem as pernas. A thread invisível ao core virou ACHADO DA COMPOSIÇÃO no nó, com asserção (`thread -`).
5. **(baixa) O rc 0 não atestava nada, e a saída não era "inteira".**
   - **Cura:** cada etapa tem asserção (`expect`), e o rc final é o número de falhas. O texto diz "caminhos do scratch saneados".
6. **(baixa) O `head` cortava a evidência** da moldura dupla, do -32601 e do motivo da N5, e a 1ª rodada não estava versionada.
   - **Cura:** todos viraram asserções. A saída da 1ª rodada foi versionada (`run-2026-11-22-umask002.txt`).
7. **(baixa) A contagem dos negativos estava errada.**
   - **Cura:** o nó não conta mais "dez"; a contagem sai do log de asserções.
8. **(baixa) A etapa 5 é trivial por construção.**
   - **Cura:** está declarada no nó como "só mostra que o MCP não lê a fila".
9. **(baixa) A varredura da N4 tinha escopo estreito.**
   - **Cura:** a `write_file` mira um caminho de sonda FORA do diretório do ensaio, e a asserção confere que ele fica ausente. A afirmação foi limitada ao que se mede.

## Mutantes

- Cópia do rehearsal com o guard do bridge desligado (`why = None`): sai com rc 5, porque reprovam N2a (2 asserções), N2b, N2d e N3d. A saída está em `run-2026-11-22-mutant-guard-off.txt`.
- Não houve mutante do `a2a-rt-mcp.py`, porque o ensaio resolve o MCP pelo checkout do core. Um mutante dele exigiria uma cópia do checkout inteiro. A superfície do MCP já é coberta pela bancada `run_a2a_rt_selftests`.

## Limites declarados

- **A ponta Codex não foi medida**, porque o CLI não está instalado. O pedido de instalação e de uso do login existente está na `Q_COMPOSICAO_PERNA_CODEX_LACUNA_1122`, com o maestro.
- **O bridge e o aceite humano são simulados.** O envio humano recusa dentro da sessão (rc 4) e foi substituído pelo motor que ele chama.
- **Não medidos:** o envio automático ao fim da sessão, o pareamento e o P5.
