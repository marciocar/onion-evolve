---
branch: chore/kg-ssot-4.32.0
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: 8c90dd245d937cafb8a0f74a19a86a1674bf24ea9617883630916e7742d5e14b
reviewed_code_sha256: 0f54448a6d9efce02385175b3e0ec519b1c3867e7b470e700300f374b4b78d70
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 25
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão de continuação (claude-opus-5-5), passada própria sobre o diff inteiro"
nota: "tokens não medidos; a passada leu o diff herdado do agente anterior antes de completá-lo"
---

# Passada adversarial: `chore/kg-ssot-4.32.0`

## O que muda

A adoção da kg-ssot 4.32.0 (contrato v4.16: classes de `provenance.method` com forma canônica em inglês e os cinco
aliases em português). O radar reconhece `testimony` no aviso MISPLANED de testemunho em PROD e na exceção da
decisão selada pelo maestro; a ajuda do escritor de grafos por MCP ensina as canônicas e os aliases; e os gravadores
do core passam a emitir a classe em inglês. Os grafos existentes não migram.

## Achados

1. **Leitor que só conhecia o português** (real, corrigido): o `kg-migrate-v3.py` validava o `method_final` da
   planilha contra as cinco classes em português e exigia o prefixo `medição: ` em `manter-prod-medido` e
   `binario-prod`. Uma planilha escrita na forma canônica seria recusada. A leitura passa a aceitar as dez formas; o
   que a ferramenta escreve segue em português (ondas seladas). Caso (m2) com mutante na família `kg_migrate_v3`.
2. **Dois casos do escritor sem mutante** (real, corrigido): `method-classe-ingles-e-alias-aprovam-sem-aviso` e
   `method-sem-classe-avisa` entraram sem mutante, contra a regra da família (um mutante por caso). Ganharam um
   cada: o veredito sem os avisos SHOULD, e as classes em inglês desfiguradas antes do contrato. Os dois mordem.
3. **Caso de aceitação incompleto** (real, corrigido): o caso do escritor conferia quatro classes em inglês e dois
   aliases; faltavam `testimony`, `leitura`, `derivado` e `testemunho`. Agora confere as dez.

Conferido e sem defeito: a regex do radar exige o `:` logo depois da classe (não casa `testimonyX:`); o
`kg-decide-seal.sh` confere o method que acabou de gravar contra o mesmo texto; a matriz `radar_rules.json` da
kg-ssot (tools/runners, não vendorizada) já casa `(?:testemunho|testimony)` na mensagem nova.

Conferidos os `confirmed` de maior impacto do grafo editado (REGRA 87, PR que EDITA um `.kg.yaml` enxergou os
`confirmed` dele): `E_SPIKE_SOBREVIVENCIA_PREMIA_O_TRIVIAL_1012` (critério de spike de produto),
`E_SINAL_TRANSPORTE_ENTRE_AGENTES_1025` (transporte A2A entre agentes) e `E_SINAL_PROTOCOLO_ENTRE_SESSOES_1025`
(auditoria das mensagens entre sessões). Nenhum trata do vocabulário de `provenance.method`, e nenhum é contrariado
pelo nó novo `E_KG_SSOT_432_ADOTADA_1027`, que só registra a adoção no molde do 4.31.0. O
`vendor/kg-ssot/spec/examples/minimal.kg.yaml` é arquivo do vendor, que chega pela tag e não se edita no core.

## Mutantes

- radar (a2)/(h2): sem `testimony` na regex, o caso inglês cala e o português segue avisando.
- selo do maestro (r3)/(r4): um mutante por forma, cada um faz o seu selo voltar ao aviso.
- escritor: três mutantes, um por caso novo, todos com FAIL do caso nomeado.
- migração (m2): só o prefixo em português, e o nó inglês volta a ser recusado.

## Limites declarados

- O MISPLANED é aviso (rc 0), como já era para `testemunho:`; o contrato o marca SHOULD. Não virou reprovação.
- O escritor em produção não foi reiniciado: o deploy é do maestro (card no corpo do PR).
- A bancada inteira não rodou localmente (o seletor caiu no failsafe por causa do README do escritor); rodaram as 15
  famílias tocadas e a do inventário do harness, e o CI roda o resto.
