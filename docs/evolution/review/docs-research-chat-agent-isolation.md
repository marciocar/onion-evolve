---
branch: docs/research-chat-agent-isolation
pr: 1162
date: 2026-10-16
reviewed_diff_sha256: 232edd636bbced50ea7536b45b9ae3ab021da639dcb0e051385a18d7d83d6742
reviewed_code_sha256: ce49b6a423cf70f1ecc2030599a5445a518cf3645156ec0ed233415cbbcd9e4d
findings_total: 10
findings_real: 10
tokens: 211129
duration_min: 4
findings_fixed: 10
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente general-purpose opus, mandato REFUTAR
nota: "PR de registro: grafo da pesquisa (2 runs) + selo da decisão do maestro de 2026-10-16 + SYNTHESIS; 2 passadas do refutador (3 + 7 achados), todas curadas; o 2º commit traz as 3 provas como evidência."
---

# Passada adversarial: `docs/research-chat-agent-isolation`

## O que muda

Registro da pesquisa `chat-agent-isolation-2026-10` (rodadas `wf_505962e3-7c9` e `wf_8847e3af-370`): o grafo de
124 nós, a decisão do maestro de 2026-10-16 («Degrau 0 já + 3 provas») selada pelo `kg-decide-seal.sh` como nó
NOVO (`D_MAESTRO_DEGRAU0_E_TRES_PROVAS_1016`, TRACES_TO a decisão-mãe, que segue `open`), o teto do `meta:`
subido de 123 para 124 com motivo, a `SYNTHESIS.md` com o contrato de custo e o `docs/backlog.md` regenerado.

## Achados

1. Inventário de contas da VPS (com nome de adotante e de pessoas) num nó do grafo público. CURADO: trocado por
   "6 contas humanas e de serviço".
2. A decisão-mãe ainda dizia que hosting e CVE-2026-39861 não tinham sido lidos. CURADO: o `verified_against`
   aponta a lacuna fechada pela rodada 2, a recomendação vigente e o selo parcial.
3. A SYNTHESIS dizia não acrescentar nada ao grafo, mas traz custo e balanço. CURADO: a frase diz "afirmação de
   domínio" e nomeia o journal dos runs como fonte do custo.

## Mutantes

Não se aplica: o PR não muda código nem guarda; o gate é o radar `--integrity --schema` (exit 0) e o
`kg-contract-check.sh` (rc 0), rodados de novo depois das curas.

## Limites declarados

As 3 provas pedidas pelo Elenxo NÃO estão neste PR: entram como evidência num 2º PR, depois das medições.
Decisão tomada sem o maestro: o selo como nó novo (não fechar a decisão-mãe), com o teto subindo 1.

## Re-revisão (2º commit: as 3 provas)

O PR recebeu as 3 provas pedidas pelo Elenxo como nós de evidência (`E_PROVA1/2/3_*`, teto 124→127, 11
arestas) e a seção correspondente na SYNTHESIS. O diff mudou depois da 1ª passada, então o carimbo volta a
`pendente` e o `reviewed_code_sha256` sai; o `pr-finalize` recarimba. Passada adversarial própria sobre o
diff novo (opus, mandato REFUTAR, reexecutou probe1b e probe3): 7 achados de PRECISÃO, nenhum derruba prova,
todos curados no texto: (1) o 'fail-open dali em diante' da prova 3 não foi medido, agora é 'o CLI declara';
(2) a aresta E_PROVA2 → lançador por socket sustentava o que a prova não prova, removida; (3) o filtro do
managedSettings também deixa passar um allow, então não é puramente restritivo; (4) o 'só' do
filterEscalatingDefaultMode não foi medido; (5) a prova 1 confirma só a metade de CARGA da objeção 32;
(6) o 'pat-negado' do hook não tem controle positivo; (7) a propagação do exitCode não foi comparada.
Radar e contrato rc 0 depois das curas.

## Re-revisão (3º commit: baseline da REGRA 99)

O CI (selftest, família kg-machine-path) acusou ISENCAO-NOVA nos 2 nós que citam o `/proc/` da man page do
systemd.exec(5) com `x_path_is_content: "citação"`. O caminho É o conteúdo da quote; o baseline foi emitido
pelo gerador (`kg-machine-path-check.sh --emit-baseline`) e o diff dele é só essas 2 linhas `isento`.

