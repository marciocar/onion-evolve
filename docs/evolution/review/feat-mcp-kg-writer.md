---
branch: feat/mcp-kg-writer
date: 2026-10-12
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 3
findings_fixed: 2
tokens: 0
duration_min: 60
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial própria (refutador com default reprovado, sem subagente) + 25 mutantes — gate mecânico: mcp_onion_kg_writer
---

# O chat da casa escreve grafos, e o refutador procurou por onde escrever errado

O PR traz `ops/mcp-onion-kg-writer/`, o MCP de escrita que a decisão do maestro de 2026-10-12 pediu:
qualquer usuário logado escreve só na própria área, e o grafo que reprova na maquinaria é recusado
sem gravar nada. O refutador partiu de "reprovado" em quatro eixos e só mudou o veredito com
medição.

## Achados

1. **Fuga de área entre usuários: não encontrada, provada pela bancada.** O e-mail passa por regex
   (nada de `/`, `..` nem placeholder não substituído) e vira `<local saneado>-<sha256 16 hex>`. O
   `slug` é kebab-case estrito. O `lstat` recusa symlink em cada nível (área, diretório do slug,
   arquivo), inclusive symlink que aponta para DENTRO da própria área, onde o `realpath` sozinho
   aprovaria. O git da área roda com `--git-dir` explícito e `GIT_CEILING_DIRECTORIES`: a bancada
   põe a raiz de dados dentro de um repo pai e confere que ele segue sem commit.
2. **Gravação com o gate reprovando: um caminho achado e CURADO.** Se o `safe_load` do servidor não
   parseava o texto, a conferência `meta.id == slug` era pulada e o veredito ficava com os gates.
   Medido: uma tag `!x` faz o contrato reprovar (`parse.yaml-error`), então não havia gravação real.
   Mesmo assim a cura entrou: `meta.id` não conferível força `REPROVADO`. O mutante dessa linha
   sobrevive pela defesa dupla, e isso está declarado como teto na família. Timeout de gate, gate
   ausente e crash do gate também contam como reprovação, e o caso `gate-timeout-reprova` prova isso.
3. **Execução de conteúdo recebido: não encontrada.** O texto só passa por um `SafeLoader` que recusa
   âncora e alias, contra a bomba de expansão (CURADO na forja, caso `alias-recusado`). Depois vira
   arquivo com nome fixo `<slug>.kg.yaml`, e o slug não pode começar com hífen. O radar não tem
   `system()` nem `getline` de comando (medido por grep). Os gates rodam com env mínimo, `cwd` e
   `HOME` no diretório temporário e `stdin` fechado.
4. **Auth que falha aberto: não encontrada.** Sem token, o servidor não sobe. O `_auth_ok` exige token
   não vazio e compara em tempo constante. `tools/call` exige o e-mail. Raiz de código sem radar ou
   sem contrato, raiz de dados ausente ou symlink, e falta de PyYAML: o servidor não sobe. **Teto
   declarado (aberto, para o maestro):** a identidade é a que o LibreChat declara, e o IdP tem
   cadastro aberto. Pela decisão (1) não há lista de e-mails, então o teto por área (200 × 512 KB)
   limita uma conta, mas não o número de contas. Isso virou o nó `Q_CADASTRO_ABERTO_E_DISCO`.

## Prova

- `LC_ALL=C python3 -I -B ops/mcp-onion-kg-writer/selftest.py`: **28/28**, com servidor real por HTTP.
- `LC_ALL=C bash .claude/validation/lint-selftest.sh --families mcp_onion_kg_writer`: **26/26**, ou
  seja, o harness com a contagem travada mais 25 mutantes plantados por `ops/mutate-and-restore.sh`
  numa cópia do servidor. Cada mutante reprova o caso nomeado.
- Dogfood em `127.0.0.1:38737`, com raiz temporária e a maquinaria deste worktree:
  - `initialize`, `tools/list` (5 tools) e chamada sem token (401);
  - grafo com `type:` no lugar de `edge_type:` e status `aberta`: `REPROVADO`, com 2 linhas ✗ do radar
    e 5 MUST do contrato; `kg_write` não gravou nada e `kg_my_list` voltou vazio;
  - grafo real pequeno: `APROVADO`, gravado e commitado com autor `marcio@grana.ai`. O
    `kg_my_get` devolveu os bytes idênticos.
- O grafo `mcp-kg-writer-2026-10` passa no radar `--integrity --schema` com rc 0 e no
  `kg-contract-check` com rc 0. Fica um aviso SOFT `decision-done-em-DEV`, porque o pedido foi
  `done` em DEV.
