# Onda O7: veredito do juiz independente (SAC-73)

> **Papel:** juiz. O mandato é refutar, e na dúvida o veredito é REPROVADO. O juiz não escreveu a proposta, não edita
> grafos e não abre PR.
> **Base:** branch `feat/provenance-wave-o7` sobre `1dd84a1a`, com a O6 aplicada.
> **Planilha:** [`o7-juiz.csv`](o7-juiz.csv), com **93 linhas**: as 92 do proponente e 1 omissão. Uma linha por (nó, campo),
> com as colunas `id, grafo, campo, proposta_original, veredito, proposta_final, valor_final, motivo, confianca`.
> O `valor_final` segue a convenção da O6/O7 (`label: … · narrative (acrescentar): …`).

## Concordância

| | Linhas |
|---|---:|
| APROVADO | 75 |
| CORRIGIDO, sobre linhas do proponente | 17 |
| CORRIGIDO, omissão nova | 1 |
| REPROVADO | 0 |
| **Total** | **93** |

- **Concordância com o proponente:** 75 de 92 linhas, ou **81,5%**.
- **Os 61 labels condensados (variante A)** eram o foco. Saíram **47 aprovados** e **14 corrigidos**:
  - **11 são defeito de fidelidade** na condensação: linhas 0, 2, 3, 23, 27, 42, 48, 67, 73, 75 e 82. São 18% dos 61.
  - **3 têm outra razão:** o 50 é segredo e foi aplicado, o 76 é o marcador e o 84 é cosmético.
- **Os 9 scrubs curtos** (confiança 0.85, "afirmação idêntica") foram todos aprovados.
- **As 6 linhas dos itens selados da O6** foram todas aprovadas, com a conferência abaixo.
- **Nenhum REPROVADO.** Todo defeito achado tinha correção derivável do label antigo, sem regra nova.

## Padrões de erro

1. **A condensação tira a ressalva de certeza e fortalece a afirmação** (linhas 2, 23, 48 e 0). É o padrão dominante:
   - "dezenas de sessões" perde o "(número de 09-02, não re-medido)", que o próprio `verified_against` do nó confirma;
   - "um convidado leu o .env de produção" perde "só contas de teste existiam" e o resíduo (bwrap ausente);
   - "FECHADO" perde a ação pendente do maestro;
   - o gatilho perde o ramo "OU a próxima onda de guardas".

   O label curto **afirmava mais** que o longo. Isso é a `worst-truth-is-uncertain` acontecendo dentro de uma
   migração que não devia mexer em semântica.
2. **A condensação afirma o que o antigo negava ou não dizia** (linhas 3, 27, 67 e 75):
   - "provado por /catch-up", quando o próprio label desmentia essa prova;
   - "conclusões voltam a valer", quando o antigo só dizia que a ressalva deixava de valer;
   - "crontab do root", conta inventada;
   - "achado ao medir uma cópia em /tmp", quando foi exatamente essa medição que errou.
3. **Id de nó truncado** (linha 73): `Q_A2A_SPAWNSYNC` não existe. Referência a nó tem de ser o id inteiro.
4. **O gerador aninha os marcadores ⟨⟩** (linhas 39, 53 e 85): `⟨histórico em ⟨…⟩ (pin⟩`. O par externo marca como
   editado um texto verbatim. A correção deixa só o par interno; o texto e as descrições estão certos. No
   `E_HISTORICO_DO_REGISTRO_DOS_ADOTANTES` (8931 car.), o diff confirma que **só as 2 regiões de caminho mudam**: o
   resto está preservado, como pede o item 9.
5. **A recomendação do gmill inventava nomes** (linha 82). O proponente trocou o nome privado também no domínio
   público, no vhost versionado, no compose de deploy e na entrada do `pass`. Com isso surgiram
   `hub-operacoes-enterprise.onionevolve.com` e `ops/caddy/conf.d/hub-operacoes-enterprise.caddy`, que não existem.
   Conferi: no repo só existe `ops/caddy/conf.d/gmill.caddy`. O selo diz que o domínio e o arquivo de deploy ficam,
   então eles voltam verbatim. Só a sessão, o nome da demo e a entrada do `pass` viram ⟨descrição⟩ com o id.
6. **O mesmo caminho recebe dois tratamentos** (linha 76): o `/dev/null` do curl de aceite ia ser marcado como `receita`,
   mas o mesmo `/dev/null` no `F_ID_1` foi descrito ("apontando ao dispositivo nulo"). A REGRA 2 selada manda descrever
   cada caminho do label anterior, então a correção descreve e tira o marcador.
7. **A omissão vem da regex, não do proponente:** `E_ASSIMETRIA_DE_PERMISSAO_DIR`
   (`claude-code-2.1-onion-2026-08`) tem `` `Read(//home/marcio/**)` `` no label, um caminho do `settings.local.json`
   deste core. O `ABS_FS_RE` exige que o caractere antes de `/home` seja espaço ou pontuação, e na barra dupla ele é
   `/`. Entrou como CORRIGIDO pela variante A, com o label antigo de mais de 280 caracteres.

