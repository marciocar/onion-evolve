# Mitigação de inferência — defender um KG do motor que o lê (doutrina)

> **Categoria:** concepts · **Status:** doutrina (contrato), mecanismo executável NÃO-embarcado (é do adotante — ver §6).
> **Proveniência:** promovida da pesquisa P4/P5 do programa de KG pessoal (~40 fontes, cada dimensão verificada
> adversarialmente). Esta KB é o **frame geral scrubado**; os específicos de qualquer adotante N=1 ficam privados.
> **Irmã:** [`knowledge-graph-sdaal.md`](knowledge-graph-sdaal.md) (o KG que o motor lê) · [`onion-guardrails.md`](onion-guardrails.md) (R15 — o gate de efeito/proveniência).

## O problema — o transformer que lê o grafo é o risco

Quando um KG concentra a verdade de um domínio (uma vida, uma organização, um cliente) e um LLM legítimo o lê para
servir o dono, o maior risco de privacidade **não** é o dado em repouso nem o operador do host — é o **próprio motor**:
um LLM sobre o KG **deduz o não-declarado** a partir de estilo e tópico, não de strings (Staab et al., *Beyond
Memorization*, ICLR 2024 — até 85% top-1). Cifra em repouso e zero-knowledge no transporte são corretos e necessários,
mas **não tocam** esta camada. A inferência é uma capacidade de raciocínio emergente, não memorização (memorização é ~8%
da superfície real — *Privacy Is Not Just Memorization!*, 2025).

## A verdade governante — feature dentro, perigo na fronteira

O achado que reenquadra tudo (Deng et al., *When Are LLM Inferences Acceptable?*, 2026, prova empírica): o conforto com
a inferência é **3,75/5** quando serve o dono, **2,34/5** quando vai a terceiros; o "creepy corner"
(intrusivo+surpreendente) despenca a **1,74**. Para o dono, inferir **correlaciona com utilidade** (ρ=0,613).

> **O dano é o *cruzamento* da fronteira, não a dedução.** Para o dono, o motor raciocinar sobre o próprio grafo *é o
> produto*. Logo a mitigação **não é impedir o motor de inferir** (impossível, e destrói a feature) — é **governar a
> fronteira de saída e o escopo de cada consulta**. A tensão *raciocínio rico × mínima superfície de inferência* é
> declarada **irreconciliável** na literatura de 2025; não se resolve por um telos ("versão segura final"), **se
> contorna** — deslocando a defesa da redação interna para a fronteira de saída.

## A honestidade dura — o cenário não tem defesa publicada

Aplicada a régua, quase toda defesa forte resolve o **threat model errado** (defender um *release* publicado ou um
adversário *externo*):

| Defesa forte | Contra quem protege | Contra o motor-legítimo-para-o-dono? |
|---|---|---|
| Capability-split (reasoner↔store) | modelo **externo** nunca vê o bruto | **NÃO** — o reasoner *é* o motor local do dono |
| TEE / confidential computing | o **operador** do host/nuvem | **NÃO** — ao contrário, **garante a entrega** ao dono |
| DP (inference-time) | adversário de **extração** | **NÃO** — inferência de atributo é *imputação* por correlação; **N=1 é o pior caso** (sem multidão onde esconder) |
| Machine unlearning | — | **NÃO** — imaturo/contornável; o fato vive no **store re-consultável** (*GraphSteal*, 2026) |
| Anonimização (FgAA, INTACT, TRACE-RPS) | defender um **release** publicado | **NÃO** — ofuscar o grafo que se **quer** reconciliar é autocontraditório |
| MI-regularização em treino (MINE-Reg, 2026) | composição **espacial**: profundidade de pipeline de agentes, por-pedido | **NÃO** — treino-time e sem ledger de runtime; mede outra composição (não a **temporal**, de turnos sobre KG persistente). Detalhe em §O irredutível |

**Scrubbing de PII é comprovadamente inútil aqui:** removido todo PII literal, um Llama-3.3-70B recupera
idade/gênero/país com F1 0,84–0,90, operando sobre estilo e tópico que o filtro nunca toca (*Inferential Privacy
Leakage*, 2026). **k-anonymity/l-diversity/t-closeness falham em grafo denso** (quase-identificadores estruturais
re-identificam). Declarar um KG "à prova de inferência" seria **falsa distinção às avessas**. Só se garante
**não-EMISSÃO** (o destilado não cruza) e **fronteira de acesso**. A inferência interna é indefesa **por construção —
e isso é a feature.**

## As seis camadas negativas na fronteira (o contrato)

A defesa é **negativa** (não dar / não emitir) e começa no **acesso** — a regra-mãe: *a saída não consegue filtrar
uma conclusão que nunca foi string*.

