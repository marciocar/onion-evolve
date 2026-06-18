# 📣 CHANGELOG de co-evolução — anúncios do core aos projetos (fluxo A)

> Log **append-only**. O core registra aqui mudanças do framework **relevantes aos projetos** que o
> adotam (ex.: bumps que pedem `/meta:adopt --update`, fixes que afetam adotantes, breaking changes).
> Cada projeto puxa e decide em casa. Não reescrever entradas (auditoria). Formato por entrada:
>
> `## <AAAA-MM-DD> · <assunto> · <COMPATÍVEL|BREAKING> · alvo: <ids ou "todos">`

---

## 2026-06-18 · Bootstrap do canal de co-evolução · COMPATÍVEL · alvo: todos

- Criado `docs/evolution/` no core (modelo dos 3 fluxos, inbox upstream, RFC-0001 canônica) e este registro.
- Nenhuma ação requerida dos projetos. A partir daqui, mudanças do framework relevantes aos adotantes são anunciadas neste log.

## 2026-06-17 · fix `/meta:adopt` never-clobber `.env.example` (#89) · COMPATÍVEL · alvo: futuros adotantes

- O `/meta:adopt`/`--update` deixou de sobrescrever o `.env.example` do projeto-alvo (escreve `.env.example.onion` se já existir).
- Origem: sinal de campo do `rhilo-metagamify` (dogfooding) — ver [`../inbox/2026-06-17-veredito-strategy-layer.md`](../inbox/2026-06-17-veredito-strategy-layer.md) e o bug `adopt-env-example-clobber`.
- Ação p/ adotantes existentes: nenhuma retroativa; vale na próxima adoção/update.
