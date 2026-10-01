# Três capacidades de motor de regras: o que cada uma CUSTA, o que QUEBRA, e o plano

> **Estado: ANÁLISE, nada executado.** O maestro selou em 2026-10-01: *"nenhuma agora, PRIMEIRO tem que
> analisar a proposta de cada uma e suas consequências e o que pode quebrar para ter um plano de
> implementação sem falhas"*. Este documento é esse plano. A decisão de executar é dele.
>
> Insumo: `docs/evolution/research/motores-de-regras-deterministicos-2026-10/` e
> `docs/evolution/research/engenharia-de-corpus-de-regras-2026-10/` (2026-10-01).

## A medição que muda tudo, e foi feita antes de escrever o plano

**O lint do Onion NÃO escreve. Quem escreve é o pre-commit.**

| componente | papel | evidência |
|---|---|---|
| `lint-artifacts.sh` | **leitor puro** — 93 `check_*` em sequência literal, nenhum gera artefato | zero chamadas de geração no corpo |
| `.githooks/pre-commit` | **escritor** — 7 `git add`, cadeia de auto-fix (plugins → marketplace → painel → re-carimbo do SHA) | medido |

Isso **reduz o escopo** das três propostas: a fronteira de ordem não está entre as 93 regras — está
entre **o hook que escreve** e **o lint que lê**, e **dentro** da cadeia do hook. E metade disso já foi
curada hoje: o invariante *"nada muta o índice depois do re-carimbo do SHA"* virou guarda testada
(`run_hook_chain_order_selftests`, 3 casos, 3 mutantes mortos).

E há precedente interno: `check_scan_sanity` **já é primeira por desenho**, com a razão escrita —
*"se a varredura está cega, o veredito de qualquer regra abaixo é vacuidade"*. A ordem já existe no
motor; o que não existe é **ela ser verificável**.

---

## Capacidade 1 — ordem leitor-depois-de-escritor

**O que é.** A única convenção de ordenação achada em toda a pesquisa (pacote `precommit` do R):
*hooks que só LEEM rodam depois dos que ESCREVEM*. Regra de **duas classes**, não DAG.

**Por que cabe aqui.** É **derivável do corpo**, como a severidade já é (literais `violation HARD/SOFT`)
e como o mapa família→arquivo já é. Ninguém declara dependência par-a-par.

**Escopo real, depois da medição:** não são 93 guardas. São os **7 pontos de escrita do hook** e os
**6 sítios de leitura de projeção** do lint.

### O que pode quebrar

| risco | por quê | mitigação |
|---|---|---|
| **Classificar errado** | a classe sai de heurística textual (`git add`, `--write`, `> arquivo`); uma guarda que escreve por helper indireto seria lida como leitora | a guarda **declara NÃO-MEDIDO** quando não consegue classificar, em vez de chutar — mesmo dialeto do `resolve-production-branch.sh` |
| **Falso positivo parando o gate** | se nascer HARD e classificar errado, trava commit legítimo | nasce **SOFT com baseline**, pelo idioma das catracas: passivo declarado que só encolhe |
| **A ordem do hook mudar por refactor** | hoje a posição é implícita na linha | já coberto pelo invariante de hoje; esta capacidade **estende** o mesmo mecanismo |

### Plano, em três passos verificáveis

1. **Derivar e IMPRIMIR, sem julgar** — um `--classify` que lista cada ponto como `ESCRITOR`/`LEITOR`/
   `NÃO-MEDIDO`. Entrega: a lista. Critério de aceite: os 7 `git add` do hook saem como escritores e os
   6 sítios de projeção como leitores, conferidos à mão uma vez.
2. **Guarda SOFT com baseline** — acusa leitor que roda antes de escritor. Nasce com o passivo atual
   tolerado e declarado. Mutante obrigatório: inverter dois pontos tem de reprovar.
3. **Promoção a HARD só por gatilho nomeado** — e o gatilho é: *a guarda acusar um caso REAL que
   custaria ciclo de CI*. Antes disso, promover é engessar sem evidência.

**Custo estimado:** baixo. Reusa `--map`/`--list` que já existem. **Risco residual declarado:** a
heurística não enxerga escrita feita por script externo que o hook chama — fica como NÃO-MEDIDO, visível.

---

## Capacidade 2 — teste diferencial spec ↔ implementação

**O que é.** O padrão do campo contra drift: o Rust do Cedar é diferenciado **contra o modelo em Lean**
por teste aleatório **imposto pelo CI** — achou **25 bugs** que review e teste unitário não pegaram.

