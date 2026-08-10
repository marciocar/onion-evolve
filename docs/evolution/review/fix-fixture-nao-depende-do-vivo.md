---
branch: fix/fixture-nao-depende-do-vivo
date: 2026-08-10
reviewed_diff_sha256: af6e290af59e098457dd0133df0f81ee4d54c1f5c37e5875718bf9029efa3833
findings_total: 6
findings_real: 6
findings_fixed: 5
tokens: 92072
duration_min: 12
verdict: REGRA-DERRUBADA-E-REESCRITA-4-DEFEITOS-REAIS-3-DO-LADO-QUE-MAIS-CUSTA
reviewer: passada adversarial (refutar-nao-aprovar) + reproducao independente minha de cada achado antes de agir
---

# A fixture dependia do conteúdo do arquivo que ela testa

## O gatilho, e ele não foi teórico

O CI reprovou a bancada em `docs/waha-rotacao-e-hash`:

```
✗ kg-backlog: (b) item `done` SEM carimbo REPROVA — GUARDA-DA-GUARDA:
              a mutacao NAO foi aplicada (arquivos identicos) — o sed virou no-op
```

A causa não estava na guarda nem na regra. Os três casos montavam o mutante assim:

```bash
sed '0,/^    status: open$/s//    status: done/' "${bg}" > "$d/done.yaml"
```

— mutar **o primeiro nó `open` do backlog vivo**. E no commit anterior eu tinha colhido o backlog a
**zero abertos**. Zero aberto é o **estado saudável**, o alvo declarado do próprio arquivo. A fixture
quebrava exatamente quando o sistema atingia o objetivo dele.

## O que separa `(b)` de `(e)`

| caso | tinha guarda-da-guarda? | o que aconteceu |
|---|---|---|
| `(b)` DONE-NU | **sim** (`_prove_mutation`) | gritou: *"arquivos idênticos"* |
| `(b2)` mensagem | herda de (b) | falhou junto |
| `(e)` atravessa o gate | **não** | compararia dois lints idênticos e **passaria em silêncio** |

`(e)` é o caso que mede se a violação **conta** no lint inteiro (HARD 7→8). Sem mutação, ele compara
7 com 7, conclui "não subiu" e reprova — ou, com a asserção invertida, aprovaria medindo o nada.
**A diferença entre gritar e mentir foi ter ou não a guarda-da-guarda.**

## A cura: a fixture passa a ser auto-suficiente

`_fixture_done_nu <src> <dst>` — **APPEND** de um nó sintético, sem depender de nenhum nó existente:

```bash
sed -E 's/(#.*TETO:[[:space:]]*)[0-9]+/\1999/' "${_src}" > "${_dst}"
cat >> "${_dst}" <<'FIXTURE_DONE_NU'

  - id: I_FIXTURE_DONE_SEM_CARIMBO
    node_type: decision
    plane: PROD
    status: done
    ...
FIXTURE_DONE_NU
```

Duas costuras deliberadas:

1. **append**, nunca mutação de nó existente — não há conteúdo do vivo do qual depender;
2. **teto elevado a 999 na cópia** — o nó extra poderia estourar o cap e trocar a acusação de
   `DONE-NU` para `TETO`, fazendo o caso reprovar pela razão errada. Um caso que passa pelo motivo
   errado é pior que um que falha.

Aplicada nos **três** sítios: `kg-backlog (b)`, `modos (b2)`, e `kg-backlog (e)` — este último via
arquivo temporário + `mv`, porque lá a mutação é in-place num sandbox.

## E a lição virou caso, não comentário

`(b3)`: a fonte tem **zero `open` por construção** (`sed` trocando todo `open` por `confirmed`),
com asserção prévia de que a troca de fato zerou. Se alguém voltar a mutar no existente, este caso
reprova na hora — **sem depender de o backlog real estar num estado ou noutro**.

É a diferença entre "aprendi" e "o mecanismo repete sozinho". Um comentário dizendo *não dependa do
arquivo vivo* não teria pegado a reincidência; `(b3)` pega.

## O verde do #574 foi acidental — e vale dizer

O PR anterior fechou verde porque o nó que criei (o vazamento da senha) **reintroduziu um `open`**, e
o `sed` voltou a funcionar. Nada foi corrigido lá; a condição de falha apenas saiu de cena. Ao colher
aquele nó agora — senha rotacionada, backlog de volta a zero aberto — a condição **retornaria**, e é
por isso que este conserto precede a colheita no mesmo movimento.

## Declarado, e não coberto

