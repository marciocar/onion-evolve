#!/usr/bin/env bash
# =============================================================================
# members-validate.sh — valida o registro de membros da federação (members.yaml)
#
# Propósito : O "teste que falha se um membro quebrar o registro". É o validador
#             determinístico que a spec m3-federation-admin nomeia como
#             pré-requisito de qualquer OP de mutação (OP-1..4) — hoje só há
#             yaml.safe_load tolerante e awk frouxo (bug FED-2-0). NÃO reimplementa
#             a P6 de nome-projetado (isso é projection-safety.sh, guarda-única).
#
# Onde RODA hoje (behavior-over-declaration — o alcance exato, sem prometer mais):
#             (1) Passo 7 de /meta:federation-member (barra o membro ANTES do commit
#             na rota do comando); (2) lint-selftest sobre as fixtures; e (3) o gate HARD
#             do lint sobre o members.yaml VIVO, pela REGRA 66 (Registro da federação
#             validado no gate), em lint-artifacts.sh. ⚠️ Até 2026-10-15 este cabeçalho
#             dizia que (3) não existia: a REGRA 66 nasceu em 2026-09-01 e ninguém voltou
#             aqui, e o plano do configurador A2A chegou a pedir "ligar o HARD" que já
#             estava ligado (medido na F1, SAC-122).
#
# Obrigatórios por membro derivado: id(único) name role kind parent onion_version
#             adopted_at mode personality_summary specializations personality_last_sync
#             trust(5 listas). OPCIONAIS: remote, local_path, lineages, exposes, etc.
#             A fonte (kind:source ⇔ role:source) é isenta dos obrigatórios.
#
# BLOCO a2a (opcional; validado desde 2026-10-15, F1 do configurador A2A, SAC-122), em
#             TODO membro que o declarar, inclusive a fonte:
#             · a2a é mapa; keys, se presente, é lista de kids na forma <id>-<N> (o que o
#               a2a-keygen.sh gera), e nenhum kid pertence a dois membros (jwks/<kid>.pem é
#               um espaço de nomes só: kid repetido seria a mesma pública para dois donos);
#             · cada kid tem jwks/<kid>.pem com pública RSA de pelo menos 2048 bits (o piso deste
#               validador e do doctor; o gate a2a-verify.sh NÃO confere bits, e o keygen gera 3072;
#               os dois pinos vivos de 2048 explicam o piso). JWKS = --jwks, senão o
#               .claude/utils/federation-transport/jwks da raiz do repo do registro. A variável
#               A2A_JWKS_DIR do ambiente NÃO é lida aqui de propósito: exportada numa shell, ela
#               dava HARD falso na REGRA 66 ou desviava a checagem (achado do refutador da F1a);
#             · keys não vazio exige sends_to (menos a FONTE, kind source, que assina a volta para
#               vários receptores; 2026-11-06), e sends_to, quando há, aponta um membro do registro que é
#               receptor: role source ou hub, e NÃO porta (kind door). Medido no spike
#               (C_RECEPTOR_PELO_PAPEL_INCLUI_A_PORTA): olhar só o role deixava entrar a porta.
#
# PARENT (desde 2026-10-15, F3 do configurador A2A, SAC-124): a rede do hub nasce junto com a do
#             core, com os filhos do hub registrados AQUI com `parent: <hub>`. Por isso o parent
#             deixou de ser só "presente":
#             · aponta um membro do registro, e nunca o próprio membro;
#             · `role: consumer` (T2) ⇔ parent é um hub (role hub, NÃO porta). Consumer pendurado
#               no core, ou standalone/hub pendurado num hub, é tier contraditório: o trust-check
#               julga o consumer pelo parent, e o co-deliver recusa entregar a quem adota um hub;
#             · quem não é consumer tem como parent a FONTE (kind source);
#             · consumer com a2a.sends_to manda para o PRÓPRIO hub ou para a fonte (é o que o
#               trust-check autoriza: consumer→outro hub é BLOQUEADO lá).
#
# NOMES (desde 2026-11-27, D_ECOSYSTEM_NAMING_PATTERN_1127, SAC-567): o id é TERMO DE VARREDURA das guardas
#             (REGRA 36, 106 e 119 derivam termos dele), então renomear custa caro. O padrão novo é prefixo por
#             tipo (company-brain-<empresa>, second-brain-<pessoa>, onion-<peça>, onion-vps-<serviço>; a Persona
#             brain-onion-evolve é categoria à parte), e o membro ANTIGO não se renomeia: ganha `aliases:` e
#             `rename_trigger:`. Doutrina: docs/knowledge-base/concepts/ecosystem-naming.md.
#             · `aliases:` é lista de nomes na forma do id, escrita em FLUXO numa linha só (`aliases: [a, b]`),
#               porque os leitores das guardas são awk e só leem essa forma;
#             · um alias não colide com NENHUM id nem com outro alias (sem caixa: as guardas comparam em
#               minúsculas), não repete o próprio id e não é um prefixo nu do padrão;
#             · `aliases:` não vazio exige `rename_trigger:` (o evento nomeado em que o rename acontece), e
#               `rename_trigger:` sem alias é erro (o par vem junto);
#             · AVISO (não reprova): membro NOVO (id ausente no registro-base) fora dos prefixos do padrão.
#               Registro-base = --base <arquivo>, senão `git show origin/main:<caminho>` quando o caminho é o
#               canônico; sem base, o aviso não roda (teto: a bancada passa --base). SOFT porque o tipo da peça
#               não é campo do registro: projeto de cliente (kind adopter comum) não tem prefixo no padrão, e um
#               HARD acusaria todo adotante novo legítimo;
#             · o MAPA (`ecosystem-naming-map.md` ao lado do registro, core-only), quando existe, lista TODO
#               membro uma vez, com os mesmos aliases: membro fora do mapa, linha órfã ou alias divergente
#               reprova (é a catraca da projeção à mão).
#
# Uso       : bash .claude/validation/members-validate.sh [<path-do-members.yaml>] [--json] [--jwks <dir>] [--base <yaml>|none]
#               <path> : caminho PASSADO COMO ARGUMENTO; default = o members.yaml
#                        do próprio repo (resolvido por BASH_SOURCE, nunca embutido).
#               --json : saída JSON {valid, path, errors[]} para o comando consumir.
#               --jwks : diretório das públicas pinadas (default acima).
#
#               --base : registro-base para o aviso de membro novo ('none' desliga).
#
# Saída     : exit 0 = válido (avisos em linhas "   ⚠ aviso:") · 1 = inválido (erros listados) · 2 = uso incorreto
#             · 3 = python3+yaml ausente (degrada gracioso, não reprova)
#
# Determinístico, sem LLM. É a peça de validação do par
# /meta:federation-member (orquestra) ↔ este script (valida) — ajuste 6a:
# a validação vive aqui, NUNCA num agente.
# =============================================================================

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GIT_DIR neutralizado (mesmo cuidado do federation-console.sh): sob hook do git em
# worktree o GIT_DIR é ABSOLUTO e faria rev-parse devolver o subdir, não a raiz.
ROOT="$(env -u GIT_DIR -u GIT_WORK_TREE git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../.." && pwd))"

