---
branch: feat/a2a-queue-live
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 12
findings_real: 12
tokens: 152017
duration_min: 9
findings_fixed: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "subagente general-purpose (opus), mandato REFUTAR"
nota: "3 ALTA (2 pré-existentes), 4 MÉDIA, 5 BAIXA, todos medidos. 8 foram curados na branch com caso. 4 ficam declarados: interpretador e afins fora do juiz, versionado sem exigir árvore limpa, modo de teste ligado por env $(cat …) e o --force-unaccepted, que fica ao alcance da sessão por desenho."
---

# Passada adversarial: `feat/a2a-queue-live`

## O que muda

O wrapper core-only `ops/a2a-queue-live.sh` é o caminho de escrita na fila A2A do bridge de produção que o veto do MOAT deixa passar. A fila é `data/a2a-pending`: a do core fica na raiz e a de cada hub num subdiretório.

O wrapper tem três subcomandos:
- **list**: mostra os registros sem o corpo do sinal.
- **show**: faz uma cópia 0600 do registro, que é o que o `a2a-accept.sh` lê.
- **archive**: faz `mv` para `_archived/`. Nunca apaga. Tem trava, ensaio por padrão, backup, prova por conjunto, contagem e sha256, `archive.log` e rollback impresso.

O archive só move registro aceito, isto é, cujo `taskId` está sob `verificacao:` num frontmatter fechado do inbox do core. Fora disso, só com `--force-unaccepted` e motivo.

Mudanças no MOAT:
- A linha nova do `ops/moat-targets.tsv` nomeia o wrapper da fila.
- O juiz fecha `ONION_A2A_QUEUE_TEST` na linha de comando.
- O juiz fecha a cópia não versionada do wrapper, reconhecida pelo nome.

Bancada: família `a2a_queue_live`, casos (q1)–(q29), e `moat_gate`, casos (p1)–(p7).

Conferido contra os `confirmed` do grafo que este PR edita:
- `E_WRAPPER_DO_CONVITE_DE_PRODUCAO`: o molde, seguido na forma.
- `C_CONFIANCA_VALE_NO_CLONE_SERVIDO`: não se aplica. Este wrapper não depende do clone servido; ele lê a fila e o inbox do checkout do operador.

Nenhum dos dois é contrariado.

## Achados

1. **ALTA, curado (trocado).** O 1º fecho do juiz, "função que embrulha sudo", era guarda por vocabulário. Passavam array, alias, `s\udo`, `su''do`, função com mais de 600 caracteres e `python3 -c`. Agora o fecho é pela cópia do wrapper, reconhecida pelo nome, e a classe geral fica como teto declarado. Casos (p6) e (p7).
2. **ALTA, pré-existente, declarado.** Ficam fora do juiz:
   - `sudo -u <conta>` com `python3 -c`, `perl -e` ou `node -e`;
   - `rsync --remove-source-files`;
   - `tar --remove-files`;
   - `sh -c` com o alvo em `$0`;
   - `awk system()`.

   O cabeçalho do wrapper deixou de dizer "único caminho" sem qualificação.
3. **ALTA, pré-existente, declarado.** "Versionado" quer dizer rastreado, não rastreado e limpo. Um wrapper rastreado e editado sem commit passa no juiz. Em produção, o próprio wrapper recusa rodar sujo, mas essa checagem é o script atestando a si mesmo.
4. **MÉDIA, declarado (mesma classe do `ONION_A2A_LIVE_TEST`).** O modo de teste ligado por `env $(cat …)`, `export ${V}_TEST` ou `read` passa no hook e roda o backup nomeado pelo ambiente.
5. **MÉDIA, curado.** Havia corrida com o bridge: um registro que chegava durante o `mv` dava falha falsa, e o rollback impresso desfazia um arquivamento correto. Agora a fila é medida como conjunto. Registro que chega não é falha; registro alheio que some é. Casos (q24) e (q25).
6. **MÉDIA, curado.** Falso positivo do 1º fecho: diagnóstico só de leitura vendorizado nos adotantes, com `_dk(){ docker … || sudo -n docker …; }`, era vetado. Caso (p7).
7. **MÉDIA, curado.** O (q14) não provava a contagem. A prova agora é por conjunto, (q24) e (q25), e por sha256, (q23), cada uma com seu mutante. O (q14) foi renomeado para o que de fato prova.
8. **BAIXA, curado.** `_archived` ou a fila do receptor como symlink eram seguidos. Agora são recusados. Caso (q26).
9. **BAIXA, curado.** Contava como aceite um frontmatter sem fechamento, ou um `taskId:` sob qualquer chave. Agora vale só sob `verificacao:` num frontmatter fechado. Casos (q9) e (q27).
10. **BAIXA, curado.** Um taskId com tab ou quebra de linha injetava linha no `archive.log`. Agora o taskId fora da forma do UUID conta como ausente. Caso (q28).
11. **BAIXA, curado.** O `list` em texto imprimia sequência ANSI vinda do remetente. Agora os campos saem sem caractere de controle. Caso (q29).
12. **BAIXA, por desenho.** O `--force-unaccepted` fica ao alcance da sessão com qualquer motivo de 8 caracteres ou mais. É o pedido da tarefa, e o motivo fica no `archive.log`.

## Mutantes

Cada caso tem mutante executado na própria bancada (`_prove_mutation`). Resultado de `LC_ALL=C bash .claude/validation/lint-selftest.sh --families moat_gate,a2a_invite_live,a2a_queue_live`: 241 passaram, 0 falharam.

Plantei 16 mutantes com `ops/mutate-and-restore.sh` (core-only) no wrapper e no juiz reais, e todos derrubaram a família (rc 1):
- **wrapper, ensaio e aceite**: o ensaio, o ramo do force e o `mv` trocado por `cp`;
- **wrapper, recusas**: o symlink do registro, o backup, o destino existente, a trava, a forma do registro, o aceite do hub e o `_archived` como symlink;
- **wrapper, provas**: a perda na fila, o frontmatter fechado e o sha256;
- **juiz**: o fecho do modo de teste, o fecho pós-análise e a lista dos wrappers.

Restauração conferida: `grep -c ONION_MUTANTE` = 0 nos dois arquivos.

## Limites declarados

- **NÃO MEDIDO: o arquivamento na fila de produção.** É a prova viva da sessão principal depois do merge, com os 2 registros de teste do `maestro-notebook-test` de 2026-10-15. Desses, um tem o aceite no inbox (taskId `2f472a20…`) e o outro não (`64e63ca5…`).
- **NÃO MEDIDO: o backup real.** O `sudo bridge-backup.sh` dentro do wrapper não rodou; na bancada o backup é stub.
- **Override da fila não medido.** O caminho da fila é o default do bridge sob o `WorkingDirectory` da unidade, e o unit não tem override. O `.env` do bridge não foi lido, porque a guarda o barra.
- **Registro de hub.** Conta como não aceito, porque o hub aceita no repo dele, que este wrapper não lê.