- O caso `(c)` do teto ainda compara a mensagem contra a constante literal `teto declarado 20`. Se o
  cap do `meta:` mudar, `(c)` quebra — e quebra **fazendo barulho**, não em silêncio, o que é o lado
  certo de falhar. Não mexi: seria mudança fora do gatilho medido.
- `_fixture_done_nu` assume que o `meta:` declara `TETO: <n>` num comentário. Num backlog sem teto o
  `sed` do 999 é no-op e a fixture herdaria o `SEM-TETO` — mas o caso `(d)` existe justamente para
  esse cenário e o cobre por outro caminho.

---

## Segunda rodada — a mesma classe, terceira vez no dia, agora com guarda

Um shell ficou preso **1h06**. A causa não era lentidão:

```bash
until ! pgrep -f 'git commit -F' >/dev/null 2>&1; do sleep 30; done
```

`pgrep -f` casa **a linha de comando do próprio shell que roda o laço** — o padrão está escrito ali.
A condição nunca podia virar verdadeira. O `git commit` tinha terminado havia mais de uma hora.

**Três vezes na mesma sessão, três danos diferentes** — que é o que separa classe de descuido:

| # | forma | dano |
|---|---|---|
| 1 | `pkill -f X`, conferido com padrão **Y** | afirmei ter matado o que não morreu |
| 2 | `pgrep -fc X` devolvendo 1 com o alvo morto | o sobrevivente era o meu shell |
| 3 | `until ! pgrep -f X` | **espera para sempre** — e esperar parece trabalhar |

O nº 2 é o que condena a cura por atenção: eu **notei o mecanismo e o expliquei em voz alta**, e
escrevi o nº 3 vinte minutos depois. E nas três, quem viu foi o maestro.

### A guarda, e por que ela tem dois lados

Regra `(3b)` na hook anti-fail-open do shell. Acusa `pgrep -f`/`pkill -f` sem o idioma do colchete e
sem exclusão do próprio PID; desarma em `-x` (casa o **nome**, não a linha) e `--older`.

O caso `(b3)` — *cala no `pgrep -f '[l]…'`* — não é simetria decorativa. É a lição da REGRA 56, que
puniu quem obedecia **23 vezes** e ensinou a contornar o hook. Uma guarda que acusasse todo `pgrep`
empurraria quem faz certo para o bypass. **Ela tem de reconhecer a forma correta, não só a errada.**

Verificação: 7 casos no harness (3 acusam, 4 calam), `(b2)`/`(b3)` permanentes na bancada,
**778 passaram / 0 falharam / 0 pularam**, sha do arquivo estável entre início e fim.

### E a espera desta vez é por PID

```bash
while kill -0 "$BPID" 2>/dev/null; do sleep 30; done
```

Remove a classe em vez de escapar dela: não há padrão a casar, logo não há como casar a si mesmo.

---

## Terceira rodada — a passada adversarial derrubou a regra da segunda

⚠️ **A seção acima descreve a 1ª versão da regra e está SUPERADA.** O número "778 passaram" e a
descrição *"desarma em `-x` e `--older`"* valiam para um código que não existe mais. Fica registrado
em vez de reescrito: o resíduo é log de rodadas, e apagar a versão derrubada esconderia o custo.

A passada adversarial contra a regra achou **quatro defeitos**, e três do lado que mais custa. Todos
reproduzidos por mim antes de agir:

| # | defeito | como escapava |
|---|---|---|
| i | **cobertura menor que a promessa** | exigia o cluster com `f` como PRIMEIRO token — escapavam `pkill -9 -f` (a forma mais comum do mundo real), `-a -f`, `-u root -f`, `--full` |
| ii | **falso-positivo em comando de leitura** | `grep -rn "pgrep -f" .claude/` disparava; a própria mensagem de commit também |
| iii | **a cura recomendada não curava — e a guarda a certificava** | `bash x.sh & until ! pgrep -f '[x]'`: a forma NUA está na linha pelo lançamento, o laço trava, e a guarda ficava MUDA porque via o `[` |
| iv | **`-A`/`--ignore-ancestors` passava por acidente** | caía no buraco de (i), não era reconhecida |

O **(ii) é o meta-defeito**: quarenta linhas abaixo, no mesmo arquivo, está escrito que o detector (5)
sofreu exatamente isso e que a cura foi **ancorar em início de comando**. Escrevi a (3b) no dia
seguinte sem reusar a cura já paga. A casa tinha o remédio no mesmo arquivo.

### Duas afirmações minhas que estavam erradas

