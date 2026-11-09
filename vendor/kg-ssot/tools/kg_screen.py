#!/usr/bin/env python3
"""A triagem do texto de grafo antes de chegar a um modelo (4.47.0): o que o kg-mcp devolve a um agente é texto escrito
por usuários do armazém, e uma instrução escondida nele chega ao modelo por esse caminho.

Só biblioteca padrão, determinística: uma função pura do texto, sem relógio, sem rede e sem modelo.

Três vereditos:
  pass        nenhum sinal: o texto vai como está;
  quarantine  um sinal sozinho (caractere invisível, região escondida OU frase de diretiva): o texto vai, com o achado,
              para quem lê decidir; texto visível que fala de injeção de prompt costuma ser um documento SOBRE o tema, e
              texto escondido sozinho costuma ser sobra de editor;
  block       a diretiva ESCONDIDA (dentro de região escondida, no bloco de tags, ou partida por invisíveis): o texto é
              retido. É o caso de um texto arrumado para um humano não ver e um modelo ler. Um invisível legítimo em outro
              ponto (emoji com ZWJ, marca bidi) junto de uma diretiva visível fica em quarantine.

O que é conferido:
  - caracteres invisíveis: toda a categoria Cf do Unicode (largura zero, junções, controles bidirecionais da classe
    "Trojan Source", o hífen suave, o bloco de tags, o U+FEFF fora do início), os controles C0 e C1 (menos tab, quebra de
    linha e retorno) e os preenchimentos que não desenham nada (U+034F e os de Hangul); o bloco de tags é também
    decodificado, e a diretiva escrita nele conta como escondida;
  - regiões escondidas: comentário HTML, template, noscript e HTML cujo próprio atributo esconde (display:none,
    visibility:hidden, opacity:0, font-size:0, color:transparent, aria-hidden, o atributo hidden);
  - diretivas: frases que se dirigem a um modelo (ignore/disregard/forget as instruções anteriores, "you are now",
    "system prompt", "do not tell the user", e as mesmas em português) e marcadores de template de chat.

O que NÃO é conferido, e um pass não garante: homóglifos e confusíveis; conteúdo codificado (base64, hex, percent não é
decodificado e triado de novo); diretivas em outra língua além de inglês e português; a cascata de CSS (o esconder é
lido no atributo da própria tag, não num <style> em outro lugar); a região aninhada (o primeiro fechamento de mesmo
nome encerra a região); a posição fora da tela; e o que já está no armazém só é triado quando é lido.

Uso: kg_screen.py ARQUIVO...   (imprime o veredito e os achados de cada arquivo; rc 0 pass, 1 quarantine, 3 block)
"""
import json
import re
import sys
import unicodedata

# os preenchimentos que não são da categoria Cf mas não desenham nada (o combinador CGJ e os de Hangul)
EXTRA_INVISIBLE = {"͏", "ᅟ", "ᅠ", "ㅤ", "ﾠ"}
ALLOWED_CONTROLS = {"\t", "\n", "\r"}
TAG_LO, TAG_HI = 0xE0000, 0xE007F
HIDING_ATTR = re.compile(
    r"display\s*:\s*none|visibility\s*:\s*hidden|opacity\s*:\s*0(?:\.0+)?(?![\d.])|font-size\s*:\s*0(?:\.0+)?(?![\d.])"
    r"|color\s*:\s*transparent|aria-hidden\s*=\s*[\"']?true|(?:^|\s)hidden(?:\s|=|$)", re.I)
