---
title: 'Resíduo adversarial — passivo YAML zerado, a causa real da r16 e a classe de locale virando guarda'
date: 2026-09-13
branch: fix/kg-yaml-passivo-zero
reviewed_diff_sha256: f921962786cf88eec3830a8b3f52396278e5e9e317397613dc6c85cfecb1c848
findings_total: 15
findings_real: 15
findings_fixed: 14
tokens: 216265
duration_min: 19
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Um refutador com default REPROVADO atacou o diff inteiro, medindo com /usr/bin/grep numa cópia descartável.
  Resultado: 0 ALTA, 5 MÉDIA, 9 BAIXA. Três alegações centrais sobreviveram: os 4 grafos não mudaram de sentido,
  a alternância não quebrou a precedência da REGRA 16, e o context-freshness sai idêntico nos dois locales.
  As cinco MÉDIA eram guarda que não guardava onde devia: fora do pre-commit, cega a formas reais, cura
  parcial, asserção vazia e projeção caduca. Um achado fica declarado, não curado: citações textuais a ids colhidos.
---

# A r16 "só falhava na suíte" porque a suíte roda em locale C

## A causa, medida

A falha `r16-count-drift/bad-invocaveis-invertida`, que reprovava só na bancada completa, **não era
concorrência** nem fixture em voo. A REGRA 16 (Contagem de inventário-TOTAL divergente da SSOT) casava
`Comandos — <N> invocáveis` com o conjunto `[—:–-]`. No **GNU grep** em locale C, esse conjunto casa um
**byte** do travessão, e a guarda ficava cega. A suíte e o hook de pre-commit rodam em C; o teste "isolado"
rodava na minha shell.

E eu já tinha "medido" que aquele conjunto era **inócuo**, e fechado o fio sem código. A medição foi feita no
caminho errado: na shell do agente, `grep` é uma **função que chama o ugrep**, que casa por caractere em
qualquer locale. O nó `E_LOCALE_FRAGIL_EM_TRES_SITIOS_PRE_EXISTENTES` carrega agora as duas correções, a
segunda desfazendo a primeira.

Curado com alternância `(—|–|:|-)`. A classe virou mecanismo: o caso `shell-locale`, uma guarda de forma que
varre os bytes das regex de shell atrás de conjunto `[...]` com caractere não-ASCII.

## As cinco MÉDIA

1. **A guarda nova não rodava no pre-commit.** A família citava `.claude/validation` sem barra final, e o
   seletor `--affected` só reconhece diretório com barra. Corrigido; o `--dry-run` agora escolhe a família para
   `claude-md-fuse.sh` e `projection-safety.sh`.
2. **A guarda deixava passar formas reais.**
   - Ela exigia `grep|sed|awk` na mesma linha e não aceitava `\/` dentro do conjunto. Por isso não via
     `gsub(/[—–\/;,]/…)` do `projection-safety.sh`, que **não era inócuo**: com um membro `ÓTICA-Z`, em C os
     termos saíam partidos (`TICA-Z`, `Dona`) e a guarda da REGRA 30 comparava pedaços. Parecia inócuo só porque
     o `members.yaml` de hoje não tem esses bytes.
   - Curado o sítio. A palavra-chave ganhou `gsub|sub(|match(|split(|case|*[|re=`, o conjunto aceita escape, e
     regex Python é isenta (imune ao locale do shell).
   - Falsos-negativos que ficam, declarados: conjunto com espaço dentro, e linha-padrão de awk sem nenhuma
     palavra-chave.
3. **A cura do `claude-md-fuse` era parcial.** Em C o `-i` não dobra caixa de multibyte, então `é obrigatório`
   continuava invisível e a fusão furava o never-clobber. Agora é `obrigat(ó|Ó|o|O)ri[oa]`, com o caso `(f)`
   rodando em `LC_ALL=C`.
4. **A asserção do regen-baselines não pegava o defeito que nomeia.** Com `%s chave(s)` recebendo `"0\n0"`,
   as duas contagens davam 2 = 2. Agora toda linha não vazia precisa de marcador; linha órfã é a deformação.
5. **`testing-inventory.md` e `testing-state.md` caducos** (981 × 983 sítios). Regenerados no estado final.

## BAIXA

- **tar da cópia do sandbox:** saía 1 em "file changed as we read it", e há escritores vivos nas pastas
  copiadas. `--warning=no-file-changed` e rc 1 tolerado do lado que empacota. O comentário deixou de dizer
  "a mesma do .gitignore".
