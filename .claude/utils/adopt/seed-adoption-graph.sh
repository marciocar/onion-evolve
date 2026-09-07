#!/usr/bin/env bash
# seed-adoption-graph.sh — semeia o PRIMEIRO `.kg.yaml` do adotante, com fatos VERIFICADOS.
#
# ── POR QUE ESTE HELPER EXISTE (achado de campo, 2026-08-17) ──────────────────────────────
# A adoção entregava todos os RECURSOS (warm-up, catch-up, onion, skills, agentes, comandos) e
# ZERO ESTADO: nenhum `.kg.yaml`. E o passo 0 do `/warm-up` é literalmente *"se existir um
# `.kg.yaml` no repo, consulte-o PRIMEIRO"*, resolvido ao vivo por `git ls-files '*.kg.yaml'`.
# Com zero grafos, o passo 0 não falha — ele fica VAZIO, e a sessão degrada para ler prosa. O
# conhecimento do projeto segue morando no contexto de uma conversa em vez de no repo, e é isso
# que prende o dono a uma sessão.
#
# ⚠️ E A CAUSA SE PARECE COM UM ACHADO ANTERIOR desta casa: a medição de 2026-08-16 encontrou
# grafo autoral em 3 de 7 adotantes e ia culpar o não-uso — do mesmo jeito que ia culpar os
# adotantes pelo zero de resíduos R56, até se medir que `review-artifact-check.sh` NUNCA FOI
# VENDORIZADO. Aqui é a mesma forma: parte do "não usam KG" é CAPACIDADE QUE NUNCA ENVIAMOS —
# a adoção nunca semeou o primeiro nó. Culpar o hábito antes de conferir o envio erra o alvo.
#
# ⚠️ O QUE ESTE HELPER **NÃO** FAZ: inventar o domínio do adotante. Ele semeia só o que a adoção
# PODE verificar de si mesma (pin, modo, papel, branch de integração, prova do gate) e deixa UMA
# `question` aberta pedindo o primeiro nó de domínio — que o radar afunda na seção ESTADO a cada
# leitura. Semente com fato verificado + uma pergunta viva é hábito começando; template cheio de
# TODO é ruído que se aprende a ignorar.
#
# Never-clobber: se JÁ existir qualquer `.kg.yaml` no alvo, não escreve nada (o adotante já tem
# grafo — semear ali seria empurrar ruído para quem já pegou o hábito).
#
# Uso:  bash seed-adoption-graph.sh <DEST> [--gate-proven|--gate-unproven]
# Códigos: 0 = semeado ou no-op deliberado · 2 = uso inválido/alvo inexistente.

set -u

DEST=""
GATE="unknown"
while [ $# -gt 0 ]; do
  case "$1" in
    --gate-proven)   GATE=proven; shift ;;
    --gate-unproven) GATE=unproven; shift ;;
    "") shift ;;   # flag vazia (chamador com "${GATE_FLAG:-}" não setado) é ausência, não erro
    -*) echo "seed-adoption-graph: opção desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${DEST}" ] && DEST="$1" || { echo "seed-adoption-graph: alvo já informado" >&2; exit 2; }; shift ;;
  esac
done
if [ -z "${DEST}" ] || [ ! -d "${DEST}" ]; then
  echo "uso: seed-adoption-graph.sh <DEST> [--gate-proven|--gate-unproven]   (alvo inexistente: '${DEST}')" >&2
  exit 2
fi

# NEVER-CLOBBER — e a pergunta certa é "o alvo TEM grafo?", não "este arquivo existe?": semear um
# 2º grafo de adoção num repo que já mapeia o próprio domínio é ruído, ainda que o nome não colida.
# Resolve AO VIVO, como o warm-up (git ls-files), com fallback em find p/ alvo ainda sem commit.
# ⚠️ A isenção de FIXTURE vem do predicado ÚNICO (kg-fixture-paths.sh) e AQUI ela é load-bearing de
#    um jeito diferente dos outros sítios: um `grep -v '/fixtures/'` incompleto faz uma FIXTURE DE
#    TESTE responder "o alvo já tem grafo" — e a semente, que existe para dar ESTADO ao adotante,
#    nunca nasce. Não é gate afrouxado: é CAPACIDADE CANCELADA, exatamente o buraco que este helper
#    veio fechar. Medido 2026-09-05: adotante com só `packages/kg/src/__fixtures__/orphan.kg.yaml`
#    (convenção Vitest) → `⊘ never-clobber` e ZERO grafos semeados.
#    `--filter` serve aos dois caminhos porque filtra STDIN: vale para `git ls-files` e para `find`.
_KFP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../validation" && pwd)/kg-fixture-paths.sh"
[ -f "${_KFP}" ] || { echo "  ✗ seed-adoption-graph: predicado de fixture ausente (${_KFP}) — sem ele uma FIXTURE de teste responde 'o alvo ja tem grafo' e a semente NAO nasce (medido 2026-09-05)." >&2; exit 2; }
existing=""
if git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1; then
  existing="$(git -C "${DEST}" ls-files '*.kg.yaml' 2>/dev/null | bash "${_KFP}" --filter | head -1 || true)"
