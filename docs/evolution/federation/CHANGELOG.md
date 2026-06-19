# 📣 CHANGELOG de co-evolução — anúncios do core aos projetos (fluxo A)

> Log **append-only**. O core registra aqui mudanças do framework **relevantes aos projetos** que o
> adotam (ex.: bumps que pedem `/meta:adopt --update`, fixes que afetam adotantes, breaking changes).
> Cada projeto puxa e decide em casa. Não reescrever entradas (auditoria). Formato por entrada:
>
> `## <AAAA-MM-DD> · <assunto> · <COMPATÍVEL|BREAKING> · alvo: <ids ou "todos">`

---

## 2026-06-19 · `/meta:adopt --integration-branch` + base do PR resolvida do `.onion-version` (#104) · COMPATÍVEL · alvo: adotantes

- `/meta:adopt` ganhou `--integration-branch <nome>` (carimbado no `.onion-version`, campo `integration_branch`); `/engineer:pr` passou a **resolver** a base do PR via `.claude/validation/resolve-integration-branch.sh` (cadeia: `.onion-version` → `git config gitflow.branch.develop` → default detectado) em vez de hardcodar `develop`.
- Útil para adotantes com branch de integração própria (ex.: `<projeto>-evolve`, separada da branch de produto).
- Ação p/ adotantes: opcional. Sem escolha explícita, a base resolve por detecção (sem regressão). Para fixar uma branch, rodar `/meta:adopt --update <repo> --integration-branch <nome>`.

## 2026-06-18 · warm-up aponta para o inbox de co-evolução + `/meta:co-evolve` (#102) · COMPATÍVEL · alvo: adotantes

- `warm-up.md` (root) e `engineer/warm-up.md` passaram a apontar para `docs/evolution/inbox/` + `/meta:co-evolve` quando o diretório existe (silencioso se vazio; o hook "you have mail" continua contando).
- Ação p/ adotantes: nenhuma; chega via `/meta:adopt --update`.

## 2026-06-18 · `/meta:adopt --update` idempotente + Procedimento de Configuração pós-cópia (#99) · COMPATÍVEL · alvo: adotantes

- O `--update` passou a re-aplicar os passos install-only via "Procedimento de Configuração pós-cópia (idempotente)" — merge never-clobber dos hooks Onion no `settings.json` (helper testável `merge-onion-hooks.sh`) + starter `docs/evolution/`. Sem isto, um adotante com `settings.json` próprio recebia os *scripts* dos hooks mas não o **registro** (o "you have mail" não disparava).
- Ação p/ adotantes existentes: rodar `/meta:adopt --update` para receber o registro dos hooks; idempotente (re-rodar não duplica).

## 2026-06-18 · Bootstrap do canal de co-evolução · COMPATÍVEL · alvo: todos

- Criado `docs/evolution/` no core (modelo dos 3 fluxos, inbox upstream, RFC-0001 canônica) e este registro.
- Nenhuma ação requerida dos projetos. A partir daqui, mudanças do framework relevantes aos adotantes são anunciadas neste log.

## 2026-06-17 · fix `/meta:adopt` never-clobber `.env.example` (#89) · COMPATÍVEL · alvo: futuros adotantes

- O `/meta:adopt`/`--update` deixou de sobrescrever o `.env.example` do projeto-alvo (escreve `.env.example.onion` se já existir).
- Origem: sinal de campo do `rhilo-metagamify` (dogfooding) — ver [`../inbox/2026-06-17-veredito-strategy-layer.md`](../inbox/2026-06-17-veredito-strategy-layer.md) e o bug `adopt-env-example-clobber`.
- Ação p/ adotantes existentes: nenhuma retroativa; vale na próxima adoção/update.