| Camada | Mecanismo (fonte) | O que reduz | O que **NÃO** fecha |
|---|---|---|---|
| **L1 — Escopo de consulta** | schema-masking + fatia-por-propósito (AskSafely); permission-aware retrieval | dá ao motor **só o que o propósito exige**; retém a topologia **rotulada** como sensível | inferência sobre o liberado; topologia **NÃO-rotulada** e a sensibilidade que emerge da **co-ocorrência** de arestas inócuas |
| **L2 — Propósito vinculado** | monitor de traço tipado sobre a **tupla de Integridade Contextual** (categoria-de-dado × propósito × **destinatário**; C-Trace) | rejeita ação/saída **fora do propósito ou para destinatário não autorizado** | inferência **dentro** do propósito |
| **L3 — Filtro por composição** | 2ª camada QI-cluster + CI-CoT | vazamento **por-composição** e literal | conclusão nova nunca-string; **colapsa sob confusão de estilo** (AUROC 0,95→0,72) |
| **L4 — Juiz-de-CI separado** | gerador ≠ porteiro (1-2-3 Check) | o que o gerador (otimizado p/ ajudar) deixa passar | probabilístico (−18/−19pt, não zero) |
| **L5 — Self-red-team** | rodar o **próprio motor como atacante** contra o destilado antes de emitir (FgAA) | vazamento detectável **pré-emissão** | atacante mais forte que o self-red-team; custo 15–20× |
| **L6 — ε-ledger** | débito monotônico por release (DP-Fusion/DP-ICL) | **reconstrução por repetição** no tempo | N=1 é o pior caso — garantia degrada, custo morde |

## O que o Onion já provê que se reaproveita (régua Aristóteles)

A postura do Onion **já é** metade do stack; a arte externa dá o nome técnico. Reusar o que é **igual**, desenhar
fresh o que é **diferente** — nunca reuso preguiçoso nem reinvenção do maduro
([transfer-heuristic-aristotle](transfer-heuristic-aristotle.md)):

| Primitiva Onion | Camada | IGUAL / DIFERENTE |
|---|---|---|
| **`query-gate`** | L1 | IGUAL o gesto / DIFERENTE — falta schema-masking + fatia-por-propósito (hoje recupera "tudo") |
| **`responder-gated`** (gerador≠porteiro) | L4 | IGUAL (já é doutrina) / DIFERENTE — o juiz-de-CI é subagente novo |
| **`de-identification`** (`none` fail-safe) | L3 | IGUAL transporte / DIFERENTE — só pega formato-fixo; precisa 2ª camada whole-graph-aware |
| **`verify-before-act`** | L2/L5 | IGUAL — monitor de propósito + self-red-team ("veredito como hipótese a verificar") já são a postura |
| **`exposes:` + níveis de trust** (RFC-0003) | L1 | IGUAL — aplicados no adapter de recuperação = permission-aware retrieval |
| **fail-safe `none` / abstain** | L3/L4 | IGUAL — "abster para revisão humana" *é* o `none` fail-safe (recusar, não degradar) |
| **guardrails R15** (efeito-gate + proveniência) | fronteira | **MISTO** — IGUAL a forma (predicado tipado, veredito `gate`, fail-safe recusa, deny-by-default do desconhecido) · DIFERENTE o regime (o effect-gate é stateless sobre lista fechada; L2 é stateful sobre eixos abertos). Detalhe em §Contrato →Reúso |

**A descoberta bonita:** o **self-red-team** (L5) — rodar o próprio motor de inferência como atacante contra o
destilado antes de emitir — **é a doutrina de dogfood do Onion aplicada à privacidade**: "veredito de revisor como
hipótese a verificar com evidência", virado guarda de saída. Se o motor deduz o oculto, **não emite**.

## Fronteira core ↔ adotante — quem escreve o quê

Distinção de escopo (decidida em campo, 2026-07-19):

- **A DOUTRINA/contrato é do CORE** — esta KB: o frame das 6 camadas, os limites honestos, o mapa de reúso SDAAL, as
  âncoras de pesquisa. Qualquer adotante de KG-de-vida a **cita**.
- **O SSOT executável é do ADOTANTE** — o mecanismo que integra classificação-por-inferência + gate-por-propósito +
  ε-ledger, rodando sobre o KG **privado**, **nunca** vive no core. Invariante: o KG cru não sai do device/nó
  confiável; o motor local é do adotante (ex.: porta on-device do gate, como o kg-radar multi-runtime de
  [`knowledge-graph-sdaal.md`](knowledge-graph-sdaal.md)). Construir o mecanismo no core violaria a invariante **e**
  seria mecanismo sem consumidor (adotante-KG opera por método-por-referência ou cliente próprio, não por vendorização).
- **Promoção dirigida por dogfood:** cada camada vira doutrina refinada **a partir do uso real** do adotante (o
  de-id v1 → 6 camadas), não à frente dele — a mesma disciplina da promoção dos guardrails R15.

## Contrato de conformidade — L1 e L2 (o que o adotante tem de PROVAR)

O core não implementa o gate (§Fronteira). Mas "o adotante constrói" não pode virar "cada um garante o que
quiser": sem contrato, `declarado≠verificado` volta pela porta de sempre — alguém afirma "temos gate de
propósito" e ninguém consegue contestar. Este é o contrato.

