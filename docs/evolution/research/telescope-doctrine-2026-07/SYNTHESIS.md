# Síntese — Nome + doutrina da observação read-only de sessões vivas (avaliação multi-lente)

> **Proveniência:** orquestração `wf_35e1e7a2` (2026-07-18) — 4 lentes independentes (Transformer-absorção ·
> coerência-doutrinária · mercado/prior-art · risco-adversarial) → síntese opus → verificação adversarial opus.
> Este é o **`write(KG)`** daquela orquestração (dogfood do passo 7 de `onion-orchestration`). Grafo audit
> co-locado: `./telescope-doctrine.kg.yaml` (radar exit 0, arestas `SUPERSEDES` = a superação auditável).
> **Método** (padrão vivo): [ver o playbook "validação de doutrina" em `onion-patterns`](#o-metodo-virou-padrao).

## O que se decidiu

**A ferramenta:** o core/maestro OBSERVAR (read-only) outras sessões Claude Code vivas na mesma máquina
(`tmux capture-pane` + transcript JSONL), no loop de evolução/dogfooding — substitui o copy-paste manual de telas.

**Nome (CONFIRMADO pela verificação adversarial; confiança MÉDIA-ALTA):**
- **`telescópio`** — o **conceito/doutrina** (par por *oposição* com o `farol`: farol = a observada **emite**
  metadado consentido; telescópio = o observador **recebe** conteúdo pleno, unilateral). Capacidade
  categoricamente nova (metadado→conteúdo) — não sinônimo do farol (respeita gênero×espécie).
- **`vislumbre`** — a **unidade do ato** (espécie): "dá-se **um vislumbre** pelo telescópio", nunca "telescópio
  ligado". Absorve a captura da lente adversarial (o daemon-vigia) e carrega os invariantes de efemeridade (#2/#5)
  que `telescópio` carrega mal.
- Slug funcional (inglês, `onion-patterns`): `/meta:telescope` — o verbo marca pontualidade, **nunca "observar" solto**.
- Tagline: *"olhar-sem-tocar"*.

**Por que o nome importa (critério decisivo do maestro — absorção pelo Transformer):** um nome é **mecanismo**
(não conselho) quando os *entailments físicos da própria palavra* já implicam o invariante **sem** a sessão
futura reler a doutrina. "Telescópio" entrega `observar≠comunicar` de graça (não se fala através de um
telescópio; o alvo é indiferente a ser visto; é operado por alguém). "Observe" não blinda — é gramaticalmente
compatível com "observar-e-responder", o comportamento proibido. Rejeitados: periscópio/tap/shadow (bagagem de
vigilância — *ensinam o padrão proibido*), espelho/mirror (bidirecional), introspect (auto-observação), mirante
(lugar passivo). Detalhe: a garantia read-only mora na **convenção + allowed-tools**, não numa flag (o próprio
tmux documenta `attach -r` como "convenience, not security" → preferir `capture-pane`).

## A doutrina — 10 invariantes (do rascunho 1-5 + 4 gaps de coerência 6-9 + critério Transformer 10)

1. **OBSERVAR ≠ COMUNICAR** — read-only, unidirecional; a ação nascida de um vislumbre volta pelo canal async (inbox/beacon/commit), jamais injeta na observada. (Ancora I3 + "sem IA-fala-IA".)
2. **DECLARADO ≠ VERIFICADO aplicado a sessões** — a tela é declarada (transiente); o artefato commitado é o verificado. Um vislumbre prova nada.
3. **Soberania da observada** — inconsciente e intacta; nunca depende de ser vista.
4. **Mediado pelo maestro/autoridade** — o core invoca; não é daemon (senão vira vigilância / IA-vigia-IA).
5. **Efêmero** — o vislumbre não se persiste cru; achado que vale → artefato normal (sinal/migalha).
6. **Assimetria de consentimento** — farol = metadado que a observada ESCOLHE emitir; telescópio = conteúdo que ela NUNCA escolheu mostrar. Privacidades distintas.
7. **Não substitui o farol** — nunca participa da arbitragem de escrita; posse/colisão continua 100% do farol.
8. **On-demand, nunca daemon** — vislumbre pontual em checkpoint; polling contínuo recria o W7 rejeitado e torna `observar≠comunicar` escudo falso.
9. **Dentro do envelope de confiança + LOCAL-ONLY** *(corrigido — ver furos A/B)*.
10. **Mechanism, not advice** — os invariantes precisam ser CABEADOS (allowed-tools restrito a `capture-pane` + leitura JSONL, só sob invocação do maestro), não só escritos. A reincidência KG-first (≥4× após a doutrina escrita) prova: prosa não basta.

## O que a verificação adversarial GANHOU (a superação em curso)

O verify **refutou** a auto-avaliação e achou **furos reais** — é a superação de `#9` acontecendo:

- **FURO A — consentimento.** `#9` fazia *pertencer-à-federação* implicar *consentir-em-ser-telescopado* — upgrade silencioso que viola a soberania (#3). **Correção:** opt-in explícito da observada — campo **`telescope: allowed`** que o próprio MEMBRO seta no `members.yaml` (espelha que o farol é dela levantar). Sem o interruptor da observada, o telescópio é assimétrico com o farol.
- **FURO B — colisão com `never-live-pull`.** Telescopar tmux+JSONL vivo **é** um live-pull; `#9` era ambíguo local vs remoto. **Correção:** restringir a **leitura LOCAL same-machine pelo maestro humano** (`capture-pane` em localhost ≠ transporte de federação; never-live-pull não se aplica) e **largar** o enquadramento remoto/"tokens". Remoto, se um dia: exceção NOMEADA e gated (território a2a-live), nunca coerência em silêncio.
- **FURO C — reuso sobre reinvenção.** `#1/#5` herdam explicitamente a régua da `NOTE-04` (*"guardar ≠ aceitar ≠ aplicar"*): o vislumbre (display/intake) degrada **SKIP** (falhar não faz dano); só a AÇÃO derivada degrada **VETO**.

**Veredito final:** nome CONFIRMADO (confiança **média-alta** — o gate P3 testa `telescópio` E `vislumbre`);
doutrina **não sela até A+B fechados e C herdado**. Status: **gated até 1 dogfood de recall** (uma sessão
federada reidentifica os invariantes ao ouvir só o nome, sem reler a fonte).

## O método virou padrão

Esta avaliação (fan-out de lentes → síntese → verify adversarial → `write(KG)` com `SUPERSEDES`) não é one-off:
é o **motor de qualidade da superação de doutrina** — decisões que "já existem" como Aufhebung (nega+conserva) de
ideias anteriores, seladas no KG-SSOT de forma auditável. Nomeado como playbook em `onion-patterns` ·
ADR do telescópio: [`onion-adr-telescope-session-observation-2026-07`](../../../analysis/onion-adr-telescope-session-observation-2026-07.md).
