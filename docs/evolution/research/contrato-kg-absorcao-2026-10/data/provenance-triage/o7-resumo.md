# Onda O7: proposta do proponente (SAC-73)

> **Papel:** proponente. Esta onda **não edita grafos e não abre PR**. Um juiz independente refuta depois.
> **Base:** `origin/main` em `1dd84a1a` (2026-10-10), com a O6 aplicada.
> **Planilha:** [`o7-proposta.csv`](o7-proposta.csv), com **92 linhas** sobre **84 nós** em **35 grafos**, uma linha por
> (nó, campo).
> **Regra:** P6-label, selada pelo maestro em 2026-10-10: caminho de máquina (absoluto ou `~/`) sai também de
> `label` e de `narrative`. O acréscimo do coordenador traz os 4 itens da O6 selados no mesmo dia (6 linhas).

**Convenção da planilha** (a mesma da O6):

- `valor_novo` traz o valor **inteiro** do campo depois da troca;
- linhas de vários campos usam a forma `chave: valor · narrative (acrescentar): …`, que o `o6_ops` já lê. A
  chave `label:` é nova, porque a O6 não escrevia label;
- nas linhas `ao-maestro`, `valor_novo` é a recomendação, prefixada por `(rec)`.

## Contagens

| Campo | Proposta | Linhas |
|---|---|---:|
| `label` (+ `narrative`) | `reescrever` | 67 |
| `label` (+ `narrative` + marcador) | `marcar-path-conteudo` | 1 |
| `label` | `ao-maestro` | 2 |
| `narrative` | `reescrever` | 9 |
| `provenance.locator` | `reescrever` | 4 (3 P6 + 1 do item 4) |
| `verified_against` | `reescrever` | 2 |
| `provenance.method` | `reescrever` | 1 |
| `reverify_note` | `reescrever` | 1 |
| `trace` (+ `narrative`) | `reescrever` | 3 (itens 1 e 2) |
| `x_path_is_content` (+ `narrative`) | `marcar-path-conteudo` | 2 (item 3) |

### Universo, medido

Usei o `ABS_FS_RE` do `kg-migrate-v3.py` (l.655) e o hostname da VPS, sobre os **139** `.kg.yaml` rastreados. Saem
os que têm `/fixtures/` e os três `--exclude` do `onion-validate.yml`. Os arquivos foram carregados com PyYAML e
a varredura percorreu **todos os campos de todo nó**, em qualquer profundidade.

| Campo | Nós com acerto | Nesta planilha | Fora, e por quê |
|---|---:|---:|---|
| `label` | 70 | 70 | — |
| `narrative` | 8 | 8 + 1 | +1 é o `C_DRIFT_44_PCT_NA_VPS`, que a regex não pega (achado de classe, abaixo) |
| `provenance.locator` | 6 | 3 | `E_m3` já tem o marcador `receita`; `E_SKILL_…` e `E_F4_…` ganham o marcador do item 3 |
| `verified_against` | 4 | 2 | `E_m3` (marcado) e `E_SKILL_…` (item 3) |
| `provenance.method` | 1 | 1 | o hostname no `ENT_whatsapp` (J-O6-1) |
| `reverify_note` | 1 | 1 | um campo que nenhuma onda olhou: `E_p1p3_provisioned` |

O hostname aparece em 12 valores, espalhados por label, narrative, locator, `verified_against` e method. Os 12
estão cobertos. A varredura fora do nó acha um único caso, o `meta.note` de `bridge-produto-2026-08` (F-O7-3).

Os falsos positivos mapeados (`/meta:*`, endpoints, URLs, globs relativos e `/lib/` em caminho relativo) não
casam com a regex. As rotas do bridge (`/chat`, `/a2a`, `/admin`) e o `/en/` do site também não. Nenhuma linha
foi aberta por eles.

**Guardas do gerador.** O gerador fica fora do commit, porque carrega os literais antigos. Ele recusa a linha em
cinco casos:

- a substituição não casa por substring exata;
- sobra `ABS_FS_RE`, a forma `~<conta>/` ou o hostname no `valor_novo` ou na `evidencia`;
- um nome de pasta privada de adotante aparece em qualquer valor escrito. A lista vem do `members.yaml`: são as
  pastas cujo basename difere do id, 7 hoje;
- o label novo passa de 280 caracteres;
- a única exceção é a linha marcada como receita (o dispositivo nulo do curl de aceite).

A checagem final relê o CSV e sai limpa.

## A forma da P6-label, e o conflito que ela resolve

**O conflito.** A convenção selada copia o label antigo **verbatim** para a narrative, como "label anterior: …"
(o `corrigir-label` faz `_append_narrative(block, "label anterior: " + old_label)`). Aplicada aqui, ela levaria o
caminho de máquina de volta à narrative, que a P6 também limpa. As duas regras não cabem juntas ao pé da letra.

**A forma proposta:**

