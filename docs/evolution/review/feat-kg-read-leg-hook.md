---
title: 'Resíduo — a perna de leitura do KG deixou de ser conselho'
date: 2026-09-16
branch: feat/kg-read-leg-hook
reviewed_diff_sha256: f2bc56224301d9a77ddeca884166d912db3eca362bf17618c09aba4438ae58ed
findings_total: 8
findings_real: 8
findings_fixed: 8
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Triagem de 10 sinais de campo (lidos por inteiro, 684 linhas) + a primeira cura. Sem refutador
  externo: o trabalho nasceu de sinais que JÁ são refutação de campo, e a bancada reprovou três
  vezes durante a construção. O que vale registrar não é o hook — é que quatro dos dez sinais
  já estavam curados, e eu teria proposto trabalho morto se tivesse triado pelo título.
---

# O grafo que não é lido é indistinguível do grafo que não foi escrito

A frase é de um adotante, e ele a comprou caro.

## A triagem — e por que ler por inteiro não era formalidade

Dez sinais acumulados. Medi **cada um contra o vivo** antes de triar, e **quatro já estavam
curados**:

| sinal | estado real |
|---|---|
| `/meta:adopt` gera inventário antes do commit | ✅ curado — `_tracked_or_find` pergunta "houve resultado?", e o comentário cita este sinal |
| proposta de 1 nó reprova no radar | ✅ curado — modo proposta (`meta.target` / `*.proposal.kg.yaml`) |
| `onion-research` volta vazio em fonte com sessão | ✅ curado — `unreachable` 12×, `zero claims`, `notVerifiedByBudget` |
| anúncio contradiz o relatório | ⚠️ **metade** — o `co-deliver` exige `.onion-version`; a metade do RELATO segue viva |

A última é a lição de método: **arquivar um sinal meio-curado apagaria o achado vivo**. Antes de
mover, registrei a metade sobrevivente como nó (`A_ANUNCIO_DERIVA_O_NUMERO_DA_MEDICAO`) — o anúncio
afirmava *"as portas estão OK"* enquanto a catraca da mesma leva tinha contado **38 exposições**, e
citava "3 fallbacks" onde o padrão produzia **19 em 10 variáveis**.

## O caso que justifica o hook

Sinal de 2026-09-11. Uma sessão leu **8.585 linhas** de fonte em quatro frentes e publicou **quatro
teses erradas em sequência** — todas derrubadas por correção do autor, nenhuma pelo método — num
corpus que tinha a resposta em **quatro nós** de um `.kg.yaml` que ela **citou no próprio prompt**,
como checklist de conferência e nunca como fonte.

Não foi falta de acesso nem de contexto. Foi falta de mecanismo. E o core sabia: o `grep -l
'\.kg\.yaml' .claude/hooks/*.sh` devolvia **zero** — a perna de leitura estava anunciada como
mecanismo e era conselho.

## O que foi construído

- **`--emit-index`** no `kg-trace-resolve.sh` — o **mesmo** parser que julga a âncora emite o índice.
  Um segundo extrator de `trace:` seria a segunda cópia da gramática, que é a classe que a REGRA 82
  (Os dois leitores do corpus CONCORDAM sobre quem é nó) existe para pegar. **1.844 pares**.
- **`docs/onion/kg-read-index.tsv`** — projeção commitada. Medido: gerar **7.722 ms** · consultar
  **8 ms**. Um hook de `PreToolUse` a 7,7 s por `Read` seria desligado no primeiro dia, e guarda
  desligada é pior que guarda ausente porque o desligamento não fica registrado em lugar nenhum.
- **`.claude/hooks/kg-read-leg.sh`** — ao abrir arquivo que algum nó aponta, diz **quais** nós.
  **Não bloqueia**, e é desenho: gate que impede trabalho é contornado com `--no-verify` na primeira
  sexta-feira, e aí se perde o mecanismo *e* a informação.
- **REGRA 84 (Índice de leitura do KG em sincronia com os traces)** — índice defasado não faz o hook
  gritar errado: faz ele **ficar calado** sobre um nó que existe, e calado é indistinguível de "não
  há grafo" — o fail-open exato que a perna de leitura foi ligada para curar.
- **Bancada `kg_read_leg` 7/7**, e dois casos existem contra a fraude mais barata: (c) o hook cala no
  arquivo sem nó — hook que fala sempre vira ruído e é desligado; (d) prefixo **não** conta como
  cobertura, senão `alvo.ts` apontaria nós ao abrir `alvo.ts.bak`, que é pior que silêncio porque
  parece informação.

## O que a máquina me cobrou (e eu não teria visto)

1. **REGRA 60 (Identificador de código em INGLÊS)** — 5 identificadores em pt-BR no hook.
2. **REGRA 59 (Modo que a produção consome é exercitado pela bancada)** — `--emit-index` é consumido
   em produção e não estava coberto. Dois casos novos, e o (g) prova o **fail-closed**: corpus sem
   trace resolvível sai ≠0, senão o regenerador gravaria um índice cego.
3. **`fail-closed-exposes-incomplete-harness`** — o caso (f) reprovou porque o sandbox copiava o
   motor sem `kg-fixture-paths.sh`. A cura é no harness, nunca afrouxar a guarda.
4. **`paste -sd' · '` não junta com " · "** — o `-d` é um *conjunto* e o paste cicla um caractere por
   junção. Saiu byte solto no meio dos nomes dos grafos.

## Teto declarado — e este é o que importa

**O hook não foi verificado em execução real nesta sessão.** Hook novo só passa a valer depois de
reiniciar a sessão (medido nesta casa em 2026-09-02, e eu já errei uma vez afirmando o contrário).
O que está provado é: o contrato de saída é JSON válido com `hookSpecificOutput.additionalContext`,
o índice resolve, e os 7 casos de bancada reagem. O que **falta** provar é o harness consumindo o
`additionalContext` de um `PreToolUse` — isso se vê na próxima sessão, abrindo um arquivo coberto.

Os outros três itens da ordem proposta pelo adotante (radar avisar vencimento · exigir o par
desvio↔redesenho · gatilho por contradição) ficam em `A_PERNA_DE_LEITURA_DO_KG_E_CONSELHO`, abertos.