**Defeitos menores, sem linha própria.** A regra é não corrigir só por cosmética; onde a linha já foi corrigida por
outra razão, o defeito foi consertado junto.

- A preposição gerada ("o .env **de o** clone", "existem SO **em o** clone") aparece em várias narratives. Foi
  consertada só na linha 2, que já estava corrigida.
- Os ⟨⟩ às vezes envolvem palavras vizinhas não editadas (por exemplo, "⟨NAO cria o marcador…⟩" no
  `E_LIVEPATCH`). Os limites ficam imprecisos, mas o conteúdo está correto.

## A conferência do segredo (`Q_ARANDEK_SEGREDOS_E_BINDS_NO_COMPOSE_COMMITADO`)

O valor foi medido **sem ser impresso nem gravado**. Ele era extraído do label vivo num pipe, e só contagens saíam.

- **O valor inteiro** (20 caracteres) aparece 0 vezes no `o7-proposta.csv`, 0 no `o7-resumo.md` e 0 neste
  `o7-juiz.csv`.
- **Fragmentos:** nenhum fragmento de 12 caracteres ou mais casa. Os fragmentos curtos que casam são coincidência com
  texto comum do corpus: o contexto foi conferido com o fragmento mascarado, e nenhum deles é cópia do valor. Qual texto
  coincide fica de fora de propósito, porque nomeá-lo revelaria parte do valor.
- **No corpus rastreado** (`.kg.yaml`, `.md`, `.csv`, `.yaml`, `.json`, `.jsonl`), o valor vive em **um único lugar**:
  o label desse nó. A linha 162 do mesmo grafo (`I_SEGUNDO_IDP…`) cita o `requirepass` sem o valor.
- **Os outros 4 segredos** (LANGFUSE e MINIO) sempre estiveram só nominados, sem valor.
- **A linha 50 deixa de ser `ao-maestro` e é aplicada (CORRIGIDO).** A REGRA 6 está selada. O label condensado é
  fiel, e a narrative traz "o `--requirepass` (valor omitido) na linha 60".

## Itens selados da O6, conferidos

| Item | Nó | Conferência | Veredito |
|---|---|---|---|
| 1 | `E_MEDIDO_LOCAL_TIER10…`, `E_OBJECAO_EXIT2…` | `npm view @anthropic-ai/claude-code@2.1.259` e `@2.1.286` devolvem a versão (2026-10-10); a forma é `binário do Claude Code <versão>` | APROVADO |
| 2 | `E_GRANAAI_DOCTRINE` | ver abaixo | APROVADO |
| 3 | `E_SKILL_INSTALL…`, `E_F4_CLAUDE_JSON…` | o `~/` está na citação verbatim de terceiro: a página do jev e a l.7 do CHANGELOG oficial. Os labels são paráfrase e são reescritos à parte | APROVADO |
| 4 | `E_lid_addressing_root_cause` | o locator troca `onion-vps-waha@` (pasta) por `onion-waha@` (remoto `marciocar/onion-waha`) e ganha a ressalva do sha posterior (2026-08-02T23:22Z contra o nó de 08-01) | APROVADO |

**Item 2, a divergência 07-17/07-18, confirmada.** O `git log --follow --diff-filter=A` mostra:

- `80dcfc71` (2026-07-17T13:25Z) criou só o `kg-radar-falso-verde`;
- `00e9ac24` (2026-07-18T12:38Z) criou os outros 3.

Os 4 têm `from: granaai`, e nenhum mudou desde o sha citado, o que confirma a cópia fiel. O `_processed` do clone do
adotante tem só `.gitkeep`, então vale o ramo "original extinto". **Ressalva:** "nenhum sha é posterior ao nó" só vale
na granularidade de data. O `00e9ac24` é do mesmo dia do `verified_at` (07-18), e a hora do nó não é conhecida.

## Busca própria (a omissão)

**Universo:** 139 `.kg.yaml` rastreados, sem `/fixtures/` e sem os 3 `--exclude` do `onion-validate.yml`. A busca
percorreu todos os campos de todo nó, em qualquer profundidade.

**Varredura estrita** (o `ABS_FS_RE`, `~<conta>/` e o hostname): 92 acertos em 82 nós. Todos estão na planilha ou
fora por desenho:

- `E_m3`, já marcado como `receita`;
- `E_SKILL…` e `E_F4…`, cobertos pelo marcador do item 3;
- `~abril/` em `E_QUOTA_GAP…`, que é aproximação, não home de conta.

**Varredura frouxa** (o prefixo de sistema em qualquer posição, `~<x>/`, `marcio/`, `onion/onion-`), para achar o que a
regex não vê:

- **1 omissão real:** `E_ASSIMETRIA_DE_PERMISSAO_DIR`, com a barra dupla `//home/marcio`. Entrou como CORRIGIDO.
- **7 campos com o idioma de shell** `2>/dev/null` ou `--//dev/stdin`, todos em label e um também em narrative. Vão
  ao maestro (item A4), porque o tratamento muda conforme o caractere anterior.