1. Disse que os achados de `$$` e `-x` **"não reproduziram"**. Reproduzem — contra a versão que estava
   no PR. Eu medi contra uma versão mais nova na árvore de trabalho e li a diferença como refutação.
2. Meu primeiro teste de mutação **calava dos dois lados**: a sonda `grep -rn "pgrep -f"` é silenciada
   pelo regex de modo-full (`-f"` não é token de opção), não pela âncora. Eu teria concluído
   *"cláusula indetectável"* sobre uma cláusula sadia. `echo pgrep -f alvo` isola a âncora.

### E o caso (b2d) reprovava sobre uma regra CORRETA

Eu tinha escrito o padrão como `([m]arcador-x.sh)` para escapar do JSON — o parêntese **entra no
argumento**, a forma nua vira `(marcador-x.sh)` e não ocorre no lançamento. O artifício de escape do
teste virou parte do dado medido. Mesma família de `bancada-espelha-o-runner`, do lado do **dado**.

### Estado final

Julgamento **por invocação** com dois escopos · modo-full lido de **qualquer** token · âncora em
início de posição de comando · `-A` reconhecida · e a mensagem nova **`COLCHETE-FURADO`**, que a
versão anterior não tinha como emitir.

**Matriz 20/20** · bancada **784 / 0 falharam / 0 pularam** · sha estável na corrida.

---

## Erros conhecidos, cada um com cura ou superação anexada

> Diretriz do maestro (2026-08-10): *situação que se repete tem de ser registrada, reavaliada e
> corrigida — ou ser conhecida, com todo erro tendo proposta de cura ou superação, mesmo em tempo de
> execução.* **Limite declarado sem proposta é dívida disfarçada de honestidade.**

| erro conhecido | cura ou superação |
|---|---|
| a guarda acusa **dado de teste dentro de string** (me atingiu ao testá-la) | **superação**: reusar `unquoted()` do detector (1) para a **âncora**, mantendo o cru para o **argumento**. Não feito agora: seria a 4ª iteração da cura que abriu buraco 3× hoje. **contorno em runtime**: testar via arquivo de matriz, nunca `printf` inline |
| **bancada não é hermética** contra outra bancada (foi a falha de `graph: determinismo`) | **cura**: fixtures em `mktemp -d` fora do repo, ou `flock`. **contorno**: rodar solo; se determinismo falhar, conferir instância concorrente ANTES de investigar o script |
| **três sessões no mesmo branch** — escrevi sobre trabalho de outra | **superação**: o farol avisa no **boot**, quando ainda não há colisão. Falta checagem **no momento da escrita** — `PreToolUse(Edit\|Write)` sobre o mesmo `session-beacon.sh check`. O motor já existe |
| caso `(c)` compara a constante literal `teto declarado 20` | quebra **fazendo barulho** se o cap mudar — lado certo de falhar. **cura**: ler o cap do `meta:` também no teste. Fora do gatilho |
| `_fixture_done_nu` assume `TETO:` declarado | num backlog sem teto o `sed` do 999 é no-op e herda `SEM-TETO` — **coberto** pelo caso `(d)`, por outro caminho |

---

## Quarta rodada — o revisor achou um identificador pt-BR, e a guarda que existe para isso estava cega

`lint-selftest.sh:5143` trazia `local _b4_falhou=0` — pt-BR no mesmo bloco onde `_cov_fail`/`_esc_fail`
usam inglês. Renomeado para `_b4_fail`, conferido **por ausência da palavra** (`grep -w _b4_falhou` = 0,
`_b4_fail` = 3), como a migalha `rename-verifica-por-ausencia-da-palavra` prescreve.

**Mas o achado que importa é o segundo:** a REGRA 60 existe exatamente para isto e **passou calada**.
`falhou` não estava nas 71 palavras da lista. Medido depois de adicionar (`falha`, `falhou`, `falhar`,
`passou` → 74): com o identificador presente ela acusa **nominalmente** (`✗ IDIOMA: _b4_falhou
(segmento falhou)`) e sai 1; sem, cala. E o baseline **não cresceu** — nenhum outro identificador do
repo usa essas palavras, então a cobertura aumentou de graça.

**A cura é hábito, não código:** detector por lista de palavras só enxerga o que foi enumerado — é
limite de desenho, e até hoje estava *declarado sem cura*. A cura: todo identificador pt-BR achado por
revisão entra na lista **no mesmo movimento** em que é renomeado. Sem isso, cada achado se paga uma
vez só, e a regra fica eternamente um passo atrás de quem a viola.
