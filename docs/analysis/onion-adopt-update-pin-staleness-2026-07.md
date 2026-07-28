# Candidato de feature — aviso de pin vencido no `/meta:adopt --update`

- **Status:** BACKLOG — proposto, **não implementado**. Priorização é decisão do maestro.
- **Origem:** sinal upstream do adotante **arandek**, triado 2026-07-27 (`docs/evolution/inbox/_processed/2026-07-27-correcao-pin-declarado-no-sinal-anterior.md`).
- **Diário-par:** `.claude/diary/2026-07-27-adopt-update-pin-staleness.md`
- **Família:** `declarado≠verificado` · `fix-must-become-mechanism`

## Problema

O `/meta:adopt --update` atualiza o pin canônico do adotante (`.claude/.onion-version`: `source_commit`, `updated_at`, `integration_branch`). Mas o pin vive **derivado** em artefatos que o comando **não toca**:

- memórias de sessão (gravadas na adoção original);
- frontmatter de sinais de co-evolução em rascunho;
- docs que citam a versão do core.

Quando o update roda, o `.onion-version` avança e essas cópias ficam para trás — **em silêncio, sem nada avisar**. O artefato derivado passa a declarar um pin que não é mais o vivo.

## Evidência de campo

O arandek adotou em 2026-07-24 (pin `5e3ea5ee46ac`) e atualizou em 2026-07-25 (pin `65d8a7501a03`, branch `develop`). Um sinal upstream posterior carimbou no frontmatter `source_commit: 5e3ea5e` — **o pin da adoção original, não o vivo** — porque o valor veio da memória de sessão nunca reconciliada no update.

Efeito na triagem do core: se a decisão usasse o pin para aferir se um fix já entregue alcançou o adotante, a conta partiria de "dois dias e um update de distância". No caso, o conteúdo não foi afetado (o adotante verificou os fixes **contra o filesystem, não a prosa**, e a lacuna do radar `UNANCHORED` nasceu depois do pin correto), mas a classe de erro é real.

## Proposta

No `/meta:adopt --update`, após reescrever o `.onion-version`:

```
grep -rl "<pin-antigo>" <repo-do-adotante>   # excluindo .git/, node_modules/
```

e reportar a **contagem** no relatório de update: *"N referências ao pin anterior (`<pin-antigo>`) neste repo — revise (memórias, frontmatter, docs)."*

O grep **detecta**, não conserta — corrigir cada artefato exigiria entender a semântica de cada um (uma memória pode citar o pin historicamente de propósito). Detectar-e-avisar pega a classe inteira a custo baixo.

## Custo × benefício

- **Custo:** um `grep -rl` + uma linha no relatório. Trivial.
- **Benefício:** fecha uma porta da família `declarado≠verificado` — a mesma que mordeu o próprio core (memória stale sobre o estado do bridge, nesta mesma janela). `fix-must-become-mechanism`: o aprendizado vira guarda no comando.
- **Fronteira honesta (do próprio adotante):** "pode ser que o custo não compense para uma classe de erro que só morde quem escreve frontmatter à mão." Registrado como observação, não pedido (R15.2).

## Decisão

Aceito como **backlog**. Implementar/priorizar é do maestro. Se aprovado, o toque é em `.claude/commands/meta/adopt.md` (fase de update) — pequeno, com selftest do grep sobre um pin antigo plantado.
