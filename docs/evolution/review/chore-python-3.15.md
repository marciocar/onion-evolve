---
branch: chore/python-3.15
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 9
tokens: 146990
duration_min: 9
findings_fixed: 6
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose, model opus, 1 passada com mandato de refutar
nota: "3 achados declarados sem cura: as dependências de BUILD do PyYAML (sdist no 3.15) vêm sem hash; o pin do setup-python fora do censo de actions (que só mede action que instala CLI); a instalação dupla do requirements no onion-validate. A bancada completa em 3.15 roda no CI (o PR toca .github/workflows, nível completo); localmente rodaram as famílias tocadas em 3.15 e 3.12"
---

# Passada adversarial: `chore/python-3.15`

## O que muda

- CI: `actions/setup-python` v7.1.0 (pin `6d4fd22b`) com `python-version: '3.15'` nos jobs que rodam Python: `lint-onion-artifacts`, `plano`, `selftest` e `alarme-main`. As dependências entram pelo pino com hash do leitor do KG-SSOT, e um passo prova que o `python3` efetivo é o 3.15.
- CI: há um passo novo de **piso 3.12** no `onion-validate`. Ele compila todo `.py` rastreado no 3.12 e roda o harness do escritor com o PyYAML de wheel, que traz libyaml.
- `currency-census.sh`: superfície nova `python`, que compara o minor do `python3` do lint com o `python-version` dos workflows `onion-*`. A linha marcada `# onion:floor` fica fora da conta.
- Harness do escritor (`ops/mcp-onion-kg-writer/selftest.py`) e a família `mcp_onion_kg_writer` da bancada: o caso e o mutante `profundidade-tab-inicial` passam a respeitar a ausência da libyaml, medida no próprio interpretador.

## Achados

1. **ALTA, curado.** A perna lia qualquer workflow e, no adotante, cobrava o Python da aplicação dele, chegando a mandá-lo para baixo do piso. Agora a perna lê só os `onion-*`. Casos py5 e py6.
2. **ALTA, curado.** Nada segurava o piso 3.12 no CI. Entrou o passo "Piso 3.12" no CI. Mutante medido: um `except A, B:` sem parênteses compila no 3.15 e falha no 3.12.
3. **MÉDIA, declarado.** As dependências de build do PyYAML (setuptools, Cython) entram sem hash quando ele compila do sdist no 3.15. É teto, e ficou escrito no workflow.
4. **MÉDIA, curado.** O caminho C (libyaml) da guarda de aninhamento saía do CI. Agora ele é provado pelo harness no passo do piso 3.12, que afirma `yaml.__with_libyaml__`. O `libyaml-dev` não cura no 3.15: o `_yaml.c` do sdist não compila contra a API C do 3.15, medido na VPS.
5. **MÉDIA, curado.** O texto de cura da linha `defasada` mandava instalar com o pip do python velho. Agora manda usar `<venv>/bin/python -m pip`, e o py2 exige isso.
6. **MÉDIA, curado.** "Sem setup-python a superfície some" não estava provado, e os mutantes `sort -u`→`sort` e `want` vazio sobreviviam. O py1 agora tem dois passos `3.15` e a linha do piso. Entraram também o py6 (omitida) e o py7 (valor ilegível vira não medido, nunca omitido).
7. **BAIXA, curado em parte.** Quando o setup-python não traz valor legível (matriz, `3.x`), o estado agora é não medido. O `3.10` sem aspas, que o YAML lê como 3.1, segue declarado.
8. **BAIXA, declarado.** O pin do setup-python fica fora do censo de actions, que só mede action que instala CLI.
9. **BAIXA, declarado.** O requirements é instalado duas vezes no `onion-validate`. É inofensivo.
10. **Informativo.** A branch estava atrás da `origin/main`. Foi rebaseada antes do PR.

## Mutantes

- Tirar `grep -v onion:floor` ou trocar `sort -u` por `sort`: o py1 reprova, por construção da fixture.
- Inverter a comparação do minor: o py1, o py2 ou o py3 reprova, medido pelo refutador.
- `except A, B:` no piso: `SyntaxError: multiple exception types must be parenthesized` no 3.12, enquanto o 3.15 aceita.

## Limites declarados

- O passo do piso só confere a sintaxe dos `.py` e roda um harness. O Python embutido em heredocs dos `.sh` e a API de biblioteca (por exemplo `copy.replace`) não passam por ali.
- No 3.15 o PyYAML não tem libyaml até sair um wheel cp315, e ele chega pelo pino do kg-ssot.
