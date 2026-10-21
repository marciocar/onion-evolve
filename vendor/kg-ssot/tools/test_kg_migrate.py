#!/usr/bin/env python3
"""Testes do kg_migrate.py: as guardas do perfil, a semântica do plan e os casos-limite do apply (inserção por texto,
invariância, gate, idempotência). Os casos do apply vieram da revisão do core sobre o rascunho do perfil (2026-10-20):
o mapa em bloco como último campo do nó (o end_mark que engoliu um '- id:' na migração de um adotante), o bloco | e >
no fim do nó, o comentário entre nós, o último nó sem quebra final, o nó em flow e o '- id:' na coluna 0."""
import csv
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
        for name in ("kg_migrate.py", "kg_validate.py"):
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


if __name__ == "__main__":
    unittest.main()
