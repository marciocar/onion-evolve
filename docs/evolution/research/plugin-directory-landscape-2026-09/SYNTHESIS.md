---
title: "Plugins e marketplaces de Claude Code em destaque (2026-09) — padrões, namespacing, curadoria do diretório"
date: 2026-09-04
kg: docs/evolution/research/plugin-directory-landscape-2026-09/plugin-directory-landscape-2026-09.kg.yaml
run_id: wf_611d652e-74f
tokens: 161008
agents: 103
duration_min: 6
genre: landscape
mode: research
budget: { maxFetch: 15, maxVerify: 25 }
review_after: 2026-10-04
---

# Plugins e marketplaces de Claude Code em destaque — 2026-09

> **Projeção** do grafo `plugin-directory-landscape-2026-09.kg.yaml` (18 nós, 20 arestas, radar exit 0). A fonte é o grafo; este `.md` deriva. Rodada R1 do plano de revisão dos plugins do Onion para o diretório oficial.

## Custo declarado

| Item | Valor |
|---|---|
| Tokens (run final, medido pela ferramenta) | 161.008 |
| Tokens da 1ª tentativa (Scope morreu por schema, 5×) | 66.703 |
| 2ª tentativa | morta com o processo — **não medida** |
| Workers do run (`agent()` do workflow) | 103 (5 ângulos do tema + 5 eixos fixos; 15 fontes; 55 claims; 25 verificadas) |
| Parede | ~6 min no run final |

## O que se confirmou (3-0 salvo indicado)

**Namespacing.** Comando e skill de plugin são sempre `/<plugin>:<cmd>`; não há resolução de `/cmd` nu — a versão standalone e a cópia do plugin coexistem (tier 10). Corroboração comportamental, tier 6, 2-1: plugin `foo` com comando `foo` só responde a `/foo:foo`. **Implicação:** as 531 referências no namespace do core medidas em `plugins/**` eram ponteiros mortos; a REGRA 72 + NAMESPACE-PORTABILITY (PR da mesma data) são a cura correta, e a pergunta "o nu resolve quando único?" do plano F5 já tem resposta: não.

**Curadoria em duas camadas.** O diretório `claude-plugins-official` é adicionado automaticamente na primeira sessão e a inclusão nele é **a critério exclusivo da Anthropic**. O caminho endereçável por esforço é o marketplace **comunitário** (`anthropics/claude-plugins-community`): validação automatizada + triagem de segurança, cada plugin **fixado a um commit SHA**, revisão automática **a cada update** do repo GitHub, e um selo opcional "Anthropic Verified" de revisão manual sem garantia. O repo público do comunitário é espelho read-only sincronizado nightly (tier 6): PR nele não é submissão.

**Requisitos de conformidade (política de diretórios de software da Anthropic, tier 10).** Repo GitHub público; descrição que **corresponda precisamente** à funcionalidade, em linguagem natural estreita; **ao menos três exemplos funcionais de prompt/caso de uso**; **política de privacidade** acessível; **contato de suporte** verificado. Dos cinco, o Onion cumpre hoje só o primeiro e parcialmente o segundo.

**Granularidade (2-1).** O sinal primário favorece o **plugin vertical coeso** (skills + commands + sub-agents + MCP por função de trabalho) sobre micro-plugins de ferramenta única. A tração corrobora: os dois mais instalados do catálogo oficial são bundles verticais — Frontend Design (1.134.112 instalações) e Superpowers (1.009.371). **Implicação:** a consolidação 8→5 decidida pelo maestro está alinhada; `onion-work-tools` (saco de ferramentas) é o candidato que reprova no critério.

**Superfície embarcável (tier 4, 3-0).** Plugins podem embarcar `SessionStart` hooks (shell executado em toda sessão — a razão da triagem de segurança) e registrar servidores MCP que o modelo chama como tools. Nenhum dos 8 plugins do Onion embarca `.mcp.json` apesar da tríade kg/exec/framework já existir (`D_TRIADE_MCP_POR_EIXO`).

