#!/usr/bin/env python3
"""Testes do kg_migrate.py: as guardas do perfil, a semântica do plan e os casos-limite do apply (inserção por texto,
invariância, gate, idempotência). Os casos do apply vieram da revisão do core sobre o rascunho do perfil (2026-10-20):
o mapa em bloco como último campo do nó (o end_mark que engoliu um '- id:' na migração de um adotante), o bloco | e >
no fim do nó, o comentário entre nós, o último nó sem quebra final, o nó em flow e o '- id:' na coluna 0."""
import os
os.environ.setdefault("KG_SSOT_LANG", "pt-BR")  # as asserções destes testes são da tradução pt-BR

import collections
import contextlib
import csv
import io
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

TOOLS = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import kg_gate  # noqa: E402
import kg_migrate  # noqa: E402
import kg_validate  # noqa: E402

HEAD = 'meta:\n  schema_version: "1"\n  id: t\nnodes:\n'
EDGES = "edges:\n  - from: C_A\n    to: Q_Z\n    edge_type: SUPPORTS\n"
QZ = '  - id: Q_Z\n    node_type: question\n    plane: DEV\n    status: open\n    impact: 1\n    confidence: 0.5\n    label: "Âncora."\n'

PROFILE = """profile_version: "1"
contract: kg-ssot-v4.12.0
note: "não reverificado na migração de teste"
rules:
  - id: irrecuperavel
    when: {id_in: [C_GONE]}
    then: {status: unverifiable}
  - id: codigo
    when: {trace_path_glob: "src/**"}
    then:
      provenance: {source: "{trace_path}", locator: "{trace}", method: {class: leitura, detail: "código-fonte"}, locality: repo}
  - id: drive
    when: {trace_matches: "^drive", match_case: false}
    then:
      provenance: {source: "{trace}", locator: "{trace}", method: {class: leitura, detail: "documento no Drive"}, locality: privado}
"""