JSON=0
MEMBERS=""
JWKS=""
BASE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --jwks) [[ -n "${2:-}" ]] || { echo "uso: $0 [<path-do-members.yaml>] [--json] [--jwks <dir>]" >&2; exit 2; }
            JWKS="$2"; shift 2 ;;
    --base) [[ -n "${2:-}" ]] || { echo "uso: $0 [<path-do-members.yaml>] [--base <yaml>|none]" >&2; exit 2; }
            BASE="$2"; shift 2 ;;
    -*) echo "uso: $0 [<path-do-members.yaml>] [--json] [--jwks <dir>]" >&2; exit 2 ;;
    *) MEMBERS="$1"; shift ;;
  esac
done
[[ -z "$MEMBERS" ]] && MEMBERS="${ROOT}/docs/evolution/federation/members.yaml"
# JWKS: a raiz do repo do REGISTRO (não a deste script) quando o caminho tem a forma canônica, para
# que validar o registro de outra árvore confira as públicas daquela árvore.
if [[ -z "$JWKS" ]]; then
  _mabs="$(cd "$(dirname "$MEMBERS")" 2>/dev/null && pwd)/$(basename "$MEMBERS")"
  case "${_mabs}" in
    */docs/evolution/federation/members.yaml) JWKS="${_mabs%/docs/evolution/federation/members.yaml}/.claude/utils/federation-transport/jwks" ;;
    *) JWKS="${ROOT}/.claude/utils/federation-transport/jwks" ;;
  esac
fi

# REGISTRO-BASE do aviso de membro novo: explícito, ou a origin/main do repo do registro quando o caminho é o canônico.
BASE_FILE=""
if [[ "$BASE" == "none" ]]; then
  :
