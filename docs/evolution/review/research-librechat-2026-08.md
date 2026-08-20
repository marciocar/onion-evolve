---
branch: research/librechat-2026-08
pr: 636
date: 2026-08-20
reviewed_diff_sha256: 19290f020c176f2375d404d8d2144d9adbcad7a9749cc01fcb8ae599d408c38b
findings_total: 5
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 20
verdict: CONFORME-DOIS-GATES-DA-CASA-PEGARAM-E-CURARAM-NO-CAMINHO
reviewer: passada adversarial manual (3 ataques dirigidos) + os dois gates do pre-commit; sem subagentes além dos 3 Explore do plan mode
REVISOU: true
---

# Resíduo — `research/librechat-2026-08`

**Origem:** F7 do plano aprovado (LibreChat padrão Onion VPS) — persistir a pesquisa das 3
explorações ANTES de evaporar do contexto, + o catálogo da VPS acompanhando o boot.

## Achado 1 — proveniência-invertida (REAL, curado pelo gate)

O 1º commit foi BLOQUEADO: a síntese nova não era citada por nenhum `.kg.yaml` em `trace:` —
o grafo nascia como predecessor da prosa em vez de fonte dela. Curado com `trace:` nos 2 nós
de decisão. É o gate REGRA-de-proveniência fazendo exatamente o que a doutrina KG-first pede.

## Achado 2 — coverage do grafo público stale (REAL, curado pelo gate)

O 2º commit foi BLOQUEADO: a página pública afirmava coverage 114 e o vivo tinha 115 — porque
a MINHA síntese nova entrou no corpus contado. Regenerada com o número vivo. O gate pegou a
consequência de segunda ordem do próprio diff, que a passada manual não tinha listado.

## Os 3 ataques da passada manual (limpos)

- **(a) traces resolvem?** 3/3 existem (2 na síntese, 1 no compose da VPS).
- **(b) o custo declarado bate?** 50058+102362+66444 = **218.864** = o frontmatter.
- **(c) o SSO afirmado é o vivo AGORA?** `client_id=sqov79y2x3s6qawreafga` no redirect real —
  idêntico ao nó (re-medido no momento do resíduo, não herdado da hora do boot).

## Ressalva declarada

Os testes de UI (login SSO completo — a prova final do ES384 —, mensagem Claude real, upload
RAG, busca Meili) exigem o navegador do maestro e estão na checklist entregue a ele; o nó do
grafo registra o que foi medido do lado servidor e nomeia essa fronteira. O achado
BACKUP-EM-CLARO do exposure-check (3 arquivos em ~/backups/bridge) é PRÉ-EXISTENTE e alheio a
este PR — fica anotado como fio da casa, não como item deste diff.