def claim(nid, trace, extra=""):
    return (f"  - id: {nid}\n    node_type: claim\n    plane: DEV\n    status: confirmed\n    impact: 3\n"
            f"    confidence: 0.9\n    label: \"Afirmação {nid}.\"\n    trace: \"{trace}\"\n" + extra)


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmp.name)
        (self.root / "src").mkdir()
        (self.root / "src" / "a.ts").write_text("", encoding="utf-8")
        self.profile = self.root / "perfil.yaml"
        self.profile.write_text(PROFILE, encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def graph(self, text, name="g.kg.yaml"):
        p = self.root / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(text.encode("utf-8"))
        return p

    def run_cmd(self, *args):
        p = subprocess.run([sys.executable, "-I", str(TOOLS / "kg_migrate.py"), *map(str, args)],
                           capture_output=True, text=True)
        return p.returncode, p.stdout + p.stderr

    def apply(self, path):
        return self.run_cmd("apply", "--profile", self.profile, "--root", self.root, path)


class ProfileGuards(Base):
    def bad(self, text):
        self.profile.write_text(text, encoding="utf-8")
        with self.assertRaises(kg_migrate.Broken):
            kg_migrate.load_profile(self.profile)

    def test_perfil_valido_carrega(self):
        self.assertEqual(len(kg_migrate.load_profile(self.profile)["rules"]), 3)

    def test_exemplos_da_release_carregam(self):
        for ex in sorted((TOOLS.parent / "spec" / "migrate-examples").glob("*.profile.yaml")):
            self.assertTrue(kg_migrate.load_profile(ex)["rules"], ex)

    def test_id_de_regra_repetido(self):
        self.bad(PROFILE.replace("id: drive", "id: codigo"))

    def test_marcador_desconhecido(self):
        self.bad(PROFILE.replace("{trace_path}", "{caminho}"))

    def test_privado_antes_da_4_12(self):
        self.bad(PROFILE.replace("kg-ssot-v4.12.0", "kg-ssot-v4.9.1"))

    def test_verified_scope_so_por_lista_de_ids(self):
        self.bad(PROFILE.replace("then: {status: unverifiable}", "then: {status: unverifiable, verified_scope: nenhum}"))

    def test_no_em_dois_scopes(self):
        self.bad(PROFILE + "scopes:\n  - {id: a, id_in: [C_A], verified_scope: fato}\n  - {id: b, id_in: [C_A], verified_scope: nenhum}\n")

    def test_regex_invalida(self):
        self.bad(PROFILE.replace('"^drive"', '"("'))

    def test_when_so_com_match_case_e_recusado(self):
        """N11 da 3ª passada do core: {match_case: false} sozinho casaria todo nó."""
        self.bad(PROFILE.replace("when: {id_in: [C_GONE]}", "when: {match_case: false}"))
        self.bad(PROFILE.replace("when: {id_in: [C_GONE]}", "when: {id_in: [C_GONE], not: {match_case: false}}"))


class PlanSemantics(unittest.TestCase):
    def test_trace_parts(self):
        tp = kg_migrate.trace_parts
        self.assertEqual(tp("src/a.ts:12"), ("src/a.ts", "12"))
        self.assertEqual(tp("docs/x.md:§2 · outro"), ("docs/x.md", "§2"))
        self.assertEqual(tp("a.ts:1; b.ts:2"), ("a.ts", "1"))
        for t in ("drive:abc", "https://x.org/a", "conversa 2026-10-09", "", None):
            self.assertEqual(tp(t), (None, None), t)

    def test_trace_parts_corta_ancora_e_ponto_barra(self):
        """N12 da 3ª passada do core."""
        tp = kg_migrate.trace_parts
        self.assertEqual(tp("./src/a.ts:12"), ("src/a.ts", "12"))
        self.assertEqual(tp("docs/x.md#secao"), ("docs/x.md", None))
        self.assertEqual(tp("./docs/x.md#secao:3"), ("docs/x.md", "3"))
        self.assertEqual(tp("https://x.org/a#b"), (None, None))

    def test_glob(self):
        g = kg_migrate.glob_match
        self.assertTrue(g("src/a.ts", "src/**"))
        self.assertTrue(g("a.ts", "**/*.ts"))
        self.assertFalse(g("src/x/a.ts", "src/*.ts"))
        self.assertTrue(g("docs/m/x.md", ["src/**", "docs/**/*.md"]))

    def test_padrao_de_texto_nao_casa_citacao(self):
        """Um caso real de adotante: 'mecanismos' numa citação não é escopo, porque o escopo só sai de id_in."""
        schema = json.loads(kg_migrate.PROFILE_SCHEMA.read_text(encoding="utf-8"))
        self.assertNotIn("verified_scope", schema["$defs"]["then"]["properties"])


class Discovery(Base):
    def git(self, *args):
        subprocess.run(["git", "-C", str(self.root), *args], check=True, capture_output=True)

    def test_vendor_fica_de_fora_e_grafo_quebrado_vai_para_revisao(self):
        """N9 da 3ª passada do core: o plan sem lista usava os fixtures quebrados da suíte vendorizada e saía com rc 2."""
        self.graph(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES)
        (self.root / "vendor" / "kg-ssot").mkdir(parents=True)
        (self.root / "vendor" / "kg-ssot" / "bad.kg.yaml").write_text("nodes: [\n", encoding="utf-8")
        (self.root / "docs").mkdir()
        (self.root / "docs" / "quebrado.kg.yaml").write_text("a: 1\na: 2\n", encoding="utf-8")
        (self.root / "docs" / "outro.kg.yaml").write_text("x: [\n", encoding="utf-8")
        self.git("init", "-q")
        self.git("add", "-A")
        rc, out = self.run_cmd("plan", "--profile", self.profile, "--root", self.root, "--exclude", "docs/outro.kg.yaml")
        self.assertEqual(rc, 0, out)
        self.assertNotIn("vendor", out)
        rows = json.loads(self.run_cmd("plan", "--profile", self.profile, "--root", self.root, "--json")[1])["rows"]
        files = {r["file"] for r in rows}
        self.assertIn("g.kg.yaml", files)
        self.assertNotIn("vendor/kg-ssot/bad.kg.yaml", files)
        broken = [r for r in rows if r["file"] == "docs/quebrado.kg.yaml"]
        self.assertEqual(len(broken), 1)
        self.assertIn("não parseia", broken[0]["review"])
        rc, out = self.run_cmd("plan", "--profile", self.profile, "--root", self.root, self.root / "docs" / "quebrado.kg.yaml")
        self.assertEqual(rc, 2, out)  # o grafo dado à mão que não parseia segue sendo entrada quebrada

    def test_vendor_carimbado_fora_de_vendor_fica_de_fora(self):
        """Pedido do core (2026-10-22): a pasta com o carimbo .kg-ssot-version é o vendor, mesmo fora de vendor/."""
        self.graph(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES)
        self.graph("nodes: [\n", "lib/kg/spec/x/bad.kg.yaml")
        (self.root / "lib" / "kg" / ".kg-ssot-version").write_text("{}", encoding="utf-8")
        self.git("init", "-q")
        self.git("add", "-A")
        rows = json.loads(self.run_cmd("plan", "--profile", self.profile, "--root", self.root, "--json")[1])["rows"]
        self.assertEqual({r["file"] for r in rows}, {"g.kg.yaml"})
        self.assertEqual(kg_migrate.tracked_graphs(self.root, (), False)[-1], str(self.root / "lib/kg/spec/x/bad.kg.yaml"))

    def test_caminho_fora_da_raiz_nao_consulta_o_host(self):
        """N10 da 3ª passada do core: absoluto, ~ ou ../ não pode olhar o disco fora da raiz."""
        m = kg_migrate.Matcher(kg_migrate.load_profile(self.profile), self.root)
        g = kg_migrate.Graph("g.kg.yaml", kg_validate.parse_v1(HEAD + QZ)[1])
        outside = pathlib.Path(self.tmp.name).parent
        for t in (str(outside), "~" + "/x", "../", "src/../../etc"):
            n = {"id": "C_X", "trace": t}
            self.assertFalse(m.when({"trace_path_exists": True}, n, g), t)
            self.assertFalse(m.when({"trace_path_is_dir": True}, n, g), t)
        self.assertTrue(m.when({"trace_path_exists": True}, {"id": "C_X", "trace": "src/a.ts:1"}, g))
        back = "../" + pathlib.Path(self.tmp.name).name + "/src/a.ts"  # sai e volta: o caminho é léxico, e sair é sair
        self.assertFalse(m.when({"trace_path_exists": True}, {"id": "C_X", "trace": back}, g))
        self.assertTrue(m.when({"trace_path_is_dir": True}, {"id": "C_X", "trace": "./src"}, g))


class ApplyEdges(Base):
    def assert_migrated(self, text, ids):
        p = self.graph(text)
        rc, out = self.apply(p)
        self.assertEqual(rc, 0, out)
        new = p.read_text(encoding="utf-8")
        _, doc, code = kg_validate.parse_v1(new)
        self.assertIsNone(code, new)
        by = {n["id"]: n for n in doc["nodes"]}
        for i in ids:
            self.assertIn("provenance", by[i], new)
        self.assertEqual([n["id"] for n in doc["nodes"]], [n["id"] for n in kg_validate.parse_v1(text)[1]["nodes"]])
        rc2, out2 = self.apply(p)
        self.assertEqual((rc2, p.read_text(encoding="utf-8")), (0, new), out2)  # idempotente
        return new

    def test_mapa_em_bloco_como_ultimo_campo(self):
        extra = "    x_meta:\n      fase: 1\n      dono: time\n"
        self.assert_migrated(HEAD + claim("C_A", "src/a.ts:1", extra) + claim("C_B", "src/a.ts:2") + QZ + EDGES
                             .replace("C_A\n    to: Q_Z", "C_A\n    to: Q_Z") + "  - from: C_B\n    to: Q_Z\n    edge_type: SUPPORTS\n",
                             ["C_A", "C_B"])

    def test_bloco_literal_e_dobrado_no_fim_do_no(self):
        for style in ("|", ">"):
            extra = f"    narrative: {style}\n      linha um\n      linha dois\n"
            self.assert_migrated(HEAD + claim("C_A", "src/a.ts:1", extra) + QZ + EDGES, ["C_A"])

    def test_comentario_entre_nos_fica(self):
        new = self.assert_migrated(HEAD + claim("C_A", "src/a.ts:1") + "  # comentário entre nós\n" + QZ + EDGES, ["C_A"])
        self.assertIn("# comentário entre nós", new)

    def test_ultimo_no_sem_quebra_final(self):
        text = HEAD + QZ + "edges:\n  - from: C_A\n    to: Q_Z\n    edge_type: SUPPORTS\n"
        text = text.replace("edges:", claim("C_A", "src/a.ts:1").rstrip("\n") + "\nedges:")
        self.assert_migrated(text.rstrip("\n"), ["C_A"])

    def test_id_na_coluna_zero(self):
        text = ('meta:\n  schema_version: "1"\n  id: t\nnodes:\n- id: C_A\n  node_type: claim\n  plane: DEV\n'
                '  status: confirmed\n  impact: 3\n  confidence: 0.9\n  label: "A."\n  trace: "src/a.ts:1"\n'
                '- id: Q_Z\n  node_type: question\n  plane: DEV\n  status: open\n  impact: 1\n  confidence: 0.5\n'
                '  label: "Z."\nedges:\n- from: C_A\n  to: Q_Z\n  edge_type: SUPPORTS\n')
        new = self.assert_migrated(text, ["C_A"])
        self.assertIn("\n  provenance:\n    source:", new)

    def test_no_em_flow_nao_e_tocado(self):
        text = (HEAD + '  - {id: C_A, node_type: claim, plane: DEV, status: confirmed, impact: 3, confidence: 0.9, '
                'label: "A.", trace: "src/a.ts:1"}\n' + QZ + EDGES)
        p = self.graph(text)
        rc, out = self.apply(p)
        self.assertEqual(rc, 1, out)
        self.assertIn("flow", out)
        self.assertEqual(p.read_text(encoding="utf-8"), text)

    def test_rebaixar_troca_so_o_status(self):
        text = HEAD + claim("C_GONE", "script nunca versionado") + claim("C_A", "src/a.ts:1") + QZ + EDGES + \
            "  - from: C_GONE\n    to: Q_Z\n    edge_type: SUPPORTS\n"
        new = self.assert_migrated(text, ["C_A"])
        by = {n["id"]: n for n in kg_validate.parse_v1(new)[1]["nodes"]}
        self.assertEqual(by["C_GONE"]["status"], "unverifiable")
        self.assertNotIn("provenance", by["C_GONE"])

    def test_drive_minusculo_ganha_privado(self):
        new = self.assert_migrated(HEAD + claim("C_A", "Drive: planilha") + QZ + EDGES, ["C_A"])
        self.assertIn('locality: "privado"', new)

    def test_invariancia_recusa_edicao_que_mexe_em_outro_no(self):
        old = HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES
        broken = old.replace('label: "Âncora."', 'label: "Outra."')
        self.assertIsNotNone(kg_migrate.invariance_problem(old, broken, {}))
        self.assertIsNone(kg_migrate.invariance_problem(old, old, {}))


class ReviewFindings(Base):
    """Os achados da revisão adversarial do PR (2026-10-20), cada um com o caso que o prende."""

    def plan_rows(self, text, profile=None, name="g.kg.yaml"):
        if profile is not None:
            self.profile.write_text(profile, encoding="utf-8")
        p = self.graph(text, name)
        rc, out = self.run_cmd("plan", "--json", "--profile", self.profile, "--root", self.root, p)
        self.assertEqual(rc, 0, out)
        return {r["id"]: r for r in json.loads(out)["rows"]}

    def test_crlf_fica_crlf_e_o_diff_so_acrescenta(self):
        text = (HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES).replace("\n", "\r\n")
        p = self.graph(text)
        rc, out = self.apply(p)
        self.assertEqual(rc, 0, out)
        raw = p.read_bytes().decode("utf-8")
        self.assertEqual(raw.count("\n"), raw.count("\r\n"))
        self.assertIn("provenance:", raw)
        old, new = text.split("\r\n"), raw.split("\r\n")
        self.assertEqual([l for l in new if l in old], old)  # todas as linhas antigas, na ordem

    def test_quebras_misturadas_recusa_sem_gravar(self):
        text = HEAD + claim("C_A", "src/a.ts:1").replace("\n", "\r\n", 2) + QZ + EDGES
        p = self.graph(text)
        rc, out = self.apply(p)
        self.assertEqual(rc, 1, out)
        self.assertEqual(p.read_bytes().decode("utf-8"), text)

    def test_trace_patologico_nao_derruba_o_plan(self):
        (self.root / "loop").symlink_to(self.root / "loop")
        traces = ["loop/x.md", "src/" + "a" * 6000 + ".ts", "src/a\\0.ts"]
        text = HEAD + "".join(claim(f"C_{i}", t) for i, t in enumerate(traces)) + QZ + EDGES
        prof = PROFILE.replace("rules:\n", "rules:\n  - id: inexistente\n    when: {trace_path_exists: false}\n"
                                            "    then: {review: \"caminho que não existe\"}\n")
        rows = self.plan_rows(text, prof)  # o plan sai com rc 0, e o caminho que não se consulta conta como inexistente
        self.assertEqual({rows[f"C_{i}"]["rule"] for i in range(3)}, {"inexistente"})

    def test_testemunho_em_prod_vai_com_o_aviso_e_o_apply_aceita(self):
        prof = PROFILE.replace("class: leitura, detail: \"código-fonte\"", "class: testemunho, detail: \"relato\"")
        text = HEAD + claim("C_A", "src/a.ts:1").replace("plane: DEV", "plane: PROD") + QZ + EDGES
        rows = self.plan_rows(text, prof)
        self.assertEqual(rows["C_A"]["action"], "provenance")
        self.assertIn("integrity.testimony-in-prod", rows["C_A"]["review"])
        rc, out = self.apply(self.root / "g.kg.yaml")
        self.assertEqual(rc, 0, out)

    def test_aviso_nao_anunciado_recusa_o_arquivo(self):
        old = HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES
        g = kg_migrate.load_graphs([str(self.graph(old))], self.root)
        with mock.patch.object(kg_migrate, "coherence_lit", lambda n, p: []):
            prof = kg_migrate.load_profile(self.profile)
            prof["rules"][1]["then"]["provenance"]["method"]["class"] = "testemunho"
            text = old.replace("plane: DEV", "plane: PROD", 1)
            p = self.graph(text)
            graphs, files, _ = kg_migrate.load_graphs([str(p)], self.root)
            report = kg_migrate.apply(prof, graphs, self.root, files)
        self.assertFalse(report[0][1], report)
        self.assertIn("SHOULD", " ".join(report[0][2]))
        self.assertEqual(p.read_text(encoding="utf-8"), text)

    def test_proposta_com_placeholder_ou_caminho_de_maquina_vai_para_revisao(self):
        prof = PROFILE.replace('source: "{trace_path}"', 'source: "desconhecida"')
        rows = self.plan_rows(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES, prof)
        self.assertEqual(rows["C_A"]["action"], "review")
        self.assertIn("reprovaria", rows["C_A"]["review"])
        prof = PROFILE.replace('detail: "código-fonte"', 'detail: "lido em /srv/dados"')
        rows = self.plan_rows(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES, prof)
        self.assertEqual(rows["C_A"]["action"], "review")
        self.assertIn("caminho de máquina", rows["C_A"]["review"])

    def test_glob_nao_casa_caminho_que_sai_da_raiz(self):
        rows = self.plan_rows(HEAD + claim("C_A", "src/../../fora/x.ts") + claim("C_B", "docs/../src/a.ts") + QZ + EDGES)
        self.assertEqual(rows["C_A"]["action"], "review")
        self.assertEqual(rows["C_B"]["proposal"]["provenance"]["source"], "src/a.ts")

    def test_match_case_vale_dentro_de_any_of_e_not(self):
        prof = PROFILE.replace('when: {trace_matches: "^drive", match_case: false}',
                               'when: {match_case: false, any_of: [{trace_matches: "^DRIVE"}, {id_in: [C_NADA]}]}')
        rows = self.plan_rows(HEAD + claim("C_A", "drive: doc") + QZ + EDGES, prof)
        self.assertEqual(rows["C_A"]["rule"], "drive")

    def test_scope_diferente_ja_gravado_vai_para_revisao(self):
        prof = PROFILE + "scopes:\n  - {id: s, id_in: [C_A], verified_scope: fato}\n"
        extra = '    verified_at: "2026-10-01"\n    verified_scope: mecanismo\n'
        rows = self.plan_rows(HEAD + claim("C_A", "src/a.ts:1", extra) + QZ + EDGES, prof)
        self.assertTrue(any(r["action"] == "review" and "já tem verified_scope" in (r["review"] or "")
                            for r in json.loads(self.run_cmd("plan", "--json", "--profile", self.profile, "--root",
                                                             self.root, self.root / "g.kg.yaml")[1])["rows"]))

    def test_modo_do_arquivo_fica(self):
        p = self.graph(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES)
        os.chmod(p, 0o640)
        self.assertEqual(self.apply(p)[0], 0)
        self.assertEqual(p.stat().st_mode & 0o777, 0o640)


class PlanContract(Base):
    """Prende a semântica do plan que os mutantes da revisão derrubavam sem nenhum teste reprovar."""

    def rows(self, text, profile=PROFILE):
        self.profile.write_text(profile, encoding="utf-8")
        graphs, _, _ = kg_migrate.load_graphs([str(self.graph(text))], self.root)
        return {r[1]: r for r in kg_migrate.plan(kg_migrate.load_profile(self.profile), graphs, self.root)}

    def test_a_primeira_regra_que_casa_decide(self):
        prof = PROFILE.replace("rules:\n", "rules:\n  - id: primeiro\n    when: {trace_is_path: true}\n"
                                            "    then: {review: \"a primeira\"}\n")
        self.assertEqual(self.rows(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES, prof)["C_A"][2], "primeiro")

    def test_sem_regra_vai_para_revisao(self):
        r = self.rows(HEAD + claim("C_A", "conversa solta") + QZ + EDGES)["C_A"]
        self.assertEqual((r[3], r[5]), ("review", "nenhuma regra do perfil casou"))

    def test_applies_to_restringe(self):
        prof = PROFILE + "applies_to: {id_in: [C_B]}\n"
        r = self.rows(HEAD + claim("C_A", "src/a.ts:1") + claim("C_B", "src/a.ts:2") + QZ + EDGES, prof)
        self.assertNotIn("C_A", r)
        self.assertIn("C_B", r)

    def test_placeholder_conta_como_vazio_e_template_vazio_vai_para_revisao(self):
        prof = PROFILE.replace("rules:\n", "rules:\n  - id: vazio\n    when: {trace_empty: true}\n    then:\n"
                               "      provenance: {source: \"{verified_against}\", locator: x, method: {class: leitura, "
                               "detail: x}, locality: repo}\n") + 'trace_placeholders: ["nunca versionad[oa]"]\n'
        r = self.rows(HEAD + claim("C_A", "script nunca versionado") + QZ + EDGES, prof)["C_A"]
        self.assertEqual((r[2], r[3]), ("vazio", "review"))
        self.assertIn("vazio", r[5])

    def test_note_vai_no_fim_do_method(self):
        r = self.rows(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES)["C_A"]
        self.assertTrue(r[4]["provenance"]["method"].endswith("; não reverificado na migração de teste"))

    def test_universo_e_supports(self):
        text = (HEAD + claim("C_A", "", ) + claim("C_U", "x").replace("status: confirmed", "status: unverifiable").replace("plane: DEV", "plane: PROD")
                + claim("C_P", "src/a.ts:1", '    provenance: {source: s, locator: l, method: "leitura: x"}\n') + QZ
                + "edges:\n  - from: C_U\n    to: C_A\n    edge_type: SUPPORTS\n")
        prof = PROFILE.replace("rules:\n", "rules:\n  - id: suporte\n    when: {has_supports: true}\n"
                                            "    then: {review: s}\n")
        r = self.rows(text.replace('    trace: ""\n', ""), prof)
        self.assertNotIn("C_U", r)
        self.assertNotIn("C_P", r)
        self.assertNotEqual(r["C_A"][2], "suporte")  # SUPPORTS de um unverifiable não conta

    def test_trace_is_self(self):
        prof = PROFILE.replace("rules:\n", "rules:\n  - id: circular\n    when: {trace_is_self: true}\n"
                                            "    then: {review: c}\n")
        self.assertEqual(self.rows(HEAD + claim("C_A", "g.kg.yaml:3") + QZ + EDGES, prof)["C_A"][2], "circular")

    def test_scope_sem_verified_at_vai_para_revisao(self):
        prof = PROFILE + "scopes:\n  - {id: s, id_in: [C_A], verified_scope: fato}\n"
        self.profile.write_text(prof, encoding="utf-8")
        graphs, _, _ = kg_migrate.load_graphs([str(self.graph(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES))], self.root)
        rows = kg_migrate.plan(kg_migrate.load_profile(self.profile), graphs, self.root)
        self.assertIn(("C_A", "s", "review"), {(r[1], r[2], r[3]) for r in rows})

    def test_symlink_que_sai_da_raiz_conta_como_inexistente(self):
        fora = pathlib.Path(self.tmp.name).parent / (pathlib.Path(self.tmp.name).name + "-fora")
        fora.mkdir()
        self.addCleanup(fora.rmdir)
        (self.root / "link").symlink_to(fora)
        m = kg_migrate.Matcher(kg_migrate.load_profile(self.profile), self.root)
        g = kg_migrate.Graph("g.kg.yaml", kg_validate.parse_v1(HEAD + QZ)[1])
        self.assertFalse(m.when({"trace_path_is_dir": True}, {"id": "C_X", "trace": "link/"}, g))
        self.assertTrue(m.when({"trace_path_is_dir": True}, {"id": "C_X", "trace": "src/"}, g))

    def test_exclude_tira_o_grafo(self):
        self.graph(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES)
        self.graph(HEAD + claim("C_X", "src/a.ts:1") + QZ + EDGES, "fora.kg.yaml")
        subprocess.run(["git", "-C", str(self.root), "init", "-q"], check=True)
        subprocess.run(["git", "-C", str(self.root), "add", "-A"], check=True)
        out = self.run_cmd("plan", "--json", "--profile", self.profile, "--root", self.root, "--exclude", "./fora.kg.yaml")[1]
        ids = {r["id"] for r in json.loads(out)["rows"]}
        self.assertIn("C_A", ids)
        self.assertNotIn("C_X", ids)

    def test_fixtures_aninhadas_saem_por_padrao_como_no_gate(self):
        """Achado do adotante hub na 4.13.0: o plan pegava as fixtures que o gate não mede, e */fixtures/* não casava
        o caminho aninhado."""
        self.graph(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES)
        self.graph(HEAD + claim("C_F", "src/a.ts:1") + QZ + EDGES, "pkg/validation/fixtures/x/f.kg.yaml")
        self.graph(HEAD + claim("C_M", "src/a.ts:1") + QZ + EDGES, "docs/materials/m.kg.yaml")
        self.graph(HEAD + claim("C_O", "src/a.ts:1") + QZ + EDGES, "docs/a/b/o.kg.yaml")
        subprocess.run(["git", "-C", str(self.root), "init", "-q"], check=True)
        subprocess.run(["git", "-C", str(self.root), "add", "-A"], check=True)

        def ids(*extra):
            out = self.run_cmd("plan", "--json", "--profile", self.profile, "--root", self.root, *extra)[1]
            return {r["id"] for r in json.loads(out)["rows"]}
        self.assertEqual(ids() & {"C_A", "C_F", "C_M", "C_O"}, {"C_A", "C_O"})
        self.assertNotIn("C_O", ids("--exclude", "docs/*"))  # * atravessa /, como no kg_gate.py
        self.assertNotIn("C_O", ids("--exclude", "**/b/**"))
        self.assertNotIn("C_A", ids("--exclude", "**/g.kg.yaml"))  # o **/ do glob antigo casa zero pastas: segue valendo
        self.assertTrue({"C_F", "C_M"} <= ids("--no-default-excludes"))
        self.assertEqual(kg_migrate.DEFAULT_EXCLUDE[1:], list(kg_gate.DEFAULT_EXCLUDE))

    def test_rodar_sem_menos_b_nao_deixa_pycache_no_vendor(self):
        """Achado do adotante hub: python3 -I kg_migrate.py importava o kg_validate e gravava o .pyc no vendor."""
        dest = self.root / "vendor" / "kg-ssot"
        shutil.copytree(TOOLS.parent / "spec", dest / "spec")
        (dest / "tools").mkdir()
        for name in ("kg_migrate.py", "kg_validate.py", "kg_i18n.py"):  # o kg_i18n viaja com eles desde a 4.18.0
            shutil.copy(TOOLS / name, dest / "tools" / name)
        env = {k: v for k, v in os.environ.items() if k != "PYTHONDONTWRITEBYTECODE"}
        r = subprocess.run([sys.executable, "-I", str(dest / "tools" / "kg_migrate.py"), "--help"], capture_output=True,
                           env=env)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(list(dest.rglob("__pycache__")), [])

    def test_grafo_rastreado_nao_utf8_vai_para_revisao(self):
        self.graph(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES)
        (self.root / "latin.kg.yaml").write_bytes("meta: {id: \xe7}\n".encode("latin-1"))
        subprocess.run(["git", "-C", str(self.root), "init", "-q"], check=True)
        subprocess.run(["git", "-C", str(self.root), "add", "-A"], check=True)
        rc, out = self.run_cmd("plan", "--json", "--profile", self.profile, "--root", self.root)
        self.assertEqual(rc, 0, out)
        self.assertTrue(any(r["file"].endswith("latin.kg.yaml") for r in json.loads(out)["rows"]))


class ApplyGuards(Base):
    """O apply liga cada guarda: um edit_text sabotado nunca chega ao disco."""

    def run_apply(self, text, sabotage):
        p = self.graph(text)
        graphs, files, _ = kg_migrate.load_graphs([str(p)], self.root)
        real = kg_migrate.edit_text
        with mock.patch.object(kg_migrate, "edit_text", lambda t, e: sabotage(*real(t, e))):
            report = kg_migrate.apply(kg_migrate.load_profile(self.profile), graphs, self.root, files)
        return p, report

    def test_edicao_que_mexe_em_outro_no_e_recusada(self):
        text = HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES
        p, report = self.run_apply(text, lambda new, ref: (new.replace('"Âncora."', '"Outra."'), ref))
        self.assertFalse(report[0][1])
        self.assertEqual(p.read_text(encoding="utf-8"), text)

    def test_edicao_que_tira_linha_e_recusada(self):
        text = HEAD + claim("C_A", "src/a.ts:1", "    # nota\n") + QZ + EDGES
        p, report = self.run_apply(text, lambda new, ref: (new.replace("    # nota\n", ""), ref))
        self.assertFalse(report[0][1])
        self.assertIn("diff", " ".join(report[0][2]))

    def test_linha_acrescentada_em_outro_no_e_recusada(self):
        """O diff só acrescentou linhas, mas uma delas foi parar noutro nó: a comparação nó a nó pega."""
        text = HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES
        p, report = self.run_apply(text, lambda new, ref: (new.replace('label: "Âncora."\n', 'label: "Âncora."\n    x_extra: 1\n'), ref))
        self.assertFalse(report[0][1])
        self.assertIn("Q_Z", " ".join(report[0][2]))
        self.assertEqual(p.read_text(encoding="utf-8"), text)

    def test_codigo_must_novo_e_recusado(self):
        text = HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES
        with mock.patch.object(kg_migrate, "invariance_problem", lambda *a: None):
            p, report = self.run_apply(text, lambda new, ref: (new.replace("impact: 1", "impact: 9"), ref))
        self.assertFalse(report[0][1])
        self.assertIn("MUST", " ".join(report[0][2]))
        self.assertEqual(p.read_text(encoding="utf-8"), text)

    def test_status_de_varias_linhas_nao_e_rebaixado(self):
        text = (HEAD + claim("C_GONE", "x").replace("status: confirmed", "status: >-\n      confirmed") + QZ + EDGES
                + "  - from: C_GONE\n    to: Q_Z\n    edge_type: SUPPORTS\n")
        p = self.graph(text)
        rc, out = self.apply(p)
        self.assertEqual(rc, 1, out)
        self.assertIn("status fora da forma", out)

    def test_scope_igual_sai_como_same_no_plan(self):
        """Sugestão do adotante hub: o scope que já bate não conta como proposta."""
        self.profile.write_text(PROFILE + "scopes:\n  - {id: s, id_in: [C_A], verified_scope: fato}\n", encoding="utf-8")
        p = self.graph(HEAD + claim("C_A", "src/a.ts:1", '    verified_at: "2026-10-01"\n    verified_scope: fato\n'
                                    '    provenance: {source: s, locator: l, method: "leitura: x"}\n') + QZ + EDGES)
        rows = json.loads(self.run_cmd("plan", "--json", "--profile", self.profile, str(p))[1])["rows"]
        self.assertEqual([r["action"] for r in rows if r["id"] == "C_A"], ["same"])

    def test_scope_igual_ja_gravado_nao_regrava(self):
        self.profile.write_text(PROFILE + "scopes:\n  - {id: s, id_in: [C_A], verified_scope: fato}\n", encoding="utf-8")
        text = HEAD + claim("C_A", "src/a.ts:1", '    verified_at: "2026-10-01"\n    verified_scope: fato\n'
                            '    provenance: {source: s, locator: l, method: "leitura: x"}\n') + QZ + EDGES
        p = self.graph(text)
        rc, out = self.apply(p)
        self.assertEqual((rc, p.read_text(encoding="utf-8")), (0, text), out)


class English(Base):
    """A saída humana em inglês (a língua-fonte); a planilha TSV segue em português, porque é dado que o core lê."""

    def main_en(self, *args):
        import contextlib
        buf = io.StringIO()
        with mock.patch.dict(os.environ, {"KG_SSOT_LANG": "en"}), contextlib.redirect_stdout(buf):
            rc = kg_migrate.main([str(a) for a in args])
        return rc, buf.getvalue()

    def test_plan_apply_e_entrada_quebrada_em_ingles(self):
        p = self.graph(HEAD + claim("C_A", "src/a.ts:1") + QZ + EDGES)
        tsv = self.root / "plano.tsv"
        rc, out = self.main_en("plan", "--profile", self.profile, "--root", self.root, "--out", tsv, p)
        self.assertEqual(rc, 0, out)
        self.assertIn("node row(s) in the plan", out)
        self.assertIn("nothing was written (plan)", out)
        self.assertTrue(tsv.read_text(encoding="utf-8").startswith("arquivo\tid\tregra\tação\tproposta\trevisar\t"))
        rc, out = self.main_en("apply", "--profile", self.profile, "--root", self.root, p)
        self.assertEqual(rc, 0, out)
        self.assertIn("WRITTEN ", out)
        self.assertIn("· 1 file(s) touched; 0 refused", out)
        self.profile.write_text(PROFILE.replace("id: drive", "id: codigo"), encoding="utf-8")
        rc, out = self.main_en("plan", "--profile", self.profile, p)
        self.assertEqual(rc, 2, out)
        self.assertIn("BROKEN INPUT  repeated rule id in the profile: codigo", out)


class AdopterHub(unittest.TestCase):
    """A aceitação contra o corpus real anonimizado de um adotante hub (tools/fixtures/migrate/adopter-hub/README.md)."""
    FIX = TOOLS / "fixtures" / "migrate" / "adopter-hub"

    def setUp(self):
        import tarfile
        self.tmp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmp.name) / "corpus"
        self.root.mkdir()
        with tarfile.open(self.FIX / "corpus.tgz") as tar:
            for m in tar.getmembers():  # sem symlink nem caminho fora do destino
                self.assertTrue(m.isfile() or m.isdir(), m.name)
                self.assertNotIn("..", pathlib.PurePosixPath(m.name).parts, m.name)
            tar.extractall(self.root, filter="data")
        self.graphs = sorted(str(p) for p in (self.root / "docs" / "graphs").glob("*.kg.yaml"))
        with open(self.root / "esperado.csv", encoding="utf-8", newline="") as fh:
            self.expected = {(r["graph"], r["id_hash"]): r for r in csv.DictReader(fh)}

    def tearDown(self):
        self.tmp.cleanup()

    def cmd(self, *args):
        p = subprocess.run([sys.executable, "-I", str(TOOLS / "kg_migrate.py"), *args, "--profile",
                            str(self.FIX / "profile.yaml"), "--root", str(self.root), *self.graphs],
                           capture_output=True, text=True)
        return p.returncode, p.stdout + p.stderr

    def test_plan_bate_com_o_gabarito(self):
        rc, out = self.cmd("plan", "--json")
        self.assertEqual(rc, 0, out)
        got = {}
        for r in json.loads(out)["rows"]:
            if r["action"] == "provenance":
                prov = r["proposal"]["provenance"]
                got[(r["file"], r["id"])] = (prov["method"].split(":", 1)[0], prov.get("locality", ""), False)
            elif r["action"] == "unverifiable":
                got[(r["file"], r["id"])] = ("", "", True)
        self.assertEqual(len(self.expected), 1024)
        wrong = []
        for key, e in self.expected.items():
            g = got.get(key)
            if g is None or g[2] != (e["status_depois"] == "unverifiable") or (e["method_class"] and g[0] != e["method_class"]) \
                    or (e["locality"] and g[1] != e["locality"]):
                wrong.append((key, e, g))
        self.assertEqual(wrong, [])

    def test_apply_grava_tudo_e_e_idempotente(self):
        rc, out = self.cmd("apply")
        self.assertEqual(rc, 0, out)
        self.assertIn("0 recusados", out)
        must = kg_validate.make_validator(json.loads(kg_validate.CONTRACT_MUST.read_text(encoding="utf-8")))
        left = [(g, c) for g in self.graphs for c in kg_validate.codes(pathlib.Path(g).read_text(encoding="utf-8"), must)
                if "provenance" in c]
        self.assertEqual(left, [])
        before = {g: pathlib.Path(g).read_bytes() for g in self.graphs}
        rc, out = self.cmd("apply")
        self.assertEqual(rc, 0, out)
        self.assertEqual({g: pathlib.Path(g).read_bytes() for g in self.graphs}, before)


