---
reviewed_diff_sha256: 1bc6c9d5c0b9fad9a305e7d206da70e0cc0daf8cffdd702f6feffd0692abb3c3
findings_total: 5
findings_real: 5
tokens: 115675
duration_min: 23
verdict: REPROVADO_E_CURADO
elenxo: sim
---

# Resíduo da passada adversarial — `chore/inbox-triage-2026-10` (PR #903)

Refutador `sonnet` em worktree isolada, mandato REFUTAR. **5 achados, 5 reais, todos provados.**
Veredito: **REPROVADO**. Curados nesta branch — daí `REPROVADO_E_CURADO`.

## O achado que importa, e é contra mim

Eu arquivei os 6 sinais declarando **"todos endereçados, com prova em `origin/main`"**. A prova que
eu levantei cobria o **pedido principal** de cada sinal — não os pedidos **internos**. Quatro ficaram
abertos, sem resposta e sem teto:

| Pedido aberto | Onde estava escondido |
|---|---|
| `docs/knowledge-base/index.md` do adotante **sobrescrito** pelo `--update` (perdeu frontmatter, quebrou o `docs:check` dele) | pedido **3 de 3** do sinal do pre-commit — os 2 primeiros eu curei no #902 |
| convergência docs-only no `--update` — **o gatilho já disparou** (`adopt.md:685` diz "gated até o 1º caso real", e o caso chegou) | adendo 1 do mesmo sinal |
| baseline explícito no stamp (`_clean_baseline` nunca acha base com KB mista) | adendo 2 do mesmo sinal |
| 3 falsos-positivos de gate relatados pelo hub `gmill` | seção própria do sinal dele |

**A classe:** "endereçado" medido pelo título e pelo pedido de cabeça de lista, quando o sinal tem
seções com pedidos próprios. É `read-full-content-before-triage` reincidindo — agora na direção do
**arquivamento**, não da leitura. E **nenhuma guarda sabe ler o que um sinal PEDE**: o gate saiu
`0 HARD` em todas as passadas. O refutador, lendo os sinais inteiros, achou os quatro em 23 minutos.

**Cura:** os quatro viraram nós com gatilho nomeado, sustentados pela evidência
`E_TRIAGEM_DECLAROU_ENDERECADO_SEM_LER_O_SINAL_INTEIRO`, em
`docs/evolution/research/inbox-triage-2026-10/` (radar `rc=0`, 5 nós / 5 arestas). E os remetentes
foram avisados — item órfão do lado de quem sinalizou continua órfão.

> **O mecanismo me corrigiu DUAS vezes neste movimento, e a segunda foi a lição boa.**
>
> (a) Os 4 nós nasceram **órfãos (grau 0)** e o `kg-radar --integrity` **reprovou**: "nada fica
> órfão" aqui é `exit 1`, não conselho.
>
> (b) Eu os escrevi **dentro de `fios-abertos.kg.yaml`**, e a **REGRA 58 (O backlog cumpre as
> promessas do próprio `meta:`)** acusou TETO — 24 nós contra 19 declarados. **O teto era o sintoma,
> não a doença.** O `meta:` daquele arquivo diz, em letra grande: *"NENHUM FATO NASCE AQUI — nó só
> entra para ser ponta de aresta cross-grafo; achado mora onde nasceu, aqui mora o COMPROMISSO"*, com
> o teste explícito *"se eu apagar este nó, perco um FATO ou perco só a ORDEM? Perdeu fato → você
> duplicou SSOT"*. Os meus 5 eram FATOS. Se eu tivesse apenas subido o teto — a saída óbvia — teria
> consertado o número e **mantido a violação de fronteira**. Os fatos foram para um grafo próprio e o
> `fios-abertos` voltou a 19 nós, exatamente no teto que ele promete.

## O segundo achado, também contra a minha própria honestidade

A nota de arquivamento que eu escrevi afirmava **"nenhuma palavra do sinal foi alterada"**. O
refutador mediu pelo `diff`: era **falso em dois dos três** links — eu havia reescrito o caminho de um
(relativo → a partir da raiz) e o texto do outro (`types.md` → `./types.md`). **A cura não foi
enfraquecer a frase**: restaurei texto e caminho originais (`` `texto` → `caminho` ``) e a frase
passou a ser verdadeira. Declarado≠verificado dentro da própria nota que se propunha a ser honesta.

## O que RESISTIU

- Lint `0 HARD` no `63c25c3b`, 16 SOFT (passivos de sempre).
- **REGRA 22 (Links relativos quebrados em docs/evolution/ e docs/knowledge-base/) nas duas
  polaridades, por execução:** sonda com link quebrado em `_processed/` → **1 HARD**; a mesma sonda no
  1º nível de `inbox/` → **silêncio**. Sondas removidas, sem sobra.
- Nenhuma projeção conta sinais de inbox — mover não exige atualizar registro nenhum.
- Os pedidos 1–4 da réplica do adotante conferidos **no código**, não no CHANGELOG.

## nota:
O refutador deixou **um** item sem prova e declarou: o falso-positivo nº 2 do `gmill`
(`bash-empty-result-guard` em `git commit -F - <<EOF`) ele não conseguiu sondar — o ambiente da
worktree recusou heredoc aninhado. **Não descartei por isso**, e há razão: eu mesmo travei um
`git commit -F -` por **31 minutos** à espera de stdin nesta sessão, por heredoc mal escrito. O nó
`Q_GMILL_FALSOS_POSITIVOS_SEM_TRIAGEM` carrega essa observação, para que a próxima medição não comece
do zero nem do descarte.
