# Onboarding do adotante — como um projeto adota o Onion

> KB canônica (vendorizada — viaja no `/meta:adopt` para todo adotante). É a **fonte** da orientação de
> adoção; guias de onboarding específicos (por adotante) devem **apontar para cá**, não duplicar.

O Onion **não mistura projetos**: cada projeto vira um repo que *adota* o framework — recebe uma cópia
vendorizada de `.claude/` + `docs/` e passa a rodar o mesmo gate determinístico. A cópia limpa do
framework é a **fonte**; cada adoção é uma projeção dela num projeto-alvo.

## `/meta:adopt` é um comando do Claude Code

Você **digita no chat do Claude Code** (não no terminal), com a cópia do framework aberta, apontando
para o projeto-alvo. O adopt é **never-clobber**: nunca sobrescreve o que já existe no alvo — extrai
para tmp, faz *diff*, aplica só após revisão. E carimba um `.claude/.onion-version` (o marcador de papel).

**Sempre comece com `--dry-run`** — mostra o que fará, sem tocar em nada.

## Os quatro casos (o comando muda conforme o estado do alvo)

| Estado do projeto-alvo | Comando (no chat do Claude Code) | O que acontece |
|---|---|---|
| **NOVO** (pasta vazia / recém-criada) | `/meta:adopt <path> --mode greenfield` | Instala o framework do zero. Greenfield-first. |
| **EXISTENTE** com código próprio | `/meta:adopt <path> --mode legacy` | Vendoriza o `.claude/` **sobre** o código, sem tocá-lo (never-clobber). |
| **Já tem adoção Onion ANTIGA** | `/meta:adopt <path> --update` | Atualiza a superfície vendorizada preservando customizações (merge estrutural via branch `onion/vendor`, idempotente). NÃO é re-adoção do zero. |
| **Tem `.claude/` de OUTRO framework** (não-Onion) | `/meta:adopt <path> --dry-run` **primeiro** | O never-clobber não apaga o `.claude/` alheio, mas os dois podem conflitar. Revise o diff do dry-run; se houver conflito, faça backup do `.claude/` antigo antes de aplicar. |

**Domínio regulado** (saúde, fintech, dado sensível): considere `--mode regulated` — puxa a régua de
compliance (agentes ISO 27001 / SOC2 / 22301). Requer que a cópia-fonte seja **cheia** (inclua a
categoria `compliance`), não um bundle distilado.

## Duas regras de ouro (aprendidas em campo)

1. **Rode o lint DENTRO do repo adotado, nunca só na fonte.** `bash .claude/validation/lint-artifacts.sh`
   no repo do alvo. O repo-fonte é o **pior oráculo** do que viaja: um guard verde na fonte pode quebrar
   no adotante (escopo, ausência de `members.yaml`, arquivos core-only não-vendorizados).

2. **A verdade de um adotante é um CLONE FRESCO, não o working dir.** Ao gerar/validar uma adoção,
   verifique num `git clone` limpo — o working dir de quem gerou pode ter arquivos *untracked* (ex.: o
   `.onion-version`, que é gitignored na fonte) que mascaram o que o clone realmente recebe. Um stamp
   `role: adopted` que não foi commitado deixa o clone sem o marcador de papel → todos os guards de
   adotante desligam → falso-HARD em massa. A REGRA "adotante trackeia o `.onion-version`" guarda isso.

## Depois de adotar

Trabalhe no projeto pelo Claude Code normalmente — os workflows `/product/*`, `/engineer/*`, `/docs/*`,
`/meta/*` já estão disponíveis. Um projeto de cada vez: prove o método num antes de adotar o próximo.
