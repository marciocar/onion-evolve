# 🔨 Doutrina da forja — o conjunto COMPLETO de um comando-com-framework

Fragmento canônico. O `/meta:forge` **referencia** este arquivo; nenhum comando o copia. Ele existe
porque a composição inteira — *doutrina declarada como fragmento reutilizável + contexto medido
injetado + orquestração determinística em script + destino do que se produz* — **não tem nome de
mercado confirmado** (achado ancorado de 2026-09-28: o campo nomeou as partes, e o destino do que se
PRODUZ ficou sem dono). O nome **forja** é cunhagem do maestro, 2026-09-28.

## As 7 peças, e o que cada uma compra

| # | peça | onde vive | o que ela compra | modo de falha se ausente |
|---|---|---|---|---|
| 1 | **superfície invocável** | `.claude/skills/<n>/SKILL.md` ou `.claude/commands/<cat>/<n>.md` | o opt-in: nada dispara sem o humano pedir | o poder existe e ninguém alcança |
| 2 | **doutrina reutilizável** | `.claude/commands/common/prompts/<n>-doctrine.md` | a lente vive num lugar só; a superfície fica fina | a doutrina se duplica e as cópias divergem em silêncio |
| 3 | **contexto medido injetado** | bloco na superfície, alimentado por um MEDIDOR | a sessão lê o estado antes de raciocinar | o modelo responde de memória o que um `ls` responde |
| 4 | **orquestração faseada** | `.claude/workflows/<n>.js` (ou `<n>-workflow.mjs`) | fases, schemas, budget, tiering, retomada | a coordenação vira prosa e não retoma |
| 5 | **destino do que se produz** | fase final: `write(KG)` + radar exit 0 + contrato de custo | o conhecimento nasce no grafo, não em `/tmp` | a síntese evapora entre sessões |
| 6 | **lente/guarda** | `.claude/rules/<n>-lens.md` + a REGRA que a cobra no lint | a doutrina carrega sozinha ao tocar o caminho | a doutrina fica escrita e nunca é lida |
| 7 | **bancada** | família `run_<n>_selftests` | a guarda é exercitada, não prometida | a guarda apodrece verde |

## As quatro cláusulas

### 1. A peça 3 é MEDIDA por script, nunca escrita à mão

Contexto injetado que alguém digita é contexto que caduca em silêncio. A peça 3 exige um **medidor
determinístico** cuja saída entra na superfície. E o medidor **descobre por referência, nunca
construindo nome a partir do candidato** — a classe que isto proíbe custou três erros seguidos em
2026-09-28, todos do mesmo formato: `skills/onion-onion-research/` (prefixo duplicado), radical vs
nome cheio (`research-doctrine.md` para o candidato `onion-research`), e `grep kg-radar` num doc que
dizia "radar exit 0". **O artefato nomeia as suas próprias partes; o medidor lê essa citação.**

O corolário é desconfortável e fica declarado: peça que existe mas o artefato **não cita** conta como
ausente. Não é falso negativo — é a verdade operacional, porque a sessão que lê a superfície também
não a acharia. Medido no dia em que este fragmento nasceu: `onion-research`, a instância de
referência, tinha lente e bancada e **não citava nenhuma das duas**.

### 2. A peça 5 é INVARIANTE; as outras seis são variáveis

Todo comando-com-framework CARREGA a fase de destino — e a forja a EXIGE de quem o escreve. Exigir
não é gerar: qual peça a forja gera em cada versão está declarado no `/meta:forge`, e a 2ª passada
adversarial cobrou justamente a confusão entre as duas. As outras seis se ajustam à topologia do comando — e a forja
**entrevista** essa topologia em vez de assumi-la. Assumir é petrificar a forma da primeira instância
como se fosse a forma do padrão, que é a objeção `N=1` que sobreviveu a refutação real: **nenhum
candidato além da instância de referência passa de 4 das 7 peças** — medido em 2026-09-29, 4 alcançam
4+ e apenas 1 alcança 6+.