**O que o Onion tem e o que falta.** A bancada de 200 famílias prova **capacidade** da guarda (ela
dispara no mutante). Falta a **spec executável** contra a qual diferenciar — hoje a "spec" é o
docstring, que é prosa, e o `rules-registry.sh` já deriva dele severidade, categoria e `previne:`.

### O que pode quebrar — e esta é a mais perigosa das três

| risco | por quê |
|---|---|
| **Spec vira segunda fonte** | se a spec for escrita à mão ao lado da guarda, nasce o drift que ela existe para medir. Seria o oposto do princípio da casa, onde a severidade vem do COMPORTAMENTO |
| **Gerador aleatório sem oráculo** | diferenciar exige um oráculo independente. Para política (Cedar) o oráculo é o modelo formal; para guarda em shell que lê arquivo, o "input aleatório" é um repositório inteiro — gerar isso é projeto próprio |
| **Custo de CI** | teste aleatório contínuo sobre 91 regras, num gate que já leva 17 min no lane mais pesado |

### Plano honesto: NÃO fazer agora, e o porquê é específico

A capacidade só existe quando há **duas implementações independentes** do mesmo contrato. O Onion tem
**uma**. Construir a segunda (uma spec executável por regra) é maior que o problema que resolve hoje.

**O caminho barato que entrega 80% disso já existe e está sub-usado:** o teste de **mutação**, hoje
praticado **à mão**. Converter isso em convenção (um mutante declarado por família, rodado no CI) dá a
mesma garantia — *"a guarda reprova quando o sujeito quebra"* — sem inventar spec paralela.

**Proposta:** substituir esta capacidade por **"mutação como convenção de bancada"**, que é derivável,
não cria segunda fonte, e tem precedente medido nesta casa (3 mutantes mortos hoje; 8 de 9 na família
do Zoho). **Gatilho para reabrir o diferencial de verdade:** existir uma segunda implementação do gate
(por exemplo, o porte `onion-codex`, que já tem `.codex/validation/` próprio) — aí há dois lados para
diferenciar, e o custo cai para zero porque as duas implementações já existem.

---

## Capacidade 3 — análise estática de conflito (SMT)

**O que é.** Cedar reduz política a SMT com codificação **sólida, completa e decidível**: acha `permit`
sombreado, condição impossível, redundância, e compara dois conjuntos (Equivalent / More-Permissive /
Less-Permissive / Incomparable). Verificado em Lean, e o **SymCert (FMCAD 2026)** verifica a própria
análise — porque erro na camada de verificação corrompe em silêncio.

### O que quebra: tudo, e a razão é de categoria

**O poder vem da LINGUAGEM RESTRITA, não da ferramenta.** Cedar decide `permit`/`forbid` sobre um
request — é função pura, sem efeito, ordem-independente **por projeto**. As guardas do Onion:

- **leem o sistema de arquivos** (entrada não é um request; é um repositório)
- **produzem artefato** (o hook escreve)
- **dependem de ordem** (o que esta sessão mediu em 4 ciclos de CI)
- **precisam do `exit 2`** de hook, que nenhum motor entrega

Reescrever 91 guardas numa DSL restrita para ganhar análise estática trocaria **a capacidade que compra
o acoplamento** (veto real, sob `bypassPermissions`) por **uma propriedade que só vale em decisão pura**.

### Plano: RECUSAR, com a razão escrita e o gatilho de reabertura

Recusa não é desprezo — é categoria errada. **Gatilho para reabrir:** se um dia existir um subconjunto
das regras que seja **decisão pura sobre metadados** (sem ler arquivo, sem escrever, sem ordem), esse
subconjunto é candidato legítimo. Hoje não sei se ele existe, e **medir isso é barato**: classificar as
91 por "lê arquivo?" / "escreve?" / "depende de ordem?" — e essa classificação é **o mesmo passo 1 da
Capacidade 1**.

---

## O que eu recomendo, em uma linha cada

| capacidade | recomendação | razão |
|---|---|---|
| **1 — ordem leitor/escritor** | **fazer, em três passos, começando por IMPRIMIR sem julgar** | custo baixo, derivável, e o problema tem custo medido (4 ciclos de CI num dia) |
| **2 — diferencial spec↔impl** | **não agora; trocar por mutação como convenção** | exige segunda implementação que não existe; a troca entrega quase o mesmo por quase nada |
| **3 — SMT de conflito** | **recusar, com gatilho** | categoria errada: o poder vem da linguagem restrita, e adotá-la custaria o `exit 2` |

**E o passo 1 da Capacidade 1 é o mesmo insumo do gatilho da Capacidade 3** — classificar as 91 por
leitura/escrita/ordem serve às duas. É o único trabalho que paga duas contas, e por isso é por onde
começar se você mandar executar.
