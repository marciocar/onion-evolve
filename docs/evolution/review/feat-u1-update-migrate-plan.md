---
branch: feat/u1-update-migrate-plan
date: 2026-10-21
reviewed_diff_sha256: pendente
reviewed_code_sha256: pendente
tokens: 321968
duration_min: 16
findings_total: 14
findings_real: 8
findings_fixed: 8
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente refutador (só leitura, duas passadas, ~47 chamadas, sandboxes próprios e a cópia pré-migração do hub)
---

# Passada adversarial: `feat/u1-update-migrate-plan`

## O que muda

A fase 2 de D_U1_CAMADA_SDAAL_NO_UPDATE (a migração do corpus ao contrato vendorizado, no `--update`):

- `plan-contract-migration.sh` (novo) usa o `remeasure-contract.sh` como gatilho. Com dívida MUST, roda o `kg_migrate.py plan` do vendor do alvo com o perfil do dono do corpus e grava a planilha fora do alvo. Depois cola no relatório o resumo por ação e por regra, os recusados pelo contrato e a conferência nó a nó contra a dívida medida.
- Sem perfil, orienta pelo exemplo do vendor e sai com rc 2.
- Nunca roda o `apply`. Se a foto do alvo mudar entre antes e depois, sai com rc 5.
- O `remeasure-contract.sh` ganha `ONION_CONTRACT_NODES_OUT` (os nós da dívida em JSON lines), e a frase dele aponta a fase 2.
- O `adopt.md` muda em duas passagens, sem linha a mais.
- A bancada ganha a família `plan_contract_migration`.
- O grafo fecha Q_U1_FASE2_MIGRACAO_CONDUZIDA.

## Achados

**1ª passada (5 REAL, todos curados com caso e mutante):**

1. **REAL, curado.** Sem `sha256sum` no PATH (o macOS não o tem), a foto saía vazia antes e depois e "batia". Um migrador que escrevia num `.kg.yaml` saía com rc 0 e "Nada foi escrito". Agora a foto é feita por `hashlib` do Python, e foto vazia dá rc 3. Caso (f) com PATH sem `sha256sum`, e mutante.
2. **REAL, curado.** Uma planilha pré-existente que fosse symlink para um arquivo ignorado do alvo fazia o migrador gravar nesse arquivo, e o helper saía com rc 0. Agora a planilha é apagada antes do plan e recusada se ainda existir. Caso (h) e mutante.
3. **REAL, curado.** O universo do plano era conferido só pela contagem. `vendor/outra/` (a fase 1 mede, o migrador sempre exclui) e `fixtures/` na raiz (traduzido errado: `**/fixtures/**` contra o fnmatch `*/fixtures/*`) divergiam, e o aviso mandava "conferir a planilha", onde o nó nem aparecia. Agora o glob é `*/**/fixtures/**`, e a conferência é por identidade, com a lista dos nós fora do plano e o motivo. O cabeçalho errava ao dizer que a fase 1 exclui `vendor/**`; foi corrigido. Caso (i) e dois mutantes.
4. **REAL, curado.** Com um `TMPDIR` dentro do alvo, a pasta nascia no alvo antes da recusa. Agora o `TMPDIR` é resolvido e recusado antes de qualquer `mktemp`. Caso (g) e mutante.
5. **REAL, curado.** O comando de `apply` impresso quebrava com espaço no caminho do perfil. Agora sai com `printf %q`. O refutador colou a linha de volta e ela funcionou.

**2ª passada, só nas curas (3 REAL, curados):**

6. **REAL, curado.** Um id repetido gerava um falso "fora do plano": a fase 1 lia `nó X (#2)`, e o plano era um set. Agora o place é lido pela forma do `where()` e os dois lados são multisets. Caso (j) e mutante.
7. **REAL, curado.** Um grafo por symlink gerava outro falso "fora do plano": o migrador registra o caminho real, e a fase 1 registrava o nome rastreado. Agora os dois lados usam o caminho real relativo ao alvo. Caso (j). O mutante não cobre o lado da fase 1, porque a cópia mutante leva o `remeasure-contract.sh` real.
8. **REAL, curado na frase.** A foto não lê o conteúdo de arquivo ignorado (custo de `node_modules`), e a saída dizia "Nada foi escrito no alvo". Agora diz "Nada rastreado nem não rastreado do alvo mudou (a foto não lê o conteúdo de arquivo ignorado)". O teto está declarado no cabeçalho.

**Notas, não curadas (teto):**

- Um perfil não-ASCII sai como `$'…'` no `%q`. Funciona em bash e zsh, não em sh nem fish.
- O `rm -f` da planilha e a gravação do migrador têm uma janela de corrida. O out-dir é do operador.
- TAB ou quebra de linha no id ou no nome de arquivo quebravam a lista de nós da fase 1, que era TSV. Isso saiu de graça com o JSON lines da cura 6, e a foto usa `-z`. Ainda falta o lado da planilha, que é o TSV do migrador.
- O resumo agora conta as linhas de scope para revisão à parte. "com ação e aviso" inclui o rebaixado que tem `then.review`.
- O `--profile` relativo é resolvido contra o alvo, e isso está declarado no cabeçalho.
- Os excludes estão fixos no helper. Um vendor futuro que mude o `DEFAULT_EXCLUDE` do gate é pego pela conferência por identidade, que nomeia o nó.

## O que o refutador tentou e não derrubou

- `--out-dir` como symlink para dentro do alvo, relativo, inexistente, igual ao alvo ou com prefixo parecido.
- O mapeamento dos rc: traceback, rc 2 do migrador, perfil fora do schema, dois perfis, vendor 4.9.1 e frase ausente no rc 1 da fase 1.
- O mutante plan→apply: a foto pega, com rc 5.
- Os números do grafo: 12.131 arquivos, 1.024 nós, classe 1023/1024 e locality 1021/1021, reproduzidos pela planilha dele.

## Dogfood

- **Cópia descartável do hub em 606d6941b** (`git archive`; o repo do hub não foi tocado), com o vendor trocado pelo 4.13.0 do core, como o merge do `--update` faria:
  - com o perfil de exemplo do vendor ajustado aos 3 ids e ao glob de pesquisa do hub: rc 0, 1.024 nós (1.021 propostas, 2 rebaixados, 1 para revisão), "o plano cobre, nó a nó, os 1024";
  - contra a migração à mão f3738f4aa: classe igual em 1.023 de 1.024 e locality igual à HEAD em 1.021 de 1.021. A divergência é a já conhecida da 3ª passada sobre o migrador (`C_D16_NOT_IMPLEMENTED`, trace `apps libs`);
  - com o exemplo cru: 1.007 de 1.024, a medida de por que o helper não copia o exemplo;
  - sha256 dos 12.131 arquivos igual antes e depois, sem `__pycache__`.
- **Depois do rebase sobre a main**, que subiu o vendor para 4.13.1: os mesmos números (1.024 nós, 1023/1024 e 1021/1021) e o sha256 igual. Um mutante (o `-B` do plan) ficou equivalente porque o `kg_migrate.py` 4.13.1 já liga `sys.dont_write_bytecode`. Foi retirado, com a razão escrita na bancada.
- **Sem perfil:** rc 2, com a orientação.
- **Com o vendor 4.9.1:** rc 3, NÃO MEDIDO ("não traz o tools/kg_migrate.py").
- **O core:** rc 2, sem perfil.
- **Bancada `plan_contract_migration`:** 26/26 (10 casos, 16 mutantes), e `remeasure_contract` segue verde.
