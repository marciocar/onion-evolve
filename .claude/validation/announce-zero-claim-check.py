#!/usr/bin/env python3
"""Segmentador de FRASES do REGRA 95 — chamado por announce-zero-claim-check.sh.

Vive em arquivo próprio porque heredoc-dentro-de-heredoc é onde o aninhamento de aspas quebra
em silêncio (medido na própria escrita, 2026-10-01). O shell carrega o vocabulário por env.
"""
import io, os, re, sys

zero = re.compile(os.environ["ANZ_ZERO"], re.I)
classe = re.compile(os.environ["ANZ_CLASSE"], re.I)
prov = re.compile(os.environ["ANZ_PROV"], re.I)
rel = os.environ.get("ANZ_REL", sys.argv[1])

linhas = io.open(sys.argv[1], encoding="utf-8", errors="replace").read().split("\n")

# PARÁGRAFO = bloco entre linhas vazias. Dentro dele o wrap do markdown é cosmético e se junta;
# guardamos a linha de ORIGEM para a mensagem apontar o sítio real no arquivo.
paragrafos, atual = [], []
for n, l in enumerate(linhas, 1):
    if l.strip() == "":
        if atual:
            paragrafos.append(atual)
            atual = []
    else:
        atual.append((n, l))
if atual:
    paragrafos.append(atual)

achou = False
for par in paragrafos:
    texto = " ".join(l.strip() for _, l in par)
    n0 = par[0][0]
    # FRASE = unidade de uma AFIRMAÇÃO. Corta em . ! ? seguidos de espaço.
    for frase in re.split(r"(?<=[.!?])\s+", texto):
        if not (zero.search(frase) and classe.search(frase)):
            continue
        # proveniência vale no PARÁGRAFO inteiro: a medição costuma vir no mesmo bloco
        if prov.search(texto):
            continue
        print(
            "REGRA 95: [anuncio-zero/SEM-MEDICAO] %s:%d: afirma ZERO sobre classe verificavel sem "
            "colar a medicao nem dizer 'nao medido' — o anuncio e o UNICO documento que chega ANTES "
            "do merge, e um zero em prosa desliga a acao do adotante (em 2026-08-31 congelou 38 "
            "exposicoes como toleradas). Rode a medicao e cole o numero, ou escreva 'nao medido'. "
            "Frase: %s" % (rel, n0, frase[:130])
        )
        achou = True

sys.exit(1 if achou else 0)
