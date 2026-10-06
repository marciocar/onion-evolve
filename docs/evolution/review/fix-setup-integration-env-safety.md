---
reviewed_diff_sha256: cc6ad535fdcef07af24cdb8c279b3cf36be3aa2ee3fc2f24b7ef80291edc665d
reviewed_code_sha256: cd451e7e1c0aee3ec04fe831137d8da93df7657549850c6847d28128e8cafa54
findings_total: 19
findings_real: 19
tokens: 255580
duration_min: 21
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Sinal de campo de um hub (gmill, dogfood do Zoho, 2026-10-05): o setup-integration mandava ler o .env com
  Read "sem expor valores" — e expõe. DUAS passadas do Elenxo (opus), ambas REPROVARAM, todas curadas aqui.
  1ª (9 achados): trocar permissões não proíbe nada (allowed-tools só pré-aprova; Read livre; `Bash(grep * .env)`
  liberado no settings e na skill onion; sob bypass nada é restrito) → VETO exit 2 no PreToolUse
  (pretooluse-env-guard.sh); plugins editados à mão eram projeção → manifesto + assembler; helper ignorava o
  ambiente; comentário inline no .env.example quebrava o hook; --set-provider aceitava 'jira clickup'; segredo na
  linha de comando do curl; prosas "ler .env" restantes; caso (e) da bancada com buracos.
  2ª (10 achados): quebra de linha não separava comandos (`test -f .env` liberava o bloco); comentário e `echo`
  viravam falso positivo NOS BLOCOS DA PRÓPRIA CURA; `git diff --no-index`/`git show :.env`, glob (`cat .e*`,
  Grep glob) e interpretador inline escapavam; `source .env && env` despejava; --get vazava credencial em URL;
  parsers do hook e do helper divergiam. Curados; o eco nominal de UMA variável após source, `sed -i`, e o veto
  embarcado só no plugin onion ficam como TETO declarado no cabeçalho do hook.
  FORA DO ESCOPO, CURADO AQUI: o Claude Code subiu para 2.1.291 e a bancada (f) do cited-directive voltou a
  acusar DERIVA — 2ª vez em dois dias, só renomeação de identificadores minificados. Virou mecanismo: a
  checagem compara a ESTRUTURA do motor (identificadores como curinga) — renomear não é deriva, mudar o
  comportamento é; o mutante que tira o lookbehind da cópia ainda morde (4 ✗).
  Bancada `run_env_exposure_selftests`: 11 casos (inclui 84 polaridades do veto em bateria externa e a
  VARREDURA dos 18 blocos bash do corpus que citam .env); 18 mutantes mordem; 1 redundante por construção
  (o redirecionamento `< .env`, também barrado como argumento do leitor).
---

# Resíduo — `fix/setup-integration-env-safety`

O `.env` nunca chega ao modelo: veto `exit 2` + helper `env-check.sh` (nomes, provider e `--get` só de NÃO-segredo).
