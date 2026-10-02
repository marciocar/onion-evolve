#!/usr/bin/env bash
# ===========================================================================
# announce-zero-claim-check.sh — ANÚNCIO que afirma ZERO sem medição (REGRA 95)
#
# ── POR QUE EXISTE (dano consumado, medido 2026-08-31 e re-medido 2026-09-16) ───────────────
# Um anúncio do core para um adotante escreveu, em prosa: *"As portas estão OK (nenhuma sem
# prefixo de bind)"*. A catraca da MESMA leva tinha contado 38 exposições, o relatório dentro da
# própria branch dizia o número certo — e o PRÓPRIO anúncio citava "os 38 casos legados" doze
# linhas antes. Dois artefatos da mesma leva discordando, um dizendo 0 e o outro 38.
#
# O ANÚNCIO É O ÚNICO DOCUMENTO QUE CHEGA ANTES DO MERGE. Quem leu só ele concluiu que não havia
# o que fazer, e a dívida tolerada ficou tolerada PARA SEMPRE, porque ninguém foi avisado.
#
# ── POR QUE SÓ A AFIRMAÇÃO DE ZERO, e é desenho, não preguiça ──────────────────────────────
# O mesmo anúncio errou um número NÃO-ZERO: disse "3 fallbacks" onde o padrão produzia 19 em 10
# variáveis — quem aplicasse "o fix de 3 linhas" curaria 16% da classe achando ter curado a classe.
# ESSE caso é INDETECTÁVEL por grep: nenhum padrão sabe a contagem verdadeira do alvo.
# A assimetria que sobra é a que paga: um não-zero errado ainda PROVOCA ação (o leitor vai olhar);
# um ZERO desliga a ação inteira. A guarda cobra o zero e DECLARA que não cobre o resto — guarda
# que promete o que não mede ensina a ignorar o vermelho.
#
# ── ESCOPO PROSPECTIVO ─────────────────────────────────────────────────────────────────────
# Julga só anúncios de 1º NÍVEL em `outbox/<id>/` — os que ainda VÃO viajar, onde a cura existe.
# `_processed/` e `_archive/` já viajaram e história não se reescreve; acusá-los seria passivo sem
# cura, o modo-de-falha travante desta casa. Medido 2026-10-01: 0 em 1º nível, logo a guarda nasce
# SEM-OBJETO e morde o PRÓXIMO anúncio — a forma canônica da casa para ausência legítima.
#
# ⚠️ A UNIDADE É A FRASE, NUNCA A LINHA — e descobri isso porque a 1ª versão NÃO PEGOU o defeito
# histórico contra o qual foi escrita. O anúncio de 2026-08-31 traz a afirmação PARTIDA pelo wrap
# do markdown: `As portas` fecha uma linha e `estão OK (nenhuma sem prefixo de bind)` abre a
# seguinte. Casando linha a linha, ZERO e CLASSE nunca caem juntos e a guarda passa verde no caso
# que a motivou. Calibrar contra o dano real é o que separa guarda de teatro — e foi a calibração,
# não o raciocínio, que achou isto.
#
# ⚠️ TETO DECLARADO: ZERO e CLASSE VERIFICÁVEL são LISTAS, e lista falha pelo VOCABULÁRIO (classe
# medida 3× num dia nesta casa). As duas estão visíveis abaixo; a guarda nunca afirma cobertura
# além delas. E ela não sabe se o número colado está CERTO — só que foi colado.
#
# Uso:  bash .claude/validation/announce-zero-claim-check.sh [<repo>]
# Saída: uma linha por achado, prefixada por `REGRA 95: `. Exit: 0 limpo/sem-objeto · 1 achado · 3 não pude julgar.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_announce_zero_claim_selftests).
# ===========================================================================
set -uo pipefail
REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "announce-zero-claim: alvo inexistente: ${REPO}" >&2; exit 3; }
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "announce-zero-claim: ${REPO} não é repo git — NÃO PUDE JULGAR" >&2; exit 3; }
command -v python3 >/dev/null 2>&1 \
  || { echo "announce-zero-claim: python3 ausente — NÃO PUDE JULGAR (a segmentação em frases mora nele)" >&2; exit 3; }

# ── VOCABULÁRIO 1: a forma de afirmar ZERO ──────────────────────────────────────────────────
export ANZ_ZERO='nenhum|nenhuma|nenhuns|nenhumas|zero|não há|nao ha|não existe|nao existe|sem nenhum|livre de'
# ── VOCABULÁRIO 2: a CLASSE VERIFICÁVEL sobre a qual o zero é afirmado ──────────────────────
# (só o que uma medição do Onion de fato CONTA — é isso que torna o zero cobrável)
export ANZ_CLASSE='exposiç|exposic|violaç|violac|achado|ocorrênc|ocorrenc|fallback|segredo|credencial|porta|HARD|SOFT|pendênc|pendenc|drift|vazament'
# ── PROVENIÊNCIA: a medição colada, ou a ausência declarada ─────────────────────────────────
export ANZ_PROV='`bash |`/meta:|-baseline\.txt|não medido|nao medido|SEM-OBJETO|exit 0|rc=0'

mapfile -t ANUNCIOS < <(git -C "${REPO}" ls-files 'docs/evolution/federation/outbox/*/*.md' 2>/dev/null \
  | grep -v '_processed/\|_archive/' | sort || true)

if [ "${#ANUNCIOS[@]}" -eq 0 ]; then
  echo "REGRA 95: [anuncio-zero/SEM-OBJETO] nenhum anúncio de 1º nível em outbox/<id>/ — guarda prospectiva, nada a julgar nesta passada (os de _processed/ já viajaram e história não se reescreve)"
  exit 0
fi

found=0
for rel in "${ANUNCIOS[@]}"; do
  export ANZ_REL="${rel}"
  if ! python3 "${BASH_SOURCE[0]%.sh}.py" "${REPO}/${rel}"; then found=1; fi
done
exit "${found}"
