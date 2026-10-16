---
branch: feat/chat-isolation-degrau1
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 12
findings_real: 12
tokens: 318101
duration_min: 12
findings_fixed: 10
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose (opus), mandato REFUTAR
nota: "duas passadas do refutador (145058 + 173043 tokens, 7 + 5 min); 2 achados ficam como teto declarado (data/ gravável com o arquivo de convites; rename do .claude da home)"
---

# Passada adversarial: `feat/chat-isolation-degrau1`

## O que muda

O degrau 1 do isolamento do /chat (decisão `D_MAESTRO_DEGRAU1_JA_DEGRAUS_2_3_POR_SPIKE_1016`): o wrapper core-only
`ops/bridge-hardening.sh` renderiza, ensaia, instala e prova o drop-in `30-integrity.conf` do `onion-vps-bridge`.
O alvo entra no `ops/moat-targets.tsv`, o juiz do MOAT fecha o modo de teste e a cópia do wrapper, e o
`update-bridge.sh` chama o `verify` no fim. A bancada ganha a família `bridge_hardening` (25 casos com mutante) e
os casos (b1) a (b5) no `moat_gate`. No grafo entram o selo e três nós de medição (degrau 1 ensaiado, spike 2 e
spike 3).

O grafo editado tem `confirmed` de alto impacto que conferi contra a proposta:
`E_SYSTEMD_PROTECTPROC_HIDES_OTHER_USERS_ONLY` (nenhuma diretiva fecha o environ do mesmo UID; por isso o drop-in
declara que só dá integridade e não guarda segredo), `E_SPIKE2_SOCKET_LAUNCHER_DYNAMICUSER_1016` e
`E_SPIKE3_APPARMOR_SANDBOX_REQUIREMENTS_1016` (nascidos aqui; o degrau 1 não depende deles). Também
`E_OBJECAO_01_ENVFILE_LEAKS_TO_PROCFS_ENVIRON`: é por ele que o drop-in não tem `EnvironmentFile=` e o pré-voo o
recusa no `20-hardening.conf`.

## Achados

1. **ALTA, real, curado.** Protegia só subdiretórios (`src/`, `node_modules/`, `jwks/`…). Com o pai gravável,
   `mv onion-bridge onion-bridge.old && mkdir -p onion-bridge/src` dava uma árvore nova gravável (provado numa unit
   transitória). Cura: as duas árvores inteiras só-leitura (a raiz vira ponto de montagem, então o rename dá EBUSY,
   medido), com `ReadWritePaths=` aninhado nas escritas do serviço. O `check_script` passou a exigir que cada
   caminho SEJA o ponto de montagem. Caso (h24).
2. **ALTA, real, curado.** O `.git/config` e os hooks dos dois repositórios, o `~/.config/git/config` e o
   `package-lock`/`.npmrc` eram graváveis de dentro, e rodam como a conta do serviço FORA da unit, no git e no npm
   do update-bridge, com a chave de deploy e o PAT à vista. Cura: as árvores inteiras cobrem os `.git` e o lockfile;
   `.config` e `.npmrc` viram placeholders só-leitura.
3. **MÉDIA, real, curado.** `docs/onion/federation-orgs.json` e `docs/onion/agent-card.json`, lidos pelo bridge,
   ficavam fora. Cura: o clone inteiro está só-leitura.
4. **MÉDIA, real, curado.** O NOOP saía 0 sem provar que o processo vivo carregou o drop-in. Cura: o NOOP só vale
   com o `verify` passando; senão a execução segue para o restart. Caso (h26).
5. **MÉDIA, real, curado.** O ensaio provava menos do que o nó afirmava: só `tsx --version`, uma contagem errada
   (23, não 24) e um label que o achado 1 refutava. Cura: o ensaio transpila `src/health.ts`; o nó foi reescrito
   e teve a confiança rebaixada (0.85 para 0.8); o strace das sondas fica declarado como medição do scratchpad.
6. **BAIXA, real, curado.** Um symlink num alvo faria o bind seguir o link. Cura: o pré-voo recusa `test -L`.
   Caso (h25).
7. **BAIXA, real, curado.** O `update-bridge` tratava todo rc diferente de 0 do `verify` como reprovação, e o
   motivo sumia. Cura: distingue rc 0, 1 e o resto, e mostra as linhas FALHA.
8. **BAIXA, real, curado em parte.** Se um placeholder falhasse no meio, o anterior ficava sem rollback impresso.
   Cura: os placeholders nascem depois do `rollback()`, com `fail_after`. A outra metade (o modo de teste não
   redireciona a unit nem o `/health`) fica como teto declarado: o juiz do MOAT fecha esse modo na linha de comando.

### 2ª passada (sobre as curas)

9. **MÉDIA, real, curado.** Um symlink num componente do MEIO de uma exceção gravável (`.claude -> .claude-x`,
   `.claude-x/utils -> sessions/utils`) desviava a escrita para o `a2a-verify.sh` com a raiz `ro` (provado numa unit
   transitória; só plantável antes do install). Cura: o pré-voo exige que o caminho resolvido seja o literal
   (`realpath -m`), e o verify confere um a um os arquivos de confiança concretos. Casos (h27) e (h28).
10. **MÉDIA, real, NÃO curado: teto declarado no grafo.** `data/` segue gravável inteiro, e o arquivo de convites
    A2A mora lá. O serviço só o LÊ, mas o agente no mesmo UID ainda cunharia convites. A cura muda o bridge (o
    arquivo num subdiretório só-leitura) ou vem com o degrau 2.
11. **BAIXA, real, curado em parte.** `~/.local/bin` (entra no PATH do `.profile`) e `~/.bash_profile` (vence o
    `.profile` no login) podiam ser criados: viraram placeholders (o `.bash_profile` só encadeia o `.profile`).
    Renomear o `~/.claude` gravável tira o bind dos `settings*.json`. Fica como teto, de impacto baixo porque o SDK
    carrega só `settingSources: project`.
12. **BAIXA, real, declarado.** O ensaio não monta os placeholders, que ficam ausentes até o `--apply`. O verify
    depois do restart é a prova deles.

## Mutantes

Cada caso da família `bridge_hardening` (h1 a h28, sem h7) roda no wrapper intacto e num mutante (a linha que o
caso protege trocada), provado por `_prove_mutation`: 54 passaram, 0 falharam; com o `moat_gate`, 267 passaram. Os casos (b1) a (b5) do
`moat_gate` também passaram, cada um com o seu mutante.

## Limites declarados

- O `--apply` em produção NÃO rodou. Fica com a sessão principal depois do merge.
- O namespace da bancada é simulado por permissão. A fidelidade frente à unit real vem do ensaio no host e das
  sondas em units transitórias, não da bancada.
- Ficaram sem medir: um chat real e um `POST /a2a` com o drop-in ativo, e as escritas de versões futuras do CLI.
- `~/.cache` e `~/.local` seguem graváveis, sem consumidor medido fora da unit.
