# O3 onda 1: proposta do proponente (2026-10-09)

Esta é a projeção da proposta da onda 1 da O3 (SAC-73, `Q_MIGRAR_CORPUS_PARA_CONTRATO_V3`), feita
sob as políticas de `D_POLITICAS_DA_MIGRACAO_DE_PROVENANCE` e o modo de selo da O3. **Nada foi
aplicado nos grafos.** A próxima etapa é um juiz independente refutar esta planilha, e só depois
vem a aplicação determinística. Todo flip de status passa pelo selo do maestro.

## Partição em ondas (`o3-waves.tsv`)

O universo `o3-universe.tsv` tem 828 nós em 113 grafos. Ele foi dividido em 3 ondas por grafo
inteiro, com LPT guloso: do maior grafo para o menor, cada grafo vai para a onda de menor carga.
O resultado é **276 / 276 / 276** nós, com 37, 38 e 38 grafos. A onda 1 tem 37 grafos e 276 nós.

## Contagens da onda 1 (`o3-wave1-proposta.csv`)

| proposta | nós |
|---|---|
| corrigir | 241 |
| testemunho | 25 |
| dev-óbvio | 6 |
| rebaixar | 4 |
| dev-dúvida | 0 |

Por status e plano:

| status | plano | corrigir | testemunho | dev-óbvio | rebaixar |
|---|---|---|---|---|---|
| confirmed | DEV | 131 | 6 | — | 2 |
| confirmed | PROD | 86 | 11 | 1 | 2 |
| done | PROD | 8 | 2 | 1 | 0 |
| open | PROD | 7 | 0 | 4 | 0 |
| superseded | PROD | 5 | 6 | 0 | 0 |
| refuted | PROD | 4 | 0 | 0 | 0 |

Classes de `method` nas 266 linhas com fonte: leitura 133, juízes 57, medição 44, testemunho 25,
derivado 7.

**Flips de status propostos: 4.** Todos são `confirmed → unverifiable` (rebaixar). Os 6 dev-óbvio
mudam o **plano** (PROD → DEV), não o status. Nenhum nó não-confirmed foi rebaixado.

## Como foi feito

Seis workers trabalharam em paralelo, cada um com cerca de 46 nós de grafos inteiros. Cada worker
recebeu o nó completo e as políticas seladas, e abriu a fonte candidata: o arquivo irmão do grafo
(SYNTHESIS, NOTE-*, H*.md, `data/wf_*.json`), o commit ou PR com `git show` e `gh`, os clones dos
adotantes em `/home/marcio/<repo>`, os journals `wf_*` no host e as URLs com `curl`. A consolidação
conferiu que há 276 linhas, sem duplicata e sem nó faltando, que cada `method` está em
`<classe>: <detalhe>` e que dev-* só aparece em PROD.

O proponente aplicou uma correção à saída dos workers. Cinco nós cuja única fonte é um journal
`wf_*` fora do git, no host, passaram de `corrigir` para `testemunho` com
`testemunho: leitura do arquivo <x> no host`, pela política 7. São eles:
`E_LACUNAS_DECK_PATTERNS_0924`, `E_MERCADO_DECK_PATTERNS_0924`, `E_LACUNAS_CORPUS_DE_REGRAS_1001`,
`E_LACUNAS_EIXO_D_2026_10` e `E_MERCADO_OCR_LOCAL_0908`.

## Por que tão poucos rebaixamentos

A heurística do `bucket` previa muito mais rebaixamentos: 53 nós `U:vazio` e 18 `U:prosa` na onda.
Na prática, quase todos os grafos desta onda são pesquisas com **arquivos irmãos versionados**.
São esses arquivos que sustentam os labels:
- 36 claims `C_H*` do `scope-inheritance` são o começo, truncado, da nota da tabela de verificação
  adversarial dos H1–H4. Viraram `juízes`, com arquivo e linha.
- `interface-state-of-art` tem as notas NOTE-00 a NOTE-06.
- `colaboracao-onion` tem os sinais em `docs/evolution/inbox/_processed/` e o diário e a KB do
  adotante no clone, em commit fixo.
- `onion-doctrine-elenxo-bulbo` tem o rascunho em `docs/analysis/`.

A dica da O1/O2 dizia "sem fonte" porque olhava só `verified_against` e `trace`, sem abrir o
diretório do grafo.

## Casos difíceis (para o juiz olhar primeiro)

1. **4 nós `E_R3_TST_*`** (compartilhamento, confiança 0,55). A proposta é `corrigir` com classe
   juízes, com base em `data/wf_44d33784-fe6-return.json`: o ancorador marcou ANCORADA citando o
   item da ementa. Mas **o acórdão do TST segue sem localizador**: o processo não está registrado,
   e o RR-21162 do dossiê é o caso das câmeras. Se a regra "citação sem localizador não é fonte"
   for aplicada à risca, os 4 viram `rebaixar`.
