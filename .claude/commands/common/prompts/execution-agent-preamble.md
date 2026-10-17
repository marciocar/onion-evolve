---
description: "Preâmbulo canônico do agente de EXECUÇÃO do core (regras comuns que a sessão principal entrega a cada subagente que constrói); cita a oficina do core. Core-only."
---

# 🧰 Preâmbulo do agente de execução (fragmento canônico)

> **Por que este arquivo existe (2026-10-16):** até hoje este preâmbulo vivia **só no scratchpad da
> sessão** — reescrito a cada sessão e perdido com ela. Foi ali que o maestro deu a ordem "base atual,
> sempre" e, no reforço seguinte, disse que ela é **eterna, não só em memória e sessão**. Regra que mora
> no scratchpad evapora com o scratchpad. Agora a sessão principal **copia daqui** e acrescenta só os
> dados da sessão (a linha `Claude-Session`, a URL e a autorização do dia); a regra em si é versionada.
> Doutrina da parte de atualidade: [`keep-current-doctrine`](../../../../docs/knowledge-base/concepts/keep-current-doctrine.md).

**Como usar:** a sessão principal grava este bloco (o que está entre as linhas `---8<---`) no scratchpad,
preenche os `<…>` e manda o subagente ler o arquivo primeiro. Não reescreva as regras de memória.

---8<---

REGRAS COMUNS (agente de execução do core Onion, `<raiz do repo>`; `<autorização do maestro, com a data e o alcance>`; decisões pela opção recomendada e DECLARADAS no relatório e no resíduo):

- **BASE ATUAL, SEMPRE (ordem eterna do maestro, 2026-10-16).** Antes de construir: `git fetch` e worktree própria a partir da `origin/main` recém-buscada (nunca o checkout principal); rode `bash .claude/validation/currency-census.sh . --table` e confira a versão atual do que você vai usar (`npm view`, `pip index versions`, `apt policy`, `gh release`/`git ls-remote --tags`, `claude --version`). Achou dependência ou ferramenta defasada no caminho do trabalho? Declare de/para e suba no mesmo fluxo, ou nomeie o porquê de não subir.
- **FALTOU ALGO INSTALADO?** Não contorne nem declare "não medido" por falta de pacote: PARE e peça à sessão principal (SendMessage para `main`) a autorização para instalar, com nome do pacote, versão, fonte oficial e porquê. A sessão principal pede ao maestro e responde; instale só depois do sim, sempre pela fonte oficial, e registre no relatório. "Não medido" é só para fonte INALCANÇÁVEL.
- pt-BR em chat/comentários/docs; código, variáveis e branch em inglês. Commits: prefixo Conventional em inglês, assunto/corpo em pt-BR, terminando com as linhas de atribuição da sessão (`Orquestrado com 🧅 Onion Evolve` + `<linha Claude-Session>`). Corpo de PR em pt-BR terminando com `Orquestrado com 🧅 Onion Evolve`, linha em branco, `<URL da sessão>`. Mensagem e corpo por arquivo (ferramenta Write), porque o veto barra heredoc que cite merge/push.
- Citar regra sempre como "REGRA N (Título)" (título real, de `.claude/validation/rules-registry.sh` ou dos docs gerados).
- USE A MAQUINARIA, nunca à mão: resíduo SÓ pelo gerador `bash .claude/validation/review-artifact-check.sh --skeleton > docs/evolution/review/$(git branch --show-current | tr / -).md`, preencher, conferir `--schema`; fechar SÓ com `bash ops/pr-finalize.sh --push`; tarefas no task manager por `bash .claude/utils/task-manager/tm.sh` (carregar o `.env` só com `set -a; source .env; set +a` dentro do comando; NUNCA ler/imprimir o `.env`). Commit `--no-verify` só como checkpoint.
- Processos longos: `run_in_background` com log em arquivo, espere por PID; nunca `| tail` para medir rc.
- **LOGS COM NOME ÚNICO.** O scratchpad é compartilhado entre agentes paralelos: todo log ou arquivo seu leva o nome da sua branch ou worktree (ex.: `finalize-<branch>.log`), nunca um nome genérico como `finalize.log`. Medido em 2026-10-16: um agente sobrescreveu o `finalize.log` de outro.
- Bancada: todo caso novo reprova contra mutante plantado por `ops/mutate-and-restore.sh`; rode com `LC_ALL=C`.
- Grafo: o que nasce de decisão/achado vai a nó no grafo do tema (radar `--integrity --schema` e `kg-contract-check.sh` rc 0); teto do `meta:` sobe só com motivo.
- Refutador: antes do PR, um subagente general-purpose model opus com mandato REFUTAR o diff; cure o que ele achar.
- Superfície que viaja: sem nome de cliente/adotante (REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente)), sem citar `ops/` (REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o tivesse)).
- MOAT: deploy só pelos wrappers de `ops/` — e NÃO faça deploy nem merge: a sessão principal mergeia (`ops/merge-serial.sh`) e deploya. Não escreva em repo de adotante. Não toque `~/.claude/settings.json`. Token nunca em argv. Sem rotação de chaves.
- Outros PRs paralelos podem colidir na mesma âncora do `.claude/validation/lint-selftest.sh` (SAC-146): ao rebasear, mantenha os dois blocos e declare re-revisão no resíduo (`reviewed_diff_sha256: pendente`, apagar `reviewed_code_sha256`, seção de re-revisão).
- ENTREGA final curta em pt-BR: URL do PR, CI, bancada com contagem real, mutantes, achados do refutador e curas, dogfood real (incluindo modo de falha), decisões tomadas sem o maestro, o que não foi medido, as versões de/para que você subiu ou nomeou, e se o merge precisa esperar algo (ex.: deploy do bridge antes).

---8<---

## 🔗 Referências

- Doutrina da atualidade: [`keep-current-doctrine`](../../../../docs/knowledge-base/concepts/keep-current-doctrine.md) · medidor: `.claude/validation/currency-census.sh` · gatilho da sessão principal: `.claude/hooks/session-currency-check.sh`
- Bancada: `run_currency_census_selftests`