fi
if [ -z "${existing}" ]; then
  existing="$(find "${DEST}/docs" -name '*.kg.yaml' 2>/dev/null | bash "${_KFP}" --filter | head -1 || true)"
fi
if [ -n "${existing}" ]; then
  echo "  ⊘ seed-adoption-graph: alvo já tem grafo (${existing#${DEST}/}) — nada semeado (never-clobber)."
  exit 0
fi

# Fatos que a adoção PODE verificar de si mesma. Nada aqui é chute: sai do stamp e do git do alvo.
SLUG="$(basename "$(cd "${DEST}" && pwd)")"
STAMP="${DEST}/.claude/.onion-version"
_f() { [ -f "${STAMP}" ] && awk -v k="$1" '$1==k":"{print $2; exit}' "${STAMP}" || true; }
PIN="$(_f source_commit)"; [ -n "${PIN}" ] || PIN="$(_f commit)"; [ -n "${PIN}" ] || PIN="(não carimbado)"   # write-stamp escreve source_commit (medido 2026-09-02: saía "(não carimbado)" em toda adoção)
MODE="$(_f mode)";         [ -n "${MODE}" ] || MODE="(não carimbado)"
ROLE="$(_f role)";         [ -n "${ROLE}" ] || ROLE="(não carimbado)"
IB="$(_f integration_branch)"; [ -n "${IB}" ] || IB="(não declarado — resolvido por PR)"
TODAY="$(_f adopted_at)"
if [ -z "${TODAY}" ]; then
  TODAY="$(git -C "${DEST}" log -1 --format=%cd --date=short 2>/dev/null || true)"
fi
[ -n "${TODAY}" ] || TODAY="(sem data — alvo sem commit e sem stamp)"

case "${GATE}" in
  proven)   GATE_STATUS="confirmed"
            GATE_LABEL="O gate determinístico foi PROVADO POR EXECUÇÃO na adoção (hook nativo via core.hooksPath, commit-sonda barrado com o lint reprovando) — não por existência de arquivo. Isso importa porque a medição de 2026-08-16 achou o gate INERTE em 4 de 6 adotantes (husky sombreando o hooksPath, hooksPath para diretório vazio, hook ausente), e nenhum caso era visível sem executar."
            GATE_VERIF="verify-adopter-gate-executado-na-adocao" ;;
  unproven) GATE_STATUS="open"
            GATE_LABEL="O gate está INSTALADO mas NÃO foi provado por execução nesta adoção (alvo sem commits, ou lint indisponível no momento). Instalar não é sinônimo de proteger: rode 'bash ops/verify-adopter-gate.sh <este-repo>' a partir do core, ou faça um commit que viole o lint de propósito e confirme que ele é BARRADO. Enquanto isto for \`open\`, a proteção deste repo é declarada, não verificada."
            GATE_VERIF="nao-verificado-gate-declarado-e-nao-provado" ;;
  *)        GATE_STATUS="open"
            GATE_LABEL="O gate foi instalado; se ele BARRA de fato, ninguém mediu nesta adoção (o semeador não recebeu --gate-proven nem --gate-unproven). Prove antes de confiar: 'bash ops/verify-adopter-gate.sh <este-repo>' do core."
            GATE_VERIF="nao-informado-ao-semeador" ;;
esac

OUT="${DEST}/docs/onion/graph/onion-adoption.kg.yaml"
mkdir -p "$(dirname "${OUT}")"

