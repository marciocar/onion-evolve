---
branch: fix/fixture-nao-depende-do-vivo
reviewed_at: 2026-08-10
reviewed_diff_sha256: 91fe0a9068c3dce6379f428cb6b0c55ff02c3250388bf5e12bf4ef72c3363009
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