> ### 🔒 REGRA DE ADMISSÃO (aplica-se a TODA garantia, inclusive às futuras)
>
> **Todo mecanismo introduzido para fechar um furo entra provando-se — com fixture própria E com a
> integridade dos seus PRESSUPOSTOS provada pelo mesmo rigor.** Pressuposto é tudo aquilo de que o
> mecanismo depende para valer — e a lista é **fechada e exaustiva**, porque é o fechamento dela que faz o
> regresso terminar:
>
> **(0) A SUPERFÍCIE DE ESCRITA DO MOTOR — o item que define o critério de todos os outros.** Enumere, por
> **deny-by-default**, onde o motor pode escrever; tudo abaixo tem de ficar **fora** dela, provado pelo mesmo
> check estrutural. Num sistema agêntico que **escreve código**, o motor desligar a verificação não é hipótese
> remota — é o modo normal de operação. Por isso a lista inclui **o código do gate e o dos próprios checks**.
>
> **(0′) A SUPERFÍCIE DE LEITURA — o segredo com que se decifra o store.** Item irmão do (0), e o que faltava:
> toda a lista acima prova **não-alterabilidade**; nenhuma prova **não-legibilidade**. **Cifra em repouso NÃO
> é defesa aqui** — a própria KB o diz (§O problema: cifra em repouso "não toca esta camada"; TEE "**garante a
> entrega** ao dono"). Se o motor tem shell e corre como **o mesmo principal** que detém a chave, ele faz
> `cat` no store e lê a chave do keychain: mediação completa cai **sem tocar em nada que as fixtures observam**.
> **Exigência:** **separação de principal** — a capability de decifrar pertence ao resolver (uid/serviço/enclave
> distinto), **nunca** ao principal do motor. **Se o adotante não puder separar, a garantia G1.0 é NULA e tem
> de ser declarada nula** — não "parcial", não "mitigada". Um gate perfeito sobre um store que o motor lê
> direto é teatro. `T1.0(d)` prova: o principal do motor tentando abrir o store **sem** o resolver → negado
> pelo SO/capability, não por convenção de código.
>
> **(1) a POLÍTICA** — a matriz de pares permitidos **e a rotulagem** (o que é sensível, o que é
> topologia-sensível, a categoria de cada nó, o escopo de cada `P`) · **(2) a chave** com que verifica ·
> **(3) a lista de revogação** que consulta · **(4) o relógio** que lê · **(5) a lista** de leitores
> privilegiados, com **vocabulário e flags pinadas** · **(6) o canal de saída** por onde responde ·
> **(7) o campo** de onde lê a origem · **(8) o CANAL DE ATESTAÇÃO** — o caminho dono→gate por onde a via
> (i) chega, com a **identidade do requisitante autenticada** e o canal fora da superfície de escrita do
> motor. Sem ele, provar que "houve mensagem humana no turno" não prova **de quem**: num device
> compartilhado, ou num canal de mensagens roteado ao turno, qualquer terceiro que consiga uma mensagem
> declara `P` largo e o gate de ACESSO abre.
>
> ⚠️ **Por que a POLÍTICA foi a última a ser vista (lição de método):** ela sustenta G1.1-G1.4, G2.1 e G2.7 —
> e **escapou TODAS as passadas adversariais anteriores porque toda fixture a usa como DADO**. A matriz é o pano de fundo de
> cada teste, e **o que é pano de fundo não é observado**. Sem forjar nada, o motor que acrescenta
> `(saude × coaching × recrutador) = permitido` e remove um rótulo `topologia-sensível` deixa **todas** as
> fixtures verdes *por construção*: o gate funciona perfeito, executando a política errada.
> **Pressuposto não enumerado é rodada adversarial futura.**
>
> **Por que esta regra existe (custo real, observado):** este contrato passou por sucessivas rodadas adversariais, e
> em cada uma o furo estava um nível mais fundo — sempre pela **mesma** falha de forma: *o mecanismo criado
> para fechar o buraco anterior entrava ele próprio sem prova*. O eixo `destinatário` entrou sem exigir
> proveniência (e voltou a passar pelo rótulo). A concessão durável entrou sem exigir assinatura verificada
> (e o `P` injetado voltou carimbado). A verificação de assinatura entrou sem proteger a **âncora** (e
> forjar virou trocar a chave). **Um contrato que não carrega esta regra precisa de um adversário externo
> para sempre.** Ao acrescentar uma garantia nova: pergunte *"de que ela depende para valer?"* e prove
> **isso** também — antes de considerá-la fechada.

> **⚠️ Diferença estrutural vs o contrato do `kg-radar` — leia antes de usar.** No multi-runtime do KG existe
> um **`.sh` soberano** ao qual as portas se conformam: o teste é *"a porta concorda com a autoridade?"*.
> Aqui **não existe implementação de referência no core, por desenho** — pela invariante da §Fronteira acima
> (o gate roda sobre o KG privado, que nunca entra no core). Logo **o contrato É a autoridade** — e por isso
> precisa ter forma **executável** (dado X + propósito P → saída esperada Y), nunca prosa. Um contrato em
> prosa aqui seria exatamente a garantia não-verificável que a doutrina proíbe.

> **⚠️ ESCOPO DA GARANTIA — por-TURNO, não composta.** Todas as fixtures abaixo são **por-consulta**. Uma
> implementação conforme **não** impede *purpose-shopping*: N turnos com N propósitos estreitos, cada um
> passando em tudo, cuja **união** no contexto do motor reconstrói o grafo. Fechar a composição é L3, e a
> repetição no tempo é L6 — **ambas GATED**. Quem for conforme em L1+L2 pode dizer *"governo cada consulta"*;
> **não** pode dizer *"o motor nunca viu o conjunto"*. G1.6 abaixo é o mínimo enquanto L3/L6 não existem.

### L1 — Escopo de consulta (o gate de ACESSO)

Regra-mãe: *a saída não consegue filtrar uma conclusão que nunca foi string.* L1 é onde mais se ganha.

| # | O que DEVE garantir | Como se PROVA (fixture determinística) |
|---|---|---|
| **G1.0** | **MEDIAÇÃO COMPLETA — o gate é a única superfície que pode ALIMENTAR O MOTOR.** Sem isto, tudo abaixo prova **um caminho**, não o sistema. O critério **não** é "tocar o store" — é **poder virar contexto do motor**: indexador de embeddings, job de sync, tool de debug e o pipeline de de-id que carrega o grafo em memória **são violação**. **Leitor privilegiado** é admitido em duas formas, e só nelas: *(a)* **validador de canal LIMITADO** — emite veredito de **vocabulário fechado**, **enumerado NA LISTA e fixado pela fixture** (nunca declarado pela implementação: um código livre tipo `DETAIL: <texto>` devolveria o dump por dentro do "vocabulário"): só **códigos + contagens**, ids **opacos ou já in-scope**, **NUNCA valores de nó** e **nenhum campo de payload livre**; *(b)* leitor sobre **projeção já mediada**. ⚠️ **É o MODO que qualifica, não a ferramenta — e nem todo modo de veredito qualifica.** **Verificado por execução (2026-07-20), o `kg-radar.sh --integrity` do core NÃO cabe em (a) como está:** ele imprime **ids de nó** (`✗ nó órfão (grau 0): <id>`, `✗ aresta N: to aponta nó inexistente: <id>`) e **valores de campo** (`✗ <id>: impact fora de 1-5: 7`) — e ids no Onion são **slugs semânticos por doutrina** (a KB irmã manda citar ids como migalha auditável). Num KG de vida, o *checador de integridade* vaza `P_DIVORCIO_EM_CURSO` para o contexto do motor. Para ser privilegiado, um validador precisa de **redação na saída** (mapa id→opaco por-sessão, valores suprimidos) — o wrapper é do adotante. E o mesmo binário em `--triples` **emite o grafo** e nunca cabe. "Validador" não pode virar a palavra que autoriza o dump — **nem quando a ferramenta é a da casa**. Ambas vivem em **lista enumerada e auditável** — e a entrada **pina a INVOCAÇÃO** (binário **+ flags permitidas**), não a ferramenta: modo é argumento de runtime, e listar `kg-radar.sh` sem pinar as flags deixa um call site chamar `--triples` em produção enquanto a fixture testa `--integrity`. Fora da lista = violação | `T1.0` — verificação **ESTRUTURAL**, não espião in-process (leitor em **outro processo** — o indexador do próprio exemplo — é invisível a fixture in-process): **(a)** grafo de imports/permissão prova que **só o resolver e os leitores ENUMERADOS** tocam o driver do store. ⚠️ **NÃO apoiar esta perna em "cifrado em repouso"** — a própria KB declara isso não-defesa contra este adversário (§O problema); cifra protege o disco roubado, não o motor que roda dentro da fronteira; **(b)** asserção sobre a **SAÍDA** de cada leitor privilegiado, não só sobre presença na lista: saída fora do vocabulário fixado, ou contendo **id semântico** ou valor de nó, → **falha** (é onde o `--integrity` do core reprova hoje); **(c)** **nenhum call site** invoca um leitor privilegiado fora das flags pinadas (grep-ável, determinístico); **(d)** **SEPARAÇÃO DE PRINCIPAL** (pressuposto 0′): o principal do motor tentando abrir o store **sem** o resolver → **negado pelo SO/capability**, não por convenção de código. Se o motor detém a chave, (a)-(c) são teatro e a garantia é **nula** — declare-a nula. Determinístico e rodável em CI, no espírito do lint da casa |
| **G1.1** | **Need-to-know por propósito**: dado o propósito `P`, o motor recebe **só** a fatia que `P` exige — nunca "o grafo todo" | `T1.1` — KG com nós dentro/fora do escopo de `P` → a fatia é **exatamente** o conjunto in-scope (assert de **igualdade**, não de contenção: **extra é falha**) |
| **G1.2** | **Valores mascarados por default**: estrutura pode ser visível; **valores de instância não**, salvo se `P` os exigir | `T1.2` — nó sensível sob `P` que não requer valores → **mascarado**; sob `P` que requer → em claro |
| **G1.3** | **Topologia é dado**: se a mera **existência** da relação é sensível, mascarar valor **não basta** — a aresta não entra na fatia | `T1.3` — aresta rotulada topologia-sensível **ausente** da fatia (não presente-com-valor-oculto) |
| **G1.4** | **Fail-closed no propósito — desconhecido OU não-atestado.** `P` inexistente na matriz → fatia **vazia**. **E também:** `P` que EXISTE na matriz mas **não vem atestado** por canal confiável (ver G2.5) → fatia **vazia**. Atestação é condição dos **DOIS** gates: exigi-la só na emissão fecha a saída e deixa o **acesso** aberto — e o acesso é onde a regra-mãe vive | `T1.4a` — `P` inexistente → fatia vazia + recusa nomeada. `T1.4b` — `P` **mapeado porém não-atestado** (ex.: propósito largo `auditoria-completa` proposto por nó ingerido de terceiro) → fatia **vazia**; **falha** se a fatia larga for entregue "porque o `P` estava na matriz" |
| **G1.5** | **Derivado herda o escopo da origem**: sumário, agregado, contagem, rótulo calculado ou **embedding** de nó fora-de-escopo/mascarado **carrega o escopo do dado de origem** | `T1.5` — fatia com `salario: ***` **e** um derivado `faixa_de_renda: alto` (ou o embedding do nó mascarado) → **falha**. Sem isto a conclusão vira string na ENTRADA e a regra-mãe morre dentro do próprio L1 |
| **G1.6** | **Escopo de sessão inspecionável**: a implementação **expõe** o acumulado de fatias do contexto vivo e **avisa** ao cruzar um teto (paliativo enquanto L3/L6 são GATED) | `T1.6` — **duas** asserções, senão é satisfazível de graça: **(a)** após N turnos com propósitos distintos, o acumulado exposto é **igual** à união das fatias (assert de igualdade, no espírito de T1.1 — não basta "existe um endpoint"); **(b)** com o teto **fixado pela fixture** (nunca declarado pela implementação — `teto = ∞` passaria), o aviso **dispara**. Não é defesa — é **tornar a composição visível** em vez de silenciosa |
| **G1.7** | **A POLÍTICA e o próprio GATE ficam fora da superfície de escrita do motor.** Matriz de pares, rotulagem (sensível / topologia-sensível / categoria / escopo de cada `P`), lista de privilegiados, vocabulário, flags pinadas — **e o código do resolver e o dos checks**. Sem isto o gate é correto e a regra é de quem a editou por último | `T1.7` — política alterável **pelo caminho do motor** → **falha**; rótulo removível pelo motor → **falha**; e **o código do gate e dos próprios checks** alteráveis pelo caminho do motor → **falha** (senão o motor desliga a verificação em vez de burlá-la, e as fixtures passam a testar outro gate) |

> **Limite honesto de L1 — declarar junto (simétrico ao de L2):** G1.3 fecha **apenas o que foi rotulado**.
> Topologia sensível **não-rotulada**, e a sensibilidade que **emerge da co-ocorrência** de arestas
> individualmente inócuas, **continuam na fatia**. Passar em `T1.3` autoriza dizer *"as relações que
> classifiquei como sensíveis não saem"* — **nunca** *"a topologia está fechada"*. A completude da rotulagem
> é responsabilidade do adotante e **não é verificável por este contrato**.

### L2 — Propósito vinculado (o gate de AÇÃO/SAÍDA)

| # | O que DEVE garantir | Como se PROVA |
|---|---|---|
| **G2.1** | **Tripla, não par**: toda ação/saída carrega `(categoria-de-dado × propósito × **destinatário/canal**)` — e o **destinatário é RESOLVIDO PELO GATE a partir do sink efetivo** (URL, canal, handle), **nunca aceito da chamada**. Um destinatário auto-declarado é `declarado≠verificado` no exato eixo onde a KB mede o dano (3,75 dono × **2,34 terceiros**). *(O 4º eixo da Integridade Contextual — **princípio de transmissão**: consentimento, reciprocidade, retenção — fica **GATED junto de L3-L6**: sem fixture que o prove, seria obrigação decorativa, e a literatura de CI largamente o confunde com propósito. Contrato só exige o que sabe testar.)* | `T2.1a` — tupla com categoria×propósito **permitido** mas destinatário **declaradamente externo** não autorizado → rejeitada (o caso "coaching → recrutador"). `T2.1b` — tupla declarando `destinatário: dono` **e sink efetivo externo** (`http_post` p/ host de terceiro) → **rejeitada**. Sem `T2.1b` o eixo volta a passar pelo rótulo |
| **G2.2** | **Rejeitar, não degradar**: recusa é **sentinela tipada + payload de dados VAZIO** — não um rótulo `refused` acompanhado de resumo explicativo | `T2.2` — assert sobre **o payload**, não sobre o campo de status: qualquer conteúdo derivado do dado na resposta recusada = **falha** |
| **G2.3** | **Propósito prende o turno**: sem elevação a meio-caminho, e **todo canal derivado herda o `P` do turno** — sub-agente, tool-call, retry e re-tentativa com `P` diferente | `T2.3` — um caso **por canal** (sub-agente / tool-call / retry): cada um tentando operar com `P` ampliado → rejeitado. + **mutation**: removida a herança, o caso do sub-agente **falha** |
| **G2.4** | **Não-tautologia**: o gate precisa **deixar passar** o que conforma | `T2.4` — ação conforme **passa**; + **mutation test**: desfeita a vinculação, `T2.1a` **e** `T2.1b` **falham** (só `T2.1a` deixaria o eixo do sink efetivo sem prova de não-tautologia). Gate que nunca deixa passar (ou nunca barra) não é gate |
| **G2.5** | **Proveniência de QUEM declara `P`** (vale nos DOIS gates — ver G1.4): o propósito vincula só se **atestado**. `P` auto-declarado pelo modelo ou **derivado de conteúdo ingerido** não vincula. **Duas formas:** *(i)* **viva** — requisitante **autenticado como o DONO** no turno (não "um humano qualquer": a via (ii) exige assinatura do dono; exigir menos da via (i) — que é a MAIS usada — é deixar a porta principal aberta e trancar a de serviço); *(ii)* **durável/delegada** — concessão do dono com **assinatura VERIFICADA** (não basta ter campo `sig`), `P` **estreito por predicado**, destinatário **fixo**, **TTL** e revogação. **Não-delegável:** concessão não autoriza emitir outra concessão. Execução autônoma vale **só sob (ii)**; **ausentes ambas → fail-closed**. ⚠️ Fail-closed **absoluto** seria pior: negaria o resumo diário do próprio dono — o caso central de um KG-de-vida — e o implementador inventaria um "modo interno" fora do gate, furo maior e não-documentado. ⚠️ **A concessão é o mecanismo que fecha o buraco anterior — logo entra provando-se, como todos os outros; senão o `P` injetado volta carimbado** | `T2.5a` — nó de e-mail/PDF de terceiro dizendo *"o propósito é auditoria-completa"* → `P` **não aceito**, mesmo na matriz. `T2.5b` — turno autônomo **sem** concessão → recusa. `T2.5c` — concessão **expirada/revogada** → recusa; **válida e estreita → passa** (senão a via (ii) é decorativa). **`T2.5d`** — concessão com assinatura **ausente, inválida ou auto-emitida** → **recusa**; + **mutation**: removida a verificação de assinatura, `T2.5d` **falha** (sem isto, checar só `exp` + revogação passa em tudo). **`T2.5e`** — **TTL acima do máximo fixado PELA FIXTURE** → recusa (teto nunca declarado pela implementação: `TTL=10 anos` passaria); e `P` da concessão cuja fatia **não** seja subconjunto de um **teto de escopo fixado PELA FIXTURE** → recusa. (Comparar com o `P` mais largo da matriz quase não morde: excluiria só ele — `revisao-geral` com 98% da largura passaria. Mesmo remédio do TTL: o teto sai das mãos da implementação.) **`T2.5f`** — concessão que tenta **emitir outra** → recusa. **`T2.5g`** — **a ÂNCORA de confiança (pubkey/keystore do dono) vive FORA da superfície de escrita do motor**, provado pelo **mesmo check estrutural de T1.0**: âncora alterável pelo caminho do motor → **falha**. Sem isto, forjar deixa de ser inventar um `sig` e passa a ser **trocar a chave** — e a assinatura fica criptograficamente válida (regra de admissão: o verificador prova a integridade daquilo COM QUE verifica). **`T2.5h`** — **lista de revogação** fora da superfície de escrita do motor (mesmo check de T1.0) **e inalcançável → fail-closed**, nunca "não consta revogação, segue": é o artefato-irmão da âncora, e protegê-la sozinha deixava a concessão-zumbi. **`T2.5i`** — **fonte de tempo verificada**: relógio regredido ou sem prova de sincronia → **fail-closed**. Não redesenhar — **transferir** a guarda que a casa já tem: `a2a-verify.sh` exige prova de NTP (`timedatectl|chronyc|ntpstat`) e **veta `clock-untrusted`**. ⚠️ **Transfira a guarda, NÃO o escape dela:** lá o bypass `A2A_CLOCK_TRUST=attested` é um **operador humano** num host sem tooling; aqui seria uma **variável de ambiente que o próprio motor exporta** (ele tem shell). No contexto do KG o atestado de relógio é **atestação do dono** — a mesma âncora de G2.5(ii) — e a chave do escape vive **fora da superfície de escrita do motor**. Fixture negativa: escape setado **pelo caminho do motor** → recusa. (Régua Aristóteles: a forma era igual, a exceção **não** era.) Sem isto o TTL é decorativo (quem controla o relógio nunca expira). **`T2.5j`** — a via **(i) VIVA** também se prova: atestação **resolvida do CANAL** (existe mensagem real do requisitante neste turno), **nunca aceita da chamada** — campo `attested_by` setado em turno sem mensagem correspondente, ou por sub-agente montando turno sintético, → **recusa**. É o mesmo defeito que `T2.1b` consertou no eixo do destinatário, e a via viva é a MAIS usada. **`T2.5k`** — resolver do canal prova que a mensagem **existe**, não **de quem é**: a identidade do requisitante é **autenticada contra a mesma âncora do dono** de `T2.5g`. Mensagem real de **terceiro** roteada ao turno (device compartilhado, canal de mensagens, colega) declarando `P` largo → **recusa**, ainda que o canal seja legítimo e a mensagem verdadeira. Sem esta, a via (i) exige menos que a (ii) e vira a porta principal do `P` injetado |
| **G2.6** | **Pré-requisito: o nó carrega a própria origem.** G2.5 é inimplementável se o KG não souber de onde cada nó veio — todo nó carrega **origem + nível de confiança**. Não é mecanismo novo: é o `exposes:` + níveis de trust (RFC-0003) que L1 já reusa, aplicado ao nó. ⚠️ **Convive com o `write(KG)` da KB irmã, sem contradizê-lo:** o motor **escreve conteúdo** legitimamente (é a 4ª perna do ciclo `read→verify→act→write`), mas o campo `origin`/nível de confiança é preenchido pelo **caminho de INGESTÃO**, nunca pelo motor — senão bastaria carimbar um nó ingerido como confiável e `T2.5a` cai. É o item (0) da regra de admissão aplicado ao item (7) | `T2.6` — nó **sem** campo de origem → tratado como **não-confiável** (jamais confiável por omissão). A fixture roda contra **o caminho de produção** (o mesmo resolver, não um duplo de teste) — senão prova a existência do campo no teste e não no artefato; é a doutrina de dogfood da casa: invoque o artefato de verdade |
| **G2.7** | **Deny-by-default na categoria**: dado **sem categoria** (import, campo livre, derivado novo) é tratado como **restrito**, nunca como "não-restrito" | `T2.7` — nó de categoria nula/desconhecida → `gate`, nunca liberado. É o análogo do `gate unknown-verb` do effect-gate no eixo de L2 |

> **Limite honesto de L2 — obrigatório declarar junto:** L2 **não fecha inferência DENTRO do propósito**.
> Dados de carreira liberados legitimamente para "coaching" ainda permitem deduzir saúde. Quem implementar
> L1+L2 conformes pode dizer *"governo fronteira de acesso e de emissão, por turno"* — **não** pode dizer
> *"o motor não infere sobre mim"*. **Este contrato não quantifica redução, e não endossa as estimativas
> de §O irredutível** (marcadas lá como não-reproduzíveis) — número sem fonte é o `declarado≠verificado`
> que este contrato existe para matar, inclusive quando o número é da casa.

### Reúso — o que transfere do effect-gate R15, e o que NÃO transfere

Régua Aristóteles aplicada nos **dois sentidos** (ela pune tanto reuso preguiçoso quanto reinvenção do
maduro). Veredito **MISTO** — verificado lendo e executando `.claude/validation/guardrails/onion-effect-gate.sh`:

| | Veredito |
|---|---|
| **IGUAL → transfere** | a **forma**: predicado **tipado** sobre a ação · veredito `gate` = pare · **fail-safe recusa** · e sobretudo o **deny-by-default do desconhecido** (`--action frobnicate` → `gate unknown-verb`), que vira G1.4/G2.7 |
| **DIFERENTE → desenha fresh** | o effect-gate é **puro e sem estado**, sobre uma lista **fechada e enumerável** de verbos × um **booleano**, **independente de domínio**. L2 é **stateful** (G2.3 prende o turno), sobre eixos **abertos e domínio-dependentes** (a taxonomia é mantida pelo adotante — §decisões abertas #1/#2). **Não** porte o classificador stateless de listas fixas esperando que sirva |
| **O eixo que NÃO pode ser descartado** | o effect-gate carrega **proveniência** (`--untrusted-derived`). Trocar "verbo × proveniência" por "categoria × propósito" **perdendo** a proveniência abre o buraco que G2.5 fecha. A tupla certa **soma**, não substitui |

L1 reusa `exposes:` + níveis de trust (RFC-0003) como *permission-aware retrieval* — o nome técnico do que o
Onion já faz.

### L3-L6 — explicitamente GATED (não especificar agora)

O contrato **para aqui de propósito**. L3 (filtro por composição), L4 (juiz-de-CI), L5 (self-red-team) e L6
(ε-ledger) **não** ganham contrato antes do dogfood do **de-id v1** do adotante — especificá-las agora é
cerimônia à frente da substância, e a taxonomia de QI de L3 é *domínio-dependente* (a mesma razão pela qual
o core não a mantém).

**Gatilho de destravamento — OBSERVÁVEL pelo core** (gatilho que só o adotante enxerga apodrece por inércia):
a chegada, em `docs/evolution/inbox/`, de um **sinal de co-evolução originado do de-id v1 em uso real** — o
que ele acertou e o que deixou passar **é** o insumo do contrato de L3. Verificável com `ls`, não com fé.

## O irredutível e as decisões abertas (engenharia, não achado)

**Irredutível:** a inferência do motor legítimo sobre o próprio grafo, para o dono, **não se impede**. Gerenciada na
fronteira, não zerada. Resíduo **~7–8% — estimativa NÃO-REPRODUZÍVEL** (herdada da síntese de origem; não rastreável a nenhuma das referências abaixo — **não cite como medida**, trate como ordem de grandeza); garantia **por-resposta, não composta** (N=1 é o pior caso). Declarar um KG
"privado" **exige nomear esse resíduo**.

**Abertas (a desenhar no adotante):**
1. **Taxonomia de QI por vertical** (L3 é domínio-dependente; ~36% falso-positivo em finanças) — quem mantém?
2. **Granularidade do purpose-binding** — propósito largo legitima inferência indesejada; quão fino sem matar usabilidade?
3. **ε-ledger em N=1** — por-destinatário? por-vertical? qual ε preserva utilidade sem agregado onde esconder?
4. **Custo do self-red-team** (15–20× por release) — por-release? amostrado?
5. **O juiz-de-CI usa o mesmo modelo ou um SLM capado?** (menos inferência × julgamento mais grosso)
6. **Superfície de metadados do sync** (frequência de commit vaza padrão comportamental) — é esta fronteira na
   camada de transporte; prior-art: git-remote-gcrypt whole-repo, age-wire para interop.

**Prior-art verificado (2026-07-20) para o item 3 (ε-ledger/L6) e o item de composição (L3) — não abre o
gate.** Leitura do PDF (extração própria, `pdftotext`) de Asif & Mohammadi Amiri, *Information-Theoretic
Privacy Control for Sequential Multi-Agent LLM Systems* (arXiv:2603.05520) — candidato natural por atacar
"sequential composition" com bound formal. Mecanismo: **MINE-Reg** (o texto usa `MINE-Reg` e `MI-reg`),
regularização por **informação mútua** (estimada via MINE/Donsker-Varadhan) entre a saída de cada agente e
uma variável sensível `Sᵢ`, aplicada **em treino** (LoRA sobre Qwen/LLaMA). Resultado central, **Teorema
4.1**: bound com amplificação **exponencial** sob composição ingênua (contribuição maior dos agentes
**iniciais** — "*early-agent dominance*").

⚠️ **O `N` deste paper NÃO é o `N` do core — eixos diferentes.** O `N` do core é **população de indivíduos**
(por que DP/k-anonymity falham: sem multidão onde esconder). O `N` do paper é **profundidade de um PIPELINE**
de agentes especializados servindo um único pedido (N∈{2..5}), **por-pedido**, sem modelar multi-usuário.
Confundi-los seria o erro de uma leitura rasa.

**Veredito: NÃO fecha L3 nem L6 para o cenário do core** — mas por motivos que são do *desenho*, não de
fraqueza declarada pelos autores. Régua Aristóteles (diferente → não transfere): **(a)** é **treino-time**,
não runtime — exige rotular `Sᵢ` **a priori** e re-treinar cada agente; o motor do core é generalista e
aberto. **(b)** o bound é **diagnóstico** — corrobora a premissa de L3 (garantia por-turno não fecha
composição) em vez de resolvê-la. **(c)** **zero ledger/orçamento em runtime**: não há rastreamento de perda
acumulada entre interações, logo **nada transfere para L6** — nem nome, nem mecanismo. **(d)** a composição
medida é **espacial** (profundidade de pipeline num pedido), não **temporal** (turnos repetidos sobre um KG
persistente), que é a de L3/L6.

> 🚧 **Correção de citação (2026-07-20) — registrada, não apagada.** A 1ª versão deste bloco atribuía aos
> autores três "limites" que o PDF **refuta ou não contém**: dizia que o bound "pode ser *purely vacuous*"
> quando o paper afirma o oposto — *"the bound captures a practically relevant failure mode **rather than a
> purely vacuous worst case**"*; citava entre aspas que a estrutura de Markov "*may not hold in practice*" —
> frase **inexistente** no paper (0 ocorrências); e dizia que "MINE é *intractable*" quando o intratável é o
> cálculo **direto** da MI (*"Direct computation of the MI (Oᵢ;Sᵢ) is intractable"*) — MINE é justamente a
> **solução** para isso. Numa KB cuja tese é `declarado≠verificado`, **aspa fabricada destrói a autoridade do
> documento inteiro**; fica o registro do erro junto da correção. **Também sub-declarava o threat model:** o
> §3.2 cobre *"both external observers ... and internal agents attempting to infer upstream sensitive
> information from shared representations"* — o segundo caso é **mais próximo** do cenário do core do que a
> 1ª redação admitia, e o veredito de "não fecha" se sustenta pelos motivos (a)-(d), não por dispensar o
> paper.

Prior-art citado; L3/L6 seguem **GATED por
dogfood** (gatilho inalterado — ver §L3-L6 acima).

## Referências

- Staab, R. et al. (2024). *Beyond Memorization: Violating Privacy via Inference with LLMs.* ICLR 2024. https://arxiv.org/pdf/2310.07298
- Staab, R. et al. (2025). *Large Language Models are Advanced Anonymizers (FgAA).* ICLR 2025. https://arxiv.org/abs/2402.13846
- *Position: Privacy Is Not Just Memorization!* (2025). https://arxiv.org/pdf/2510.01645
- *Inferential Privacy Leakage in Anonymized Conversational AI Logs* (2026). https://arxiv.org/abs/2605.23820
- Jayaraman & Evans (2022). *Are Attribute Inference Attacks Just Imputation?* https://arxiv.org/abs/2209.01292
- *Truthful Text Sanitization Guided by Inference Attacks (INTACT)* (2024). https://arxiv.org/abs/2412.12928
- *Stop Tracking Me! (TRACE-RPS)* (2026). https://arxiv.org/abs/2602.11528
- *Ask Safely (PrivateNL2CYPHER)* (RCIS 2026). https://arxiv.org/abs/2512.04852
- *Contextual Integrity via Reasoning and RL (CI-CoT/CI-RL)* (2025). https://arxiv.org/abs/2506.04245
- *Capable but Careless (AgentCIBench)* (2026). https://arxiv.org/abs/2606.23189
- *Runtime Compliance Verification (C-Trace)* (2026). https://arxiv.org/abs/2606.19242
- *1-2-3 Check* (2025). https://arxiv.org/abs/2508.07667
- Deng et al. (2026). *When Are LLM Inferences Acceptable?* https://arxiv.org/abs/2605.10013
- *GraphSteal* (2026). https://arxiv.org/abs/2605.28645
- Asif, S. & Mohammadi Amiri, M. (2026). *Information-Theoretic Privacy Control for Sequential Multi-Agent LLM Systems.* https://arxiv.org/abs/2603.05520
