#!/usr/bin/env python3
# ===========================================================================
# selftest-families.py — merge driver do git para .claude/validation/lint-selftest.sh (SAC-146).
#
# ── POR QUE EXISTE (medido em 2026-10-15) ──────────────────────────────────────────────────
# Três PRs em paralelo (#1133, #1134, #1135) acrescentaram cada um uma família nova da bancada depois
# da MESMA linha (`_family run_residue_schema_selftests`). Cada merge deixou o próximo em conflito de
# fonte, que o `pr-finalize --rebase` recusa (corretamente: não é projeção gerada), e a resolução foi à
# mão, sempre a mesma: manter os dois blocos. Já tinha acontecido em 2026-10-07 (#951).
#
# ── POR QUE NÃO `merge=union` ────────────────────────────────────────────────────────────────
# O union vale para o ARQUIVO inteiro: todo conflito vira "as duas versões, uma depois da outra". Num
# arquivo de 36 mil linhas de código isso é perda silenciosa: duas edições da mesma linha (ex.: a lista
# SELFTEST_CORE_ONLY_FAMILIES) viram duas atribuições, a segunda vence e a família da primeira some da
# lista sem conflito nenhum. A bancada (família selftest_family_merge, caso (c)) prova isso.
#
# ── O QUE ESTE DRIVER FAZ ────────────────────────────────────────────────────────────────────
# Roda o merge de 3 vias de texto (`git merge-file --diff3`) e resolve um conflito SÓ quando TODOS os
# conflitos do arquivo são o caso medido:
#   (1) a base do conflito é VAZIA: os dois lados só ACRESCENTARAM linhas no mesmo ponto;
#   (2) o ponto fica na região de famílias (entre os marcadores ONION-BENCH FIM DO MOTOR e INÍCIO DO
#       SUMÁRIO), nunca no motor, e no TOPO: a linha de código anterior é uma invocação `_family`;
#   (3) cada lado é um BLOCO INTEIRO: termina numa invocação `_family run_<x>_selftests`, não tem
#       marcador ONION-BENCH e passa sozinho no `bash -n` (fragmento de função não passa);
#   (4) nenhum nome colide: família ou função de topo (coluna 0) que o resultado define mais vezes do
#       que qualquer um dos dois lados definia (duas definições = a segunda apaga a primeira em silêncio);
#   (5) o arquivo resultante passa no `bash -n`.
# A resolução é a mesma da mão: o bloco da base do rebase (HEAD) primeiro, o do commit reaplicado depois.
# Basta UM conflito fora do caso para o driver devolver o merge de texto PADRÃO, com os marcadores, e
# sair ≠ 0 — o comportamento de sempre. Nunca resolve pela metade.
#
# ── LIGAÇÃO ──────────────────────────────────────────────────────────────────────────────────
# .gitattributes:   .claude/validation/lint-selftest.sh merge=onion-selftest-families
# O nome só vale com o driver na config do git; sem ele o git cai no merge de texto (o de sempre). O
# `ops/pr-finalize.sh --rebase` passa a config por `git -c` (nada persiste). À mão, numa worktree:
#   git -c merge.onion-selftest-families.driver='python3 -I ops/merge-drivers/selftest-families.py %O %A %B %L %P' rebase origin/main
# ⚠️ Driver configurado que NÃO consegue rodar (python3 ausente, caminho errado) deixa o arquivo como o lado
#    HEAD, marcado em conflito mas SEM marcadores: quem dá `git add` ali perde o lado reaplicado. Por isso o
#    pr-finalize só passa a config com o python3 presente e o arquivo no disco.
#
# USO (pelo git):  selftest-families.py <base %O> <nosso %A> <deles %B> [<tamanho do marcador %L>] [<caminho %P>]
# SAÍDA: 0 = resolvido (resultado em %A) · 1 = conflito, %A com os marcadores do merge padrão
#        2 = uso errado. Uma linha por resolução vai ao stderr: `SELFTEST-FAMILIES: ...` (o pr-finalize a repassa).
# ===========================================================================
import os
import re
import subprocess
import sys
import tempfile

