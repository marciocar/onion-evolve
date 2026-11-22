---
branch: feat/agent-colors
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: b9ed225af7550ca40c190b18c11cc29a8329c0823ce99bc8d879e7128c49476a
reviewed_code_sha256: 880995d18ffcb4d30bdb7df70e9821c267e892f39a3e842d61f90d425d45bd94
findings_total: 5
findings_real: 5
findings_blocking: 0
tokens: 166387
duration_min: 22
findings_fixed: 4
verdict: APPROVED
elenxo: true
reviewer: "subagente general-purpose (opus), refutador independente, só leitura"
nota: "Refutador com mandato de achar falso positivo; aprovou sem bloqueio. Curei 3 limites no código (sem name: não é julgado, diretório ilegível vira rc 2, citações de REGRA com título) e declarei 2 no TETO (formas raras de YAML e --only julgando a árvore). O 5º, estilo, também curado."
---

# Passada adversarial: `feat/agent-colors`

## O que muda

- **SSOT** `.claude/validation/agent-colors.tsv`: a paleta que o Claude Code aceita (8 valores, doc sub-agents
  lida em 2026-11-22 e binário 2.1.330) e a cor de cada uma das 9 categorias. git e deployment dividem o `orange`,
  a 1ª opção da proposta da curadoria.
- **Os 51 agentes** com a cor da categoria: 38 mudaram (7 fora da paleta, 1 sem a chave, 30 trocadas).
- **Guarda** `.claude/validation/agent-color-check.sh` (molde: `agent-frontmatter-keys-check.sh`), com `--selftest`
  de 31 casos, e a **REGRA 122 (Cor de agente presente, na paleta do Claude Code e igual à da categoria)** no
  lint: HARD na fonte, com passivo zero, e SOFT no adotante e na porta.
- **Molde** do `@agent-creator-specialist`, **template** de agente e `/meta:create-agent`: a cor sai da categoria.
  Os templates rápidos do molde perderam `maroon` e `black`, e as linhas `related_commands: […]autonomy:`
  coladas foram separadas.
- **Bancada** `run_agent_color_selftests` e grafo `docs/evolution/research/guard-agent-color-2026-11/`.

Os `confirmed` do grafo novo foram conferidos contra o que o PR propõe:
- `E_PALETA_DOC_E_BINARIO_2_1_330`: a paleta do `.tsv` é a mesma.
- `E_CORES_FORA_DA_CATEGORIA_1122`: o refutador re-mediu os 38 de 51.
- `E_BANCADA_AGENT_COLOR`: re-rodada depois das curas.

## Achados

1. **LIMITE, declarado no TETO.** Estas formas são cor válida para o Claude Code, e o juiz as acusa:
   - alias de âncora;
   - tag `!!str`;
   - escape;
   - bloco `>-` ou `|-`;
   - mapa indentado.

   O refutador mediu isso com o leitor do Claude Code reconstruído em bun, em 30 formas de frontmatter. Nenhum agente real usa essas formas.
2. **LIMITE, curado.** Um frontmatter sem `name:` era julgado, e o Claude Code descarta esse arquivo. Agora ele não é julgado. Casos novos no selftest: "frontmatter sem name:" e "name: vazio", cada um com mutante.
3. **LIMITE, curado.** Um diretório ilegível saía com rc 0 e "0 agente(s)". Agora uma sonda do `find` devolve rc 2. Caso (f) novo na bancada. O mutante foi plantado por `ops/mutate-and-restore.sh` e morreu (helper rc 1).
4. **LIMITE, declarado no TETO.** Com `--only` num agente, a guarda julga a árvore inteira, igual à REGRA 102.
5. **ESTILO, curado.** O texto atribuía a chave duplicada à REGRA 17. Agora diz que nenhuma regra a acusa, e as REGRAS 1 e 23 aparecem com o título.

O que o refutador suspeitou e não se confirmou: na leitura de BOM, CRLF, aspas, comentário, chave entre aspas e fecho com tab, o juiz bate com o Claude Code. O `---` no meio do frontmatter é coberto pela REGRA 102 (Chave de frontmatter de agente pertence à allowlist (oficiais + as da casa)): ela o acusa como FECHO-AMBIGUO.

## Mutantes

- A bancada tem 29 mutantes na cópia da guarda, um por caso do `--selftest`, e exige o ✗ do caso nomeado. Mutante que não se aplica conta como falha.
- Na 1ª rodada, 3 mutantes não morderam, e os três defeitos estavam nos casos:
  - "fecho com tab" e "sem frontmatter" não tinham conteúdo depois do fecho que denunciasse o corte;
  - o caso "derivado" esperava o nome errado.

  Curei os casos, e os mutantes dos dois primeiros também morreram pelo `ops/mutate-and-restore.sh`.

## Limites declarados

- A paleta vale para 2026-11-22 (doc e binário 2.1.330). Uma cor nova do Claude Code é acusada até entrar no `.tsv`, e o `/meta:cc-update` reconfere.
- A categoria vem do diretório. A coerência com o campo `category:` é da REGRA 23 (Frontmatter: category: em agentes (a metade 'model: em comandos' foi REVOGADA pela REGRA 71)).
- Ficam fora agentes de plugin, de usuário e do `--agents` JSON. A doc diz que este último ignora `color`.
- O template e o molde têm cópias legíveis do mapa. O caso (t) da bancada as compara com o `.tsv`.
