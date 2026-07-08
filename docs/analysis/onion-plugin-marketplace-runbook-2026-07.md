# Runbook — Publicar e instalar o marketplace de plugins Onion (Fase 5)

> **Status:** operacional/interativo · **Data:** 2026-07-08 · **Gated:** o acesso-por-grupo (role-scoping
> nativo) exige plano **Team/Enterprise** do Claude; o resto funciona em qualquer plano.
>
> Operacionaliza o último passo da estratégia de distribuição (ADRs
> [`onion-adr-exchange-unit-2026-06`](onion-adr-exchange-unit-2026-06.md) +
> [`onion-distribution-strategy-2026-06`](onion-distribution-strategy-2026-06.md)). As **Fases 1–4**
> (maquinaria no repo) estão feitas; esta Fase 5 é **interativa** (o maestro roda `/plugin …` no Claude
> Code) e não pode ser automatizada por script no repo.

## Pré-requisitos (já satisfeitos pelas Fases 1–4)

- `.claude-plugin/marketplace.json` com 6 verticais registrados (`onion-{design,compliance,engineering,product,testing,docs}`).
- `plugins/<name>/` gerados e validados (drift-guards lint R19/R20).
- `.claude/utils/marketplace/roles.yaml` (mapa role→bundle) + `resolve-role-bundle.sh` (resolver).
- Para o **acesso-por-grupo**: conta **Team ou Enterprise** (admin).

---

## Parte A — Publicar o marketplace (torná-lo instalável)

O marketplace é um **repo git** (GitHub syncing = updates versionados). No Claude Code:

```
/plugin marketplace add marciocar/onion-evolve
```

- Aponta para o repo do core; o `.claude-plugin/marketplace.json` é lido de lá.
- Verificar: `/plugin marketplace list` → deve listar `onion-evolve` com os 6 plugins.
- Updates: quando o core publica novos verticais/versões, `/plugin marketplace update onion-evolve`
  (ou o auto-update, se habilitado) traz as mudanças. Pin de versão por plugin é nativo.

## Parte B — Instalar um vertical (qualquer plano)

```
/plugin install onion-engineering@onion-evolve
```

- Ou pelo menu `/plugin` (navega o marketplace, instala com 1 clique).
- Verificar: os comandos do vertical aparecem (`/engineer:*`, `/git:*`) e os agentes ficam disponíveis.
- ⚠️ **Caveat `${CLAUDE_PLUGIN_ROOT}` em command markdown** (upstream claude-code #9354): a substituição
  pode ser não-confiável no markdown de comando. Testar ao vivo um comando do vertical que referencie
  um componente bundlado (util/validation); se o path não resolver, reportar/aguardar o fix upstream ou
  usar o vertical via os agentes (que resolvem por nome).

## Parte C — Acesso-por-grupo = role-scoping nativo (SÓ Team/Enterprise)

É aqui que o `roles.yaml` vira execução. O admin (hPanel de plugins da org) cria **grupos espelhando os
papéis** e configura, por grupo, quais plugins **auto-instalam / ficam disponíveis / ficam escondidos**.

Para cada papel, o bundle vem do resolver (não da memória):

```
bash .claude/utils/marketplace/resolve-role-bundle.sh standalone                 # base
bash .claude/utils/marketplace/resolve-role-bundle.sh standalone --with-optional # base + opcionais
```

Mapa recomendado (do `roles.yaml`):

| Grupo (papel) | Auto-install (base) | Disponível (opcional) | Escondido |
|---|---|---|---|
| **source** (core) | os 6 verticais | — | — (a meta-factory nunca é plugin) |
| **hub** | engineering, product, testing, docs | design, compliance | meta-factory |
| **standalone** | engineering, product, testing, docs | design, compliance | meta-factory |
| **consumer** (T2) | engineering, docs | product, testing | design, compliance, meta-factory |
| **distilled** (mini) | — (não instala) | — | tudo |

Doutrina: **a meta-factory** (`/meta:create-*`, `/meta:adopt`, `/meta:federation-*`, `/meta:evolve`,
`/meta:graph`, `/meta:inventory`) **não é vertical e nunca sai do core** — nenhum grupo a recebe.

## Parte D — Fallback sem marketplace (regulado / air-gapped / sem Enterprise)

`/meta:adopt` continua o caminho (invariante): entrega **sempre** as Camadas 2+3 (docs path-addressed +
governança/co-evolução) **e**, como fallback, a Camada 1 vendorizada. Para vendorizar **por papel** (em
vez de tudo), use o mesmo resolver para saber quais verticais copiar:

```
for v in $(bash .claude/utils/marketplace/resolve-role-bundle.sh standalone); do echo "vendorizar: $v"; done
```

Regulados (ex.: granaai) preferem este caminho de propósito: vendoring deliberado, pinado e auditável —
**não** auto-update de plugin.

---

## Verificação (checklist)

- [ ] `/plugin marketplace list` mostra `onion-evolve` (6 plugins).
- [ ] `/plugin install onion-engineering@onion-evolve` instala; comandos/agentes aparecem.
- [ ] Um comando do vertical roda ponta-a-ponta (checar o caveat `${CLAUDE_PLUGIN_ROOT}`).
- [ ] (Enterprise) grupo `standalone` auto-instala engineering/product/testing/docs; meta-factory escondida.
- [ ] `/meta:adopt` num adotante regulado segue entregando Camadas 2+3 + L1 vendorizada.

## Referências

- Anthropic: [Manage plugins for your organization](https://support.claude.com/en/articles/13837433-manage-plugins-for-your-organization) ·
  [Create and distribute a plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces)
- ADRs: `onion-adr-exchange-unit-2026-06.md` · `onion-distribution-strategy-2026-06.md`
- Sinal de co-evolução: `docs/evolution/inbox/_processed/2026-07-08-proposta-branch-onion-vendor.md` (se já triado)
  ou `inbox/` (síntese estratégica 2026: federação = marketplace de org).
- Maquinaria: `.claude/utils/marketplace/{assemble-plugin.sh, verticals/*.manifest.sh, roles.yaml, resolve-role-bundle.sh}`.