elif [[ -n "$BASE" ]]; then
  [[ -f "$BASE" ]] || { echo "uso: --base: arquivo não encontrado: $BASE" >&2; exit 2; }
  BASE_FILE="$BASE"
else
  _mabs2="$(cd "$(dirname "$MEMBERS")" 2>/dev/null && pwd)/$(basename "$MEMBERS")"
  case "${_mabs2}" in
    */docs/evolution/federation/members.yaml)
      _mroot="${_mabs2%/docs/evolution/federation/members.yaml}"
      _btmp="$(mktemp)"; trap 'rm -f "${_btmp}"' EXIT
      if env -u GIT_DIR -u GIT_WORK_TREE git -C "${_mroot}" show origin/main:docs/evolution/federation/members.yaml > "${_btmp}" 2>/dev/null; then
        BASE_FILE="${_btmp}"
      fi ;;
  esac
fi

if [[ ! -f "$MEMBERS" ]]; then
  echo "uso: $0 [<path-do-members.yaml>] [--json]  — arquivo não encontrado: $MEMBERS" >&2
  exit 2
fi

command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
  || { echo "members-validate: python3+yaml ausente (exit 3, gracioso)." >&2; exit 3; }

python3 - "$MEMBERS" "$JSON" "$JWKS" "$BASE_FILE" <<'PY'
import sys, json, re, os, subprocess, shutil

path, json_mode, jwks_dir, base_file = sys.argv[1], sys.argv[2] == "1", sys.argv[3], sys.argv[4]
errors = []
warnings = []

def err(msg):
    errors.append(msg)

def warn(msg):
    warnings.append(msg)

# UM LEITOR SÓ NA PRÁTICA (F3, achado do refutador): o trust-topology-check.sh lê o registro por awk, e o
# resto (este validador, o gate, o bridge, o motor de convite) por PyYAML. Os dois divergem em três formas,
# medidas, e a divergência caía no lado que AUTORIZA: chave repetida no mesmo mapa (o yaml fica com a
# última, o awk com a primeira: um `parent:` duplicado deixava o filho falar com o hub errado), comentário
# na linha do `- id:` (o awk lê o comentário como id) e id com espaço (`id: evil hub-real` casava como
# `hub-real` no awk). As três reprovam aqui, no gate, antes de qualquer leitor divergir.
class _DupKey(Exception):
    pass
try:
    import yaml
    class _NoDupLoader(yaml.SafeLoader):
        pass
    def _construct_mapping(loader, node, deep=False):
        seen = set()
        for k_node, _ in node.value:
            k = loader.construct_object(k_node, deep=deep)
            if k in seen:
                raise _DupKey(f"chave '{k}' repetida no mesmo mapa (linha {k_node.start_mark.line + 1}): o yaml fica com a última e o awk do trust-check com a primeira")
            seen.add(k)
        return yaml.SafeLoader.construct_mapping(loader, node, deep=deep)
    _NoDupLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _construct_mapping)
    with open(path) as fh:
        raw = fh.read()
    for n, ln in enumerate(raw.splitlines(), 1):
        if re.match(r"^\s*-\s*id:", ln) and "#" in ln:
            err(f"linha {n}: comentário na linha do '- id:' — o trust-check (awk) lê o comentário como id; mova-o para a linha de baixo")
    doc = yaml.load(raw, Loader=_NoDupLoader) or {}
except _DupKey as e:
    err(f"registro: {e}")
    doc = None
except Exception as e:
    err(f"YAML não parseável: {e}")
    doc = None