- **REGRA 63 (Colheita de grafo emite os ids colhidos no resíduo de revisão):** eu tinha **movido**
  `D_BANCADA_FAIXAS_E_MAPA` e `E_BANCADA_FAIXAS_MEDIDA`, que apareciam no diff como colhidos, e **apagado duas
  arestas** vivas deles. Voltaram ao lugar e as arestas foram restauradas. O diff agora mostra só os 9 colhidos.
- **context-freshness:** tirar o `-i` perdeu `ULTIMA ATUALIZACAO` em caixa alta sem acento. Acrescentado e
  exercitado com o `/usr/bin/grep` em C.
- **Quinta forma de escape:** texto depois da aspa de fechamento em `bridge-produto` l.310. A aspa perdida foi
  removida do label, e `E_OS_QUATRO_ERAM_QUATRO_CLASSES_DE_ESCAPE` a nomeia.
- **Textos desatualizados:**
  - a fixture r16 ainda citava `[—:–-]`;
  - `E_LOCALE` contava "2+1 sítios", e a guarda contra o `origin/main` acha 9 (inclusive os 2 do `projection-safety`).
- **Diagnóstico da r16 usava `Viola..es`**, que não casa em C: agora é só `HARD[[:space:]]*:`. A guarda não
  enxerga `..` usado no lugar de acento (outra forma da mesma classe); isso fica declarado.
- **Índice e árvore divergiam:** o estágio foi refeito por último, arquivo a arquivo. Ficaram fora os logs de
  runtime (`session-lifecycle.jsonl`, `metrics/*.jsonl`).

## Um defeito que só apareceu no rebase

Refeito sobre o `main` com #820 e #821, o pre-commit reprovou `outbox-channel: severidade` com **HARD 32→33**.
A HARD a mais era a REGRA 11 (Método de abstração usado no consumidor deve existir na interface) acusando
`addComment()` em `agents/meta/onion.md`, só que `addComment` **está** na interface. O veredito vinha de
`printf '%s\n' "${methods}" | grep -qx "${m}"` sob `pipefail`: é a classe pipe-verdict já registrada nesta casa,
o leitor devolvendo falso sob concorrência. O `lint-artifacts.sh` tinha **8 sítios tolerados** pela catraca
(`pipe-verdict-baseline.txt`). Os 15 vereditos por pipe viraram here-string, e a linha saiu do baseline, com o
emissor confirmando 0. Não é "flaky": é um veredito que mentia às vezes e agora não mente.

## O que fica declarado, não curado

**Citações textuais a ids colhidos.** `D_ADOPT_ENTREGA_CLAUDE_MD_FUNDIDO` segue citado no cabeçalho do
`claude-md-fuse.sh`, no `adopt.md` e na bancada; `I_FECHAMENTOS_TRIVIAIS`, `I_GTM_JSONL_PERSISTIDO`,
`I_CONSOLE_AUTOOFF` e `I_FORGE_PARSE_GITLAB_SUBGRUPOS` aparecem em outros grafos. A colheita é **por desenho**:
o nó sai do grafo vivo e continua no histórico do git, e a REGRA 29 (proveniência invertida) protege o que está
ancorado em trace, não menção em prosa. Resolver cada menção é trabalho de outra passada.

## Colheita (REGRA 63 (Colheita de grafo emite os ids colhidos no resíduo de revisão))

Ids colhidos de `docs/onion/graph/fios-abertos.kg.yaml`:
I_JWKS_ATTEMPTED_AT, I_LINT_VE_WORKFLOWS, I_GTM_JSONL_PERSISTIDO, I_CONSOLE_AUTOOFF, I_FECHAMENTOS_TRIVIAIS,
Q_SELFTEST_VENDORIZADO_INSATISFAZIVEL_NO_ADOTANTE, D_ADOPT_ENTREGA_CLAUDE_MD_FUNDIDO,
E_BANCADA_NO_ADOTANTE_MEDIDA_0903, I_FORGE_PARSE_GITLAB_SUBGRUPOS

## Mutantes (todos executaram e morreram)

```
claude-md-fuse volta a OBRIGAT(Ó|O)RI[OA]   → (f) ✗ "esperava rules, veio: boilerplate"
projection-safety volta a [—–\/;,]           → shell-locale ✗ citando o sítio
claude-md-fuse volta a [ÓO]                  → shell-locale ✗ citando o sítio
relatório "0\n0"                             → órfã=1 (as contagens antigas davam 2 = 2)
REGRA 16 em C, antes/depois                  → fixture citada 0 → 1
```

## Gate

```
bancada (LC_ALL=C, --jobs auto) : 1202 pass · 0 fail · 0 skip (162 famílias, 8 workers)
lint (pre-commit, LC_ALL=C)     : 0 HARD — o commit só existe se o hook passou
```
