---
branch: feat/keep-current-eternal
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 29
findings_real: 29
tokens: 314310
duration_min: 38
findings_fixed: 26
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "2 passadas de refutador general-purpose model opus em sandbox (1a sobre 9b8db6bf: 157.725 tokens, 26 min; 2a sobre 78608957: 156.585 tokens, 11 min); curas conferidas pela família currency_census 49/49 com LC_ALL=C e 35 mutantes por ops/mutate-and-restore.sh"
nota: "findings_fixed 26 de 29: os 3 restantes são tetos declarados na doutrina (versão do SDK em cache por 5 min; processo da fonte travada vive até 4 s depois do censo; recusa sob root não é exercitável sem root). Decisões tomadas sem o maestro, pela opção recomendada: aviso e nunca veto exit 2; o hook viaja (a perna do SDK só existe onde há alvos); a pinada entra no aviso como informativa."
---

# Passada adversarial: `feat/keep-current-eternal`

## O que muda

A ordem do maestro de 2026-10-16 ("usar sempre as versões mais atuais e não criar em cima de base
velha", e no reforço: "é eterno, não só em memória e sessão") vira mecanismo:

- doutrina `docs/knowledge-base/concepts/keep-current-doctrine.md` (fonte citável) e uma linha no `CLAUDE.md`;
- medidor `.claude/validation/currency-census.sh` (CLI do host × canal no npm, Agent SDK servido × npm,
  vendor kg-ssot × tags do produto, PyYAML e jsonschema × PyPI com o pino do contrato, HEAD × branch padrão
  do origin por `ls-remote --symref`);
- gatilho `.claude/hooks/session-currency-check.sh` (`UserPromptSubmit`, aviso por superfície, exit 0);
- preâmbulo do agente de execução versionado em `.claude/commands/common/prompts/execution-agent-preamble.md`;
- grafo `docs/evolution/research/guard-keep-current-2026-10/keep-current-2026-10.kg.yaml`, com a decisão
  `D_MANTER_ATUALIZADO_E_ETERNO` selada por `kg-decide-seal.sh --new` (`--chosen "manter atualizado é eterno"`).

Os `confirmed` de maior impacto do grafo editado, conferidos contra a proposta: `E_DEFEITO_SDK_DEFASADO_SEM_AVISO`
(o defeito que a guarda existe para pegar, reproduzido verbatim no caso (b)), `E_ELENXO_1A_PASSADA_CACHE_E_PRAZO`
e `E_PREAMBULO_SO_NO_SCRATCHPAD`. Nenhum contradiz o diff: são a evidência dele.

## Achados

**1ª passada (10, todos curados):** cache envenenável e injetável (guardava a linha pronta, com o texto da
ação); a cura ficava escondida até 1 h; ferramenta da medição ausente lida como "registro inalcançável";
perna morta sumia calada (`HOME` indefinido sob `set -u`); prazo de 15 s estourável; leitura por sudo
seguindo symlink; assinatura do aviso que re-avisava a cada sha da base (e, na 1ª cura, emudecia no
vai-e-volta); 3 casos decorativos (cache nunca exercido, TTL de falha, normalização da assinatura).
Cura: o cache guarda só respostas remotas na forma de versão/sha, o lado local é relido a cada prompt,
cada perna roda sob prazo e a morte vira linha, o pré-voo declara ferramenta ausente, o SDK só é lido pelo
caminho real, e o aviso é por superfície.

**2ª passada (19; 16 curados, 3 tetos):** a intermitência do caso (k3) tinha causa — `head -1` sob
`pipefail` fazia o `printf` tomar SIGPIPE (3 em 3000, rc 141), curada com `awk 'NR==1'` em toda primeira
linha; stderr do pip misturado na resposta; pré-voo sem `grep tail cat rm date id`; o hook emudecia para
sempre a superfície que nunca volta a em dia; a falha não era gravada quando a perna morria pelo prazo
(teto da fonte agora grampeado ao prazo e marca de medição em curso); instalado à frente do pino mandava
fazer downgrade (agora `fora-do-pino`); a `pinada` calava para sempre (agora informativa); sessão sem id
compartilhava estado (agora lida do JSON do hook, e o estado só vale em diretório da conta); três menores
(git vazio, `--render` num TTY, cache do origin chaveado pelo repo e não pela URL); 5 mutantes sobreviventes
(dono do cache, uid 0 de outro nome, pino à frente do PyPI, idade negativa no cache, `sort -V` no pré-voo),
todos com caso agora. Tetos declarados: SDK em cache 5 min, processo órfão de fonte travada (≤ 4 s),
recusa sob root não exercitável sem root.

**Dogfood (achado pelo uso, antes do refutador):** o 1º disparo real do hook declarou o git AUSENTE numa
máquina que tem git, porque uma perfilagem com `ONION_CURRENCY_GIT` vazio envenenou o cache chaveado só
pelo repo (nó `E_DOGFOOD_CACHE_ENVENENADO`).

## Mutantes

35 plantados por `ops/mutate-and-restore.sh` com `LC_ALL=C`, contra a família `currency_census`: 33 mordem.
Os 2 que não mordem são redundantes por medição, e ficam declarados: o `..` no caminho do SDK (a
conferência do caminho real também o recusa) e o stderr do pip junto da resposta (ela é lida pelo nome do
pacote, não pela posição). Bancada limpa depois de cada lote: 49/49.

## Limites declarados

- Aviso, nunca veto `exit 2`: toda superfície depende de registro de terceiro e de rede.
- "Latest" do registro não é juízo de estabilidade; o canal do CLI vem do npm, não do manifesto do
  instalador nativo; managed settings não são lidos.
- Subagente não recebe `UserPromptSubmit`: a regra chega a ele pelo preâmbulo versionado.
- O hook viaja pela fusão de hooks e lá lê npm, PyPI, o remoto do kg-ssot e o origin, nas TTLs declaradas.
- Bancada completa (todas as famílias) NÃO rodada localmente nesta sessão: a rodada começou e foi
  interrompida por mim quando o código mudou; o gate final é o CI, e o pre-commit roda as famílias afetadas.
