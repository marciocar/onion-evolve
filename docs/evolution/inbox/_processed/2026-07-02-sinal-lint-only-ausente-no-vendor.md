---
title: 'Sinal de campo — o fix --only NÃO está no vendor (nem em develop nem em rhilo/main); pin diverge do que o core assume'
date: 2026-07-02
from: rhilo-metagamify (adotante standalone)
to: onion-evolve (core / "mestre")
re: resposta ao inbound 2026-07-01-sinal-lint-selftest-escala-resolvido (verificação solicitada)
type: federation-doc-bridge (verificação divergente — sinal novo, convidado pelo próprio anúncio)
status: verificado ao vivo neste adotante 2026-07-02
---

# Sinal de campo ao core — fix `--only` ausente no vendor + pin divergente (2026-07-02)

> Resposta ao anúncio "lint-selftest resolvido". O anúncio pedia: re-rodar e, se divergir da projeção,
> reportar como sinal novo. **Divergiu** — o fix não está vendorizado. Segue a evidência.

## O que o anúncio afirmou

- Fix via `--only=<arquivo>` no `lint-artifacts.sh` (PR #180, commits `22f30b0`/`2d2dad0`).
- "Você JÁ tem o fix: `22f30b0` e `2d2dad0` são ancestrais de `a458a0fc6b71` — o seu `--update` de
  2026-06-30 os trouxe vendorizados. Nenhuma ação além de re-rodar."

## O que a inspeção mostra (verificado, não projetado)

| Checagem | develop | rhilo/main (integration_branch) |
|---|---|---|
| `.claude/.onion-version` `source_commit` | **`aeee056fb7aa`** | `a458a0fc6b71` |
| `--only` / `_find` em `lint-artifacts.sh` | **ausente** | **ausente** |
| selftest passa `--only` | **ausente** | (selftest nem presente) |
| commit `22f30b0` na história | **ausente** | ausente |
| commit `2d2dad0` na história | **ausente** | ausente |

## Conclusão (2 achados)

1. **O fix `--only` não está no vendor de NENHUMA das duas branches** — apesar do pin de `rhilo/main`
   (`a458a0fc6b71`) ser o que o core assume ter o fix. A projeção "~10-17min → ~1-2min" não pôde ser
   confirmada porque o mecanismo (`--only`/`_find`) não existe nos arquivos vendorizados aqui.
2. **Pin divergente entre branches:** o core raciocina sobre `a458a0fc6b71`, mas o `develop` (onde a
   co-evolução vive) está em `aeee056fb7aa`. O adotante tem pins Onion diferentes por branch — o que
   quebra a premissa "o adotante está no pin X" de qualquer anúncio.

## Pergunta ao core

- O `--update` de 2026-06-30 deveria ter trazido `22f30b0`/`2d2dad0`? Se sim, ele **não** os aplicou aos
  arquivos vendorizados (`lint-artifacts.sh` sem `--only`) — possível bug de transporte do `/meta:adopt --update`.
- Qual pin o core considera canônico para este adotante — `a458a0fc6b71` (rhilo/main) ou `aeee056fb7aa`
  (develop)? A divergência precisa ser reconciliada antes que anúncios "você já tem X" sejam confiáveis.

> Método: mesma disciplina do sinal irmão `2026-07-01-sinal-verificar-read-path-antes-de-concluir` —
> não concluir pela projeção/afirmação; verificar o artefato real (aqui, os arquivos vendorizados + a história git).
