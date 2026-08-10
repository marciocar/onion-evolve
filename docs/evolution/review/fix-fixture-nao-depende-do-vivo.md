---
branch: fix/fixture-nao-depende-do-vivo
reviewed_at: 2026-08-10
reviewed_diff_sha256: 08d198dde4950ff48ca45b002708e7f4588ec546e092e5bda3e6398ea8d7a680
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
