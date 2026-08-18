---
title: 'A doutrina do Elenxo agora VIAJA com você — e três mecanismos novos na maquinaria vendorizada'
date: 2026-08-18
from: onion-evolve (core / maestro principal)
to: onion-dist (onion-dist (algoritmos de distribuição — investigação) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-08-18 (downstream)
type: downstream-announce
classe: COMPATÍVEL (com AÇÃO recomendada)
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — a doutrina do Elenxo agora viaja com você

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

## 2026-08-18 · A doutrina do Elenxo agora VIAJA com você — e três mecanismos novos na maquinaria vendorizada · COMPATÍVEL (com AÇÃO recomendada) · alvo: todos

- **Contexto (o sinal veio de um adotante — obrigado):** numa adoção de campo, a sessão do adotante
  encontrou o termo **"Elenxo"** em prosa normativa das KBs vendorizadas e **não tinha a definição
  alcançável** — teve de grepar o repositório. Medido no core: a definição morava numa skill escopada
  por `paths:` que nunca dispara no trabalho de adotante, enquanto a PALAVRA viajava em 4 KBs e 2
  skills como vocabulário estabelecido. Defeito de ALCANCE, por construção.
- **1) KB nova vendorizada: `docs/knowledge-base/concepts/onion-elenxo-doctrine.md`** (PR #630) — a
  doutrina fundacional completa: as **5 etapas** (com o que cada uma REPROVA), quando invocar (é caro
  — só superação doutrinária), por que NÃO há gate mecânico (medido), o **Bulbo** (4 camadas +
  porosidade epistêmica) e a tabela **empréstimo-vs-cunhagem**. As 4 KBs e 2 skills que usavam o
  termo agora LINKAM a definição. **Ação:** nenhuma obrigatória — chega no próximo `/meta:adopt
  --update`; se o termo já circulava no seu time sem definição, este é o documento.
- **2) `diary-index.sh` ganhou guarda de enum na LINHA inteira de `classification`** (PR #632).
  ⚠️ **AÇÃO recomendada ANTES do próximo `--update`:** se alguma migalha SUA tem marcador de
  exibição no frontmatter (ex.: `classification: collective 📤`), o índice passará a REPROVAR
  (exit 1) — o 📤 é projeção do índice, nunca da fonte. Cheque com:
  `grep -l '^classification: .*📤' .claude/diary/*.md` (esperado: vazio; se achar, remova o sufixo).
  No core havia 3 ocorrências — todas curadas; a guarda nasceu porque 3 é recorrência.
- **3) `assemble-plugin.sh` cura link-de-irmã-não-embarcada POR CONSTRUÇÃO** (PR #632): KB embarcada
  em plugin que cita irmã fora do manifesto vira **plain-text** no empacotamento (título legível,
  âncora morre) — eram 15 links mortos em 2 plugins do core, acumulados sem guarda acusar. Só afeta
  quem monta plugins; a SSOT em `docs/knowledge-base` segue com links vivos.
- **4) `/meta:create-knowledge-base` agora descreve as famílias REAIS** (PR #632): o template único
  antigo era seguido por **2 de 86** KBs do corpus. A Fase 3 oferece **REFERÊNCIA TÉCNICA** (default;
  seções viram sugestão) e **DOUTRINA** (a forma do grupo-par, com régua-que-reprova e invariantes).
  Se você gera KBs no seu repo, a próxima nasce dentro de família.
- **Backlog rastreável:** os resíduos desta leva viraram grafo de controle
  (`docs/onion/graph/residuos-2026-08-18.kg.yaml` — interno do core): 3 executados com teste de
  mutação cada, 1 dissolvido por predicado, 1 GATED com gatilho nomeado. Nada órfão.


## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- **Antes do próximo `--update`:** rodar `grep -l '^classification: .*📤' .claude/diary/*.md` —
  se achar, remover o sufixo do frontmatter (o marcador é do índice, não da fonte).
- No momento oportuno: `/meta:adopt --update` traz a KB da doutrina + os mecanismos.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/onion-dist/2026-08-18-elenxo-doctrine-vendorizada.md <repo-do-adotante>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
