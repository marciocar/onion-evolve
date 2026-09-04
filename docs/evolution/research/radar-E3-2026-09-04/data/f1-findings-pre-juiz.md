# Radar E3 rodada 3 — delta 2.1.259 → 2.1.260 — achados PRÉ-JUIZ (2026-09-04)
Fonte primária: data/changelog-2.1.260.md (66 itens; l.N = linha desse arquivo, numerada por `grep -n ""`).
Medições locais: repo em main 980bdbe3; guarda PreModelSwitch = hook do core; agentes com model: 43 sonnet / 8 opus / 0 fable (frontmatter real, 2026-09-03).

F1 — l.42 REVERTE a mudança de 2.1.259 que aplicava deny rules `Read()` a argumentos do Bash (negava `npm run build` sob `Read(./**/build/**)` e fazia `cd … && grep` perguntar até em auto mode). SUPERA o achado F5 da rodada 2 (radar-E3-2026-09-03/E_F5_DENY_READ_COBERTURA_E_O_ALLOW_DO_ENV), que descrevia essa cobertura como opção a adotar. Consequência: a cobertura de `.env` por deny rule volta a ser a de antes; a doutrina da casa (segredo fora do repo + pass) segue não dependendo dela. Nó antigo → superseded.

F2 — l.20 e l.21: a troca de modelo deixava de ficar BLOQUEADA pelo resto da sessão após falha de carga de um hook de plugin (l.20) ou de um marketplace gerenciado (l.21); agora cada troca re-checa e a recusa NOMEIA a causa. Relevância direta: a guarda PreModelSwitch do core É um hook; antes, uma falha de carga dela silenciava todas as trocas sem dizer por quê; agora a recusa nomeada da plataforma convive com o veto nomeado da guarda. Confirma o desenho "recusa sempre nomeia" (escada, #786).

F3 — l.18: o picker `/model` passa a MOSTRAR o Fable 5.1 para organizações que podem usá-lo (antes só aceito digitado como `/model claude-fable-5-1`). Efeito na escada: subir ao primário pelo picker fica visível; e a lacuna 6 do E3 (fonte do evento) ganha um caso mensurável: pick de Fable no picker deve chegar à guarda com source=picker e ladder=restored.

F4 — l.17: agentes `model: fable` ignoravam o tag `[1m]` num pin `ANTHROPIC_DEFAULT_FABLE_MODEL` e rodavam com 200K de contexto em silêncio. O core NÃO tem agente com `model: fable` (0 de 51) nem usa esse pin; nota para quem tierar agentes em Fable.

F5 — l.19 e l.51: cache de prompt no Fable 5.1 — o contexto anexado após tool results era re-enviado sem cache a cada turno de tool-call (l.19); mudar `/effort` no meio da sessão invalidava o cache (l.51). Custo do "sempre o máximo" cai em sessões longas de ferramenta (o caso desta casa). Sem ação; medir no `/cost` (l.4: agora nomeia a causa provável de cache miss).

F6 — l.49: auto-compact em modelos de 1M (Opus e Fable) compacta pouco antes do limite e a compactação de recuperação em contextos muito grandes deixa de estourar 10 min. Relevante à doutrina de sessões longas (esta sessão está a ~800k). Nota.

F7 — l.43 e l.34: Workflow — `agent({schema})` rejeita de saída um JSON Schema insatisfazível, e erros de teto de retry incluem a última falha de validação (l.43); subagentes de Workflow deixam de ser reiniciados como "stalled" durante compactação longa (l.34). O /onion-research usa schemas com `required` e `allOf` (KG_SCHEMA_DECISION): l.43 transforma "worker sumiu da fila" (a vacuidade que a kg-freshness documenta) em erro nomeado. Positivo; sem ação.

F8 — l.29 e l.31: subagente que retomava outro via SendMessage nunca era acordado pela conclusão (l.29); sessão movida para background aparecia 2× em ListAgents como "gêmea interativa" fantasma e recebia entregas no viewer (l.31). O core operou 2026-09-03 exatamente num job em background (bg-spare) e o maestro viu `/exit` "não sair" — l.31 é o retrato desse fantasma. Nota de plataforma.

F9 — l.61: removido o limite de 1 h em comandos de background iniciados por subagentes (rodam até sair ou serem parados, como a sessão principal). Relevância: a bancada em faixas (~8–12 min) e as medições longas do core cabiam; o teto era invisível — agora não existe.

F10 — l.5 e l.35: `/reload-plugins` em sessões headless (l.5); instalação de plugin de marketplace por URL deixa de falhar quando o host guarda a entrada como diretório (l.35). Com a versão derivada (#787), `plugin update` + `/reload-plugins` fecha o ciclo sem reiniciar. Nota.

F11 — l.9, l.10, l.11, l.54: regras de permissão — caminhos com parênteses eram descartados e deixavam pastas "read-only" graváveis (l.9); um padrão incompilável (`[` sem fechar) quebrava toda edição (l.10); zsh escondendo substituição de comando em REPORTTIME etc. era auto-aprovado (l.11); texto após o parêntese (`Bash(ls) x`) era ignorado em silêncio e passa a ser inválido (l.54). O core tem só allow rules (round 2, F5 reprovado); nota para adotante com deny rules e para o lint (candidata: regra de settings bem-formados — não agora).

F12 — l.39 e l.40: GitLab — detecção de repositório em subgrupos aninhados e links de issue `owner/repo#123` para gitlab.com. Continuidade do F10 da rodada 2: a plataforma segue costurando GitLab; o adapter gitlab do forge SDAAL do core continua "costura pronta". Sinal, sem ação.

F13 — l.59: comandos digitados no prompt `!` (bash-mode) rodam FORA do sandbox mesmo em modo estrito (`sandbox.allowUnsandboxedCommands: false`). O maestro usa `!` no core e nos adotantes; em repo com sandbox estrito, `!` é escape declarado. Nota de segurança para a doutrina de sessões compartilhadas na VPS.
