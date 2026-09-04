---
title: "Política de idioma do canal público de plugins (decisão R2) — o Elenxo reprova (i)/(ii)/(iii) como formuladas e propõe (i′)"
date: 2026-09-04
kg: docs/evolution/research/plugin-language-policy-2026-09/plugin-language-policy-2026-09.kg.yaml
run_id: wf_bde10f3f-28c
tokens: 6854451
agents: 105
duration_min: 34
genre: decision
mode: decision
budget: { maxFetch: 15, maxVerify: 25 }
review_after: 2026-10-04
---

# Política de idioma do canal público — decisão R2

> **Projeção** do grafo (26 nós, radar exit 0). Nó de decisão **`D_PLUGIN_LANGUAGE_POLICY_CANAL_PUBLICO`** (status `open`) — o maestro sela pela tabela do `/meta:drive` (KIND decision). Norte dado pelo maestro: internacional.

## Custo declarado

| Item | Valor |
|---|---|
| Tokens | 6.854.451 (medido pela ferramenta) |
| Workers do run | 105 · 15 fontes · 33 claims · 25 verificadas (7 confirmadas, **18 refutadas**) |
| Parede | ~34 min |

## O que se confirmou (3-0)

- A política de diretórios da Anthropic (tier 9) exige descrição precisa, ≥3 exemplos de prompt, política de privacidade e contato — e **não declara idioma nem campo de locale** (três recortes da mesma página; o Elenxo pesa isso abaixo).
- Tradução mantida à mão em repos grandes morre: mediana 0 commits em 6 meses contra 8,5 do original (paper, tier 6). Vale para prosa escrita; **não** para superfície gerada e travada pela REGRA 19.
- Idioma de resposta confiável se fixa por **instrução explícita** no prompt/system, não pela inferência do modelo (Anthropic, tier 10).

## O veredito do Elenxo (o que o maestro sela)

**Reprova (i), (ii) e (iii) como formuladas e recomenda (i′).** A premissa comum — "superfície é gerada, corpo é escrito" — é **falsa neste repo, medida**: as 8 descriptions de `plugin.json` são escritas à mão (o gerador só copia); os READMEs gerados imprimem tabelas a partir do `description:` de frontmatter de 134 artefatos embarcados (176 na fonte) mais `argument-hint`; e os geradores carregam ~49 blocos de prosa pt-BR. "Só as superfícies em EN" não é uma mudança de gerador; sem isso, sai README metade EN metade pt-BR — proibido pela L0 (`code-standards.md §1`: camada mista).

**(i′):** superfície pública = **tudo que os geradores emitem** + `plugin.json` + `argument-hint` + os ≥3 exemplos de prompt — o que inclui, por consequência mecânica, o `description:` de frontmatter de todo comando/agente/skill **embarcado em plugin**. pt-BR fica abaixo do frontmatter (o corpo, onde a doutrina vive) e, se necessário ao leitor pt-BR, num `README.pt-BR.md` **gerado** pelo mesmo pipeline — nunca seções misturadas, nunca à mão.

## CONSTRAINS (objeções sobreviventes que gateiam a execução)

1. **Spec antes de gerador.** A L0 hoje sanciona "frontmatter (valores narrativos): pt-BR aceito". Sem emenda ao `code-standards.md §1` via `@metaspec-gate-keeper`, (i′) é violação de L0. Nenhuma linha de gerador antes disso.
2. **Nenhuma observação do venue foi feita.** Zero plugins do diretório/mirror inspecionados. Antes de selar: censo por `gh api` no `claude-plugins-community` (quantos `plugin.json` com description não-EN; READMEs por idioma) + leitura do `plugins-reference` (há campo de locale?). Se houver não-anglófonos instalados e ranqueados, (i′) vira preferência, não necessidade.
3. **`description:` é gatilho, não rótulo.** Mexer em 176 descriptions muda o **roteamento** de skill/comando em runtime. Dogfood obrigatório antes do merge: os mesmos comandos em sessão EN e pt-BR, observar ativação e idioma de resposta.
4. **Bilíngue só por arquivo e só se gerado** (REGRA 19). Linha de tradução que precise de humano é recusada no desenho.
5. **Nomear os ≥3 exemplos de prompt** — a única superfície que o revisor executa; EN, derivados do gerador, testados.
6. **Não tratar silêncio como permissão, nem contar 3 onde há 1.** A decisão se carimba como **convenção sob evidência ausente (reversível)**, e o carimbo diz qual medição (2 ou 3) a reabre.

## Mercado (eixo invariante)

Sem sinal de capital. O escasso no diretório é confiança (selo) e coesão do bundle, não localização. A claim "repos EN têm mediana de estrelas muito maior" foi **refutada** — não usar "penalidade de descoberta" como argumento.

## NÃO-VERIFICADOS (declarado)

- **Refutados (18)**: "Claude infere o idioma da conversa, não do comando"; "penalidade de estrelas do não-inglês"; "convenção vscode-nls"; "padrão observado em marketplaces comunitários"; todas as observações sobre projetos japoneses/chineses/brasileiros.
- **Fora do orçamento**: 8 claims não verificadas, 34 fontes não lidas — entre elas as do eixo mais importante (plugins não-anglófonos no venue).
- **Caveat do run**: a recomendação deriva de duas premissas negativas (a política não exige; a duplicação custa) e de coerência com a casa — **não de precedente medido no ecossistema**.

## valeu-a-pena

6,85M tokens ÷ 26 nós ≈ **264k/nó** — 3,6× o censo (68–74k). O que se comprou: a **refutação da premissa** das três opções (medida no repo) e as 6 constraints — sem o Elenxo, eu teria selado (i) e produzido README de camada mista. O custo alto veio dos 18 refutados (fontes fracas no eixo do venue). Reabertura barata: o censo por `gh api` (constraint 2) custa uma sessão curta, não outra rodada.

## O que muda no plano

| Antes (plano F3) | Depois (R2) |
|---|---|
| Implementar (i) direto com `PLUGIN_DESC_EN`/`description_en` | **F3 ganha um passo 0**: emenda da L0 (`code-standards.md §1`) pelo gate-keeper + censo do venue + dogfood EN/pt-BR de roteamento |
| Superfície "as que os geradores emitem" (retórica) | Superfície **definida mecanicamente** (o que os geradores emitem, incl. `description:` dos artefatos embarcados) |
| README bilíngue em seções | `README.pt-BR.md` **gerado**, nunca seções mistas |
| — | ≥3 exemplos de prompt por plugin em EN, gerados e testados (também exigido pelo diretório) |
