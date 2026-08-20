---
branch: feat/mcp-onion-framework
pr: PENDENTE
date: 2026-08-20
reviewed_diff_sha256: 8f9b80ad852bac9bfb8f88220494f0effcd917f340edfa30e593e1b481b35b1c
findings_total: 2
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 15
verdict: CONFORME-3A-NATUREZA-DECISAO-PASSOU-PELO-TESTE-DO-GATILHO
reviewer: passada adversarial manual + o Teste do Gatilho contra a PROPRIA arquitetura; sem subagentes
REVISOU: true
---

# Resíduo — `feat/mcp-onion-framework`

**Origem:** a dúvida do maestro ("não é o caso de um MCP do Framework Onion e suas verticais?")
— e a honestidade de rodar o Teste do Gatilho contra a arquitetura que EU tinha acabado de
montar, em vez de defendê-la.

## O que a dúvida corrigiu (registro, não achado técnico)

Eu fragmentei por UM eixo (risco). O maestro apontou um eixo que eu não cobria: identidade/
descoberta — nenhum dos 2 MCPs respondia "o que É o Onion". A resposta madura não foi fundir
(colapsar read+exec numa porta baixa a segurança ao nível do mais perigoso) nem ignorar: foi a
3ª natureza. Separar por RISCO permanece; ADICIONAR o eixo de identidade era o que faltava.

## Os 2 ataques (limpos)

- **(a) read-only de verdade?** 5 tools: 4 leem frontmatter/filesystem, describe_coinage é grep
  read-only. Zero escrita.
- **(b) path traversal em describe_command?** valida `..` + monta path por componentes fixos
  (CMD_DIR/cat/name.md) — `../../.env` não escapa.

## O desenho final, em uma linha

3 MCPs = 3 eixos (conhecimento/ação/identidade), 1 identidade Onion, separados por risco. É o
que o maestro pediu ("um MCP do Framework") entendido corretamente: não um monólito, mas a
dimensão que faltava, somada às duas que já existiam.

## Ressalva declarada

15 tools do core no chat agora (6+4+5); nenhuma com rate-limit próprio além do timeout. 1
consumidor (o maestro). O Bridge-como-MCP Camada 2 (prompt livre) segue gated por ACL — a
tríade é toda read+exec-contido, o poder pleno continua fora.
