#!/usr/bin/env bash
# =============================================================================
# plugin-readme.sh — README.md de UM plugin, GERADO do próprio plugin montado (padrão de referência de plugins do
# Claude Code: o que traz, como instalar, comandos/agentes/skills/hooks catalogados, requisitos, proveniência, licença).
#
# Chamado pelo assemble-plugin.sh ao fim da montagem (artefato gerado; SSOT = .claude/ do source). Lê:
#   <DEST>/.claude-plugin/{plugin.json,capability.json,provenance.json}, commands/*.md, agents/*.md, skills/*/SKILL.md,
#   hooks/hooks.json. Frontmatter (name/description) parseado só entre os dois `---`; `description: >` dobrado é juntado.
# Uso: plugin-readme.sh <DEST> [<marketplace-name>=onion-plugins]      (python3 obrigatório; sem ele avisa e sai 0)
# =============================================================================
set -uo pipefail
DEST="${1:-}"; MKT="${2:-onion-plugins}"
[ -d "${DEST}/.claude-plugin" ] || { echo "plugin-readme: DEST inválido: ${DEST}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "plugin-readme: python3 ausente — README do plugin não gerado" >&2; exit 0; }
DEST="${DEST}" MKT="${MKT}" python3 - <<'PY'
import json, os, re, glob
dest=os.environ["DEST"]; mkt=os.environ["MKT"]
def jload(p):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return {}
pj=jload(os.path.join(dest,".claude-plugin/plugin.json")); cap=jload(os.path.join(dest,".claude-plugin/capability.json")); prov=jload(os.path.join(dest,".claude-plugin/provenance.json"))
name=pj.get("name") or os.path.basename(dest); display=pj.get("displayName") or ("Onion" if name=="onion" else "Onion · "+name.replace("onion-","").replace("-"," ").title())
def frontmatter(path):
    try: L=open(path,encoding="utf-8").read().split("\n")
    except Exception: return {}
    if not L or L[0].strip()!="---": return {}
    out={}; key=None; buf=[]
    for ln in L[1:]:
        if ln.strip()=="---": break
        m=re.match(r"^([A-Za-z_-]+):\s*(.*)$", ln)
        if m and not ln.startswith(" "):
            if key and buf: out[key]=" ".join(x.strip() for x in buf).strip(); buf=[]
            key=m.group(1); val=m.group(2).strip()
            if val in (">",">-","|","|-"): buf=[]
            else: out[key]=val.strip('"').strip("'"); key=None
        elif key is not None and ln.startswith(" "): buf.append(ln)
    if key and buf: out[key]=" ".join(x.strip() for x in buf).strip()
    return out
def first_sentence(s, n=160):
    s=re.sub(r"\s+"," ",s or "").strip()
    m=re.match(r"^(.+?[.!?])(\s+[A-ZÀ-Ú\[(]|$)", s)   # 1ª frase: termina em pontuação seguida de maiúscula/fim
    if m: s=m.group(1)
    return (s[:n-1]+"…") if len(s)>n else s
def esc(s): return (s or "").replace("|","\\|")
cmds=[]
for p in sorted(glob.glob(os.path.join(dest,"commands","**","*.md"), recursive=True)):
    base=os.path.splitext(os.path.basename(p))[0]
    if base.lower()=="readme": continue
    fm=frontmatter(p); cmds.append((fm.get("name") or base, first_sentence(fm.get("description",""))))
agents=[]
for p in sorted(glob.glob(os.path.join(dest,"agents","**","*.md"), recursive=True)):
    base=os.path.splitext(os.path.basename(p))[0]
    if base.lower()=="readme": continue
    fm=frontmatter(p); agents.append((fm.get("name") or base, first_sentence(fm.get("description",""))))
skills=[]
for p in sorted(glob.glob(os.path.join(dest,"skills","*","SKILL.md"))):
    fm=frontmatter(p); skills.append((os.path.basename(os.path.dirname(p)), first_sentence(fm.get("description",""))))
hooks=[]
hj=jload(os.path.join(dest,"hooks","hooks.json"))
for ev, entries in (hj.get("hooks",hj) if isinstance(hj,dict) else {}).items():
    if not isinstance(entries,list): continue
    for e in entries:
        for h in (e.get("hooks",[]) if isinstance(e,dict) else []):
            c=h.get("command","") if isinstance(h,dict) else ""
            hooks.append((ev, os.path.basename(c.split()[-1].strip('"')) if c else "?"))
provides=cap.get("provides",[]); requires=cap.get("requires",[]); conf=cap.get("conformance","")
out=[]
out.append(f"# {display} — plugin `{name}` do Sistema Onion 🧅\n")
out.append(f"{pj.get('description','')}\n")
meta=[f"**Versão** `{pj.get('version','?')}` (derivada do conteúdo: anda quando o conteúdo anda)", f"**Licença** {pj.get('license','MIT')}"]
if conf: meta.append(f"**Conformance** `{conf}`")
out.append(" · ".join(meta)+"\n")
out.append("## Instalar\n")
out.append("```\n/plugin marketplace add marciocar/%s\n/plugin install %s@%s\n```\n" % (mkt, name, mkt))
out.append("Instalado ≠ habilitado: se os comandos não aparecerem, `/plugin enable %s@%s` e reinicie o Claude Code (hooks só carregam em sessão nova).\n" % (name, mkt))
out.append("```\n# CLI, sem prompt\nclaude plugin marketplace add marciocar/%s && claude plugin install %s@%s\n```\n" % (mkt, name, mkt))
out.append("## O que traz\n")
out.append("| Componente | Quantidade |\n|---|---|\n| Comandos | %d |\n| Agentes | %d |\n| Skills | %d |\n| Hooks | %d |\n" % (len(cmds),len(agents),len(skills),len(hooks)))
if provides: out.append("**Capacidades (Capability Contract):** provê " + ", ".join(f"`{x}`" for x in provides) + (("; requer " + ", ".join(f"`{x}`" for x in requires)) if requires else "") + ".\n")
if cmds:
    out.append("## Comandos\n\nInvocação: `/%s:<comando>` (namespace do plugin).\n\n| Comando | O que faz |\n|---|---|" % name)
    out += [f"| `/{name}:{esc(n)}` | {esc(d)} |" for n,d in cmds]; out.append("")
if agents:
    out.append("## Agentes\n\n| Agente | Especialidade |\n|---|---|")
    out += [f"| `@{esc(n)}` | {esc(d)} |" for n,d in agents]; out.append("")
if skills:
    out.append("## Skills\n\n| Skill | Quando ativa |\n|---|---|")
    out += [f"| `{esc(n)}` | {esc(d)} |" for n,d in skills]; out.append("")
if hooks:
    out.append("## Hooks\n\n| Evento | Script |\n|---|---|")
    out += [f"| `{esc(e)}` | `{esc(s)}` |" for e,s in hooks]; out.append("")
    out.append("Hooks são determinísticos (bash) e podem VETAR uma ação com `exit 2` — é a capacidade que só existe no Claude Code. Nenhum envia dados para fora; todos rodam local.\n")
out.append("## Requisitos\n\n- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.\n- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `/meta:adopt` no repositório-fonte.\n")
# Só campos CONTENT-STABLE aqui: ref/commit_date mudam a cada commit e fariam o README driftar (REGRA 19 acusou no CI, 2026-09-04).
out.append("## Proveniência\n\n| Campo | Valor |\n|---|---|\n| Fonte | `%s` |\n| tree_sha (hash do conteúdo das fontes) | `%s` |\n\nRef e data do commit de origem estão em `.claude-plugin/provenance.json`.\n" % (prov.get("repository","?"), str(prov.get("tree_sha","?"))[:12]))
out.append("Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.\n")
out.append("## Licença\n\n%s — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Fonte: https://github.com/%s\n" % (pj.get("license","MIT"), prov.get("repository","marciocar/onion-evolve")))
open(os.path.join(dest,"README.md"),"w",encoding="utf-8").write("\n".join(out))
print(f"plugin-readme: {name}: {len(cmds)} comandos, {len(agents)} agentes, {len(skills)} skills, {len(hooks)} hooks")
PY
