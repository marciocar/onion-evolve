#!/usr/bin/env bash
# =============================================================================
# marketplace-readme.sh — README.md do MARKETPLACE público, GERADO (padrão de referência de marketplaces do Claude Code:
# quick start slash+CLI, tabela de plugins com o que cada um traz, atualizar/habilitar/remover/listar, requisitos,
# política de versão, o que não vem (moat), estrutura de plugin, licença). Chamado pelo materialize-marketplace-repo.sh.
# Uso: marketplace-readme.sh <TARGET> <marketplace-name>          (python3 obrigatório)
# =============================================================================
set -uo pipefail
TARGET="${1:-}"; MKT="${2:-onion-plugins}"
[ -d "${TARGET}/plugins" ] || { echo "marketplace-readme: TARGET sem plugins/: ${TARGET}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "marketplace-readme: python3 ausente" >&2; exit 2; }
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/public-face.sh"
TARGET="${TARGET}" MKT="${MKT}" ONION_PUBLIC_HOMEPAGE="${ONION_PUBLIC_HOMEPAGE}" ONION_PUBLIC_REPOSITORY="${ONION_PUBLIC_REPOSITORY}" python3 - <<'PY'
import json, os, glob
t=os.environ["TARGET"]; mkt=os.environ["MKT"]
# Face pública (public-face.sh): o source é PRIVADO — este README nunca o publica como endereço.
HOMEPAGE=os.environ.get("ONION_PUBLIC_HOMEPAGE","https://onionevolve.com")
PUBREPO=os.environ.get("ONION_PUBLIC_REPOSITORY","https://github.com/marciocar/onion-plugins")
def jload(p):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return {}
rows=[]
for pj in sorted(glob.glob(os.path.join(t,"plugins","*",".claude-plugin","plugin.json"))):
    d=os.path.dirname(os.path.dirname(pj)); p=jload(pj); name=p.get("name") or os.path.basename(d)
    n=lambda pat: len([x for x in glob.glob(os.path.join(d,pat),recursive=True) if os.path.basename(x).lower()!="readme.md"])
    cmds=n("commands/**/*.md"); ags=n("agents/**/*.md"); sk=len(glob.glob(os.path.join(d,"skills","*","SKILL.md")))
    hj=jload(os.path.join(d,"hooks","hooks.json")); hooks=sum(len(h.get("hooks",[])) for ev in (hj.get("hooks",hj) if isinstance(hj,dict) else {}).values() if isinstance(ev,list) for h in ev)
    cat={"onion":"core"}.get(name,"vertical")
    rows.append((name,cat,p.get("version","?"),cmds,ags,sk,hooks,p.get("description","")))
order={"core":0,"vertical":1,"tools":2}; rows.sort(key=lambda r:(order[r[1]],r[0]))
def short(s,n=110):
    s=" ".join((s or "").split()); s=s.split(". ")[0]; return (s[:n-1]+"…") if len(s)>n else s
L=[]
L.append(f"# 🧅 {mkt} — o Sistema Onion como plugins do Claude Code\n")
L.append("O **Onion** é um framework operacional para desenvolvimento com IA: workflows faseados e retomáveis (produto → engenharia → compliance), um grafo de conhecimento como fonte de verdade em runtime (KG-SSOT), guardas determinísticas por hook e abstrações de provider (SDAAL). Este marketplace entrega essa **capacidade** como plugins instaláveis e atualizáveis pelo gerenciador de plugins — sem vendorizar nada no seu repositório.\n")
L.append("Site: %s · Issues e suporte: %s · Licença: MIT\n" % (HOMEPAGE, PUBREPO))
L.append("## Quick start\n")
L.append("```\n/plugin marketplace add marciocar/%s\n/plugin install onion@%s\n```\n" % (mkt,mkt))
L.append("Reinicie o Claude Code depois de instalar (hooks só carregam em sessão nova). Comece por `/onion:warm-up` (contexto do projeto) ou `/onion:catch-up` (onde você parou); `/onion:onion` orienta o que fazer a seguir.\n")
L.append("```\n# equivalente por CLI, sem prompts\nclaude plugin marketplace add marciocar/%s && claude plugin install onion@%s --yes\n```\n" % (mkt,mkt))
L.append("**Instalado ≠ habilitado.** Se os comandos `/onion:*` não aparecerem: `/plugin enable onion@%s` e reinicie.\n" % mkt)
L.append("## Plugins\n")
L.append("| Plugin | Categoria | Versão | Comandos | Agentes | Skills | Hooks | O que traz |\n|---|---|---|---|---|---|---|---|")
for name,cat,ver,c,a,s,h,desc in rows:
    L.append(f"| [`{name}`](plugins/{name}/README.md) | {cat} | `{ver}` | {c} | {a} | {s} | {h} | {short(desc)} |")
L.append("")
L.append("Instale só o que precisa: `onion` é o núcleo (obrigatório: orquestrador, motores KG, guardas, runtime); cada vertical acrescenta comandos e agentes de um domínio; `onion-work-tools` traz os utilitários de trabalho (censo, backlog, freshness). Cada plugin tem o seu README com o catálogo completo.\n")
L.append("```\n/plugin install onion-engineering@%s\n/plugin install onion-product@%s\n```\n" % (mkt,mkt))
L.append("## Migração (2026-09)\n\nTrês plugins foram absorvidos para o canal premiar bundles verticais coesos (pesquisa R1, 2026-09-04): `onion-work-tools` → `onion` · `onion-testing` → `onion-engineering` · `onion-docs` → `onion-product`. Quem tinha os antigos: `/plugin uninstall <antigo>@%s` e `/plugin install <novo>@%s`. Os nomes antigos não voltam (nomes de plugin são imutáveis no diretório).\n" % (mkt, mkt))
L.append("## Manter em dia\n")
L.append("| Ação | Slash | CLI |\n|---|---|---|")
L.append(f"| Atualizar o marketplace | `/plugin marketplace update {mkt}` | `claude plugin marketplace update {mkt}` |")
L.append(f"| Atualizar um plugin | `/plugin update onion@{mkt}` | `claude plugin update onion@{mkt}` |")
L.append(f"| Habilitar / desabilitar | `/plugin enable onion@{mkt}` · `/plugin disable onion@{mkt}` | `claude plugin enable …` · `claude plugin disable …` |")
L.append(f"| Remover | `/plugin uninstall onion@{mkt}` | `claude plugin uninstall onion@{mkt}` |")
L.append("| Listar | `/plugin list` · `/plugin marketplace list` | `claude plugin list --json` |")
L.append("| Validar (dev) | `/plugin validate ./plugins/onion` | `claude plugin validate ./plugins/onion --strict` |")
L.append("")
L.append("**Política de versão.** A versão de cada plugin é **derivada do conteúdo** (`0.1.<N>`, N = commits que tocaram as fontes canônicas): ela anda exatamente quando o conteúdo anda, e o `plugin update` — que compara versões, não conteúdo — enxerga a mudança. A entrada do marketplace não repete a versão: o `plugin.json` é a autoridade (recomendação oficial).\n")
L.append("## Requisitos\n")
L.append("- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`).\n- `bash`, `git`, `awk`; `python3` para os motores de grafo e censos; `jq` opcional.\n- Os hooks são scripts locais e determinísticos; podem vetar uma ação com `exit 2` (é a capacidade que só o Claude Code oferece). Nenhum envia dados para fora.\n")
L.append("## O que este canal é — e o que não é\n")
L.append("- **É** instalação de capacidade: read-only, versionada, atualizável, removível. Os seus grafos de conhecimento são **seus** (o plugin traz o motor; você constrói o SSOT).\n- **Não é** adoção/vendorização: para ter o Onion dentro do repositório (customizável, com co-evolução), o canal é `meta:adopt` (comando do core) no repositório-fonte.\n- **Não vem** a meta-fábrica (gerar novos comandos/verticais/adotantes) nem os grafos privados do core — por desenho (moat).\n")
L.append("## Estrutura de cada plugin\n")
L.append("```\nplugins/<nome>/\n├── .claude-plugin/\n│   ├── plugin.json        # manifesto (name, version derivada, description, keywords, license)\n│   ├── capability.json    # Capability Contract: provides / requires / loads\n│   └── provenance.json    # repository + ref + tree_sha do conteúdo (content-addressed)\n├── commands/  agents/  skills/  hooks/   # o que o plugin expõe (namespace /<nome>:<comando>)\n├── kb/  utils/  validation/              # doutrina e motores embarcados (quando aplicável)\n├── README.md                             # catálogo gerado do próprio plugin\n└── LICENSE                               # licença por plugin (exigência do diretório oficial)\n```\n")
L.append("## Contribuir e reportar\n")
L.append("**Issues, dúvidas e relatos de bug: %s/issues.** É o canal de suporte deste projeto.\n\nOs plugins aqui são **artefatos gerados** por `materialize-marketplace-repo.sh` a partir de um repositório-fonte **privado**, então este repositório não recebe PRs de conteúdo: uma correção proposta numa issue é aplicada no source e chega aqui na materialização seguinte. Abrir a issue é o caminho — e é o caminho inteiro.\n" % PUBREPO)
L.append("## Licença\n\nMIT — © Onion · Marcio Carvalho.\n\n---\n🧅 Gerado do source por `materialize-marketplace-repo.sh` + `marketplace-readme.sh` (Sistema Onion). Não edite à mão: a próxima materialização sobrescreve.\n")
open(os.path.join(t,"README.md"),"w",encoding="utf-8").write("\n".join(L))
print(f"marketplace-readme: {len(rows)} plugins na tabela")
PY