if isinstance(doc, dict):
    # --- cabeçalho do ledger -------------------------------------------------
    for key in ("version", "trust_policy_version"):
        if key not in doc:
            err(f"cabeçalho: chave '{key}' ausente")

    members = doc.get("members")
    if not isinstance(members, list):
        err("top-level 'members:' ausente ou não é lista")
        members = []

    # ⚠️ DUAS DIMENSÕES, DOIS VOCABULÁRIOS — e a "unificação" de 2026-09-24 foi REVERTIDA em 2026-10-07.
    #    O `role:` DESTE registro é o TIER na rede: source (T0) · hub (T1, pode ter sub-adotados) ·
    #    standalone (T3, adota o core direto) · consumer (T2, adota um hub; é o que o
    #    trust-topology-check.sh lê). O `role:` do CARIMBO (.claude/.onion-version) é a RELAÇÃO com o
    #    framework e o CORTE de maquinaria: adopted | hub | standalone (porta só com `kind: door`
    #    no carimbo; sem ele é o adotado standalone, desde 2026-10-13). Em 2026-09-24 pôr
    #    `adopted` aqui pareceu economizar um nome, e o custo foi medido depois: `adopted` passou a
    #    nomear o T3 E o T2, o co-deliver e o resolve-target tiveram de contornar a ambiguidade
    #    (2026-09-25), e um adotante leu a divergência registro×carimbo como furo (sinal de
    #    campo, 2026-10-07). O par dos dois campos é julgado pela REGRA 92 por COMPATIBILIDADE
    #    (hub→hub; standalone→standalone|adopted; consumer→adopted), não por igualdade — que valeria
    #    só para porta.
    #    Ninguém migra: a única entrada `adopted` virou `standalone` no mesmo commit.
    # `mini` e `plugins` entraram em 2026-10-09 (F1.5 das portas, SAC-90), e são PAPEL DE PORTA, não
    # tier de rede: o nó D_MATRIZ_DE_PORTAS_2026_10 fixa onion-mini como porta didática gerada por
    # allowlist e onion-plugins como o standalone empacotado. Na F0 este validador recusou os dois
    # (E_REGISTRO_RECUSA_PAPEL_MINI_E_PLUGINS), e a matriz ficou sem como ser escrita. Por serem papel
    # de porta, só valem com `kind: door` (regra abaixo): um adotante `role: mini` não tem sentido e
    # passaria calado. Este é o vocabulário do REGISTRO; desde a F2 (2026-10-10, SAC-91) o corte de
    # maquinaria também o conhece: `roles.yaml` tem os papéis plugins e mini, e `vendor-manifest.sh
    # --role plugins|mini|source` corta (plugins = standalone) ou inclui por allowlist (mini). Nenhum
    # leitor passa o `role:` do registro ao corte (materialize-door e resolve-role-bundle leem o
    # carimbo e o roles.yaml); o `--diff` do vendor-manifest só LÊ o registro para achar o clone.
    ROLES = {"source", "hub", "standalone", "consumer", "mini", "plugins"}
    DOOR_ONLY_ROLES = {"mini", "plugins"}
    # `port` entrou em 2026-09-16 com o registro do onion-codex. Ele NÃO é `distillation`:
    # destilação é reescrita curada da MESMA doutrina no MESMO substrato; porte é TRADUÇÃO para
    # OUTRO substrato (aqui, `.codex/` + `.agents/skills/` no lugar de `.claude/`). Chamar porte
    # de destilação economizaria uma linha e mentiria sobre o objeto — e é justamente por
    # vocabulário, não por lógica, que guarda de lista falha.
    KINDS = {"source", "adopter", "distillation", "door", "method", "port"}
    NONVENDOR = {"distillation", "method", "port"}       # onion_version: n/a (não vendoriza .claude/)
    VENDOR = {"adopter", "door"}                 # pin real obrigatório
    TRUST_LISTS = ("can_receive_from", "can_advise_to", "can_correct_to",
                   "diary_readable_by", "exposes_downstream")

    seen = {}
    for i, m in enumerate(members):
        tag = f"membro[{i}]"
        if not isinstance(m, dict):
            err(f"{tag}: entrada não é um mapa")
            continue

        mid = m.get("id")
        tag = f"membro '{mid}'" if mid else tag
        if not mid or not isinstance(mid, str):
            err(f"{tag}: 'id' ausente ou vazio")
        elif not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", mid):
            err(f"{tag}: 'id' fora de [A-Za-z0-9._-] (1º caractere letra ou dígito): o id vira argumento, nome de arquivo e rota /a2a/<id>, e o awk do trust-check o lê pela última palavra")
        else:
            if mid in seen:
                err(f"{tag}: 'id' duplicado (já em membro[{seen[mid]}])")
            seen[mid] = i

        if not m.get("name"):
            err(f"{tag}: 'name' ausente")

        role = m.get("role")
        if role not in ROLES:
            err(f"{tag}: 'role' inválido ou ausente ('{role}'); esperado {sorted(ROLES)}")

        kind = m.get("kind")
        if kind not in KINDS:
            err(f"{tag}: 'kind' inválido ou ausente ('{kind}'); esperado {sorted(KINDS)}")

        # A isenção de parent/onion_version/trust é da FONTE — e a fonte se reconhece pela
        # NATUREZA (kind==source), não só pelo tier. Isentar só por role:source abria escape-hatch:
        # um adopter marcado role:source evadia o pin VERIFICADO (o false-green de pin que este
        # validador existe p/ matar). Exigir role:source ⇔ kind:source fecha o buraco.
        if role in DOOR_ONLY_ROLES and kind != "door":
            err(f"{tag}: 'role:{role}' é papel de PORTA e exige 'kind: door' (veio kind='{kind}')")

        is_source_role = role == "source"
        is_source_kind = kind == "source"
        # A porta onion-core publica o papel `source` (matriz das portas, D_MATRIZ_DE_PORTAS_2026_10, 2026-10-09):
        # `role: source` com `kind: door` é a FACE PÚBLICA da fonte. Ela não ganha a isenção da fonte (o `continue`
        # abaixo exige os dois): segue para a validação plena de derivado, com parent e pin verificado.
        if is_source_role and kind == "door":
            pass
        elif is_source_role != is_source_kind:
            err(f"{tag}: 'role:source' e 'kind:source' têm de vir juntos (fonte≠derivação); veio role='{role}' kind='{kind}'")
        if is_source_role and is_source_kind:
            continue
        # membro derivado (ou role/kind mistos, já sinalizados acima): validação plena abaixo.

        if not m.get("parent"):
            err(f"{tag}: 'parent' ausente (obrigatório salvo role:source)")

        ver = m.get("onion_version")
        if ver in (None, ""):
            err(f"{tag}: 'onion_version' ausente (use 'n/a' só p/ distillation/method)")
        elif kind in VENDOR:
            # A exceção do `n/a` da porta mini saiu em 2026-10-10: o mini foi publicado pelo carimbo (F6) e tem
            # pin. Mantê-la deixaria o pin voltar a `n/a` sem nada reprovar (refutador de 2026-10-10).
            if False:
                pass
            elif str(ver) == "n/a":
                err(f"{tag}: kind '{kind}' vendoriza — 'onion_version' não pode ser 'n/a' (pin VERIFICADO obrigatório)")
            elif not re.fullmatch(r"[0-9a-f]{7,40}", str(ver)):
                err(f"{tag}: 'onion_version' não parece um commit curto ('{ver}')")
        elif kind in NONVENDOR and str(ver) != "n/a":
            err(f"{tag}: kind '{kind}' não vendoriza — 'onion_version' deve ser 'n/a' (veio '{ver}')")

        for f in ("adopted_at", "mode", "personality_summary", "personality_last_sync"):
            if not m.get(f):
                err(f"{tag}: '{f}' ausente")
        if not isinstance(m.get("specializations"), list):
            err(f"{tag}: 'specializations' ausente ou não é lista")

        trust = m.get("trust")
        if not isinstance(trust, dict):
            err(f"{tag}: bloco 'trust:' ausente ou mal-formado (obrigatório salvo role:source)")
        else:
            for tl in TRUST_LISTS:
                if tl not in trust:
                    err(f"{tag}: trust.'{tl}' ausente")
                elif not isinstance(trust[tl], list):
                    err(f"{tag}: trust.'{tl}' não é lista")

    # Invariante do ledger: fonte≠derivação → EXATAMENTE uma fonte (kind:source).
    n_sources = sum(1 for m in members if isinstance(m, dict) and m.get("kind") == "source")
    if n_sources != 1:
        err(f"registro: esperado EXATAMENTE 1 membro fonte (kind:source), encontrado {n_sources} (fonte≠derivação: uma só fonte)")
    # A porta pública da fonte (`role: source` + `kind: door`) é UMA: duas seriam um adotante disfarçado de porta
    # source, a forma que o refutador de 2026-10-10 construiu para herdar autoridade num leitor que lia só o role.
    n_source_doors = sum(1 for m in members if isinstance(m, dict) and m.get("role") == "source" and m.get("kind") == "door")
    if n_source_doors > 1:
        err(f"registro: no máximo 1 porta com role:source e kind:door (a face pública da fonte), encontradas {n_source_doors}")

    # LINHAGEM HISTÓRICA (2026-10-09, selo do maestro sobre dois membros no mesmo remoto):
    # `superseded_by: <id>` tira o membro do escopo do ops/registry-pins.sh. Por isso o campo é
    # cobrado aqui: um id que não existe (ou que aponta para si, ou para outro histórico) esconderia
    # uma divergência VIVA atrás de uma linhagem inventada.
    by_id = {m.get("id"): m for m in members if isinstance(m, dict)}
    for m in members:
        if not isinstance(m, dict) or m.get("superseded_by") in (None, ""):
            continue
        sup, mid = m.get("superseded_by"), m.get("id")
        if sup == mid:
            err(f"membro '{mid}': 'superseded_by' aponta para o próprio membro")
        elif sup not in by_id:
            err(f"membro '{mid}': 'superseded_by' aponta para '{sup}', que não está no registro")
        elif by_id[sup].get("superseded_by"):
            err(f"membro '{mid}': 'superseded_by' aponta para '{sup}', que também é linhagem histórica (cadeia não permitida)")
    # BLOCO a2a (F1 do configurador A2A, SAC-122) — ver o cabeçalho. Vale para todo membro que o declara.
    def rsa_bits(pem):
        """bits do módulo RSA da pública em `pem`; 'nao-rsa' | 'ilegivel' | 'sem-openssl'."""
        if not shutil.which("openssl"):
            return "sem-openssl"
        try:
            out = subprocess.run(["openssl", "pkey", "-pubin", "-in", pem, "-noout", "-text"],
                                 capture_output=True, text=True, timeout=20).stdout
        except Exception:
            return "ilegivel"
        if not out:
            return "ilegivel"
        if not re.search(r"^modulus:", out, re.I | re.M):
            return "nao-rsa"
        mm = re.search(r"\((\d+) bit", out)
        return int(mm.group(1)) if mm else "ilegivel"

    kid_owner = {}
    for m in members:
        if not isinstance(m, dict) or "a2a" not in m:
            continue
        mid = m.get("id"); tag = f"membro '{mid}'"
        a = m.get("a2a")
        if not isinstance(a, dict):
            err(f"{tag}: bloco 'a2a:' não é um mapa")
            continue
        keys = a.get("keys", [])
        if keys is None:
            keys = []
        if not isinstance(keys, list):
            err(f"{tag}: a2a.keys não é lista")
            keys = []
        seen_k = set()
        for k in keys:
            if isinstance(k, str) and k in seen_k:
                err(f"{tag}: kid '{k}' repetido em a2a.keys")
                continue
            if isinstance(k, str):
                seen_k.add(k)
            if not isinstance(k, str) or not re.fullmatch(r"[A-Za-z0-9._-]+", k) or k.startswith("."):
                err(f"{tag}: a2a.keys tem kid fora de [A-Za-z0-9._-] ('{k}'); o kid vira nome de arquivo no JWKS")
                continue
            if not (isinstance(mid, str) and re.fullmatch(re.escape(mid) + r"-[1-9][0-9]*", k)):
                err(f"{tag}: kid '{k}' fora da forma <id>-<N> ('{mid}-1', '{mid}-2'...), a que o a2a-keygen.sh gera")
            if k in kid_owner and kid_owner[k] != mid:
                err(f"{tag}: kid '{k}' já pertence a '{kid_owner[k]}' (o JWKS é um espaço de nomes só: mesma pública para dois donos)")
                continue
            kid_owner[k] = mid
            pem = os.path.join(jwks_dir, k + ".pem")
            if not os.path.isfile(pem):
                err(f"{tag}: kid '{k}' pinado em a2a.keys mas jwks/{k}.pem ausente (o gate vetaria unknown-kid)")
                continue
            bits = rsa_bits(pem)
            if bits == "sem-openssl":
                err(f"{tag}: openssl ausente, não sei conferir jwks/{k}.pem (fail-closed: não sei ≠ válido)")
            elif bits == "ilegivel":
                err(f"{tag}: jwks/{k}.pem não é pública legível")
            elif bits == "nao-rsa":
                err(f"{tag}: jwks/{k}.pem não é RSA (o gate só aceita RS256)")
            elif bits < 2048:
                err(f"{tag}: jwks/{k}.pem tem {bits} bits (mínimo 2048)")
        st = a.get("sends_to")
        if st is not None and not isinstance(st, str):
            err(f"{tag}: a2a.sends_to tem de ser o id (texto) de um receptor, veio {type(st).__name__}")
            st = None
        # a FONTE (kind source) assina a volta para VÁRIOS receptores (cada membro, inclusive standalone pela fila
        # local, D_GATE_STANDALONE_FILA_LOCAL_1106): ela não tem um receptor único, então dispensa sends_to
        if keys and not st and m.get("kind") != "source":
            err(f"{tag}: a2a.keys não vazio exige a2a.sends_to (o receptor dos sinais dele)")
        if st:
            rcv = by_id.get(st)
            if rcv is None:
                err(f"{tag}: a2a.sends_to aponta '{st}', que não está no registro")
            elif rcv.get("role") not in ("source", "hub") or rcv.get("kind") == "door":
                err(f"{tag}: a2a.sends_to aponta '{st}' (role '{rcv.get('role')}', kind '{rcv.get('kind')}'), que não é receptor: só role source ou hub, e nunca porta")
    # PARENT (F3 do configurador A2A) — ver o cabeçalho.
    def is_hub(x):
        return isinstance(x, dict) and x.get("role") == "hub" and x.get("kind") != "door"
    for m in members:
        if not isinstance(m, dict) or m.get("kind") == "source":
            continue
        mid, par, role = m.get("id"), m.get("parent"), m.get("role")
        if par in (None, ""):
            continue   # a ausência já é erro acima (obrigatório salvo a fonte)
        tag = f"membro '{mid}'"
        if not isinstance(par, str):
            err(f"{tag}: 'parent' tem de ser o id (texto) de um membro, veio {type(par).__name__}")
            continue
        if par == mid:
            err(f"{tag}: 'parent' aponta para o próprio membro")
            continue
        pm = by_id.get(par)
        if pm is None:
            err(f"{tag}: 'parent' aponta '{par}', que não está no registro")
            continue
        if role == "consumer":
            if not is_hub(pm):
                err(f"{tag}: role consumer (T2) exige parent hub; '{par}' tem role '{pm.get('role')}' e kind '{pm.get('kind')}' (consumer adota um hub, nunca o core nem uma porta)")
        elif pm.get("kind") != "source":
            err(f"{tag}: role '{role}' adota o core direto, e o parent tem de ser a fonte; '{par}' tem kind '{pm.get('kind')}' (só role consumer pendura num hub)")
        a = m.get("a2a")
        st = a.get("sends_to") if isinstance(a, dict) else None
        if role == "consumer" and isinstance(st, str) and st and st != par and (by_id.get(st) or {}).get("kind") != "source":
            err(f"{tag}: consumer manda sinais para o próprio hub ('{par}') ou para a fonte; a2a.sends_to aponta '{st}' (a topologia bloqueia consumer→outro hub)")
    # NOMES (D_ECOSYSTEM_NAMING_PATTERN_1127, SAC-567) — ver o cabeçalho.
    ID_RE = r"[A-Za-z0-9][A-Za-z0-9._-]*"
    BARE_PREFIXES = {"company-brain", "second-brain", "onion", "onion-vps", "brain"}
    # a forma da linha: os leitores awk das guardas só leem o alias em FLUXO numa linha
    for n, ln in enumerate(raw.splitlines(), 1):
        if re.match(r"^\s+aliases:", ln) and not re.match(r"^\s+aliases:\s*\[[^\]#]*\]\s*(#.*)?$", ln):
            err(f"linha {n}: 'aliases:' tem de vir em fluxo numa linha só (aliases: [a, b]) — os leitores awk das guardas (REGRA 36, 106) não leem a forma em bloco")
    owner = {}   # nome em minúsculas -> (dono, 'id'|'alias')
    for m in members:
        if isinstance(m, dict) and isinstance(m.get("id"), str):
            owner.setdefault(m["id"].lower(), (m["id"], "id"))
    for m in members:
        if not isinstance(m, dict):
            continue
        mid = m.get("id"); tag = f"membro '{mid}'"
        al = m.get("aliases")
        trig = m.get("rename_trigger")
        if al is None:
            al = []
        if not isinstance(al, list):
            err(f"{tag}: 'aliases' tem de ser lista"); al = []
        if al and (not isinstance(trig, str) or not trig.strip()):
            err(f"{tag}: 'aliases' exige 'rename_trigger' (o evento nomeado em que o rename acontece, ex.: «renomear na migração para a AWS»)")
        if not al and "rename_trigger" in m:
            err(f"{tag}: 'rename_trigger' sem 'aliases' — o par vem junto (alias registrado + gatilho nomeado)")
        for a in al:
            if not isinstance(a, str) or not re.fullmatch(ID_RE, a):
                err(f"{tag}: alias '{a}' fora da forma do id ([A-Za-z0-9._-], 1º caractere letra ou dígito)")
                continue
            if a.lower() in BARE_PREFIXES:
                err(f"{tag}: alias '{a}' é um prefixo nu do padrão (colide com o nome de vertical ou família do framework)")
                continue
            prev = owner.get(a.lower())
            if prev is not None:
                if prev[0] == mid and prev[1] == "id":
                    err(f"{tag}: alias '{a}' repete o próprio id")
                elif prev[1] == "id":
                    err(f"{tag}: alias '{a}' colide com o id do membro '{prev[0]}' (as guardas varrem ids e aliases como um espaço de nomes só)")
                else:
                    err(f"{tag}: alias '{a}' colide com um alias de '{prev[0]}'")
                continue
            owner[a.lower()] = (mid, "alias")

    # AVISO de membro NOVO fora do prefixo do tipo (SOFT, ver o cabeçalho)
    if base_file:
        try:
            bdoc = yaml.safe_load(open(base_file, encoding="utf-8")) or {}
            base_ids = {x.get("id") for x in (bdoc.get("members") or []) if isinstance(x, dict)}
        except Exception as e:
            base_ids = None
            warn(f"registro-base ilegível ({type(e).__name__}): o aviso de membro novo NÃO rodou")
        if base_ids is not None:
            for m in members:
                if not isinstance(m, dict) or not isinstance(m.get("id"), str) or m["id"] in base_ids:
                    continue
                nid = m["id"]
                if nid.startswith("onion-svc-"):
                    warn(f"membro NOVO '{nid}': serviço da VPS usa o prefixo onion-vps-<serviço> (D_ECOSYSTEM_NAMING_PATTERN_1127)")
                elif not (nid.startswith(("company-brain-", "second-brain-", "onion-")) or nid == "brain-onion-evolve"):
                    warn(f"membro NOVO '{nid}' fora dos prefixos do padrão (company-brain-, second-brain-, onion-, onion-vps-): se é peça do ecossistema, use o prefixo do tipo; se é projeto de adotante comum, o padrão não se aplica e o aviso pode ser ignorado")

    # MAPA (catraca da projeção à mão): todo membro uma vez, com os mesmos aliases
    map_path = os.path.join(os.path.dirname(os.path.abspath(path)), "ecosystem-naming-map.md")
    if os.path.isfile(map_path):
        rows = {}
        for n, ln in enumerate(open(map_path, encoding="utf-8").read().splitlines(), 1):
            mm = re.match(r"^\|\s*`([^`]+)`\s*\|(.*)$", ln)
            if not mm:
                continue
            cells = [c.strip() for c in mm.group(2).split("|")]
            # colunas: id atual | tipo | conforme | alias | gatilho de rename
            alias_cell = cells[2] if len(cells) > 2 else ""
            al_map = sorted(re.findall(r"`([^`]+)`", alias_cell))
            if mm.group(1) in rows:
                err(f"mapa {os.path.basename(map_path)} linha {n}: '{mm.group(1)}' aparece duas vezes")
            rows[mm.group(1)] = al_map
        reg = {m.get("id"): sorted(m.get("aliases") or []) for m in members if isinstance(m, dict) and isinstance(m.get("id"), str)}
        for i2 in sorted(set(reg) - set(rows)):
            err(f"mapa {os.path.basename(map_path)}: membro '{i2}' do registro não está no mapa (todo membro entra no mapa: id · tipo · conforme · alias · gatilho)")
        for i2 in sorted(set(rows) - set(reg)):
            err(f"mapa {os.path.basename(map_path)}: linha '{i2}' não é membro do registro")
        for i2 in sorted(set(rows) & set(reg)):
            if rows[i2] != [a for a in reg[i2] if isinstance(a, str)]:
                err(f"mapa {os.path.basename(map_path)}: aliases de '{i2}' divergem do registro (mapa {rows[i2]} × registro {reg[i2]})")
elif doc is not None:
    err("documento raiz não é um mapa (esperado: chaves version/trust_policy_version/members)")

valid = len(errors) == 0
if json_mode:
    print(json.dumps({"valid": valid, "path": path, "errors": errors, "warnings": warnings}, ensure_ascii=False))
else:
    if valid:
        print(f"✅ members.yaml válido: {path} ({len(doc.get('members', [])) if isinstance(doc, dict) else 0} membros)")
    else:
        print(f"❌ members.yaml inválido: {path}")
        for e in errors:
            print(f"   ∟ {e}")
    for w in warnings:
        print(f"   ⚠ aviso: {w}")

sys.exit(0 if valid else 1)
PY
