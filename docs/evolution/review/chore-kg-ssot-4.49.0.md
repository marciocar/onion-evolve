---
branch: chore/kg-ssot-4.49.0
pr: pendente
date: 2026-11-11
reviewed_diff_sha256: 1b9b8f7ac6a0f4e528eeae51691d092dc6cec4099519186e9f612ab7e5d30f2b
reviewed_code_sha256: a6b6d82eb1e3fcb4951e2f8aab7f71fee812002d46e675ffc968fd6dc16885ad
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 30
findings_fixed: 0
verdict: APPROVED
elenxo: false
reviewer: agente de execução da sessão do core, por comando, sem revisor independente
nota: "tokens 0 = não medido. Vendor do kg-ssot 4.49.0 (contratos v4.20 e v4.21, só SHOULD) com a dívida dos dois avisos novos aceita como linha de base. Passada do próprio autor; nenhum agente separado."
---

# Passada: `chore/kg-ssot-4.49.0`

## O que muda

- **Vendor:** `kg-ssot-v4.48.0` → `kg-ssot-v4.49.0` (`76d6698011ba`), 765 arquivos, pelo espelho
  `https://github.com/marciocar/kg-ssot` com `--verify-attestation` (rc 0). `kg_vendor.py check` rc 0.
- **Contrato:** v4.20 (perfil `x_classification`) e v4.21 (dois avisos SHOULD), segundo o ADOPTING do vendor.
- **Linha de base do gate:** `ops/kg-gate-ci.sh` acusou exatamente os dois códigos novos
  (`form.deprecated.node.provenance.method` 0 → 5327; `form.required.node.provenance` 0 → 159) e mais nada.
  Aceitos por `--update --accept-regression` com o motivo do ADOPTING (`.kg-ssot/gate/accepted/bf19376f64ad39f2.json`).
  Nenhum grafo foi alterado para calar o aviso. Depois do update, o gate dá rc 0.

## Achados

1. **O commit da tag difere do informado no brief.** O brief dava `0bc99fbee8fb`; a tag `kg-ssot-v4.49.0` no espelho
   resolve (tag anotada, `^{}`) para `76d6698011ba`, e a atestação confere com esse commit. O vendor carimba o que a
   release atestada diz. A tag foi republicada depois do commit inicial, ou o brief citou o commit pré-release.

## Medições

- `kg_migrate.py methods plan --root .`: rc 0, 5327 apelidos a trocar em 206 arquivos, 0 para revisor, 0 na cauda,
  3975 nós `confirmed` tocados. Nada gravado (apply não foi rodado).
- `kg-radar.sh <grafo> --integrity --schema` em 3 grafos de `docs/onion/graph`: rc 0 nos três.

## Re-revisão

O CI reprovou a bancada em três casos, todos por premissa da saída antiga do vendor, nenhum por defeito do kg-ssot.
Só `.claude/validation/lint-selftest.sh` mudou; o `vendor/` segue intocado.

1. **decide (s16), grafo não rastreado:** o selador roda o contrato como 2º gate e, sem base no git, toda dívida
   conta. O fixture usava a classe `leitura:`/`medição:` (agora `form.deprecated.node.provenance.method`, v4.21) e a
   âncora `evidence` sem `provenance` (agora `form.required.node.provenance`). Cura: classe em inglês
   (`reading:`/`measurement:`) e `provenance` na âncora do grafo do caso. O que o caso prova (rc 0 e a falta declarada)
   segue igual.
2. **design-context (d), token sumido:** a 4.49.0 do `kg_trace.py` lê a fonte do `provenance` só pelo índice do git
   (nunca pelo disco). O fixture editava o JSON sem `git add`, e o trace julgava a versão antiga. Cura: `_dc_commit`
   após a edição.
3. **design-context (m), mutantes do kg-trace.sh:** consequência de (2), não de âncora. O `sed` dos mutantes m4 e m5
   casa como antes; sem o token sumido no índice o `kg-trace.sh` saía rc 0 e o controle `cura` ficava vazio. Com o
   `_dc_commit`, `cura` acusa LOCATOR-MISSING, m4 vira `rc=1 sem achado` e m5 cala: os mutantes morrem.

Observação: (g) e (l) de `decide` falham só nesta máquina, porque o censo lê o registro local de perguntas ao
maestro (`ONION_ASK_DIR`, padrão `~/.local/state/onion/maestro-asks`) que a bancada não isola. Com `ONION_ASK_DIR`
num diretório vazio passam (38/38). Não é efeito da 4.49.0 e não foi alterado aqui.
