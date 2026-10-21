---
branch: fix/co-relay-core-proof
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: c5c271a4a9277928f527dd14b0fda75faf3120dde9fa4c260806020c417abe93
reviewed_code_sha256: a406fffbfc47d751f6f117f539b00dda391455292b4ad91decd845787a94f517
findings_total: 10
findings_real: 4
tokens: 105104
duration_min: 4
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente refutador (general-purpose), só leitura, com fixtures descartáveis e as versões históricas do onion-version.sh
nota: "achados 2 e 3 são limite declarado no helper, não cura"
---

# Passada adversarial: `fix/co-relay-core-proof`

## O que mudou

O `co-relay.sh` tratava todo repo git sem carimbo `.claude/.onion-version` como o core
(`Q_CO_RELAY_SEM_CARIMBO_E_O_CORE`). Agora, no ramo sem carimbo, a função `_core_proof` **lê** o
`.claude/validation/onion-version.sh` do destino (não o executa) e exige que ele diga `role: source`:
a saída `role: source` literal, ou `role: ${role}` com todo default de coluna 0 `role=` igual a `source`.
As fixtures de core da família `corelay` deixaram de ser um `git init` vazio, que era o defeito escrito
como contrato.

## Achados

1. **REAL (curado):** o core num checkout CRLF era recusado com a mensagem "computa role: source, não
   source", porque o `sed` dos defaults não cortava o espaço final. O corte entrou nos dois `sed`. Caso
   (C5) e mutante (C-M6).
2. **REAL (limite declarado):** um script adulterado passa como core se reatribuir o papel em linha
   indentada (`  export role=hub`, `declare role=hub`) ou imprimir por `echo`/heredoc indentado. A
   leitura confere a forma do script de hoje, não a semântica de qualquer bash. Declarado no comentário
   do helper. Todos os casos exigem um script alterado à mão num checkout que o próprio maestro aponta.
3. **REAL (limite declarado, classe herdada):** uma cópia byte-idêntica sem carimbo (symlink, `cp -r
   .claude`) passa, porque pela definição do próprio script ela computa `source`. Executar não curaria:
   a cópia executada mente igual. O censo local do refutador achou zero casos assim na máquina.
4. **REAL (curado, lacuna de cobertura):** os laços sobre defaults e saídas não tinham caso com dois
   elementos. Um mutante que lesse só o 1º passaria a bancada. Caso (C4), com `standalone` (que ordena
   depois de `source`), e mutantes (C-M4) e (C-M5).
5. **Refutado:** falso recuso do core real ou histórico. HEAD e as versões `d2e9fdd8`, `23ad254a`
   (`role: source` literal), `21842a51` e `b446228a` são aceitas.
6. **Refutado:** os falsos aceites óbvios (`role=hub` em coluna 0 depois do default, `role: ${role}`
   junto de `role: hub`, `${role:-hub}`, arquivo vazio, diretório no lugar do arquivo, ilegível).
7. **Refutado:** regressão nos caminhos de hub, vendor (V1 a V9) e canal lateral. O código novo só entra
   no `else` final.
8. **Refutado:** mutantes vácuos. Cada `sed` muda a linha certa e as fixtures conferem que foram
   aplicadas. O V6 e o V-M5 passaram a cobrar a mensagem `é o dono de vendor/prod`, porque o rc sozinho
   virou vácuo (a prova do core também devolve exit 2).
9. **Refutado:** a crítica a ler em vez de executar. Executar rodaria código de outro repo com os
   privilégios da sessão, sem ganhar poder de discriminação (achado 3).
10. **Observação:** a worktree estava 2 commits atrás da `origin/main`; rebaseada antes do PR.

## Mutantes

(C-M1) sem a prova, o repo sem carimbo volta a ser o core. (C-M2) sem conferir o default. (C-M3) sem
ler a forma `role: ${role}`. (C-M4) e (C-M5) só o 1º elemento de cada laço. (C-M6) sem o corte do
espaço final. Família `corelay`: 46 de 46.

## Dogfood

`--dry-run` de um remetente descartável (carimbo `adopted`): o clone defasado do espelho do kg-ssot é
recusado com exit 2 ("não tem .claude/validation/onion-version.sh"), e o checkout do core segue aceito
como CORE. O helper da main aceitava o clone como CORE. Nada foi entregue de verdade.
