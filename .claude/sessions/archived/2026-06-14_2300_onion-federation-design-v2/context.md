# Contexto — Onion Federation Design v2

## Situação Inicial

O Sistema Onion não tinha capacidade de coordenar mudanças entre múltiplos repositórios.
A necessidade era: "não pode quebrar, monitorável, testável" — coordenação cross-repo
contract-safe.

**Rodada 1 (mesma sessão, PR #36):** design v1 com topologia hub — um orquestrador único
operando sobre N diretórios alheios. O doc foi mergeado antes da review adversarial.

**Gatilho da review:** identificar riscos antes de implementar qualquer arquivo em `.claude/`.

## Motivação do Pivô

A review adversarial (`wf_dbfb2b91-cd3`, 42 agents) confirmou **24 de 36 achados** com
**3 alertas sistêmicos raiz** que explicavam 16 dos 24:

- **SA-3 (load-bearing não verificado):** o hub repousava num spike não-verificado — um
  subagente Workflow operar sobre o diretório de outro repo como raiz. Se o spike falhasse,
  as fases cross-repo colapsariam. Nenhuma camada de segurança protegia contra isso.
- **SA-1 (viola meta-spec L0):** o hub criava `.claude/federation/` e categoria de comando
  `federation/` — ambos incompatíveis com `architecture.md §1/§7` e as identidades canônicas
  travadas em 2026-05-18.
- **SA-2 (segurança declarada, não especificada):** a "máquina de segurança" tinha 4 camadas
  prometidas sem protocolo concreto, sem fail-safe determinístico, sem especificação de
  contract-tests além de "escrever tests para o contrato".

O usuário propôs: cada repo manter seu Onion soberano + comunicação simplificada entre eles +
humano como maestro. Isso contornava exatamente o SA-3 (cada Onion opera só o próprio repo)
e dissolvia o SA-1 (nada em `.claude/federation/`).

## Restrições

- **Linha vermelha (NUNCA cruzar):** instâncias vivas conversando em tempo real (A2A/MCP
  runtime distribuído) = visão abandonada 2026-05-18. Só assíncrono.
- **Design only, sem implementar:** o entregável desta rodada era o blueprint v2 + backlog.
  Nenhum arquivo em `.claude/` foi tocado.
- **Guardrails de identidade intactos:** Claude Code-nativo; orquestração em skill/comando,
  nunca agente; SDAAL ≤ 400 linhas; sem CLI/npm/`.onion/`/multi-IDE.
- **Fase 0 como gate real:** nenhuma implementação antes do veredito do `@metaspec-gate-keeper`
  e do spike de ledger.

## Referências

- Design v2 vigente: [`docs/analysis/onion-federation-design-v2-2026-06.md`](../../../../docs/analysis/onion-federation-design-v2-2026-06.md)
- Review adversarial: [`docs/analysis/onion-federation-design-review-2026-06.md`](../../../../docs/analysis/onion-federation-design-review-2026-06.md)
- Design v1 (superseded): [`docs/analysis/onion-federation-design-2026-06.md`](../../../../docs/analysis/onion-federation-design-2026-06.md)
- Review de identidade canônica: [`docs/analysis/onion-review-2026-05.md`](../../../../docs/analysis/onion-review-2026-05.md)
