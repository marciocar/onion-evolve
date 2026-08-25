# Migalhas — como publicar (o manual)

> **Modelo mental em uma linha:** você edita **UM** arquivo de fonte; o **build Astro** projeta as
> superfícies. Você nunca edita HTML/RSS à mão — eles nem existem mais no repo.

Este diretório é uma instância de `fonte≠derivação` ([doutrina](../../../docs/knowledge-base/concepts/source-vs-derivation.md)).
**Cutover 2026-08-25 (F2 da reforma):** o `migalhas-generate.sh` foi **aposentado** — a aposta do ADR
de julho ("posts Astro-shaped de propósito") pagou, e os mesmos `posts/*.md` viraram o input direto
da coleção Astro, sem retrabalho:

```
posts/*.md  ──►  build Astro (site/src/)  ──►  dist/historia/migalhas/{index.html, provas/, feed.xml}
 (a FONTE)        (as páginas .astro leem              (as PROJEÇÕES, derivadas — dist/ é
                   a coleção `migalhas`)                 gitignored e vai ao ar pelo deploy)
```

- A **fonte** é `posts/YYYY-MM-DD-slug.md` — um arquivo por migalha (31 dos 41 originais usam
  data+slug descritivo; esse é o padrão).
- As superfícies são **build**: `ops/deploy-site.sh` builda por dentro (deploy E `--check`) e publica
  `dist/`. A REGRA 34 mudou de roupa mantendo o espírito: o que reprova (HARD) agora é **derivação
  commitada** (`site/dist*` tracked no git).
- Quem renderiza: `site/src/pages/historia/migalhas/index.astro` (+ `provas/index.astro` e
  `feed.xml.js`), sobre a coleção definida em `site/src/content.config.ts`.

---

## Publicar uma migalha nova

**1. Escreva a fonte.** Crie `posts/AAAA-MM-DD-slug.md`:

```markdown
---
slug: 2026-07-22-meu-slug
type: learning            # learning | innovation | decision | error | observation | reflection
date: 2026-07-22
review_after: 2026-10-20  # a data de re-teste (o countdown do site vem daqui)
title: "Um título em 1ª pessoa, honesto, sem hype"
rss: "O resumo de 2-4 frases — vira o card das Provas E a descrição do RSS (uma fonte só)."
prs: []                   # ou uma lista (ver abaixo). [] = sem prova de PR/commit
---
## O que descobri
Um ou mais parágrafos. Markdown: *ênfase*, `código`, [link](url). Parágrafos separados por linha em branco.

## A prova
O que existe como evidência.

## Onde isso nos levou
A consequência — o que mudou no jeito de trabalhar.
```

**2. Confira o build** (opcional — o deploy builda sozinho):

```bash
cd site && npx astro build   # o post novo entra em dist/historia/migalhas/ + feed
```

**3. Revise o diff** (`git diff site/historia/migalhas/posts/`) e **4. faça deploy**
(`ops/deploy-site.sh` — ele builda por dentro e publica).

### O campo `prs` (opcional)

Prova objetiva, público-segura — o repositório é privado, então **nunca** se linka o PR; só o metadado:

```yaml
prs:
  - {label: "PR #394", status: "mergeado", meta: "16 jul · 1 arquivo · +325 −0"}
  - {label: "commit e750023", status: "na main", meta: "9 jul · 3 arquivos · +47 −2"}
```

`label` é verbatim (`PR #NNN` **ou** `commit XXXX`). `prs: []` → o card das Provas sai sem o bloco de metadados.

---

## Editar uma migalha existente

Edite o `posts/*.md` e rode o gerador de novo. **Não** edite `index.html`/`provas`/`feed.xml` à mão dentro dos
marcadores — some no próximo `generate`, e o lint acusa HARD antes disso.

## De onde vem o texto (a curadoria)

O texto das migalhas é **derivação editorial curada** do diário (`.claude/diary/`, `classification: public`) —
nunca dump verbatim. Essa tradução (remover jargão, 1ª pessoa, público leigo) é passo de **curadoria** (feito
com julgamento, uma vez por migalha) que **produz** o `posts/*.md`. O gerador, daí em diante, é
**determinístico** — não reescreve texto, só projeta a estrutura. Curadoria ≠ geração.

---

## Deploy (passo manual, na KVM 8)

O gerador escreve em `site/` (a fonte). O webroot `/var/www/onion-landing/` é **derivado** — publica-se à mão,
depois de revisar o diff:

```bash
W=/var/www/onion-landing; S=/home/marcio/onion-evolve/site; D=$(date +%F)
# backup datado
cp -p $W/historia/migalhas/index.html        $W/historia/migalhas/index.html.bak-$D
cp -p $W/historia/migalhas/provas/index.html $W/historia/migalhas/provas/index.html.bak-$D
cp -p $W/historia/migalhas/feed.xml          $W/historia/migalhas/feed.xml.bak-$D
# deploy (cp direto — estamos NA KVM 8)
cp $S/historia/migalhas/index.html        $W/historia/migalhas/index.html
cp $S/historia/migalhas/provas/index.html $W/historia/migalhas/provas/index.html
cp $S/historia/migalhas/feed.xml          $W/historia/migalhas/feed.xml
```

> ⚠️ **NUNCA** `rsync --delete` na raiz do webroot — apagaria `/mini/` e `/pulse-mais/`, cujas fontes vivem
> em **outros** repositórios. Sempre por-arquivo.

---

## O que o sistema garante (as travas)

| Trava | O quê |
|---|---|
| **REGRA 34** (`lint-artifacts.sh`) | derivação commitada (`site/dist*` tracked) → **HARD**. O litmus "edito em um" segue estrutural — a fonte é `posts/` + `src/`; o HTML não existe mais no repo para ser editado à mão. |
| **`ops/deploy-site.sh --check`** | builda por dentro e compara dist×webroot por hash; sai 1 em drift (bancada própria: `--selftest`). |
| **Projeção segura** (REGRA 30) | nome comercial de parceiro numa superfície pública → HARD. |
| **Curadoria público-safe** | o repo é privado; a página de Provas só mostra metadado objetivo, nunca o corpo do PR. |

## Notas

- `posts/*.md` é **Astro-shaped** de propósito: quando o blog migrar para SSG-git/Astro (D1 do
  [ADR](../../../docs/analysis/onion-adr-blog-publication-generator-2026-07.md)), estes arquivos viram o input
  do Astro sem retrabalho. **A aposta pagou em 2026-08-25**: os mesmos arquivos viraram a coleção
  Astro sem tocar em um post; a "projeção interina" (o gerador) foi aposentada nesse dia.
- Dia-da-semana do RSS é calculado por Sakamoto (determinístico, sem relógio — `datetime` é bloqueado no
  harness). Verificado contra o feed vivo.
- A voz autoral do maestro (ensaios — D3) é **gated**: nasce quando o 1º ensaio real provar o contêiner.