MK_END = "# ═══ ONION-BENCH: FIM DO MOTOR"
MK_SUM = "# ═══ ONION-BENCH: INÍCIO DO SUMÁRIO"
INV = re.compile(r"^_family run_([a-z0-9_]+)_selftests(\s*\|\|\s*true)?\s*(#.*)?$")
TOPFN = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{")
WIDE = 50  # marcador largo no merge interno: nenhuma linha do arquivo se confunde com ele


def say(msg):
    print("SELFTEST-FAMILIES: " + msg, file=sys.stderr)


def merge_file(ours, base, theirs, size, diff3, labels):
    """git merge-file -p: devolve (rc, texto). rc>0 = nº de conflitos; <0 = erro."""
    cmd = ["git", "merge-file", "-p", "--marker-size=%d" % size]
    if diff3:
        cmd.append("--diff3")
    for lb in labels:
        cmd += ["-L", lb]
    cmd += [ours, base, theirs]
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode < 0 or p.returncode > 127:
        return -1, ""
    return p.returncode, p.stdout.decode("utf-8", "surrogateescape")


def bash_n(text):
    with tempfile.NamedTemporaryFile("w", suffix=".sh", delete=False, encoding="utf-8", errors="surrogateescape") as t:
        t.write(text)
        path = t.name
    try:
        return subprocess.run(["bash", "-n", path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
    finally:
        os.unlink(path)


def names(lines):
    """famílias invocadas e funções de topo, com multiplicidade."""
    out = {}
    for ln in lines:
        m = INV.match(ln)
        k = ("família", m.group(1)) if m else None
        if k is None:
            m = TOPFN.match(ln)
            k = ("função", m.group(1)) if m else None
        if k:
            out[k] = out.get(k, 0) + 1
    return out


def try_resolve(merged):
    """merged = saída diff3 com marcador largo. Devolve (texto, [descrições]) ou (None, motivo)."""
    o, b, s, t = "<" * WIDE, "|" * WIDE, "=" * WIDE, ">" * WIDE
    L = merged.split("\n")
    res, done, i, region = [], [], 0, "motor"
    while i < len(L):
        ln = L[i]
        if not ln.startswith(o):
            if ln.startswith(MK_END):
                region = "famílias"
            elif ln.startswith(MK_SUM):
                region = "sumário"
            res.append(ln)
            i += 1
            continue
        try:
            jb = next(k for k in range(i + 1, len(L)) if L[k].startswith(b))
            js = next(k for k in range(jb + 1, len(L)) if L[k].startswith(s))
            jt = next(k for k in range(js + 1, len(L)) if L[k].startswith(t))
        except StopIteration:
            return None, "conflito sem os quatro marcadores do diff3"
        ours, base, theirs = L[i + 1:jb], L[jb + 1:js], L[js + 1:jt]
        where = "conflito %d (linha %d do resultado)" % (len(done) + 1, len(res) + 1)
        if base:
            return None, where + ": a base não é vazia — os dois lados MUDARAM linhas existentes"
        if region != "famílias":
            return None, where + ": fora da região de famílias (%s)" % region
        # o ponto tem de ser o TOPO do arquivo: logo depois de uma invocação _family (ou do marcador).
        # Inserção dentro do corpo de uma função passa no bash -n e roda a "família" no lugar errado.
        prev = next((x for x in reversed(res) if x.startswith(MK_END) or (x.strip() and not x.lstrip().startswith("#"))), "")
        if not (INV.match(prev) or prev.startswith(MK_END)):
            return None, where + ": o ponto não é o topo — a linha anterior não é uma invocação _family (%s)" % prev.strip()[:60]
        fams = []
        for side, blk in (("HEAD", ours), ("reaplicado", theirs)):
            body = [x for x in blk if x.strip()]
            if not body:
                return None, where + ": o lado %s é vazio" % side
            if not INV.match(body[-1]):
                return None, where + ": o lado %s não termina numa invocação _family (bloco incompleto)" % side
            if any(x.startswith(MK_END) or x.startswith(MK_SUM) for x in blk):
                return None, where + ": o lado %s traz marcador ONION-BENCH" % side
            if not bash_n("\n".join(blk) + "\n"):
                return None, where + ": o lado %s não é código de topo completo (bash -n reprova)" % side
            fams.append(",".join(INV.match(x).group(1) for x in body if INV.match(x)))
        res.extend(ours)
        res.extend(theirs)
        done.append("%s + %s" % (fams[0], fams[1]))
        i = jt + 1
    return "\n".join(res), done


def main(argv):
    if len(argv) < 4:
        print("uso: selftest-families.py <base %O> <nosso %A> <deles %B> [%L] [%P]", file=sys.stderr)
        return 2
    base, ours, theirs = argv[1], argv[2], argv[3]
    try:
        size = int(argv[4]) if len(argv) > 4 and argv[4] else 7
    except ValueError:
        size = 7
    path = argv[5] if len(argv) > 5 and argv[5] else ".claude/validation/lint-selftest.sh"

    def fallback(why):
        # o merge de texto PADRÃO, com os marcadores do tamanho que o git pediu: o comportamento de sempre
        rc, txt = merge_file(ours, base, theirs, size, False, ["HEAD", "base", "reaplicado"])
        if rc < 0:
            say("merge-file falhou em %s — %%A intocado, conflito declarado" % path)
            return 1
        with open(ours, "w", encoding="utf-8", errors="surrogateescape") as f:
            f.write(txt)
        if rc == 0:
            return 0
        say("conflito em %s NÃO resolvido (%s) — fica para a mão, como sempre" % (path, why))
        return 1

    rc, merged = merge_file(ours, base, theirs, WIDE, True, ["HEAD", "base", "reaplicado"])
    if rc <= 0:
        return fallback("merge limpo" if rc == 0 else "erro do merge-file")
    text, info = try_resolve(merged)
    if text is None:
        return fallback(info)
    # (4) colisão de nome: o resultado não pode definir um nome mais vezes do que cada lado definia
    rd = lambda p: open(p, encoding="utf-8", errors="surrogateescape").read().split("\n")
    no, nt, nr = names(rd(ours)), names(rd(theirs)), names(text.split("\n"))
    clash = sorted("%s %s" % k for k, n in nr.items() if n > max(no.get(k, 0), nt.get(k, 0), 1))
    if clash:
        return fallback("nome definido duas vezes no resultado: " + ", ".join(clash[:5]))
    if not bash_n(text):
        return fallback("o resultado não passa no bash -n")
    with open(ours, "w", encoding="utf-8", errors="surrogateescape") as f:
        f.write(text)
    for d in info:
        say("conflito de famílias acrescentadas lado a lado resolvido em %s (mantidos os dois blocos: %s)" % (path, d))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
