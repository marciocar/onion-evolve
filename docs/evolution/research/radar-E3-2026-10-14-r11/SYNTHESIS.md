---
kg: docs/evolution/research/radar-E3-2026-10-14-r11/radar-E3-2026-10-14-r11.kg.yaml
run_id: "sem run de Workflow: rodada conduzida pelo /meta:cc-update na sessão principal, com 1 juiz opus/high (subagente não-fork)"
tokens: 199732
agents: 1
duration_min: 30
---

# Radar E3 · rodada r11 — Claude Code 2.1.299 → 2.1.300

O medidor (`cc-delta-census.sh`) separou o delta: **uma versão, 88 itens**, em `data/2.1.300.txt`. O juiz
baixou o CHANGELOG oficial e confirmou a cópia byte a byte (diff vazio, 91 linhas). O custo acima é o do juiz;
a rodada principal não tem medida de tokens própria.

## O que toca a casa (medido no vivo, julgado pelo juiz)

| Nó | Item | O que muda no core |
|---|---|---|
| `E_SAIDA_MATA_O_FUNDO_EM_1_5S` | a saída mata o fundo em 1,5 s | No fullscreen (o modo do maestro) o fundo antes seguia vivo depois da saída; agora morre. Lock, merge do forge e sync se recuperam sozinhos; o rebase do `pr-finalize --rebase` não. **Ação: SAC-136.** |
| `E_TRANSCRIPT_GRANDE_E_OS_HOOKS_STOP` | o transcript passa a gravar system prompt e ferramentas | Os 2 hooks Stop parseiam o transcript inteiro (~1,1 s por turno num de 42 MB), e ele cresce ~63 KB por resposta na amostra. **Ação: SAC-137.** |
| `E_HOOK_STOP_PUNE_O_RELATO_DE_ESPERAR_A_NOTIFICACAO` | o Claude para de ler o arquivo do fundo | O hook Stop ainda premia essa leitura como prova e veta o relato honesto de esperar a notificação. Entra na mesma forja (SAC-137). |
| `E_SESSIONEND_DO_FAROL_MAIS_CONFIAVEL` | SessionEnd roda ao sair com fundo vivo | O farol de sessão apaga na saída, em vez de ficar até 30 min como DECLARADO. |
| `E_AGENT_SPAWN_REESCREVE_O_MODELO_DO_WORKFLOW` | o hook de mod reescreve prompt e modelo de agente de Workflow | 3ª forma de falsear o tiering, que o `forced-model-check.sh` não enxerga; o core não usa mods hoje. |
| `E_UPDATEDINPUT_SEM_USO_NO_CORE` · `E_HOOKS_DO_CORE_SAO_TODOS_COMMAND` · `E_OTEL_E_REFTABLE_SEM_CONSUMIDOR` | updatedInput validado, hooks de agent, OTel, reftable | Não tocam o core (medido: 0 usos). |

## Juiz

Opus/high, mandato REFUTAR: **4 sustentam, 5 exagerados e reescritos, 0 reprovados**, 1 pergunta reescopada e 1
omissão de impacto 2 incorporada. As correções que valem lição:

- **A causa errada.** A 1ª redação atribuía o risco a "os scripts não tratam o sinal". Bash sem trap já morre
  no SIGTERM, e o `pr-finalize` tem `trap _cleanup EXIT`. O delta real é o fullscreen, em que o fundo antes
  sobrevivia à saída. O impacto caiu de 3 para 2, e a pergunta virou uma cura pontual (abortar o rebase).
- **O "tac" que não existe.** A rodada leu `tac` num grep por substring; os hooks parseiam o arquivo inteiro
  com `json.loads`. O tempo re-cronometrado foi ~1,1 s, não 1,6 s.

## Aufhebung

`x_supersedes_none`: nenhum item de 2.1.300 contradiz nó da r10. O `agent.spawn` com reescrita amplia
`E_AGENT_SPAWN_RESUME_E_SENDMESSAGE_SEM_USO` (SUPPORTS), e as duas perguntas abertas da r10 não são tocadas.

## NÃO-VERIFICADOS

- O caminho da saída real da sessão: o juiz mediu a morte do fundo por `TaskStop`, que um subagente consegue
  exercitar; a saída da sessão, não.
- A taxa de crescimento do transcript: 26 respostas, concentradas no início da 2.1.300. A direção está
  confirmada; a taxa, não.
- Se o harness roda os hooks Stop em paralelo (o que mudaria o custo somado por turno).
- Itens que o juiz mediu com impacto 1 ficaram fora do grafo: workflow retomado pela aprovação (0 sessões de
  fundo no core), hooks WorktreeCreate/Remove (0), Artifact (0 no `.claude`), `prompt.change` (sem mods). Achado
  lateral: `aside-router.sh:33` manda anotar em `scratchpad/notes.md`, caminho relativo que, resolvido contra o
  diretório atual, cairia no repo como arquivo não rastreado.
- Itens de gerenciado, VSCode, nuvem, Claude Tag e Code Review não tocam o core e não foram medidos.
