# 🔄 Doutrina do /meta:cc-update — a atualização do Claude Code como gatilho de re-medição

Fragmento canônico do [`/meta:cc-update`](../../meta/cc-update.md). A superfície **referencia**, não
copia. Lente de pesquisa que carrega quando a rodada toca `docs/evolution/research/`:
`.claude/rules/research-lens.md`.

**Por que existe, medido em 2026-10-08:** a rodada r8 do radar E3 (`docs/evolution/research/radar-E3-2026-10-08-r8/`)
foi conduzida à mão. O delta saiu de um python avulso, o inventário de hooks foi contado de memória
de leitura, e três ligações item↔Onion entraram no grafo sem medição — o juiz reprovou as três medindo
o vivo. Duas dívidas de forma (chave sem prefixo `x_`, plugin não regenerado) só apareceram no CI. O
procedimento já tinha rodado 8 vezes e não tinha superfície; o maestro decidiu nesse dia: **comando
próprio, script mede, juiz julga, vai até o PR mergeado, ação proposta vira nó + issue**.

## As cláusulas

### 1. Atualização de plataforma é gatilho de ESTRATÉGIA, não só de compatibilidade
Ordem do maestro (2026-08-31): *"sempre tem que ver se as estratégias estão adequadas ou devem ser
alteradas para maximizar a eficiência e eficácia do Claude Code com as etapas e maquinaria do Onion"*.
Checar "nada quebrou" e parar é meia-verificação: uma versão nova pode **oferecer** o que a casa faz
à mão (r8: `onFailure: "block"`, e nenhum dos 20 hooks o usa) ou **tornar obsoleta** uma guarda. O
gatilho é mecânico desde então — a REGRA 65 (Radar de mundo com baseline DATADA por eixo) compara a
`cc_version` do eixo E3 com o binário e emite SOFT quando divergem; o hook de drift avisa na sessão.
Este comando é a **resposta** padronizada a esse aviso.

### 2. O script MEDE, o juiz JULGA — e ninguém troca de papel
- **Medidor** (`.claude/validation/cc-delta-census.sh`, determinístico, sem LLM): versões (baseline,
  disco, processo), as seções do delta copiadas byte a byte do CHANGELOG oficial, o inventário das
  superfícies do Onion e o **esqueleto** do grafo. Ele **não** liga item a superfície: casar por
  palavra-chave fabrica exatamente as três ligações que a r8 teve de reprovar.
- **Rodada** (a sessão): lê o delta, propõe as ligações **medindo o vivo** (`grep` no core, leitura
  do hook, execução), escreve os nós.
- **Juiz** (subagente não-fork, opus, effort high, mandato REFUTAR): confere cada citação **byte a
  byte** contra o CHANGELOG oficial, mede cada ligação no vivo e lista o que a rodada **deixou de
  ver**. O veredito é hipótese a verificar, não sentença — mas reprovação sustentada muda o grafo.

### 3. Ligação com o Onion só com medição viva
Afirmar que um item "toca" o Onion exige a evidência no **artefato atual** (caminho, linha, saída de
comando), não a lembrança de como a casa funciona. A r8 reprovou: reescrita de input por PreToolUse
(nenhum hook do core reescreve input), SessionStart async (os do core são síncronos) e a guarda de
modelo diante do Haiku 5.5 (a guarda é allowlist sem haiku). Sem medição, o desfecho correto é
**NÃO-VERIFICADO**, que é lista de 1ª classe na SYNTHESIS.

### 4. A Aufhebung é decidida pela rodada, na forma de extensão do contrato
O esqueleto nasce **sem** a chave de superação, e a REGRA 89 (Rodada de radar selada reconcilia o
corpus que superou (Aufhebung), com catraca) acusa até a rodada decidir. As formas aceitas são
`meta.x_supersedes_external` (a rodada supera grafo anterior, nomeado) ou `meta.x_supersedes_none`
(com a razão). A forma sem prefixo é chave desconhecida para o contrato v3 do `.kg.yaml` e reprova no
gate do CI — medido na própria r8. Rodada que só **acrescenta** versões à anterior normalmente é
`x_supersedes_none`: o juiz da r8 reprovou um `supersedes` sobre a r7 por isso.

### 5. Ação proposta não se implementa aqui
Cada ação que a rodada propõe vira **nó `question` aberto** no grafo + **issue no Linear** (projeto
"Onion — core: próximas levas") pelo adapter do task manager. Implementar no mesmo PR mistura medição
com mudança e tira do maestro a decisão. O adapter executável do task manager ainda é **prosa**
(SAC-65): a criação da issue segue o adapter doc e se declara assim, sem fingir mecanismo.

### 6. A selagem é atômica
Grafo da rodada + `data/` + SYNTHESIS (com o contrato de custo: `run_id` · `tokens` · `agents` ·
`duration_min`) + a baseline do E3 em `docs/onion/radar-baselines.yaml` (`last_run`, `cc_version`,
`kg`, `descartes`) vão no **mesmo commit**. Selar a baseline sem o grafo cala o aviso de drift sem a
medição que o justificaria.

## O que esta doutrina NÃO promete

- **Não implementa ações.** Mede, julga, registra e propõe; mudar hook, guarda ou regra é outra leva.
- **Não garante a doc oficial.** A documentação de referência pode **atrasar** o CHANGELOG: na r8 o
  `onFailure` estava no CHANGELOG e em nenhuma página de hooks. A fonte primária do delta é o
  CHANGELOG; capacidade só citada lá entra com essa ressalva e com medição ao vivo como condição.
- **Não mede capacidade que o processo não tem.** Se o processo está numa versão anterior à do disco,
  o que só existe na nova está invisível nesta sessão: reinicie antes de medir comportamento.
- **Não substitui o juiz por regex.** O sinal de ids de modelo fora da allowlist é fato, não ligação.
- **Não roda offline.** Sem o CHANGELOG oficial o medidor sai rc 2 e declara a lacuna; nunca
  reconstrói o delta de memória.
