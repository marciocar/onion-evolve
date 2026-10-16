---
kg: docs/evolution/research/radar-E3-2026-10-16-r12/radar-E3-2026-10-16-r12.kg.yaml
run_id: "sem run de Workflow: rodada conduzida pelo /meta:cc-update num agente de execução, com 1 juiz opus/high (subagente não-fork)"
tokens: 159071
agents: 1
duration_min: 40
---

# Radar E3 · rodada r12 — Claude Code 2.1.300 → 2.1.301

O medidor (`cc-delta-census.sh`) separou o delta: **uma versão, 51 itens**, em `data/2.1.301.txt`. O juiz
baixou o CHANGELOG oficial e confirmou a cópia byte a byte (diff vazio, 54 linhas). Os tokens acima são os do juiz (8,6 min dele); os
40 min são a rodada inteira, que não tem medida de tokens própria. O refutador do diff gastou mais 142.641 tokens. A guarda de deriva de binário que o censo manda rodar
(`lint-selftest.sh --families cited_directive`, com `LC_ALL=C`) saiu rc 0: 6 passaram, 0 falharam.

## O achado: o delta não chega à produção

O /chat roda o **CLI 2.1.232**, embutido no `@anthropic-ai/claude-agent-sdk` 0.3.232 do bridge. Isso vale
tanto para o caminho admin (o SDK usa a resolução padrão do binário) quanto para o runner do convidado sob
DynamicUser (o `chat-runner.sh` monta esse mesmo binário por bind). O host está em 2.1.301, **57 versões
publicadas** à frente. O deploy do mesmo dia reinstalou o `node_modules` pelo lock e o SDK continuou em
0.3.232: um deploy não move o SDK. O censo não mede nada disso (0 menções a SDK).

- **Ação SAC-155:** o censo passa a medir também o CLI do SDK (`Q_CENSO_MEDE_O_CLI_DO_SDK_DO_BRIDGE`).
- **Ação SAC-156:** subir o SDK, com o verify do runner re-provado e um piso de versão
  (`Q_SUBIR_O_SDK_DO_BRIDGE_COM_PISO_DE_VERSAO`). O piso ≥ 2.1.64 (CVE-2026-39861) é pré-condição do degrau 3,
  que o maestro parqueou: ele pesa se o degrau voltar. A defasagem das correções pesa desde já.

O grafo de isolamento já media o CLI 2.1.232 (`E_CVE39861_FIXED_IN_2_1_64`, ligado por `external_edges`). O que
esta rodada acrescenta é a ligação entre essa versão e o alcance do delta do E3.

## O que toca a casa (medido no vivo, julgado pelo juiz)

| Nó | Item | O que muda |
|---|---|---|
| `E_NENHUM_ITEM_TOCA_SANDBOX_WEBFETCH_STREAMJSON` | o delta inteiro | 0 itens sobre sandbox, WebFetch, stream-json, `--settings`, socket ou SDK. Os de permissão só chegariam ao `canUseTool` e ao prompt stdio do runner depois de subir o SDK. |
| `E_GREP_E_GLOB_DEIXAM_DE_MENTIR_ZERO` | Grep/Glob devolvem erro em vez de zero | É a classe anti-fail-open que o core guarda só no Bash. A plataforma cura no host; no bridge continua aberta, e o convidado tem Grep e Glob. |
| `E_WORKFLOW_PULAVA_O_PASSO_E_DIZIA_SUCESSO` | agente de Workflow pulava o passo | O Scan do `meta-evolve-fanout` e o Fetch do `onion-research` fora do modo primaries aceitam saída vazia como medição, então um passo pulado passaria como "achou zero". |
| `E_ARTIFACT_PASSA_PELO_EDIT_E_O_KG_READ_LEG` | Artifact sob hook de Edit/Write | O `kg-read-leg` cobre Edit e Write sem nunca vetar, e mesmo assim o host recusava a atualização. Agora não recusa mais. |
| `E_PLUGIN_VALIDATE_CURTO_NO_MESMO_HOST` | login cortado por comando curto | O `claude plugin validate` da publicação abre as credenciais (medido por strace). A classe alcança o core; nenhum incidente medido. |
| `E_ALIAS_FABLE_SEM_USO_NO_CORE` · `E_SINAIS_DO_DELTA_SEM_CONSUMIDOR` | alias fable, watchdog, OTel, mods, aws, WorktreeCreate, reftable | Não tocam o core (medido: 0 usos). |

## Juiz

Opus/high, mandato REFUTAR, com critérios pré-registrados (`data/judge-verdicts.json`, CU1–CU5;
`judge-verdict-check.sh` rc 0). Sobre os 13 nós: **10 SUSTENTA, 3 EXAGERA, 0 REPROVA**. O juiz listou ainda
3 omissões, todas medidas com impacto ≤ 1, e sustentou a Aufhebung (`x_supersedes_none`). As reescritas:

- **O número.** "69 versões" era a diferença entre os números de patch. Publicadas, são 57 seções do
  CHANGELOG e 58 releases do SDK.
- **A superfície errada.** A 1ª redação apontava a leitura do `onion-research`. O juiz isentou essa leitura e
  apontou o Scan do `meta-evolve-fanout`. O refutador do diff mostrou que a isenção só vale no modo primaries: em
  research e decision, o Fetch tem o mesmo buraco.

O juiz devolveu as classes de superação com vocabulário livre ("reescrita", "nada"). A sessão respondeu à
pergunta do consolo: nenhuma superação entrega valor fora do próprio veredito, então todas foram gravadas
como `nenhuma`. A classe original ficou em `classe_do_juiz`. Essa resposta é autoavaliação da sessão
julgada, porque o juiz não recebeu o enum `entrega|nenhuma`. Na próxima rodada, o schema vai para o juiz.

**Refutador do diff** (opus): 9 achados reais, todos de baixa gravidade exceto o do Fetch. Os 9 foram curados
nesta branch.

## NÃO-VERIFICADOS

- Se o CLI 2.1.232 tem de fato os defeitos de Read binário, Grep/Glob com zero falso e passo de Workflow
  pulado. O que se mediu foi que a superfície existe e que a correção não chega lá.
- `ONION_MODEL` e a existência de `ANTHROPIC_BASE_URL` ou de um gateway no bridge (item de compactação em
  laço): os dois vivem no `.env`, que não foi lido.
- As janelas de contexto de `claude-opus-5` e `claude-sonnet-5-5`, que importam para a troca para uma janela
  menor.
- Se o tráfego do `claude plugin validate` é renovação de token ou telemetria.
- A variante musl contra a glibc do SDK no caminho admin: só o binário `linux-x64` foi executado.
- As runs antigas de Workflow, para saber se algum scan foi pulado de fato.
- Itens de vim, terminal, VSCode, Windows e self-hosted runner não tocam o core e não foram medidos.
