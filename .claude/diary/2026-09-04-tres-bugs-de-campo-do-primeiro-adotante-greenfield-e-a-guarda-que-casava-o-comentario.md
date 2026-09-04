---
date: 2026-09-04
instance: onion-evolve
type: learning
classification: public
tags: [co-evolucao, upstream, adopcao, inventario, idioma, bancada, dogfood]
affects: [meta, engineering]
breadcrumb_for: []
share_with: [portal-gamificacao]
next_recommended: "responder os 6 sinais no _processed com a triagem; a feature do kg-inbox e os 2 field-signals seguem"
review_after: 2026-12-03
conflict_class: static
---

# Três bugs de campo do primeiro adotante greenfield — e a guarda que casava o comentário

O `portal-gamificacao` adotou o Onion hoje e mandou **6 sinais** no mesmo dia. Os três bugs eram todos de superfície de adoção, e nenhum apareceria no core sozinho:

1. **`.claude/workflows` não viajava.** A skill `onion-research` (vendorizada) instrui `Workflow({scriptPath: '.claude/workflows/onion-research.js'})` — o dir não estava no `want=`, então o comando **nascia morto** no adotante. Mesma classe da REGRA 74 (Caminho .claude/ NU dentro de plugin só resolve no core, com catraca), agora na superfície de adoção.
2. **`inventory.sh` contava gitignorado.** Enumerava por `find`; o adotante tinha `.md` extraído e ignorado, então o lint local ficava verde e o CI, num checkout limpo, reprovava a REGRA 8 (Inventário canônico sincronizado com o filesystem). Cura: enumerar por `git ls-files` (mesmo conjunto que o CI), com fallback declarado para `find` onde não há git.
3. **`durable-commit.sh` escrevia assunto em inglês.** "adopt to pin X" contra a política pt-BR ratificada em 2026-08-03. A revisão adversarial **do adotante** pegou. Cura: assunto pt-BR por default e `SUBJECT=` para alvo com política própria.

**O achado que o dogfood da própria bancada deu:** o caso (b) passava verde com o mutante aplicado, porque o `grep` casava o **comentário explicativo** que eu havia escrito acima do `want=` — a prosa citava `.claude/workflows` e satisfazia o assert. Guarda que valida comentário não é guarda. Corrigido para exigir a string dentro do `want=` ignorando linhas `#`; só então o mutante mordeu.

**Padrão que se repete:** o adotante é o oráculo. Três defeitos de anos-luz de distância do core apareceram no primeiro dia de uso real de outra pessoa — e dois deles (1 e 2) tornam o artefato inutilizável em silêncio.
