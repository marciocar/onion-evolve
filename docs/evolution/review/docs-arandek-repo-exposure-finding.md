---
reviewed_diff_sha256: 3283964de56228e73e3862f2bda9ad1af8e5636590649192720b42f35c7df0db
findings_total: 5
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 6
verdict: conforme
reviewer: claude-opus-5
---

# Revisão adversarial — `docs/arandek-repo-exposure-finding`

Dois nós novos, duas arestas e um documento de handoff. Ataquei as afirmações antes de commitar.

## Achado 1 — REAL, corrigido: citei um nó que não existe

O rótulo apontava para `[C_DOCKER_FURA_O_UFW]`. Esse id **não existe no grafo** — inventei uma
referência que soava plausível. `grep '^\s*- id:'` mostrou o nó real: `C_REDE_ISOLADA_POR_CONSTRUCAO`.

Referência inventada é pior que referência ausente: ela **passa no radar** (não há checagem de id
citado dentro de `label:`) e manda a sessão futura procurar um nó fantasma. Corrigido para o id real,
e a aresta `CONSTRAINS` agora torna a ligação estrutural em vez de textual.

## Achado 2 — REAL, corrigido: o `grep` de portas voltou vazio e quase virou conclusão

Meu primeiro padrão exigia `"` ou dígito depois de `- `. O arquivo usa **aspas simples**
(`- '9090:9000'`). Zero linhas → quase escrevi *"ele não publica nada"*, que teria invertido o achado
inteiro. **Terceira ocorrência no mesmo dia** da mesma classe: guarda de branch, palavras pt-BR,
escopo de backup — e agora esta. Está registrada como nota de método no documento, porque a lição vale
mais que o achado.

## Achado 3 — REAL, corrigido: segredos de adotante não entram no core

A primeira versão do documento ia citar os valores literais para tornar o recado auto-suficiente.
Isso publicaria segredo de terceiro em repo que não é dele — e o histórico do core é durável. Trocado
por **linha + nome da chave**, que basta para localizar. O recado enviado também usa `<valor>` em vez
do literal.

## Achado 4 — INVESTIGADO, não é defeito: o nó da lacuna de mecanismo poderia ser decisão

Testei se `Q_GUARDA_DE_EXPOSICAO_SO_OLHA_PARA_DENTRO` deveria já nascer como `decision` com a regra de
lint desenhada. Não: por [[gated-work-derives-fresh]], trabalho gated não se pré-cozinha, e o gatilho
declarado (**o segundo adotante com o mesmo defeito**) ainda não disparou. Fica `question` com
candidato nomeado e gatilho explícito. Segue.

## Achado 5 — REAL, corrigido pelo GATE, não por mim: proveniência invertida

O `pre-commit` bloqueou com `[proveniência-invertida/NEW]`: documento de análise novo **sem nó que o
cite** em `trace:`/`evidence:`. Eu tinha escrito a ligação nos dois sentidos em **prosa** — o `label:`
menciona o arquivo, o arquivo menciona os nós — e prosa não é aresta. Corrigido com `trace:` inline
nos dois nós.

Vale registrar *como* isto foi pego: eu li `commit rc=1` **porque medi o código de saída**. O `push`
logo em seguida devolveu sucesso e teria criado a branch sem o commit — verde por cima de nada. É
literalmente [[exit-code-nao-e-a-verificacao]] operando a meu favor no mesmo dia em que a escrevi.

## O que este registro deliberadamente NÃO afirma

**Que o arandek está exposto.** Medi o arquivo dele e o comportamento Docker/ufw *nesta* VPS. A infra
onde ele sobe não foi medida — atrás de NAT ou firewall de nuvem o risco real é menor. O documento
diz isso em seção própria, e o recado está redigido como *"no teu repo, num host público"*.

**Que o recado foi enviado.** Está redigido, não comunicado. O documento abre mandando a sessão futura
**perguntar antes de reenviar**.

**Radar:** exit 0 medido sem pipe (25 nós, 21 arestas, zero contradição estrutural).
