---
kg: docs/evolution/research/poda-instruction-bloat-2026-09/poda-instruction-bloat-2026-09.kg.yaml
run_id: "wf_ab17f8d6-773 (workflow /onion-research em MODO DECISÃO — dogfood do F3; write(KG) relançado do cache após corrigir o contrato de decisão)"
tokens: 3499415
agents: 52
duration_min: 27
verified_at: 2026-09-03
---

# O que podar do CLAUDE.md — dogfood do modo decisão do `/onion-research` (projeção do grafo)

> **SSOT:** [`poda-instruction-bloat-2026-09.kg.yaml`](./poda-instruction-bloat-2026-09.kg.yaml) — 19 nós / 32 arestas,
> radar exit 0. O nó **`D_PODA_INSTRUCTION_BLOAT_CLAUDE_MD_E_SKILLS` está `open`: o maestro sela** (tabela de selagem do
> `/meta:drive`, KIND decision). 4 opções como claims, 7 objeções sobreviventes do Elenxo como evidência com **12 `CONSTRAINS`**
> e 1 `REFUTES`. Fio de origem: `D_PODA_INSTRUCTION_BLOAT_MEDIDA` (meta-research-lens) — segue `open` lá até o selo.

## A recomendação (do Elenxo, para o maestro selar)

**(C) re-especificada — medir COMPORTAMENTO, não carga — e só depois (A); nunca (B) nem (D).** Com estes limites
(as objeções que sobreviveram):

1. **A premissa da pergunta estava errada (~5×)**: no Claude Code só a `description` das skills entra sempre; o corpo do
   `SKILL.md` carrega sob demanda, e `onion-patterns`/`onion-validation` já declaram `paths:`. O sempre-ligado real é o
   CLAUDE.md (~5 k tokens = **0,5 % de 1 M**) + 13 descriptions. "Esgotamento da janela" (o mecanismo do Radar v34)
   **não é o constrangimento vivo**; se há custo é atenção/conflito ("lost in the middle") — outro mecanismo, outra medição.
2. **`InstructionsLoaded` existe e é medível hoje** (verificado no binário 2.1.259, tier 10): payload
   `{hook_event_name, file_path, memory_type, load_reason, globs, trigger_file_path, parent_file_path}`. Instrumentar custa
   2 comandos — mas o critério "podar o que só dispara por `load_reason`" **não classifica nada** (descreve a topologia
   atual): o desenho da medição precisa ser refeito antes de instrumentar.
3. **A evidência local é mais forte que as externas**: `E_claude_md_has_control` (2026-08-02) — seção no CLAUDE.md não
   mudou comportamento (placar 1/9; hook venceu); e `git log --follow --numstat -- CLAUDE.md` = 59 commits, +323/−77,
   maior remoção única = 5 linhas — a catraca de antiguidade do preprint corroborada em casa, com tier 10.
4. **Reordenar antes de deletar** (viés posicional): identidade/acoplamento abrem o CLAUDE.md e Task Manager/Forge/
   idioma ficam enterrados no meio — reordenar é reversível; deletar doutrina não.
5. **Classe protegida antes da poda**: identidade, CORE≠FAMÍLIA, postura de acoplamento — o que evita a conclusão errada
   já cometida em 2026-08-02 não pode cair por "não mudou comportamento medido".
6. **Poda calibrada no modelo que decide pode quebrar o que executa** (tiering): replay no tier menor, não só no opus.
7. **Registrar o porquê de cada instrução** (barato) para que a deleção futura seja decidível; e uma guarda anti-re-bloat
   (teto/gate exigindo evidência de controle para seção nova).

**Mercado (invariante):** sem capital nomeado — o único sinal é o analista (Radar v34: bloat em CAUTION, Agent Skills em
TRIAL). A mitigação virou padrão aberto; o diferencial fica na **medição** do que carrega, que ninguém padronizou.

## O que o dogfood ensinou sobre o próprio modo decisão

- **O Elenxo funcionou como projetado** — derrubou os dois achados web e reabriu 12 descartes "por orçamento/comodismo"
  (a conclusão operacional tinha sido cortada por orçamento; a correção do enquadramento do Radar idem; `mcptax` não foi
  lido). A objeção mais valiosa refutou a **minha própria pergunta**.
- **Defeito meu no write(KG)**: o patch mirou uma âncora inexistente e o agente **nunca recebeu** o bloco de decisão (1ª
  escrita: 5 nós, 0 `D_`). Cura: contrato de decisão **exigido pelo schema** (`decisionNodeId`, `optionNodeIds`,
  `constrainsEdges ≥ 1`) + bloco no INÍCIO do prompt + fail-loud em JS. Relançado do cache: 99 k tokens.
- **Custo: 3,4 M tokens / 52 agentes** (10 ângulos × busca + 8 fetch + 10 claims × 3 votos + Elenxo + síntese +
  write(KG)). ~180 k por nó. O modo decisão é caro por desenho (3 votos + refutador); orçamento default deveria ser menor
  (`maxVerify` 6) — registrado como lacuna.

## Lacunas declaradas

Nada medido no Onion (tokens reais, `InstructionsLoaded` executado, controle A/B); 10 fontes web não lidas por orçamento
(lacunas nº 1 e nº 2 do escopo); `mcptax` não aberto; telemetria de instruções como categoria comercial não confirmada.

## valeu-a-pena

Como decisão: sim — o maestro recebe 4 opções com 7 objeções datadas e uma recomendação com 7 constrangimentos, em vez de
"pode o CLAUDE.md". Como dogfood: achou 1 defeito de contrato (curado por schema) e mediu o custo do modo decisão.
