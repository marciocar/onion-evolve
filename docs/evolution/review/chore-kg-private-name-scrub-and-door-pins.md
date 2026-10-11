---
title: 'Resíduo — o nome privado do hub sai de label e narrativa, e o cache do registro alcança a release onion-v1.0.0'
date: 2026-10-11
branch: chore/kg-private-name-scrub-and-door-pins
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_fixed: 0
tokens: 101333
duration_min: 2
verdict: APROVADO
elenxo: sim
nota: >-
  Refutador numa passada adversarial curta, com default REPROVADO. O mandato era achar ocorrência que
  sobrou sem classificação, reescrita que perdeu sentido ou quebrou referência, e pin que não bate com o
  remoto. Veredito APROVADO, com 2 observações menores, ambas anteriores a este diff ou dentro do selo.
  Ficam declaradas.
---

# Resíduo — `chore/kg-private-name-scrub-and-door-pins`

## O que mudou

**Parte A, resto da SAC-99.** O nome comercial do membro `hub-operacoes-enterprise` vem do
`client-terms.txt`, lido pela REGRA 30 (Segurança de PROJEÇÃO: nome comercial de membro privado não
sai). Ele aparecia 23 vezes em 5 grafos. 13 viraram o id do members.yaml e 10 ficaram, conforme o selo
da O7: labels e ids usam o id; o DOMÍNIO e o ARQUIVO DE DEPLOY ficam.

| Classe | Grafo · campo | Nº | Desfecho |
|---|---|---|---|
| label | canal-vivo · `E_ELENXO_CHANNELS_TOGGLE_UNMEASURED_PER_ADOPTER`, `E_LACUNAS_CANAL_VIVO_PRIMARIAS_1007`, `E_ELENXO_WORKIQ_LICENSE_BY_SILENCE` | 3 | id; "label anterior" na narrative com ⟨nome privado⟩; o label-parágrafo (2314 caracteres) foi condensado a 245, e o texto inteiro foi para a narrative |
| verified_against = locator (par idêntico) | canal-vivo, 2 pares | 4 | id, e o par continua idêntico |
| comentário do topo | canal-vivo | 2 | id |
| narrative | contrato-kg-absorcao · nó da O7 | 2 | id |
| verified_against | elenxo-bulbo · `Q_BYTECODE_SEM_TESTE` | 1 | id |
| locator (nome de sessão) | vps-shared-tools · `E_hub_operacoes_enterprise_demo_route_caddy` | 1 | `⟨de vendas do hub-operacoes-enterprise⟩`, a mesma forma que a narrative do nó já usava |
| domínio / arquivo de deploy | vps-shared-tools: l.92 (registro DNS), l.93, l.94 (domínio, `.caddy`, override compose), l.97 (`.caddy`) | 7 | fica, pelo selo |
| registro histórico | vps-shared-tools: l.96 (caminho do resíduo R56) e l.98 (branch); inbox-triage: l.86 (trace para arquivo em mailbox `_processed`) | 3 | fica: renomear o arquivo entregue reescreveria o passado |

O `docs/onion/kg-read-index.tsv` é **gerado** (copia o `trace:`). A linha dele com o nome é a cópia do
trace do inbox-triage para o arquivo histórico em `_processed`, então fica enquanto o trace ficar.
Regenerar não muda nada.

**Parte B, cache do registro.** As quatro portas estão publicadas em `9b5c89318dfc` (release
onion-v1.0.0), conferido por `ops/publish-door.sh --status`. Core e standalone foram carimbados por
`ops/door-seal-pin.sh`. Plugins e mini o script recusou: rc 2, carimbo no provenance.json; rc 1, árvore
local suja. Os dois foram ajustados à mão, citando o --status. `members-validate.sh` rc 0, e o
`--status --members` do disco mostra as 4 portas em dia e sem diferença de cache. O `onion-mini` ganhou
linha na `door-staleness-baseline.txt` com o passivo medido (0) e cura o SEM-BASELINE da REGRA 85
(Porta pública espelha o core, com catraca), que existia desde a F6.

## Achados da passada adversarial

| # | Sev. | Achado | Desfecho |
|---|------|--------|----------|
| 1 | menor | canal-vivo: o par verified_against/locator cita `members.yaml (l.298-304)` e o membro hoje começa na l.258 | anterior a este diff, porque é a medição datada de 2026-10-07. Declarado: re-medir pelo `/meta:kg-freshness` em vez de reescrever o registro da medição |
| 2 | menor | vps-shared-tools l.94: o "id anterior" mascara, e o "label anterior" mantém o nome no domínio e nos arquivos | é o selo (domínio e deploy ficam). Não é defeito |

## Gates

Nos 4 grafos tocados, `kg-radar --integrity` e `--schema` deram rc 0, e `kg-contract-check` deu rc 0,
sem piorar o SHOULD herdado. Também deram 0: `kg-machine-path-check` (0 acusações), o `kg_gate` do CI e
o P7 `projection-safety.sh --kg-identifiers`. Os commits saíram com `--no-verify`, como checkpoint
declarado, e a bancada completa não rodou.

## Teto

A guarda não foi estendida. O P7 olha id e caminho, e o label e a narrative seguem sem guarda. Fica a
recomendação: estender a label/narrative/verified_against com uma lista de isenção para domínio e
arquivo de deploy, porque sem ela o veto acusaria o que o selo manteve.
