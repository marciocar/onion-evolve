---
reviewed_diff_sha256: fe99b23b99f3f45ed5ef65f19f4b4722274b9e294f31b6b3f540f59243504960
reviewed_code_sha256: b48ae34a60499f1d92a6c75d1f17ca31fb9a4e70e521d9b16a2843830526041f
findings_total: 6
findings_real: 6
tokens: 76813
duration_min: 4
verdict: REPROVADO_E_CURADO
elenxo: sim
---

# Resíduo da passada adversarial — `feat/kg-projection-with`

Um revisor novo, só leitura (`branch-code-reviewer`), recebeu o diff e o contrato, sem a conclusão de quem o
escreveu. Ele rodou a família `kg_projection` (18/18) e reproduziu o achado 1 em Python. Veredito: **amarelo,
sem bloqueador**, com dois achados IMPORTANTES, os dois HARD indevido no modo estrito do core. **Todos os seis
foram curados nesta branch** (2º commit), e as curas que mudam veredito ganharam mutante.

## Os achados e as curas

1. **IMPORTANTE: URL só em comentário virava NAO-FIXADO HARD.** A regex varria o texto cru do bloco
   `projection_of`, comentário YAML incluído; o produto lê com `yaml.safe_load` e descarta o comentário.
   **Cura:** as URLs saem do `yaml.safe_load` do frontmatter, a mesma leitura do produto. O sha em maiúsculas
   (que o git aceita) deixou de contar como ramo (`[0-9a-fA-F]`). Casos (n5) e (n6), mutantes m16 e m17.
2. **IMPORTANTE: clone sem o commit dava HARD local que o CI não reproduz.** Com o sha ausente no clone, o
   produto lê a árvore de lá, e um id criado naquele commit saía HARD ID-AUSENTE contra a versão errada.
   **Cura:** o ID-AUSENTE da página que declara uma URL `unpinned` cai a SOFT ("sem veredito firme; busque o
   commit"), e o rc 1 do produto se confere contra os achados dele (`missing`/`graph_errors`), não contra a
   severidade final. A mensagem do NAO-FIXADO diz "sha errado, ou falta `git fetch` no clone". **Fica de pé,
   por decisão do core:** o NAO-FIXADO segue HARD com `--strict`, então o clone desatualizado barra o lint
   local do core (o CI, sem clone, sai SOFT). Hoje nenhuma página do core cita grafo de outro repositório por
   URL. Caso (n4), mutante m15.
3. **MENOR: o par explícito não passava pelo filtro de uso.** **Cura:** o par cujo prefixo nenhuma página
   declara não vai nem avisa, e por prefixo vence o 1º candidato com clone (o explícito sem clone cede ao do
   registro). Casos (j3), (o2), (o3) e (o4), mutante m12.
4. **MENOR: o wrapper só aceita `https://`, e o produto aceita qualquer `://`.** **Cura:** o teto foi
   declarado no cabeçalho. A URL de outro esquema segue FORA-DO-REPO, sem verde calado.
5. **MENOR: casos que provavam pouco.** **Cura:** o (l) compara com a saída esperada, byte a byte, e a saída
   foi medida igual à do wrapper de `origin/main` no mesmo fixture. O m6 agora exige `2|0` e o m7 exige `1|1`.
6. **MENOR: o fixture vazio derrubava a suíte sob `set -e`.** **Cura:** um sha que não tem a forma certa vira
   `record_fail` e limpa os temporários.

## O caso (g) da curadoria

O caso passa na main do core e falha no adotante. A causa é o carimbo: a caixa herdava o
`.claude/.onion-version` com `role: adopted`, e o 1º ciclo rebaixava o HARD esperado. Isso foi reproduzido
numa cópia do worktree com o carimbo da curadoria: com a bancada de `origin/main` deu 9/1 e o (g) falhou; com a
desta branch deu 18/0. **Cura:** a caixa fixa o papel (sem carimbo, julga-se como o core), e um 2º passe como
adotante espera SOFT.

Orquestrado com 🧅 Onion Evolve