2. **Lacunas com contagem divergente do journal.** O critério aplicado foi: se o **label** carrega
   o número errado, rebaixar; se o erro está só no `verified_against`, a fonte sustenta o label.
   - `E_LACUNAS_INFRA_VPS_1005` vai a `rebaixar` (0,55). O label diz 33 fontes e 26 claims, mas
     esses números são `budgetDropped` e `notVerifiedByBudget`. O journal versionado registra 15
     fontes e 51 claims, e o Elenxo tem 27 sobreviventes, não 12.
   - `E_LACUNAS_DECLARADAS_OCR_0908` vai a `rebaixar` (0,80), pelo mesmo padrão, que a própria
     SYNTHESIS já apontava.
   - `E_LACUNAS_CORPUS_DE_REGRAS_1001` vai a `testemunho` (0,60): o erro está só no
     `verified_against`.
   - `E_LACUNAS_DECK_PATTERNS_0924` vai a `testemunho`: o nó declara a divergência e não a
     harmoniza.
3. **Testemunho de medição sem comando** (política 2): `E_FRAGMENTACAO_NAO_ABSORCAO` (0,50),
   `E_LACUNAS_DECLARADAS_PODA_0903` (0,55) e `E_MD_PICO_APRESENTADO_COMO_REGUA` (0,55). A origem
   (sessão e data) é explícita, mas os números só existem no próprio grafo, ou a fonte terceira
   (trendshift.io) devolveu 403. Estes são os candidatos mais fortes a virar `rebaixar` na dúvida.
4. **`E_MERCADO_OCR_LOCAL_0908`** (0,55). O journal confirma o núcleo: nenhuma claim confirmada é
   de capital. Mas "nenhuma sobreviveu aos votos" é impreciso, porque houve claims de mercado
   cortadas por orçamento antes do voto.
5. **Fonte de host mutável.** `E_O_GATE_DO_ADOTANTE_ESTA_INERTE_EM_4_DE_6` e
   `E_O_CORPUS_NAO_TRANSFERE_E_METADE_DA_CULPA_E_NOSSA` estão como testemunho e têm o corpo do
   commit datado, mas o estado dos adotantes mudou depois da cura. `E_ESTUDO_SO_O_SHLEX_EXISTE_EM_TODO_LUGAR`
   está como `corrigir` com classe medição, re-medida hoje no host: a fonte é o ambiente, não um
   arquivo, e o juiz pode querer `testemunho`.
6. **Testemunho que se apoia em corpo de commit da sessão.** São 5 nós do `m2-bridge-logto`, 4
   deles `superseded`. O corpo do commit registra a observação da própria sessão, com o link
   Claude-Session. Pela política 3, isso é mais do que "quem escreveu o nó", mas fica na fronteira.
7. **dev-óbvio em nós `open` de risco** (`Q_RISCO_*`, `Q_TENANT_WRITE_DESTINATION`) e em decisões
   de desenho (`D_TRIADE_MCP_POR_EIXO`, `D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION`). Eles
   descrevem hipótese ou desenho, não o sistema vivo. A alternativa seria rebaixar, e isso mudaria
   o status de `open` e `done`.
8. **Achados laterais, que não mudam a proposta:**
   - `C_V1`: o nó e o commit dizem 71 SKILL.md, mas o arandek tem 70.
   - `E_GAP3_FP`: a dica de "caminho sumiu" é falsa; o arquivo existe no arandek, l.178.
   - `ENT_KB_CORE`: o label diz "não mesclada", mas a KB foi mesclada no mesmo dia (`0dcacbb1`).

## Tetos

1. **O proponente não é o juiz.** As 276 linhas foram escritas por 6 workers da mesma família de
   modelo, com as mesmas instruções. A confiança é autoavaliada. O juiz independente é a etapa que
   falta.
2. **"Sustenta o label" foi julgado por leitura, não por métrica.** Em vários `C_H*` o label é a
   nota truncada, e o casamento foi lexical na própria linha. `E_F8_CORR` é paráfrase.
3. **URLs medidas uma vez**, em 2026-10-09, sem re-medição. trendshift.io devolveu 403 (Cloudflare),
   e o site do Hyper não contém "YC P26".
4. **Journals no host** (`/home/marcio/.claude/projects/…/workflows/`) não viajam com o repo. Por
   isso viraram testemunho (política 7), e o juiz só consegue reabri-los nesta máquina.
5. **Commits de adotante** (`gustavo-pulga@…`, `onion-standalone@…`, `onion-vps-logto@…`,
   `onion-bridge@…`) dependem dos clones locais em `/home/marcio/`.
6. A partição usa contagem de nós como proxy de esforço. A onda 1 concentrou grafos de pesquisa com
   irmãos ricos, e as ondas 2 e 3 podem ter taxa de rebaixamento bem maior.