- **label novo:** a afirmação com o caminho trocado pela descrição (o vocabulário é o da O6: "clone de produção do
  onion-bridge", "procfs", "conf.d do Caddy do host", "diretório temporário", "home do root");
- **narrative:** `label anterior: <label antigo>`, com cada caminho trocado pela mesma descrição **entre ⟨⟩**. A
  história fica legível, e a marca diz onde o texto foi editado.

**61 dos 70 labels já passavam de 280** antes da O7, e o maior tem 2452 caracteres. O `corrigir-label` recusa
`label_final` acima de 280, então o simples scrub não passaria na ferramenta. Nesses 61, o label novo é o **fato**
condensado em 280 ou menos, e o texto integral (sem caminho) vai à narrative. É a mesma separação
fato/narrativa da `Q_CONTRACT_FACT_NARRATIVE`. A confiança é 0.7, contra 0.85 do scrub direto. Os 9 labels
curtos mudam só no caminho.

**Variante B, para o maestro:** manter o label longo e só trocar o caminho no lugar. Nesse caso o `label_final` é
a narrative proposta sem o prefixo e sem os ⟨⟩, o que é derivável mecanicamente. A variante B exige que a
ferramenta aceite label acima de 280 quando ele **já era** longo.

**Existência de narrative.** Os 16 nós que já têm narrative a têm em escalar de uma linha; nenhum usa bloco
`>`/`|`. Por isso o `_append_narrative` funciona em todos.

**Ordem no `E_GROUNDING`.** Esse nó tem uma linha de narrative e outra de label: a reescrita da narrative
existente vem antes, e o acréscimo do label anterior depois.

## Itens selados da O6 (acréscimo do coordenador)

| Item | Nó | O que a linha faz | Medido |
|---|---|---|---|
| 1 | `E_MEDIDO_LOCAL_TIER10_NO_PROPRIO_REPO` | trace volta a ter `binário do Claude Code 2.1.259` | `npm view @anthropic-ai/claude-code@2.1.259` devolve a versão |
| 1 | `E_OBJECAO_EXIT2_E_PRIMITIVO_GRATIS` | trace = `binário do Claude Code 2.1.286` (hoje o nó não tem trace) | `npm view …@2.1.286` devolve a versão |
| 2 | `E_GRANAAI_DOCTRINE` | trace = as 4 cópias `onion-evolve@<sha>:docs/evolution/inbox/_processed/…`; a narrative diz que o original foi extinto | ver abaixo |
| 3 | `E_SKILL_INSTALL_PROMPT_AND_CURL`, `E_F4_CLAUDE_JSON_CONCORRENTE` | `x_path_is_content: "citação"` mais a linha "Caminho como conteúdo: …" (texto do juiz da O6) | a O6 **não** pôs o marcador: o `grep` no corpus acha só o do `E_m3` |
| 4 | `E_lid_addressing_root_cause` | o locator ganha a ressalva "lido em `onion-waha@86662e0`, posterior ao nó" | aplica junto o D5 retido: o locator vivo ainda diz `onion-vps-waha@` |

**Divergência no item 2.** O brief diz que as cópias foram "commitadas em 2026-07-17". O `git log --follow` por
arquivo mostra outra coisa:

- `80dcfc71` (2026-07-17) criou o `kg-radar-falso-verde-…`;
- `00e9ac24` (2026-07-18) criou as outras 3, direto em `_processed/`.

A data 07-17 é a do **nome** dos sinais. Nenhum sha é posterior ao nó, que tem `verified_at` 2026-07-18. Os 4
arquivos têm `from: granaai`. O `_processed` do clone do adotante tem só `.gitkeep` (`ls`, 2026-10-10), então
vale o ramo "original extinto".

**Item 3 × labels.** O marcador cobre a citação verbatim do `verified_against` e do locator. Os **labels** desses
dois nós são paráfrase, não citação, por isso ganham linha própria de reescrita (o `~/` sai).

## Casos difíceis

1. **A convenção "label anterior" contra a P6.** É o conflito descrito acima, e decide 70 linhas. Se o maestro
   preferir outra forma, por exemplo "label anterior: idêntico salvo o caminho", as linhas são regeneráveis.
2. **61 labels longos condensados.** Condensar é semântico. Mantive o núcleo da afirmação, os números e as
   referências de nó, e a narrative guarda o resto. Os mais arriscados são os de 1500 a 2450 caracteres:
   `I_SEGUNDO_IDP_…`, `F_ID_1_…`, `C_TETO_…`, `Q_METADE_…` e `Q_ARANDEK_…`. A variante B elimina esse risco.
3. **Texto que se declara verbatim.** A narrative do `E_HISTORICO_DO_REGISTRO_DOS_ADOTANTES` (8931 caracteres)
   diz "verbatim, por membro", e o caminho é do próprio registro do core (desta máquina). Por isso não cabe
   marcador. Os 2 caminhos viram ⟨descrição⟩ e a confiança é 0.75.
4. **Caminhos genéricos de Linux** (o marcador reboot-required, os vmlinuz do diretório de boot, o cgroupfs, o after.rules do ufw).
   Pelo precedente do `E_m3` poderiam ser receita. Segui o juiz da O6, que os **descreveu** no
   `verified_against` ("o marcador reboot-required do sistema", "o diretório de boot"). A única marcação é o
   `Q_SITE_…`: o `curl` de aceite com saída para o dispositivo nulo é o critério verificável do nó e fica verbatim no label anterior.
   A alternativa é descrevê-lo também.
5. **`C_slice_path_wrong` e família cgroup.** O caminho É o assunto (o caminho certo contra o errado). Reescrevi
   relativo à "raiz do cgroupfs" (`onion.slice/onion-auth.slice/`), o que preserva a distinção. Se o juiz achar
   que ficou vago, a alternativa é o marcador `receita`, porque são caminhos de kernel sem home nem hostname.
6. **`PR_322`.** O label é o título verbatim de um PR nosso (umbrella com o til do home seguido de worktrees). O item 3 aceita `~/` só
   em citação **de terceiro**, então reescrevi como `<home do usuário>/worktrees/…`, com confiança 0.85.

## Propostas ao maestro (NÃO aplicadas)

- **`Q_ARANDEK_SEGREDOS_E_BINDS_NO_COMPOSE_COMMITADO` (ao-maestro).** O label carrega **um segredo literal do
  adotante**: o valor do `--requirepass`, apesar de declarar "valores deliberadamente fora deste grafo". A
  convenção "label anterior" o copiaria para a narrative. Na recomendação, o valor fica omitido. Isso está fora
  do mandato (não é caminho), e o valor já está no histórico git do core. Avisar o adotante é ato do maestro.
- **`E_gmill_demo_route_caddy` (ao-maestro).** O nome da pasta privada (≠ id `hub-operacoes-enterprise`) está em
  três lugares:
  - no **subdomínio público**;
  - no **arquivo versionado** em `ops/caddy/conf.d/`;
  - no nome da sessão.

  Tirar o caminho de máquina obriga a reescrever o label anterior, e aí o nome privado aparece. A recomendação
  troca o nome pelo id em tudo. O maestro decide se domínio público e nome de arquivo versionado caem na regra.
- **Guarda P3 da classe `~<conta>/`.** O `ABS_FS_RE` pega `~/` e não pega til seguido do nome de uma conta, que é home de conta
  nomeada. São 4 nós; 3 já estão nesta planilha pelo outro caminho e 1 entrou só por isso (`C_DRIFT_44_…`). A
  regex deveria ganhar `~[a-z][a-z0-9_-]*/`, sem casar o `~abril/` de `E_QUOTA_GAP_FECHADO_ABRIL_2026`, que é
  aproximação.
- **Ferramenta.** A O7 precisa de uma ação `reescrever-label` no `kg-migrate-v3`. Ela teria quatro diferenças
  sobre o `corrigir-label`:
  - aceita `label:` na forma da O6;
  - escreve o label anterior que a linha traz, e não o verbatim;
  - recusa `ABS_FS_RE`, a forma `~<conta>/` e o hostname no label **e** na linha da narrative;
  - recusa label acima de 280, a menos que o maestro sele a variante B.

## Achados fora do mandato

- **F-O7-1, nome de pasta privada em label.** A varredura por substring (lista do `members.yaml`) acha estes nomes
  em campos de nó do corpus:
  - `onion-pessoal`: 17 labels e 13 provenances;
  - `rhilo-metagamify`: 11 labels;
  - `gmill`: 10 labels, além de 4 **ids** de nó;
  - `onion-adopt-arandek`: 3 labels.

  É a regra "nome de pasta privada não entra em lugar nenhum", ainda não varrida em label. Nas linhas desta
  planilha, troquei pelo id, por exemplo `marcio-pessoal` no `E_PENDING_SIGNAL`.
- **F-O7-2, contradição entre dois nós de `fios-abertos`.** `E_CAUSA_ABERTA_…` diz que o grep no caminho do
  sistema é o ugrep 7.8.4. `E_LOCALE_FRAGIL_…` diz que o mesmo caminho absoluto é o GNU grep 3.11 dos scripts.
  Um dos dois está errado, ou a máquina mudou entre 09-04 e 09-13. É candidato a `/meta:kg-freshness`.
- **F-O7-3, caminho de máquina no `meta.note`** do `bridge-produto-2026-08`, que aponta o arquivo de plano da
  sessão no home do maestro. Não é campo de nó, e está em bloco `>`, que a ferramenta não reescreve por linha.
- **F-O7-4.** A F-O6-1 continua de pé: o `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO` afirma "ATIVO", e a O6 mediu
  `.disabled`. A O7 não muda a afirmação, só o caminho.

## Tetos

- Não reli os nós inteiros fora do campo da onda, salvo os dos itens selados.
- Não conferi no `gh api` nenhum sha novo, porque esta onda só cria shas do próprio core. Os do item 4 vêm do juiz
  da O6.
- A fidelidade dos 61 labels condensados é juízo meu, sem medição. É o que o juiz deve atacar primeiro.
