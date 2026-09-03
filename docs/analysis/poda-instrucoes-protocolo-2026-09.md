# Poda de instruções — opção C re-especificada: protocolo (rascunho 2026-09-03)

## Pré-requisito RESOLVIDO (tier 10: binário 2.1.259, `strings`)
`InstructionsLoaded` payload = base (session_id, transcript_path, cwd, prompt_id?) + `file_path`, `memory_type` ∈ {User, Project,
Local, Managed}, `load_reason` ∈ {session_start, nested_traversal, path_glob_match, include, compact}, `globs?`, `trigger_file_path?`,
`parent_file_path?`. Registra CARGA e motivo; NÃO registra influência. Logo: o hook mede cobertura (L1); comportamento exige replay (L2).

## L1 — censo de carga (mecanismo, barato)
Hook `InstructionsLoaded` → `.claude/hooks/instructions-loaded-log.sh` → append em `.claude/sessions/instructions-loaded.jsonl`
(ts, session, file_path relativo, memory_type, load_reason, trigger_file_path). Sem veto (exit 0 sempre). Projeção
`kg`-style: por arquivo, contagem por load_reason em N sessões. Candidatos à poda = arquivos que só carregam por
`session_start` (sempre) mas cujo conteúdo é doutrina de escopo (deveria ser `path_glob_match`) e arquivos que nunca
aparecem (`paths:` que não casam nada). Gatilho de leitura: 20 sessões ou 14 dias.

## L2 — replay de comportamento (dirigido pelo L1)
Para cada instrução candidata I (seção do CLAUDE.md ou trecho de skill sempre-carregada):
- K = 5 casos reais do diário/grafo onde I deveria ter mudado o comportamento (ex.: E_claude_md_has_control: seção
  "Dogfood é o padrão master" carregada e o caso C1 falhou).
- Rodar headless (`claude -p`, sessão nova) 2× por caso: com I e sem I (CLAUDE.md variante em worktree), em 2 tiers:
  maestro (Fable) e subagente (Sonnet). Juiz opus/high julga se o resultado difere no que I prescreve.
- Veredito por I: se em NENHUM tier o comportamento muda → I sai (com nó REFUTES); se muda só num tier → fica com
  comentário "por que existe" e tier onde vale; se muda nos dois → fica.
- Custo estimado: por I: 5 casos × 2 variantes × 2 tiers = 20 runs + 20 julgamentos ≈ 400–800k tokens; 8 candidatas ≈ 5M.
  Só roda após o L1 apontar candidatas — nunca varredura global (é a lição do mutation testing).

## O que NÃO se faz
Podar por contagem de linhas; medir "carga" como se fosse influência; podar sem o comentário "por que existe" na instrução
que fica (a próxima deleção tem de ser decidível).
