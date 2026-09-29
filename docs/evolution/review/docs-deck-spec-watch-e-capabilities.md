---
title: 'A surpresa era um artefato versionado do próprio repo, e a resposta estava a um grep'
date: 2026-09-29
branch: docs/deck-spec-watch-e-capabilities
reviewed_diff_sha256: f8fa6fbc0e3e169308838906d03f1ae26ee7f2bc8616744d9fa99ce7b4b38872
elenxo: nao
findings_total: 3
findings_real: 3
verdict: CORRIGIDO
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, e o motivo é declarado: o diff é uma seção de conhecimento medido num .md de spec, sem código nem guarda nova. O que havia para refutar — "vale nascer guarda?" — foi respondido por medição no próprio texto: o estado do watch não existe no disco, então a guarda não é construível. Refutador sobre isso mediria a mesma coisa.'
---

# Resíduo — o watch re-armado, as capabilities herdadas, e o grep que eu não rodei

## O que apareceu

O maestro viu no painel de background um **Monitor auto-respondendo comentários** num Artifact, e
disse não ter criado artifact nenhum. Eu tratei como possível surpresa indesejável e fui ler o
Artifact remoto.

## O que era

`docs/onion/deck/SPEC.md`, **rastreado neste repo desde 26/09**, declara na **linha 5**:

```
artifact: https://claude.ai/artifact/Ceu8n8e7Xg7B5EAwmXFLxt
```

É o deck do Onion — *"Sistema Onion — Estrutura, Maquinaria e Ciclo"*, 73 slides, privado, do maestro,
produto do `/design:deck` com spec versionada. **Nada indevido.** A pergunta *"o que é esse
artifact?"* tinha resposta em `grep -rn Ceu8n8e7 docs/`; eu fui ao remoto. **Sétima ocorrência da
classe do dia** — afirmar ou investigar fora quando o repo respondia a um comando.

## Os três achados, e o que entrou na spec

1. **`comments` habilitado** — comentário enviado ao Claude acorda a sessão e pode ser respondido
   automaticamente, e a resposta sai *"Claude · via o usuário"*, ou seja **em nome do dono**.
2. **`mcp` com Google Drive (`create_file`, `gdrive_upload`)** — a página tem declarado o poder de
   criar arquivo no Drive do dono. Herdado do tipo `Slides`, sem uso observado, mas declarado.
3. **O `--resume` RE-ARMA o watch.** Medido: watch armado em 2026-09-28T19:34:41Z voltou sozinho após
   duas compactações e uma retomada, **com auto-reply**. É comportamento documentado do harness, e
   ninguém tinha escrito isso onde se procura por ele.

Ação tomada: watch **desarmado e verificado pelo estado** (0 watches, auto-replies paradas — e elas
não voltam nem com publish, só se o maestro pedir). Os três achados entraram na spec, que é a
superfície que alguém lê antes de mexer no deck.

## Por que NÃO nasceu guarda, e o teto está declarado

Medi antes de propor: **o estado do watch não existe no disco.** As 107 ocorrências da URL no
transcript são **menção, não estado** — um hook que as grepasse dispararia por qualquer citação,
inclusive a que registrou isto. Os `~/.claude/*.json` legíveis são cache de PR, settings e stats;
nenhum guarda watches. O estado vive no **processo** do harness.

Guarda determinística sobre fonte que não existe é exatamente o erro que esta sessão cometeu ontem —
mecanismo inventado sobre lacuna não medida, que custou uma REGRA inteira e uma decisão do maestro
tomada em falso. Aqui a escolha é a oposta: **conhecimento escrito, não catraca**.

O painel de background segue a única janela para esse estado. Depender de eu olhá-lo por rotina é
disciplina, e disciplina não escala — está dito na spec como teto do harness, não do Onion.

## Gates

- `lint-artifacts.sh` → a confirmar no SHA final
- Sem mudança de código: nenhuma família de bancada é afetada (o diff é um `.md` de spec)
- `/meta:realign` → ALINHADO nos 3 grafos nesta sessão, `--check` rc=0

## Declarado aberto

- **Paridade spec × Artifact** segue sem guarda, por decisão anterior escrita na própria spec:
  *"quando ela e o Artifact divergirem a primeira vez, nasce a guarda de paridade — e não antes,
  porque catraca sem drift medido é cerimônia."* Esta leva não muda esse gatilho.