TAG = re.compile(r"<([A-Za-z][\w-]{0,30})([^<>]{0,2000})>")
HIDING_ELEMENTS = {"template", "noscript"}
COMMENT = re.compile(r"<!--(.{0,20000}?)(?:--!?>|\Z)", re.S)
GAP = r"[^.]{0,60}"  # a distância entre as palavras da diretiva: limitada (sem regex catastrófica) e atravessa linha
DIRECTIVES = [re.compile(p, re.I) for p in (
    r"\b(?:ignore|disregard|forget|override)\b" + GAP + r"\b(?:previous|prior|above|earlier|all|any|your)\b" + GAP +
    r"\b(?:instructions?|rules?|prompts?|directions?|guidelines?)\b",
    r"\byou are now\b", r"\bact as (?:an?|the) (?:unrestricted|jailbroken|different)\b",
    r"\b(?:reveal|print|show|leak)\b" + GAP + r"\b(?:system prompt|hidden instructions?|your instructions)\b",
    r"\bdo not (?:tell|inform|mention (?:this )?to) the user\b",
    r"\b(?:call|invoke|run|execute) the (?:tool|function)\b" + GAP + r"\bwithout\b",
    r"\b(?:ignore|desconsidere|esque[çc]a)\b" + GAP + r"\b(?:instru[çc](?:[ãa]o|[õo]es)|regras?)\b" + GAP +
    r"\b(?:anteriores?|acima|todas?)\b",
    r"\besque[çc]a tudo\b", r"\b(?:agora voc[êe] [ée]|a partir de agora voc[êe])\b",
    r"\bn[ãa]o (?:conte|diga|avise) (?:isso )?ao usu[áa]rio\b",
    r"<\|(?:im_start|im_end|system|endoftext)\|>", r"\[/?INST\]", r"<<SYS>>",
    r"(?m)^[ \t]{0,8}#{0,3}[ \t]{0,8}(?:system|assistant)[ \t]{0,8}:",
)]


def _is_invisible(c, at_start):
    if c in ALLOWED_CONTROLS or (c == "﻿" and at_start):
        return False
    return c in EXTRA_INVISIBLE or unicodedata.category(c) in ("Cf", "Cc")


def _directives(text):
    return [m.group(0)[:80] for rx in DIRECTIVES for m in rx.finditer(unicodedata.normalize("NFKC", text))]


def _hidden_regions(text):
    """O conteúdo dos comentários HTML e dos elementos escondidos pelo próprio atributo (ou template e noscript)."""
    out = [m.group(1) for m in COMMENT.finditer(text)]
    for m in TAG.finditer(text):
        name, attrs = m.group(1).lower(), m.group(2)
        if name in HIDING_ELEMENTS or HIDING_ATTR.search(attrs):
            end = text.lower().find(f"</{name}", m.end())
            out.append(text[m.end():end if end >= 0 else min(len(text), m.end() + 20000)])
    return out


def screen(text):
    """O veredito do texto: {"verdict": pass|quarantine|block, "findings": [{"class", "detail"}]}. Block só quando a
    diretiva está ESCONDIDA: dentro de comentário ou elemento escondido, codificada no bloco de tags do Unicode, ou
    partida por caracteres invisíveis (só aparece quando eles saem). Uma diretiva visível e um invisível em outro ponto do
    texto (o emoji com ZWJ, a marca bidi de um texto em hebraico) são sinais independentes: quarantine. Texto que não é
    str sai pass, sem achado."""
    if not isinstance(text, str) or not text:
        return {"verdict": "pass", "findings": []}
    findings = []
    invisible = sorted({f"U+{ord(c):04X}" for k, c in enumerate(text) if _is_invisible(c, k == 0)})
    if invisible:
        findings.append({"class": "invisible", "detail": " ".join(invisible[:8])})
    hidden = _hidden_regions(text)
    if hidden:
        findings.append({"class": "hidden-region", "detail": f"{len(hidden)} region(s)"})
    stripped = "".join(c for k, c in enumerate(text) if not _is_invisible(c, k == 0))
    directive = _directives(stripped)
    if directive:
        findings.append({"class": "directive", "detail": directive[0]})
    tags = "".join(chr(ord(c) - TAG_LO) for c in text if TAG_LO + 0x20 <= ord(c) <= TAG_LO + 0x7E)
    concealed = (any(_directives(h) for h in hidden)
                 or (tags and _directives(tags))
                 or (directive and not _directives(text)))  # partida: só aparece sem os invisíveis
    verdict = "block" if concealed else ("quarantine" if findings else "pass")
    return {"verdict": verdict, "findings": findings}


def main(argv=None):
    args = sys.argv[1:] if argv is None else argv
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        return 0 if args else 2
    worst = 0
    for path in args:
        try:
            text = open(path, encoding="utf-8").read()
        except (OSError, UnicodeDecodeError) as exc:
            print(f"BROKEN INPUT  {path}: {exc}", file=sys.stderr)
            return 2
        r = screen(text)
        print(json.dumps({"file": path, **r}, ensure_ascii=False))
        worst = max(worst, {"pass": 0, "quarantine": 1, "block": 3}[r["verdict"]])
    return worst


if __name__ == "__main__":
    sys.exit(main())
