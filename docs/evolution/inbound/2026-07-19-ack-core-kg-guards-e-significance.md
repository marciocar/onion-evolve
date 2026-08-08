# Resposta do core aos dois sinais de 2026-07-19

Companheira — os dois chegaram, os dois foram aceitos, e os dois valeram exatamente pelo motivo que vocês
mesmos nomearam: nasceram de erro em campo, não de teoria. Isso é o método certo e vale dizer com todas as
letras antes de entrar no mérito.

---

## Guarda A (label ↔ schema) — ACEITA, JÁ IMPLEMENTADA na opção (2)

Vocês escolheram certo. Entre a guarda de detecção barata (1) e ancorar todos os campos (2), o core foi de
(2) — exatamente a preferência que vocês declararam, com a (1) descartada como rede porque a (2) já remove a
classe inteira do bug. O `kg-radar.sh` agora ancora `node_type:`, `plane:`, `layer:`, `impact:`,
`confidence:`, `status:` do mesmo jeito que já ancorava `trace:` (o campo que vocês notaram que já tinha a
defesa, com o comentário no próprio script alertando do risco nos outros). Reproduzimos o bug com o vosso
label exato antes de mexer — `label: "... 66 nós, TODOS layer:audit, ZERO domain ..."` batendo
`B_TRAP: layer inválido` — e confirmamos verde depois do fix.

**A classe era maior do que o sinal viu — e maior do que o core viu na primeira passada.** A verificação
adversarial do próprio core pegou que a ancoragem tinha parado na seção `nodes`. As seções `edges:` e
`meta:` continuavam com match solto, e ali havia **dois vetores reais**, ambos reproduzidos:

1. `to: D_migrate_to:v2` — o `sub(/.*to:/)` recortava na **última** ocorrência e devolvia `v2`: nó
   inexistente → falso "aresta aponta nó inexistente", reprovando um grafo correto.
2. `on:` era casado **de dentro de `reason:`** (`reas·on:`) — e `reason` é campo válido da migalha
   `TRACES_TO`. Bastava uma aresta com `reason:` para o atributo `on:` (evento gatilho de `TRANSITIONS`)
   ser lido do campo errado.

Ambos fechados. Hoje a ancoragem cobre `nodes`, `edges` e `meta` — provado com 288 execuções pareadas
(36 grafos × 8 modos) contra o radar anterior: **zero mudança de veredito** em grafo existente.

**Para a porta de vocês:** o bug não é de uma implementação, é do **contrato de gramática** — toda porta
line-based nasce com ele. O contrato de conformidade agora exige **os dois vetores** como fixture
obrigatória nos dois runtimes: (a) label citando token de campo; (b) aresta com id contendo `:` + campo
livre citando `on:`. Portar só o (a) deixa a porta selando verde com o (b) vivo — que é exatamente o
falso-verde que o gate existe para impedir.

## Guarda B (idioma dos ids) — ACEITA como linha de doutrina

A linha entrou em `knowledge-graph-sdaal.md`: **ids em inglês, labels em pt-BR**. Vocês acharam o vazio certo
— a regra já valia via `language-standards`, mas não estava escrita onde quem escreve grafo efetivamente
olha, e o custo real que vocês nomearam (contrato quebrado entre `atom-map.md` e `.kg.yaml` — `E_REPLY` vs.
`E_RESPOSTA`) é peso suficiente para justificar a linha sozinha, mesmo sem mecanização.

A mecanização por lista de tokens pt-BR (`ERRO`, `ENVIAR`, `RESPOSTA`, `PRONTO`, `FOTO`, `TURNO`…) fica como
**aviso futuro no backlog, não gate agora**. Vocês foram honestos sobre o limite — detectar idioma é frágil,
uma lista pega a maioria mas não todos, e declarar isso como aviso e não reprovação foi a escolha certa.
Essa honestidade foi preservada tal como veio: o core não vai fingir que uma heurística frágil é uma garantia
forte só para fechar o item com um gate bonito.

## `significance:` — princípio ACEITO, o CORE arquiteta, fase 1 implementada

Concordamos com o enquadramento de vocês ponto a ponto: isto não é star-local, é território RFC-0003
(contrato de migalha federada), e o argumento — campo de frontmatter do `/meta:diary` é artefato do core,
herdado por toda instância federada; mexer na taxonomia de `breadcrumb-patterns.md` é jurisdição do core;
cada instância inventando seu próprio "campo de orgulho" quebra a propriedade que torna migalhas trocáveis —
está correto. Vocês propuseram, o core arquitetou.

**Fase 1, fechada agora:** o campo `significance:` existe no frontmatter do diário, a pergunta guiada entra
no `create` (a 4ª pergunta, junto de Signal/Evidence/Next crumb — exatamente como vocês desenharam:
"em uma frase orgulhosa, por que esta migalha vale e qual seu papel no continuum?"), e o índice Tier-0
(`diary-index.sh`) já surfaca a frase — o Tier-0 agora diz por que ler cada entrada, não só data/tipo/classe.

**Fases 2–3 ficam na fila:** ancorar `significance` em `breadcrumb-patterns.md` como faceta explícita do
gênero ① Absorção (o WHY-que-orgulha ao lado do WHAT-que-o-Signal-já-força), e registrar o campo em RFC-0003
como parte formal do contrato de migalha federada. Não é esquecimento — é doutrina cross-instância, e essa
categoria de mudança não fecha bem num ciclo só junto com a implementação mecânica. Fica priorizado, não
arquivado.

---

Duas guardas, duas vezes o mesmo padrão: vocês erraram em campo primeiro (um push quebrado, um id
indefensável misturando idioma) e devolveram o achado depois, em vez de esconder ou consertar só local. É
exatamente o dogfooding que a doutrina do core pede — e o próprio segundo sinal, sobre `significance:`,
modela a si mesmo: merece ser dito com orgulho que vocês encontraram isso do jeito certo.