## Mercado (eixo invariante)

**Sem sinal de capital**: nenhuma rodada, M&A, down round ou nota de analista sobre marketplaces de plugins do Claude Code sobreviveu aos votos. O que existe é **tração**: dois bundles verticais na casa do milhão de instalações — o canal opera em escala de plataforma e a demanda se concentra em função de trabalho, não em utilitário. Para o Onion, o escasso não é dinheiro: é **atenção num diretório discricionário** (o corpus já marcava `C_INEF_DISTRIBUICAO_DO_MOAT`). Eixo capital fica **NÃO-VERIFICADO**, não inexistente.

## NÃO-VERIFICADOS (declarado, não silenciado)

- **Refutados (11)**, por fonte fraca ou por dissenso adversarial: "13 plugins em 4 categorias no marketplace oficial"; "schema público no schemastore com campos obrigatórios"; "wshobson/agents é o marketplace multi-harness de maior tração"; "sem vetting centralizado/sem sandboxing"; "namespace opcional exceto em colisão" (tensão real entre páginas da Anthropic — ver caveat 4). Lista completa no retorno do run.
- **Fora do orçamento `maxVerify` (30)**, entre eles os que mais importam ao plano: `plugin.json` exige só `name` + `description` e só ele mora em `.claude-plugin/`; `.mcp.json` na raiz do plugin e `hooks/hooks.json` carregam automaticamente e recarregam com `/reload-plugins`; **a doc oficial não tem campo nem política de idioma/locale**.
- **Fora do orçamento `maxFetch` (26)**: `anthropics/claude-plugins-official`, "Create and distribute a plugin marketplace", "Plugins reference", checklist de revisão de connectors.

## Caveats (do próprio run)

1. **i18n não respondido** — nenhuma claim confirmada toca política de idioma; a exigência de "descrição precisa" e dos "três exemplos" não diz em qual língua. É frente a desenhar (R2), não transferência.
2. **Estrutura formal não confirmada por primária** (schema, frontmatter, tamanho, versionamento) — a medição local do repo segue sendo a melhor evidência.
3. **Eixo por trajetória GitHub falhou** — a única candidata foi refutada; re-rodar com `gh api search/repositories` + HN Algolia.
4. **Tensão entre páginas da Anthropic** sobre namespace: uma diz "sempre qualificado", outra "opcional salvo colisão". Fechar no binário instalado antes de citar como doutrina.

## valeu-a-pena

161.008 tokens ÷ 18 nós = **~8,9k tokens/nó** (contra 68–74k/nó do censo). O custo real da rodada foi maior pelo que não se mediu: um Scope morto 5× por schema (66,7k) e uma tentativa inteira perdida com o processo. Defeito de mecanismo curado no mesmo loop: o prompt do Scope passou a nomear os campos JSON (evita `<question>…` dentro de um campo só).

## O que muda no plano (F0 → F1/F2/F3/F5)

| Achado | Efeito |
|---|---|
| Namespace sempre qualificado | REGRA 72 confirmada; F5 não precisa medir "nu resolve" — medir só a coexistência standalone×plugin |
| Comunitário é o canal; revisão a cada push | F5: o ciclo materialize→push ganha gate externo recorrente; `onion-publish` deve avisar |
| ≥3 exemplos, privacidade, suporte | **novo item F5**: seção "Exemplos de uso" gerada (content-stable) por plugin; `PRIVACY.md` + `SUPPORT.md` no marketplace |
| Bundle vertical coeso | consolidação 8→5 sustentada; `onion-work-tools` funde no `onion` |
| MCP embarcável, superfície de segurança | R3 recebe a restrição: `.mcp.json` aumenta a triagem |
| i18n sem resposta | R2 nasce sem transferência do corpus; incluir teste empírico (submeter em pt-BR e medir) como opção |
