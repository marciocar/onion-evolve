# Radar E3 rodada 2 — delta 2.1.257 → 2.1.259 — achados PRÉ-JUIZ (2026-09-03)
Fonte primária: CHANGELOG.md oficial (data/changelog-2.1.258-259.md; l.N = linha nesse arquivo). 2.1.258 = 2 itens (macOS 12, remoto); 2.1.259 = 37 itens.
Medições locais citadas: `grep -rlE '^model:'` no core (2026-09-03).

F1 — `model:` de frontmatter passa a VALER em sessão interativa (l.17 "Fixed frontmatter `model:` on custom commands and skills being ignored in interactive sessions"). Exposição do Onion: 111/112 comandos, 1 skill (onion-patterns, com DOIS `model:`), 51 agentes declaram `model:` — 147× `sonnet`, 19× `opus`, 3× `haiku`. Agentes sempre foram honrados (subagente); comandos/skill NÃO eram. Consequência esperada: invocar `/warm-up` (model: sonnet) no picker de uma sessão Fable tenta trocar para sonnet → a guarda PreModelSwitch (lineup fable-5-1/opus-5) VETA (exit 2). O que acontece com o comando após o veto (roda no modelo da sessão? erro?) NÃO foi medido: invocar a skill pela ferramenta Skill num job de background NÃO gerou evento em .claude/sessions/model-switch.jsonl (0 eventos hoje) — o caminho interativo é outro. LACUNA: precisa do maestro invocar /warm-up no picker e ler o log. Impacto na estratégia: o tiering de comandos por frontmatter (147 sonnet) é um DOWNGRADE latente da doutrina "sempre o máximo" que a plataforma agora executa; decisão candidata: remover `model:` de comandos/skill (mantendo em agentes) OU alinhar ao lineup.

F2 — auto mode não roda mais turno num modelo não suportado quando o frontmatter nomeia um (l.10): reforça F1 — a plataforma passou a arbitrar frontmatter vs sessão; em auto mode o modelo da sessão vence.

F3 — `--permission-prompts none` para hosts headless (l.4): tudo que pediria prompt é negado, o modo ativo (incl. auto) segue decidindo. Relevância: jobs de background do core na VPS e o degrau AUDIT do /meta:drive — hoje o Onion usa bypassPermissions + hooks exit 2; `none` é uma 2ª opção com fail-closed por default. Não muda doutrina (o exit 2 continua sendo a capacidade que compra o acoplamento); vira opção no adotante headless.

F4 — sessões concorrentes deixavam de reverter `~/.claude.json` (l.7): a VPS roda dezenas de sessões (40 processos `claude` medidos em 09-02); perda de trust/MCP entre sessões era sintoma plausível e não registrado. Nota, sem ação.

F5 — deny rules `Read()` do Bash agora cobrem arquivos em valores de opção (`-f.env`, `@file`), operandos de `git diff/grep` e compostos `cd DIR && cat FILE` (l.9). O core tem só `Bash(grep * .env)` em deny (settings.json:12) — a proteção de `.env` por deny rule é fraca; a doutrina da casa é "segredo nunca em claro no repo" + pass. Opção: adotar `Read(./.env)`-style deny agora que a cobertura é real. Decisão candidata pequena.

F6 — `claude plugin validate --json` (l.6): relatório legível por máquina; candidato a entrar no gate de `onion-publish`/assemble-plugin (hoje a validação do plugin é a nossa REGRA 19 de drift + selftest). Oportunidade, não obrigação.

F7 — `managedMcpServers` + mudança semântica de `allowedMcpServers` (l.3, l.38): allowlist governa só servidores adicionados por usuário; servidor gerenciado literal que a allowlist filtrava passa a carregar no upgrade. O Onion é MCP-opcional (SDAAL); relevante só para adotante corporativo com managed settings. Nota.

F8 — Stop hooks bloqueantes deixavam o turno seguinte sem o raciocínio e sem cache (l.30): o core usa hooks Stop? (a medir: grep Stop em settings.json). Se sim, o custo de cache dos vetos caiu.

F9 — worktrees: isolamento aceita worktrees criadas por hook (l.21) e deixa de recusar loops/xargs/launchers (l.32); resume de workflow não duplica agentes (l.27); resultados de subagente aninhado ficam no transcript do pai (l.36). Todos a favor da orquestração do core (/onion-research retomável, drive em worktree). Sem ação.

F10 — `glab mr` reconhecido (l.5) + /install-github-app explica GitLab (l.35): sinal de que a plataforma está costurando GitLab; o forge SDAAL do core tem gitlab "costura pronta, não implementada" — a demanda do lado da plataforma cresce. Nota estratégica.

F11 — managed settings ilegíveis agora ABORTAM o start nomeando a fonte (l.24): fail-loud onde era fail-open silencioso — coerente com a doutrina do core (relay-machine-signals). Nota.
