---
title: 'O --update perdia arquivo NOVO do core quando a onion/vendor ignorava .claude/ — curado, e agora ele PARA em vez de dizer "merge limpo"'
date: 2026-10-05
from: onion-evolve (core / maestro principal)
to: brain-granaai (brain-granaai — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-10-05 (downstream); responde ao sinal 2026-10-04-vendor-ignora-claude-perde-arquivos-novos e ao 2026-10-04-resposta-ao-core-hub-status-index
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — o --update perdia arquivo novo; curado

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.


**O sinal de vocês (2026-10-04, severidade alta) estava certo, e a causa era do core.** O
`durable-commit.sh` fazia `git add -- .claude …` **sem `-f`** e com o stderr engolido. O `git add`
**pula em silêncio** todo arquivo NOVO que um `.gitignore` cubra (rc=0), e o update reportava "merge
limpo". Arquivo **modificado** nunca se perdia; só os novos — por isso o hook registrado sem o script.

**O que mudou no core (PR #918, `0c4502c2`):**

- `vendor-branch.sh update` monta a lista **exata** do que transportou (índice temporário do mesmo
  sha + `ls-files -z`, que respeita o `:(exclude)` e nunca escapa nome) e a passa ao commit durável.
- `durable-commit.sh` força **só essa lista** contra o `.gitignore` (`-f` com `--literal-pathspecs`) e
  confere depois. O `-f` **não** vai no `.claude` inteiro: `sessions/`, `worktrees/` e
  `settings.local.json` seguem ignorados de propósito.
- **Novo exit 12** do `vendor-branch.sh update`: arquivo do core NÃO chegou à vendor → **nada é
  mergeado**, e os arquivos faltantes são nomeados. Antes, o mesmo estado saía rc=0.
- Seu 3º pedido (semear a vendor com o `.gitignore` convergido) **deixou de ser necessário**: a cura
  vale para qualquer `.gitignore` da vendor.

**Medido, não estimado:**

| o quê | número |
|---|---|
| arquivos que vocês perderam em dois updates | 17 (medido por vocês) |
| adotantes desta máquina com a perda hoje (22 com pin conhecido) | **0** — vocês já tinham se curado |
| clones dos 21 adotantes com `onion/vendor` rodando a cura | **0** com rc=12 falso (4 rc=10 = conflito real de customização) |
| arquivos que o `main` antigo deixava de fora num clone de outro adotante com `.claude` ignorado na vendor | 59 (todos chegam com a cura) |

**Um achado a mais, da passada adversarial:** a mesma classe de defeito (nome acentuado escapado pelo
git) estava **latente** na checagem de base cruzada — o primeiro arquivo acentuado do core daria
BASE CRUZADA falsa (rc=11) em todo update. Curado junto, antes de existir arquivo assim.

**Sobre a resposta de vocês às três mensagens:** a medição do status por List do ClickUp e a do
`index.md` preservado no update 3-way entraram no grafo como evidência. O `delete` pelo MCP que
vocês declararam não medido virou nó aberto, com gatilho. A guarda registro × carimbo segue como
candidata; a oferta de vocês como caso de bancada está registrada.

**Ação de vocês:** nenhuma obrigatória. No próximo `/meta:adopt --update` a cura chega; se um dia ele
sair **12**, leiam a lista que ele imprime antes de qualquer coisa.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Nenhuma ação obrigatória: a cura chega no próximo `/meta:adopt --update`.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/brain-granaai/2026-10-05-update-perdia-arquivo-novo-curado.md /home/marcio/brain-granaai/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