cat > "${OUT}" <<YAML
---
graph: onion-adoption
title: "Adoção do Onion neste repositório — a semente do KG"
layer: mixed
created: ${TODAY}
updated: ${TODAY}
owner: ${SLUG}
purpose: |
  Este é o PRIMEIRO grafo deste repo, semeado pela adoção do Onion. Ele existe por um motivo
  operacional: o passo 0 do /warm-up é "se existir um .kg.yaml, consulte-o PRIMEIRO" — e com zero
  grafos esse passo fica VAZIO, a sessão degrada para ler prosa, e o conhecimento do projeto segue
  preso ao contexto de uma conversa em vez de morar no repo.
  Leia com: bash .claude/validation/kg-radar.sh docs/onion/graph/onion-adoption.kg.yaml
  A seção ESTADO mostra o que segue \`open\` — é a fila real, ordenada pelo que pesa.
como_usar: |
  NÃO trate este arquivo como template a preencher. Ele carrega FATOS verificados da adoção e UMA
  pergunta aberta: qual é o domínio deste repo. Ao responder, crie o SEU grafo em
  docs/onion/graph/<seu-tema>.kg.yaml e reconcilie a pergunta daqui para \`done\`.
  Gramática antes de escrever: .claude/rules/kg-grammar.md (o campo é \`node_type:\`/\`edge_type:\`,
  nunca \`type:\`; nó PROD de alto impacto sem \`verified_at\` é acusado pela catraca).
---

# O SELO da gramática. Sem ele o radar avisa a cada leitura ("schema_version ausente"), e um aviso
# na PRIMEIRA leitura de todo adotante é o pior lugar para um aviso: ensina, de saída, que a saída
# do radar tem ruído tolerável. Medido no core: 59 dos 64 grafos declaram.
meta:
  id: onion-adoption-${SLUG}
  schema_version: "1"
  baseline: ${TODAY}
  date: ${TODAY}

nodes:
  - id: THIS_REPO
    layer: domain
    node_type: entity
    plane: PROD
    status: confirmed
    impact: 5
    confidence: 1.0
    verified_at: ${TODAY}
    verified_against: basename-do-alvo-e-stamp-claude-onion-version
    label: "\`${SLUG}\` — este repositório, consumidor do framework Onion (papel \`${ROLE}\`). Ele é a entidade dona dos estados abaixo; o domínio do NEGÓCIO dele ainda não está mapeado (ver a pergunta aberta)."

  - id: ONION_INSTALLED
    layer: domain
    node_type: state
    plane: PROD
    status: confirmed
    impact: 4
    confidence: 1.0
    verified_at: ${TODAY}
    verified_against: stamp-claude-onion-version-lido-na-adocao
    label: "Framework instalado: pin \`${PIN}\`, modo \`${MODE}\`, papel \`${ROLE}\`, branch de integração \`${IB}\`. Atualizar depois com /meta:adopt --update a partir do core — o merge de \`onion/vendor\` transforma customização local em conflito git real, resolvível, em vez de sobrescrita silenciosa."

  - id: DETERMINISTIC_GATE
    layer: domain
    node_type: state
    plane: PROD
    status: ${GATE_STATUS}
    impact: 5
    confidence: 0.9
    verified_at: ${TODAY}
    verified_against: ${GATE_VERIF}
    label: "${GATE_LABEL}"

  - id: Q_WHAT_IS_THIS_REPO_DOMAIN
    node_type: question
    plane: PROD
    status: open
    impact: 5
    confidence: 1.0
    verified_at: ${TODAY}
    verified_against: semente-da-adocao-dominio-ainda-nao-mapeado
    label: "A PERGUNTA QUE ABRE O HÁBITO, e o radar vai afundá-la a cada leitura até ela ser respondida: qual é o domínio deste repo — as entidades, os estados, as decisões já tomadas e as premissas que ainda são premissa? Responder é criar docs/onion/graph/<tema>.kg.yaml com nós reais e reconciliar esta pergunta para \`done\`. Enquanto ela estiver aberta, a próxima sessão que abrir este repo tem de reconstruir o entendimento da prosa — que é exatamente o custo que o KG existe para eliminar."

  - id: D_ADOPT_ONION
    node_type: decision
    plane: PROD
    status: done
    impact: 4
    confidence: 1.0
    verified_at: ${TODAY}
    verified_against: superficie-do-framework-presente-e-stamp-carimbado
    trace: "adoção executada por /meta:adopt a partir do core onion-evolve, pin ${PIN}, em ${TODAY}"
    label: "DECISÃO: adotar o Onion neste repo (modo \`${MODE}\`). O que se ganha não é o inventário de scripts — é o gate determinístico que REPROVA e o KG como fonte de estado. As duas metades se sustentam: gate sem grafo protege sintaxe sem memória; grafo sem gate é acervo que ninguém é obrigado a manter honesto."

edges:
  - from: THIS_REPO
    to: ONION_INSTALLED
    edge_type: HAS_STATE
    label: "O pin e o modo são estado deste repo — e o pin é o que torna a atualização um delta verificável em vez de uma cópia por cima."

  - from: THIS_REPO
    to: DETERMINISTIC_GATE
    edge_type: HAS_STATE
    label: "A proteção é estado DESTE repo, não do framework: o mesmo framework instalado pode ter gate vivo aqui e inerte no vizinho, e a diferença só aparece executando."

  - from: D_ADOPT_ONION
    to: ONION_INSTALLED
    edge_type: CAUSES
    label: "A decisão produziu a instalação; o stamp é o registro verificável dela."

  - from: DETERMINISTIC_GATE
    to: D_ADOPT_ONION
    edge_type: SUPPORTS
    label: "É a capacidade que compra a adoção: um hook que barra a ação por código de saída, inclusive sob bypassPermissions — o resto do valor é conselho, e conselho não reprova."

  - from: Q_WHAT_IS_THIS_REPO_DOMAIN
    to: THIS_REPO
    edge_type: CONSTRAINS
    label: "Não derruba nada — LIMITA o que o Onion consegue fazer aqui. Sem domínio mapeado, o /warm-up e o /catch-up leem prosa, e cada sessão nova paga de novo o custo de entender o projeto."
YAML

echo "  ✓ semeado: ${OUT#${DEST}/}  (5 nós, 5 arestas — gate: ${GATE})"
echo "    leia com: bash .claude/validation/kg-radar.sh docs/onion/graph/onion-adoption.kg.yaml"
exit 0