class PlanJsonBroken(unittest.TestCase):
    """4.18.0, pedido do core: no plan --json, a entrada quebrada sai em JSON (rc 2), distinta do erro de uso do argparse."""

    def run_main(self, argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            try:
                rc = kg_migrate.main(argv)
            except SystemExit as exc:
                rc = exc.code
        return rc, out.getvalue(), err.getvalue()

    def test_entrada_quebrada_em_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            rc, out, _err = self.run_main(["plan", "--json", "--profile", str(pathlib.Path(tmp) / "nao-existe.yaml")])
        self.assertEqual(rc, 2)
        doc = json.loads(out)
        self.assertEqual(doc["reason"], "broken_input")
        self.assertTrue(doc["error"])

    def test_out_que_nao_se_grava_e_entrada_quebrada(self):
        """Achado do Elenxo (4.18.0): o --out num diretório que não existe era traceback com rc 1."""
        profile = TOOLS.parent / "spec/migrate-examples/company-brain.profile.yaml"
        graph = next((TOOLS.parent / "spec/conformance/fixtures/latest/form/minimal").glob("valid-*.kg.yaml"))
        with tempfile.TemporaryDirectory() as tmp:
            out = str(pathlib.Path(tmp) / "nao-existe" / "x.tsv")
            rc, stdout, _err = self.run_main(["plan", "--json", "--profile", str(profile), "--out", out, str(graph)])
            self.assertEqual((rc, json.loads(stdout)["reason"]), (2, "broken_input"))
            rc, stdout, _err = self.run_main(["plan", "--profile", str(profile), "--out", out, str(graph)])
            self.assertEqual(rc, 2)
            self.assertIn("nao-existe", stdout)

    def test_erro_de_uso_nao_escreve_no_stdout(self):
        rc, out, err = self.run_main(["plan", "--json"])  # falta o --profile
        self.assertEqual((rc, out), (2, ""))
        self.assertIn("--profile", err)




KEYS = """# comentário do topo
meta:
  schema_version: "1"
  id: chaves
  title: "Título, que o v4.11 conhece"
  revisited: "2026-01-01"  # comentário na linha da chave
kind: grafo
"version": "2"
nodes:
  - id: Q_A
    node_type: question
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: "A pergunta."
    resolution: "respondida"
    x_resolution: "já existe"
    severity: alta
  - {id: Q_B, node_type: question, plane: DEV, status: open, impact: 3, confidence: 0.5, label: "B.", nota: "flow"}
edges:
  - from: Q_A
    to: Q_B
    edge_type: TRACES_TO
    provenance: "da aresta"
    confidence: 0.4
"""


class Keys(unittest.TestCase):
    """kg_migrate.py keys (4.19.0): a chave fora do contrato vira x_<chave>, pelo texto, com invariância."""

    def run_main(self, argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            try:
                rc = kg_migrate.main(argv)
            except SystemExit as exc:
                rc = exc.code
        return rc, out.getvalue(), err.getvalue()

    def write(self, tmp, text=KEYS, name="g.kg.yaml", newline="\n"):
        p = pathlib.Path(tmp) / name
        p.write_bytes(text.replace("\n", newline).encode("utf-8"))
        return p

    def test_plano_por_escopo(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = self.write(tmp)
            rc, out, _ = self.run_main(["keys", "--json", "--root", tmp, str(p)])
        rows = {(r["place"], r["key"]): (r["action"], r["new_key"]) for r in json.loads(out)["rows"]}
        self.assertEqual(rc, 0)
        self.assertEqual(rows[("meta", "revisited")], ("rename", "x_revisited"))
        self.assertEqual(rows[("topo", "kind")], ("rename", "x_kind"))
        self.assertEqual(rows[("topo", "version")], ("rename", "x_version"))  # chave entre aspas
        self.assertEqual(rows[("nó Q_A", "resolution")][0], "review")  # x_resolution já existe
        self.assertEqual(rows[("nó Q_A", "severity")][0], "review")  # viraria o perfil x_severity
        self.assertEqual(rows[("nó Q_B", "nota")], ("rename", "x_nota"))  # mapa em flow
        self.assertEqual(rows[("edges #1", "provenance")], ("rename", "x_provenance"))
        self.assertEqual(rows[("edges #1", "confidence")][0], "review")  # x_confidence é perfil da aresta
        self.assertNotIn(("meta", "title"), rows)  # o v4.11 conhece title

    def test_apply_mantem_comentario_e_crlf_e_e_idempotente(self):
        with tempfile.TemporaryDirectory() as tmp:
            text = KEYS.replace("    confidence: 0.4\n", "")  # sem a renomeação que cairia no perfil da aresta
            p = self.write(tmp, text, newline="\r\n")
            rc, out, _ = self.run_main(["keys", "--apply", "--root", tmp, str(p)])
            self.assertEqual(rc, 0, out)
            new = p.read_bytes().decode("utf-8")
            self.assertIn("\r\n", new)
            self.assertEqual(new.count("\n"), new.count("\r\n"))
            self.assertIn("  x_revisited: \"2026-01-01\"  # comentário na linha da chave", new)
            self.assertIn('"x_version": "2"', new)
            self.assertIn("# comentário do topo", new)
            self.assertIn("    resolution: \"respondida\"", new)  # a que vai para quem revisa fica como estava
            rc, out, _ = self.run_main(["keys", "--apply", "--root", tmp, str(p)])
            self.assertEqual(p.read_bytes().decode("utf-8"), new)
            codes = kg_validate.codes(new.replace("\r\n", "\n"), kg_validate.make_validator(
                json.loads(kg_validate.CONTRACT_MUST.read_text(encoding="utf-8"))))
            self.assertEqual([c for c in codes if c.startswith("form.unknown-key")],
                             ["form.unknown-key.node.resolution", "form.unknown-key.node.severity"])

    def test_recusa_o_que_ganharia_aviso_should(self):
        """A chave x_ livre não é julgada, mas uma renomeação que criasse aviso SHOULD seria recusada: medido com um
        nome de chave que não é slug depois do x_ (o nome original com ponto, escrito entre aspas, vai para quem revisa)."""
        with tempfile.TemporaryDirectory() as tmp:
            text = KEYS.replace('kind: grafo\n', 'kind: grafo\n"a.b": 1\n')
            p = self.write(tmp, text)
            rc, out, _ = self.run_main(["keys", "--json", "--root", tmp, str(p)])
            row, = [r for r in json.loads(out)["rows"] if r["key"] == "a.b"]
            self.assertEqual(row["action"], "review")

    def test_quebras_misturadas_e_entrada_quebrada(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = self.write(tmp, KEYS.replace("kind: grafo\n", "kind: grafo\r\n"))
            rc, out, _ = self.run_main(["keys", "--apply", "--root", tmp, str(p)])
            self.assertEqual(rc, 1)
            rc, out, _ = self.run_main(["keys", "--json", "--root", tmp, str(pathlib.Path(tmp) / "nao.kg.yaml")])
            self.assertEqual((rc, json.loads(out)["reason"]), (2, "broken_input"))

    def test_chaves_conhecidas_vem_do_schema(self):
        known = kg_migrate.known_keys(json.loads(kg_validate.CONTRACT_MUST.read_text(encoding="utf-8")))
        self.assertIn("title", known["meta"])
        self.assertIn("trigger", known["edge"])
        self.assertNotIn("provenance", known["edge"])


NEST_GRAPH = """meta:
  schema_version: "1"
  id: nest
nodes:
  - id: A_TASK
    node_type: artifact
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    label: "Tarefa espelhada."
    provenance:
      source: "https://tasks.example.org/t/abc123"
      locator: "a tarefa"
      method: "leitura: o quadro"
      locality: web
    # o estado no quadro
    x_board_status: backlog
    verified_at: "2026-10-19"
    verified_against: https://tasks.example.org/t/abc123
  - id: R_NORM
    node_type: rule
    layer: domain
    plane: DEV
    status: open
    impact: 4
    confidence: 0.8
    label: "Norma de exemplo."
    x_issuer: CMN
    x_in_force: vigente
    x_questions:
      - '1'
      - '6'
    x_verdict: parcial
  - id: R_FUTURE
    node_type: rule
    layer: domain
    plane: DEV
    status: open
    impact: 4
    confidence: 0.8
    label: "Norma futura."
    x_issuer: BCB
    x_in_force: futura (2027)
edges:
  - from: A_TASK
    to: R_NORM
    edge_type: SUPPORTS
  - from: R_FUTURE
    to: R_NORM
    edge_type: TRACES_TO
"""

NEST_MAP = """nest_version: "1"
nest:
  - into: x_mirror
    when: x_board_status
    fields:
      system: {const: board}
      state: {move: x_board_status}
      ref: {copy: verified_against, match: "/t/([a-z0-9]+)$"}
      url: {copy: verified_against}
      synced_at: {copy: verified_at}
  - into: x_doc_cycle
    when: x_issuer
    raw: true
    fields:
      issuer: {move: x_issuer}
      state: {move: x_in_force, values: {vigente: in_force}}
  - into: x_questionnaire
    when: x_questions
    raw: true
    fields:
      name: {const: Q}
      questions: {move: x_questions}
      verdict: {move: x_verdict, values: {sim: meets, parcial: partial}}
"""


class Nest(unittest.TestCase):
    """kg_migrate.py nest (4.21.0): as chaves x_ próprias viram um perfil canônico, pelo texto, com invariância."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.dir = pathlib.Path(self.tmp.name)
        self.map = self.dir / "map.yaml"
        self.map.write_text(NEST_MAP, encoding="utf-8")
        from unittest import mock
        env = mock.patch.dict(os.environ, {"KG_SSOT_LANG": "en"})  # as frases conferidas são as da língua-fonte
        env.start()
        self.addCleanup(env.stop)

    def write(self, text=NEST_GRAPH, newline="\n"):
        p = self.dir / "g.kg.yaml"
        p.write_bytes(text.replace("\n", newline).encode("utf-8"))
        return p

    def run_main(self, *argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            try:
                rc = kg_migrate.main([str(a) for a in argv])
            except SystemExit as exc:
                rc = exc.code
        return rc, out.getvalue(), err.getvalue()

    def plan(self, *extra):
        rc, out, err = self.run_main("nest", "--map", self.map, "--root", self.dir, "--json", *extra, self.write())
        return rc, json.loads(out) if out.strip() else None, err

    def test_plano_monta_o_perfil_e_manda_o_valor_sem_codigo_para_revisao(self):
        rc, res, _ = self.plan()
        self.assertEqual(rc, 0)
        rows = {(r["id"], r["into"]): r for r in res["rows"]}
        self.assertEqual(rows[("A_TASK", "x_mirror")]["profile"],
                         {"system": "board", "state": "backlog", "ref": "abc123",
                          "url": "https://tasks.example.org/t/abc123", "synced_at": "2026-10-19"})
        self.assertEqual(rows[("A_TASK", "x_mirror")]["moved"], ["x_board_status"])
        # o valor exato da tabela não tem texto além do código: sem x_raw (pedido do brain)
        self.assertEqual(rows[("R_NORM", "x_doc_cycle")]["profile"], {"issuer": "CMN", "state": "in_force"})
        self.assertEqual(rows[("R_NORM", "x_questionnaire")]["profile"],
                         {"name": "Q", "questions": ["1", "6"], "verdict": "partial"})
        future = rows[("R_FUTURE", "x_doc_cycle")]
        self.assertEqual((future["action"], future["profile"]), ("review", None))
        self.assertIn("futura (2027)", future["review"])
        self.assertIsNone(res["applied"])
        self.assertEqual((self.dir / "g.kg.yaml").read_text(encoding="utf-8"), NEST_GRAPH)  # o plano não grava

    def test_apply_grava_com_invariancia_e_e_idempotente(self):
        rc, res, _ = self.plan("--apply")
        self.assertEqual(rc, 0, res)
        self.assertEqual(res["applied"], [{"file": "g.kg.yaml", "written": True, "reasons": []}])
        text = (self.dir / "g.kg.yaml").read_text(encoding="utf-8")
        self.assertIn("    # o estado no quadro\n    x_mirror:\n", text)  # o comentário fica
        self.assertNotIn("x_board_status", text)
        self.assertIn("    x_in_force: futura (2027)\n", text)  # o nó em revisão não é tocado
        doc = kg_validate.parse_v1(text)[1]
        self.assertEqual(doc["nodes"][1]["x_questionnaire"]["questions"], ["1", "6"])
        self.assertNotIn("x_questions", doc["nodes"][1])
        rc, out, _ = self.run_main("nest", "--map", self.map, "--root", self.dir, "--apply", self.dir / "g.kg.yaml")
        self.assertEqual(rc, 0)
        self.assertIn("· 0 node profile(s) to build, 1 for the reviewer", out)
        self.assertEqual((self.dir / "g.kg.yaml").read_text(encoding="utf-8"), text)

    def test_prefixo_guarda_o_texto_e_o_mais_longo_que_comeca_vence(self):
        self.map.write_text(NEST_MAP.replace("values: {vigente: in_force}",
                                             'values: {vigente: in_force}, prefixes: {"vigente (": in_force, futura: enacted}'),
                            encoding="utf-8")
        both = "vigente (BCB 540 desde 05/01/2026); obrigatoriedade futura (jul/2027)"
        self.write(NEST_GRAPH.replace("x_in_force: futura (2027)", "x_in_force: " + both))
        rc, out, _ = self.run_main("nest", "--map", self.map, "--root", self.dir, "--json", self.dir / "g.kg.yaml")
        rows = {(r["id"], r["into"]): r for r in json.loads(out)["rows"]}
        self.assertEqual(rows[("R_FUTURE", "x_doc_cycle")]["profile"],
                         {"issuer": "BCB", "state": "in_force", "x_raw": {"x_in_force": both}})
        self.write()
        rc, out, _ = self.run_main("nest", "--map", self.map, "--root", self.dir, "--json", self.dir / "g.kg.yaml")
        rows = {(r["id"], r["into"]): r for r in json.loads(out)["rows"]}
        self.assertEqual(rows[("R_FUTURE", "x_doc_cycle")]["profile"],
                         {"issuer": "BCB", "state": "enacted", "x_raw": {"x_in_force": "futura (2027)"}})

    def test_crlf_fica_crlf(self):
        p = self.write(newline="\r\n")
        rc, _out, _ = self.run_main("nest", "--map", self.map, "--root", self.dir, "--apply", p)
        self.assertEqual(rc, 0)
        raw = p.read_bytes()
        self.assertIn(b"x_mirror:\r\n", raw)
        self.assertEqual(raw.count(b"\n"), raw.count(b"\r\n"))

    def test_revisao_por_fonte_ausente_perfil_existente_e_data_invalida(self):
        g = NEST_GRAPH.replace('    verified_at: "2026-10-19"\n', "")
        g = g.replace("    x_issuer: CMN\n", "    x_issuer: CMN\n    x_doc_cycle: {issuer: CMN, state: in_force}\n")
        g = g.replace("    x_issuer: BCB\n    x_in_force: futura (2027)\n", "    x_issuer: BCB\n    x_in_force: vigente\n")
        self.write(g)
        rc, out, _ = self.run_main("nest", "--map", self.map, "--root", self.dir, "--json", self.dir / "g.kg.yaml")
        rows = {(r["id"], r["into"]): r for r in json.loads(out)["rows"]}
        self.assertIn("verified_at is missing", rows[("A_TASK", "x_mirror")]["review"])
        self.assertIn("already has x_doc_cycle", rows[("R_NORM", "x_doc_cycle")]["review"])
        self.assertEqual(rows[("R_FUTURE", "x_doc_cycle")]["action"], "nest")
        self.map.write_text(NEST_MAP.replace("synced_at: {copy: verified_at}", "synced_at: {const: ontem}"), encoding="utf-8")
        rc, res, _ = self.plan()
        bad = [r for r in res["rows"] if r["into"] == "x_mirror"][0]
        self.assertIn("synced_at", bad["review"])

    def test_no_em_estilo_de_fluxo_vai_para_revisao_e_o_resto_e_gravado(self):
        g = NEST_GRAPH.replace("""  - id: R_FUTURE
    node_type: rule
    layer: domain
    plane: DEV
    status: open
    impact: 4
    confidence: 0.8
    label: "Norma futura."
    x_issuer: BCB
    x_in_force: futura (2027)
""", """  - {id: R_FUTURE, node_type: rule, layer: domain, plane: DEV, status: open, impact: 4, confidence: 0.8,
     label: "Norma futura.", x_issuer: BCB, x_in_force: vigente}
""")
        p = self.write(g)
        rc, out, _ = self.run_main("nest", "--map", self.map, "--root", self.dir, "--apply", p)
        self.assertEqual(rc, 0, out)
        self.assertIn("R_FUTURE  → x_doc_cycle  (node 3 is in flow style: edit it by hand)", out)
        text = p.read_text(encoding="utf-8")
        self.assertIn("x_in_force: vigente}", text)
        self.assertIn("    x_mirror:\n", text)

    def test_mapa_quebrado_e_entrada_quebrada(self):
        bad = {
            "duas regras": NEST_MAP.replace("into: x_questionnaire", "into: x_doc_cycle"),
            "campo de fora": NEST_MAP.replace("system: {const: board}", "system: {const: board}\n      owner: {const: x}"),
            "regex sem grupo": NEST_MAP.replace('match: "/t/([a-z0-9]+)$"', 'match: "/t/[a-z0-9]+$"'),
            "chave movida duas vezes": NEST_MAP.replace("verdict: {move: x_verdict", "verdict: {move: x_questions"),
            "fora do schema": NEST_MAP.replace("move: x_issuer", "move: issuer"),
        }
        for name, text in bad.items():
            self.map.write_text(text, encoding="utf-8")
            rc, out, _ = self.run_main("nest", "--map", self.map, "--root", self.dir, "--json", self.write())
            self.assertEqual(rc, 2, name)
            self.assertEqual(json.loads(out)["reason"], "broken_input", name)

    # --- achados do Elenxo de 2026-10-23 ---------------------------------------------------------------------------

    def run_map(self, map_text, graph_text, *extra):
        self.map.write_text(map_text, encoding="utf-8")
        p = self.write(graph_text)
        rc, out, err = self.run_main("nest", "--map", self.map, "--root", self.dir, "--json", *extra, p)
        return rc, (json.loads(out) if out.strip() else None), p.read_text(encoding="utf-8"), err

    def rows(self, res):
        return {(r["id"], r["into"]): r for r in res["rows"]}

    def test_mapa_quebrado_pelo_que_o_schema_nao_ve(self):
        bad = {
            "regex invalida": NEST_MAP.replace('match: "/t/([a-z0-9]+)$"', 'match: "/t/(["'),
            "regex so do python": NEST_MAP.replace('match: "/t/([a-z0-9]+)$"', 'match: "/t/(?P<id>[a-z0-9]+)$"'),
            "x_raw com raw": NEST_MAP.replace("issuer: {move: x_issuer}", "issuer: {move: x_issuer}\n      x_raw: {const: x}"),
            "move com tabela sem raw": NEST_MAP.replace("    when: x_issuer\n    raw: true\n", "    when: x_issuer\n")
                                       .replace("values: {vigente: in_force}", 'values: {vigente: in_force}, prefixes: {vig: in_force}'),
            "move com regex sem raw": NEST_MAP.replace("    when: x_issuer\n    raw: true\n", "    when: x_issuer\n")
                                      .replace("issuer: {move: x_issuer}", 'issuer: {move: x_issuer, match: "^(C.*)$"}'),
            "movida e copiada": NEST_MAP.replace("synced_at: {copy: verified_at}", "synced_at: {copy: verified_at}\n      x_s: {copy: x_board_status}"),
            "prefixo vazio": NEST_MAP.replace("values: {vigente: in_force}", 'values: {vigente: in_force}, prefixes: {"": in_force}'),
        }
        for name, text in bad.items():
            rc, res, _t, _e = self.run_map(text, NEST_GRAPH)
            self.assertEqual((rc, res["reason"]), (2, "broken_input"), name)

    def test_raiz_do_mapa_em_ingles(self):
        self.map.write_text('nest_version: "1"\n', encoding="utf-8")
        rc, out, err = self.run_main("nest", "--map", self.map, "--root", self.dir, self.write())
        self.assertEqual(rc, 2)
        self.assertIn("at (root):", out + err)

    def test_layouts_que_a_edicao_sabe_fazer(self):
        """A chave movida como primeira do item, a lista de mapas e de listas, a coleção vazia e o arquivo sem quebra
        final: o plano diz NEST, o --apply grava, e a releitura é o plano."""
        m = NEST_MAP.replace("verdict: {move: x_verdict, values: {sim: meets, parcial: partial}}",
                             "verdict: {move: x_verdict, values: {sim: meets, parcial: partial}}\n      x_extra: {move: x_e}")
        g = NEST_GRAPH.replace("  - id: R_NORM\n", "  - x_issuer: CMN\n    id: R_NORM\n", 1).replace("    x_issuer: CMN\n", "", 1)
        g = g.replace("    x_verdict: parcial\n", "    x_verdict: parcial\n    x_e:\n      - {k: 1, l: [2, []]}\n      - []\n      - - a\n        - {}\n")
        rc, res, text, _ = self.run_map(m, g.rstrip("\n"), "--apply")
        self.assertEqual(rc, 0, res)
        self.assertEqual(res["applied"], [{"file": "g.kg.yaml", "written": True, "reasons": []}])
        doc = kg_validate.parse_v1(text)[1]
        norm = next(n for n in doc["nodes"] if n["id"] == "R_NORM")
        self.assertEqual(norm["x_doc_cycle"], {"issuer": "CMN", "state": "in_force"})
        self.assertEqual(norm["x_questionnaire"]["x_extra"], [{"k": 1, "l": [2, []]}, [], ["a", {}]])
        self.assertTrue(text.endswith("\n"))
        self.assertIn("  - x_doc_cycle:\n      issuer: \"CMN\"\n", text)

    def test_alias_e_ancora_vao_para_revisao_no_plano(self):
        g = NEST_GRAPH.replace('label: "Tarefa espelhada."', 'label: &iss "CMN"').replace("    x_issuer: CMN\n", "    x_issuer: *iss\n")
        rc, res, text, _ = self.run_map(NEST_MAP, g, "--apply")
        rows = self.rows(res)
        self.assertEqual(rows[("R_NORM", "x_doc_cycle")]["action"], "review")
        self.assertIn("alias", rows[("R_NORM", "x_doc_cycle")]["review"])
        self.assertEqual((rc, rows[("A_TASK", "x_mirror")]["action"]), (0, "nest"))  # o resto do arquivo é gravado
        self.assertIn("x_issuer: *iss", text)
        g = NEST_GRAPH.replace("    x_issuer: CMN\n", "    x_issuer: &iss CMN\n").replace("    x_issuer: BCB\n", "    x_issuer: *iss\n")
        rc, res, text, _ = self.run_map(NEST_MAP, g, "--apply")
        self.assertEqual(self.rows(res)[("R_NORM", "x_doc_cycle")]["action"], "review")
        self.assertIn("x_issuer: &iss CMN", text)
        self.assertEqual(rc, 0)

    def test_linha_em_branco_depois_do_bloco_fica(self):
        g = NEST_GRAPH.replace("    x_issuer: CMN\n", "    x_issuer: |-\n      CMN\n\n    # comentario\n")
        rc, res, text, _ = self.run_map(NEST_MAP, g, "--apply")
        self.assertEqual(rc, 0, res)
        self.assertIn("\n\n    # comentario\n", text)

    def test_valor_nao_finito_vai_para_revisao_sem_quebrar_o_json(self):
        m = NEST_MAP.replace("verdict: {move: x_verdict, values: {sim: meets, parcial: partial}}",
                             "verdict: {move: x_verdict, values: {sim: meets, parcial: partial}}\n      x_extra: {move: x_e}")
        rc, res, _t, _e = self.run_map(m, NEST_GRAPH.replace("    x_verdict: parcial\n", "    x_verdict: parcial\n    x_e: [1, .inf]\n"), "--apply")
        row = self.rows(res)[("R_NORM", "x_questionnaire")]
        self.assertEqual((row["action"], row["profile"]), ("review", None))
        self.assertIn(".nan or .inf", row["review"])

    def test_tabela_e_regex(self):
        cases = [  # (fonte, valor, (valor, tinha texto além do código, vai para revisão))
            ({"match": "(a)|b", "prefixes": {"b": "x"}}, "b", (None, False, True)),
            ({"match": "^(x*)"}, "yz", (None, False, True)),  # o grupo vazio não é código
            ({"match": "^([a-z]+)"}, "ab12", ("ab", True, False)),
            ({"match": "^([a-z]+)"}, "ab", ("ab", False, False)),
            ({"prefixes": {"vig": "suspended", "vigente": "in_force"}}, "vigente (x)", ("in_force", True, False)),
            ({"prefixes": {"vig": "suspended"}}, "vig", ("suspended", False, False)),
            ({"values": {"vig": "in_force"}, "prefixes": {"v": "suspended"}}, "vig", ("in_force", False, False)),
            ({"match": "(a)"}, 7, (None, False, True)),
            ({"values": {"7": "x"}, "prefixes": {"7": "x"}}, 7, (None, False, True)),
        ]
        for src, value, (want, extra, review) in cases:
            out, got_extra, why = kg_migrate._map_value(value, src)
            self.assertEqual((out, got_extra, why is not None), (want, extra, review), (src, value))

    def test_raw_guarda_o_que_a_regex_cortou(self):
        m = NEST_MAP.replace("issuer: {move: x_issuer}", 'issuer: {move: x_issuer, match: "^([A-Z]+)"}')
        rc, res, _t, _e = self.run_map(m, NEST_GRAPH.replace("    x_issuer: CMN\n", "    x_issuer: CMN (Res. 4.966)\n"))
        self.assertEqual(self.rows(res)[("R_NORM", "x_doc_cycle")]["profile"],
                         {"issuer": "CMN", "state": "in_force", "x_raw": {"x_issuer": "CMN (Res. 4.966)"}})

    def test_marcador_null_vai_para_revisao(self):
        m = NEST_MAP.replace("issuer: {move: x_issuer}", "issuer: {const: CMN}")
        rc, res, _t, _e = self.run_map(m, NEST_GRAPH.replace("    x_issuer: CMN\n", "    x_issuer: null\n"))
        row = self.rows(res)[("R_NORM", "x_doc_cycle")]
        self.assertEqual(row["action"], "review")
        self.assertIn("null", row["review"])

    def test_recusa_do_arquivo_da_rc_1_e_nao_grava(self):
        p = self.dir / "g.kg.yaml"
        mixed = NEST_GRAPH.replace("\n", "\r\n", 3)
        p.write_bytes(mixed.encode("utf-8"))
        rc, out, _ = self.run_main("nest", "--map", self.map, "--root", self.dir, "--apply", p)
        self.assertEqual(rc, 1)
        self.assertIn("REFUSED", out)
        self.assertEqual(p.read_bytes(), mixed.encode("utf-8"))

    def test_codigo_must_ou_aviso_should_novo_recusa(self):
        from unittest import mock
        real_codes, real_warn = kg_validate.codes, kg_validate.warning_counts
        fake_codes = lambda text, v, corpus=None: real_codes(text, v, corpus) + (["form.x"] if "x_mirror:" in text else [])
        fake_warn = lambda text, m, s, corpus=None: real_warn(text, m, s, corpus) + (
            collections.Counter({"form.y": 1}) if "x_mirror:" in text else collections.Counter())
        for name, patch, want in (("codes", fake_codes, "MUST"), ("warning_counts", fake_warn, "SHOULD")):
            with mock.patch.object(kg_validate, name, patch):
                rc, res, text, _ = self.run_map(NEST_MAP, NEST_GRAPH, "--apply")
            self.assertEqual(rc, 1, name)
            self.assertIn(want, res["applied"][0]["reasons"][0])
            self.assertEqual(text, NEST_GRAPH)

    def test_releitura_sobreposicao_e_fluxo_na_edicao(self):
        """As guardas da edição de texto, chamadas direto: a releitura que difere, duas edições nas mesmas linhas e o
        nó em fluxo (o plano já os manda para revisão; a edição não confia nisso)."""
        from unittest import mock
        doc = kg_validate.parse_v1(NEST_GRAPH)[1]
        rows = kg_migrate.nest_plan(doc, kg_migrate.load_nest_map(self.map))
        row = next(r for r in rows if r[1] == "R_NORM" and r[2] == "x_doc_cycle")
        self.assertIsNone(kg_migrate.nest_apply_text(NEST_GRAPH, doc, [row])[1])
        with mock.patch.object(kg_validate, "canonical", lambda obj, json_keys=False: {"outro": 1}):
            self.assertIn("reread", kg_migrate.nest_apply_text(NEST_GRAPH, doc, [row])[1])
        twin = row[:2] + ("x_mirror",) + row[3:]
        self.assertIn("overlap", kg_migrate.nest_apply_text(NEST_GRAPH, doc, [row, twin])[1])
        flow = NEST_GRAPH.replace("  - id: R_FUTURE\n", "  - {id: R_FLOW, x_issuer: X}\n  - id: R_FUTURE\n")
        fdoc = kg_validate.parse_v1(flow)[1]
        frow = (2, "R_FLOW", "x_doc_cycle", "nest", None, ["x_issuer"], {"issuer": "X", "state": "in_force"})
        self.assertIn("flow style", kg_migrate.nest_apply_text(flow, fdoc, [frow])[1])

    def test_plano_de_arquivo_grande_custa_uma_edicao(self):
        """O ensaio da edição é do arquivo inteiro, e só bisseca quando falha (2a passada do Elenxo: nó a nó, o plano
        do brain foi de 1 s a 71 s). 400 nós, um deles um alias que vai para revisão."""
        import time
        head, rest = NEST_GRAPH.split("nodes:\n", 1)
        body, edges = rest.split("edges:\n", 1)
        nodes = "".join(f"  - id: R_{i}\n    node_type: rule\n    plane: DEV\n    status: open\n    impact: 2\n"
                        f"    confidence: 0.8\n    label: \"Norma {i}.\"\n    x_issuer: CMN\n    x_in_force: vigente\n"
                        for i in range(400))
        edge = "".join(f"  - from: R_{i}\n    to: R_NORM\n    edge_type: TRACES_TO\n" for i in range(400))
        g = head + "nodes:\n" + body + nodes.replace("    x_issuer: CMN\n", "    x_issuer: *iss\n", 1) + "edges:\n" + edges + edge
        g = g.replace("    x_issuer: CMN\n", "    x_issuer: &iss CMN\n", 1)
        started = time.monotonic()
        rc, res, _t, _e = self.run_map(NEST_MAP, g)
        elapsed = time.monotonic() - started
        rows = self.rows(res)
        self.assertEqual((rc, rows[("R_0", "x_doc_cycle")]["action"]), (0, "review"))
        self.assertIn("alias", rows[("R_0", "x_doc_cycle")]["review"])
        self.assertEqual(rows[("R_NORM", "x_doc_cycle")]["action"], "review")  # a âncora que o R_0 usa
        # A_TASK, o x_questionnaire do R_NORM e R_1..R_399
        self.assertEqual(sum(1 for r in res["rows"] if r["action"] == "nest"), 1 + 1 + 399)
        self.assertLess(elapsed, 30, "o plano voltou a custar uma edição por nó")

    def test_plano_com_todos_os_nos_em_alias_nao_bisseca(self):
        """O filtro de âncora e alias, de um compose só, tira os nós antes da bissecção (3a passada do Elenxo: 400 nós
        com alias levavam 146 s)."""
        import time
        head, rest = NEST_GRAPH.split("nodes:\n", 1)
        body, edges = rest.split("edges:\n", 1)
        nodes = "".join(f"  - id: R_{i}\n    node_type: rule\n    plane: DEV\n    status: open\n    impact: 2\n"
                        f"    confidence: 0.8\n    label: \"Norma {i}.\"\n    x_issuer: *cmn\n    x_in_force: vigente\n"
                        for i in range(400))
        edge = "".join(f"  - from: R_{i}\n    to: R_NORM\n    edge_type: TRACES_TO\n" for i in range(400))
        g = (head + "nodes:\n" + body.replace("    x_issuer: CMN\n", "    x_issuer: &cmn CMN\n", 1) + nodes
             + "edges:\n" + edges + edge)
        # metade dos nós com a âncora na própria chave movida, usada por outra chave (escapava do filtro na 4a passada)
        for i in range(200):
            g = g.replace(f'"Norma {i}."\n    x_issuer: *cmn\n', f'"Norma {i}."\n    &k{i} x_issuer: CMN\n    x_other: *k{i}\n', 1)
        started = time.monotonic()
        rc, res, _t, _e = self.run_map(NEST_MAP, g)
        elapsed = time.monotonic() - started
        rows = self.rows(res)
        self.assertEqual((rc, rows[("R_7", "x_doc_cycle")]["action"], rows[("R_NORM", "x_doc_cycle")]["action"]),
                         (0, "review", "review"))
        self.assertIn("anchor (&) or an alias (*)", rows[("R_7", "x_doc_cycle")]["review"])
        self.assertLess(elapsed, 15, "a bissecção voltou a rodar uma edição por nó ruim")

    def test_linhas_que_so_falham_juntas_vao_todas_para_revisao(self):
        """O ramo da bissecção em que cada metade passa e o todo não (uma interação entre nós): as linhas que só falham
        juntas vão para revisão, e as outras seguem."""
        from unittest import mock
        real = kg_migrate.nest_apply_text
        fake = lambda text, doc, rows: (text, "juntas") if len(rows) >= 2 else real(text, doc, rows)
        doc = kg_validate.parse_v1(NEST_GRAPH)[1]
        rows = kg_migrate.nest_plan(doc, kg_migrate.load_nest_map(self.map))
        with mock.patch.object(kg_migrate, "nest_apply_text", fake):
            out = kg_migrate.dry_run(NEST_GRAPH, doc, rows)
        got = {(r[1], r[2]): (r[3], r[4] or "") for r in out}
        # a metade [A_TASK] passa; a metade com as duas linhas do R_NORM falha junta e passa separada: vão as duas
        self.assertEqual(got[("A_TASK", "x_mirror")][0], "nest")
        for into in ("x_doc_cycle", "x_questionnaire"):
            self.assertEqual(got[("R_NORM", into)][0], "review")
            self.assertIn("juntas", got[("R_NORM", into)][1])

    def test_o_resto_e_ensaiado_de_novo_depois_da_bisseccao(self):
        """Depois de tirar as culpadas, o que sobrou é ensaiado junto: uma interação que a bissecção separou em metades
        diferentes manda o resto para revisão."""
        from unittest import mock
        g = NEST_GRAPH.replace("edges:\n", "  - id: R_N2\n    node_type: rule\n    plane: DEV\n    status: open\n"
                               "    impact: 2\n    confidence: 0.8\n    label: \"Outra norma.\"\n    x_issuer: CMN\n"
                               "    x_in_force: vigente\nedges:\n  - from: R_N2\n    to: R_NORM\n    edge_type: TRACES_TO\n", 1)
        doc = kg_validate.parse_v1(g)[1]
        rows = kg_migrate.nest_plan(doc, kg_migrate.load_nest_map(self.map))
        real = kg_migrate.nest_apply_text

        def fake(text, d, group):
            ids = {(r[1], r[2]) for r in group}
            if ("A_TASK", "x_mirror") in ids or {("R_NORM", "x_doc_cycle"), ("R_N2", "x_doc_cycle")} <= ids:
                return text, "junto"
            return real(text, d, group)
        with mock.patch.object(kg_migrate, "nest_apply_text", fake):
            got = {(r[1], r[2]): r[3] for r in kg_migrate.dry_run(g, doc, rows)}
        self.assertEqual(got, {("A_TASK", "x_mirror"): "review", ("R_NORM", "x_doc_cycle"): "review",
                               ("R_NORM", "x_questionnaire"): "review", ("R_FUTURE", "x_doc_cycle"): "review",
                               ("R_N2", "x_doc_cycle"): "review"})

    def test_regex_com_a_semantica_do_ecma(self):
        """\\w só em ASCII e o $ só no fim do texto, como num leitor ECMA-262; a sintaxe só do Python é recusada."""
        cases = [({"match": r"^(\w+)"}, "vigência", ("vig", True, False)),
                 ({"match": "/t/([a-z0-9]+)$"}, "x/t/abc\n", (None, False, True)),
                 ({"match": "/t/([a-z0-9]+)$"}, "x/t/abc", ("abc", True, False))]
        for src, value, want in cases:
            out, extra, why = kg_migrate._map_value(value, src)
            self.assertEqual((out, extra, why is not None), want, (src, value))
        for rx in ("(a)?(?(1)b|c)", "((?>a+))", "(a++)", "(a{,3})", r"(\N{DIGIT ONE})", r"(\U0001F600)", "(?<n>a)",
                   "(?i)(a)", r"([\S])", "([]a)", "([^]a)", "([]a])", r"(\pL)", "(a)(?<=a)+", "(a)(?<!b){2}"):
            m = NEST_MAP.replace('match: "/t/([a-z0-9]+)$"', "match: " + json.dumps(rx))
            rc, res, _t, _e = self.run_map(m, NEST_GRAPH)
            self.assertEqual((rc, res["reason"]), (2, "broken_input"), rx)
        for rx in (r"(\++)", r"(a\$)", "(a{2})", "([$])", "([^$]+)", "(a$)", "(a|b$)", "([*+]+)", "([{,])", "(x{)", "(a+?)",
                   r"(?<=a)\d+(x)", "(?<=a)[a-z]+(x)", r"(?<=a)\w{2}(x)", r"(?<=a)\(+(x)", "((?<=a)x)+", "(?<=a)(x)+", "(?<=a){{2}(x)"):
            kg_migrate.ecma_regex(rx)  # o $ e o (?P dentro de classe são literais; o $ fora dela é o fim do texto
        # o \s e o . do ECMA: o NBSP é espaço, e o . não casa \r nem U+2028
        self.assertEqual(kg_migrate.ecma_regex(r"(\S+)").search("CMN\u00a0BCB").group(1), "CMN")
        self.assertTrue(kg_migrate.ecma_regex(r"a(\s)b").search("a\u2028b"))
        self.assertEqual(kg_migrate.ecma_regex("^(.+)").search("ab\rcd").group(1), "ab")
        self.assertIsNone(kg_migrate.ecma_regex("(a$)").search("xa\n"))
        self.assertEqual(kg_migrate.ecma_regex(r"([\s]+)").search("a\u00a0b").group(1), "\u00a0")  # \s numa classe
        kg_migrate.ecma_regex("(a)(?=b)*")  # o lookahead quantificado é Annex B no ECMA: os dois leem
        # fora do BMP, o ECMA sem a flag u conta unidades UTF-16: o valor vai para quem revisa
        self.assertIsNotNone(kg_migrate._map_value("😀x", {"match": "(.{2})"})[2])

    def test_chave_especial_vai_entre_aspas(self):
        m = NEST_MAP.replace("verdict: {move: x_verdict, values: {sim: meets, parcial: partial}}",
                             "verdict: {move: x_verdict, values: {sim: meets, parcial: partial}}\n      x_extra: {move: x_e}")
        g = NEST_GRAPH.replace("    x_verdict: parcial\n", "    x_verdict: parcial\n    x_e: {'null': 1, 'True': 2, 'a b': 3, ok: 4}\n")
        rc, res, text, _ = self.run_map(m, g, "--apply")
        self.assertEqual(rc, 0, res)
        self.assertIn('"null": 1', text)
        self.assertIn('"True": 2', text)
        self.assertIn('"a b": 3', text)
        self.assertIn(" ok: 4", text)
        norm = next(n for n in kg_validate.parse_v1(text)[1]["nodes"] if n["id"] == "R_NORM")
        self.assertEqual(norm["x_questionnaire"]["x_extra"], {"null": 1, "True": 2, "a b": 3, "ok": 4})

    def test_vendor_fica_de_fora_pelo_carimbo(self):
        vendor = self.dir / "third_party" / "kit"
        vendor.mkdir(parents=True)
        (vendor / ".kg-ssot-version").write_text("kg-ssot-v4.21.0\n", encoding="utf-8")
        (vendor / "v.kg.yaml").write_text(NEST_GRAPH, encoding="utf-8")
        self.write()
        for cmd in (["init", "-q"], ["add", "-A"]):  # sem os grafos dados, o nest lê os rastreados pelo git
            subprocess.run(["git", "-C", str(self.dir), *cmd], check=True, capture_output=True)
        rc, out, _ = self.run_main("nest", "--map", self.map, "--root", self.dir, "--json")
        files = {r["file"] for r in json.loads(out)["rows"]}
        self.assertEqual((rc, files), (0, {"g.kg.yaml"}))


if __name__ == "__main__":
    unittest.main()