- `docs/discussions/onion-pessoal-marcio/…` em source, locator e trace: é caminho **relativo do repo**, não de máquina.
  Vai ao maestro (item A6).

**Fora de nó:** o `meta.note` do `bridge-produto-2026-08` (F-O7-3 do proponente), confirmado. As `edges` estão limpas.

## Itens para o maestro

- **A1. Variante A ou B.** Dos 61 labels condensados, 11 tinham defeito de fidelidade, e o padrão é sistemático:
  condensar tira ressalva. A variante A funciona **com juiz linha a linha**. A B não tem esse risco, mas exige que a
  ferramenta aceite label acima de 280 quando ele já era longo. Os dados estão aqui; a decisão é do maestro.
- **A2. O segredo do arandek.** O valor sai do grafo com esta onda, mas **segue no histórico git do core** (e no do
  adotante). Avisar o adotante, pedir a rotação e decidir se o histórico do core é reescrito são atos do maestro.
- **A3. Os ids com gmill.** O selo diz que "labels e ids usam o id", e **4 ids de nó** carregam o nome privado:
  - `E_gmill_demo_route_caddy`;
  - `E_GMILL_VEREDITO_DOS_TRES_FALSOS_POSITIVOS`;
  - `Q_GMILL_FALSOS_POSITIVOS_SEM_TRIAGEM`;
  - `Q_GMILL_MAIN_DIVERGIU`.

  Renomear id exige reescrever as arestas, e nenhuma ação da ferramenta faz isso hoje. Fica para uma próxima onda.
  Além disso, a guarda de nome privado do gerador recusaria o `valor_final` da linha 82, porque o domínio e o
  `gmill.caddy` ficam verbatim pelo selo. A ferramenta precisa da exceção selada.
- **A4. O idioma de shell com o dispositivo nulo** (`2>/dev/null`, `--//dev/stdin`), em 7 campos. O `ABS_FS_RE` não o
  pega, porque o caractere anterior é `>` ou `/`. A O7 descreveu o `/dev/null` precedido de `=` (F_ID_1) e de espaço
  (Q_SITE, nesta correção). Falta selar uma regra única: ou o dispositivo de sistema dentro de receita de comando não é
  caminho de máquina, ou ele é sempre descrito.
- **A5. F-O7-2 resolvida por medição.** O `/usr/bin/grep` é o **GNU grep 3.11** (binário de 2024-04-08, anterior a
  09-04), e o ugrep é a função da shell interativa. Logo o `E_CAUSA_ABERTA_LEITOR_MULTITHREAD_0904` erra ao dizer
  "ugrep 7.8.4 (multi-thread, /usr/bin/grep)", e a causa que ele afirma (o leitor multi-thread) fica em dúvida para os
  scripts. A O7 só preserva a redação antiga. O nó é candidato a `/meta:kg-freshness`.
- **A6. O alcance da REGRA 5 em caminho relativo do repo.** O `docs/discussions/onion-pessoal-marcio/` carrega a
  substring `onion-pessoal` em source, locator e trace, e é o grosso dos 13 provenances do F-O7-1. Ele é nome de pasta
  **do core**, não a pasta do adotante. Decidir se a regra o alcança.
- **A7. A guarda P3.** O `ABS_FS_RE` deve ganhar duas formas:
  - a barra dupla (`//home`, `//etc`…), que a sintaxe de permissão do Claude Code usa;
  - a forma `~<conta>/`, como o proponente já propôs, sem casar `~abril/`.

## Achados

- **J-O7-1.** A cegueira à barra dupla do `ABS_FS_RE` produziu a omissão desta onda (ver A7).
- **J-O7-2.** Nove sources do `librechat-2026-08` e do `vps-shared-tools-2026-07` usam `onion-vps-librechat@sha`. Esse
  repo **não tem remoto** (`git remote -v` vazio, 2026-10-10). Alguns nós declaram "repo local sem remoto alcançável",
  outros não. Está fora do mandato P6 e é candidato à próxima onda.
- **J-O7-3.** O F-O7-4 (o `I_CONSOLE_DO_LOGTO` afirma "ATIVO" e a O6 mediu `.disabled`) segue de pé. A O7 não muda a
  afirmação, e isso está correto.

## Tetos

- **Fidelidade:** foi julgada contra o label antigo e, onde havia, contra outros campos do mesmo nó. Não reli as fontes
  primárias de cada um dos 61 nós.
- **O `compose.gmill.yaml`:** não foi achado na raiz do clone do adotante. Fica verbatim por ser o arquivo de deploy
  nomeado no texto.
- **Os shas do item 4:** não conferi no `gh api`. O juiz da O6 os conferiu. Os do item 2 conferi no git local.
- **A varredura frouxa:** usa um vocabulário fixo de prefixos. Caminho de máquina sem nenhum desses prefixos e sem `~`
  escaparia.