⚠️ **E o invariante não é o que se supunha.** Medido em 2026-09-29, com os predicados corrigidos: a peça 5
é a **mais replicada** desta casa — 17 de 57 candidatos (30%), contra **4** na peça 2 e **1** na peça 3.
(Os números anteriores deste parágrafo — 23 e 1 — saíram de predicados errados que a 2ª passada
adversarial expôs: a peça 5 contava a menção solta a `.kg.yaml`, e a peça 2 exigia caminho absoluto
quando a convenção deste repo é relativa, escondendo três casos — inclusive a doutrina da própria
forja. Registrado porque a lição é a mesma da cláusula 1: número de medidor errado tem cara de
medição.) O que de fato falha nela é o **contrato de custo**
(`run_id` · `tokens` · `agents` · `duration_min`) — **e aqui a doutrina se corrige com medição**:
o número de 4,8% (2 de 42 runs) é de 2026-08-06; re-medido em 2026-09-29 pela mesma métrica (arquivos
que citam um run `wf_`), são **22 de 111 = 19,8%**, quatro vezes mais. O contrato PEGOU. Logo a peça 5
não é invariante por ser a que mais falha — é invariante porque destino sem contrato não deixa série
histórica, e essa é razão de desenho, não de defeito. Logo a peça 5 é
invariante pela sua metade *contrato*, não pela metade *destino* — e quem escrever a forja deve
emitir o contrato, não só o `kg-radar`.

### 3. Quem emite artefato guardado emite também a guarda — e MEÇA se a guarda já existe

A forja EXIGE lente (peça 6) e bancada (peça 7) — e gera a 7 desde já, enquanto a 6 fica especificada.
Emitir artefato guardado sem que algo cobre sua forma produz artefato inválido em silêncio. A guarda da lente é a **REGRA 53 (Regra path-scoped
declara `paths:` que casa algo real)**, HARD desde 2026-08-03: ela exige `paths:` presente, ao menos
um glob, e ao menos um glob casando arquivo rastreado — mais, desde 2026-09-29, a lente estar
**rastreada** e ter **corpo não-vazio**.

⚠️ **E esta cláusula carrega a sua própria lição, que é caríssima.** A versão anterior deste
parágrafo afirmava que *"nada cobrava a lente"* e que uma REGRA nova nascera para cobrir a lacuna.
**Era falso, e não foi medido**: a REGRA 53 já cobria os três predicados havia quase dois meses. A
regra nova era duplicata **SOFT** de uma HARD, e as duas **discordavam** sobre o mesmo arquivo. Pior:
o maestro decidiu criar a regra nova **sobre essa premissa minha errada**. A passada adversarial
achou; a cura foi fundir os dois predicados genuinamente novos na 53 e matar a duplicata.
A moral vai na doutrina porque é a classe que a forja mais vai encontrar: **antes de emitir uma
guarda, medir se ela já existe** — `grep -n 'REGRA' lint-artifacts.sh` custa um segundo, e afirmar
lacuna sem isso custa uma regra inteira e uma decisão do maestro tomada em falso.

### 4. Core-only até a face que viaja ser MEDIDA

A forja é Camada 1 (autoria do framework), logo core-only. A face que viaja fica **gated**, e o
gatilho é nomeado: a cura da REGRA 74 (Caminho .claude/ NU dentro de plugin só resolve no core, com
catraca) nos arquivos acusados **mais** uma medição consumer-side que hoje não existe neste repo.
`install ≠ adopt` e a distinção morde: no adotante `.claude/utils` viaja inteiro e o caminho resolve;
quem nasce sem motor é a superfície de plugin e o papel `standalone`. Confundir os dois foi achado de
passada adversarial, não hipótese.

## O que esta doutrina NÃO promete

Ela mede **presença e referência**, nunca qualidade: não diz se a doutrina emitida é boa, se o
workflow funciona, nem se a bancada testa o que importa. E confia no substrato de **escrita** — que a
lente exista e alcance é verificável; que a sessão a tenha absorvido, não.

## 🔗 Referências

- Medidor da peça 3: `.claude/validation/forge-census.sh` · bancada: `run_forge_selftests`
- Guarda da peça 6: REGRA 53 (Regra path-scoped declara `paths:` que casa algo real), em `lint-artifacts.sh`
- Grafo da decisão (core-only, não viaja): `docs/onion/graph/forge-comando-framework-2026-09.kg.yaml`
- Pesquisa que ancorou o achado: `docs/evolution/research/agent-command-composition-2026-09/`
