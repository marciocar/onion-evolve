# 🧬 Doutrina do evolve — o laço de auto-evolução do Onion Evolve

> Fragmento canônico (peça 2 do conjunto do comando-com-framework). Quem precisa da doutrina do
> laço — `/meta:evolve`, `/meta:census`, `/meta:radar`, `/meta:drive`, as forjas — **referencia
> este arquivo em vez de carregar pedaços dele por imitação**. Antes deste fragmento a doutrina do
> evolve vivia numa KB (`onion-modernization-doctrine.md`) que nenhum outro comando conseguia
> citar como peça; o `forge-census` a contava como ausente, e com razão.

## A cláusula-mãe (maestro, 2026-10-02)

> *"ele deve ser o evolve do Onion Evolve"* — o homônimo. Raio-X e auditoria dos elementos
> principais, avaliação do backlog, o que aconteceu no mundo, usando dogfood + KG-SSOT-first +
> runtime SDAAL com foco em **transformer, maquinaria e doutrinas**. Propor soluções eficientes e
> eficazes para as lacunas. **Auto-evolução é pela visão de DENTRO**, respeitando, verificando e
> acolhendo o que faz sentido e vem de fora. **Seguir e confrontar** para não fazer nada errado nem
> precipitado, como guardião do Onion. *Nem tudo que dizem e que você busca é a verdade — por isso
> **informado é diferente de verificado**.* Sempre com **eficiência e eficácia**.

## As cláusulas

1. **Ser homônimo não é ser o maior — é ser o laço canônico.** O evolve fecha
   `read(KG) → medir → confrontar → propor → write(KG)` sobre o próprio framework. Os órgãos
   específicos (`census`, `radar`, `dissect`, `drive`, as forjas) medem cada um a sua pergunta; o
   valor que **nenhum** deles entrega é o **CONFRONTO** entre o que medem separadamente. Um comando
   7/7 cuja doutrina nunca carrega é outra coisa que um 2/7 que carrega sempre — e nenhum censo
   isolado diz isso.

2. **O raio-X roda ANTES do raciocínio, e é composição.** A casa tem medidores determinísticos de
   segundos cada. O raio-X (`evolve-census.sh`) os compõe em ~6-9s medidos (2026-10-04; a 1ª
   redação dizia "~5s" e "1-2s cada", e o Elenxo mediu o forge-census a 5,4s sob carga). Varrer tudo
   com modelo é catedral; **o dogfood é POR CENSO, não por varredura**: o raio-X diz quais
   artefatos estão vencidos ou não-exercitados, e o trabalho caro roda só neles.

3. **Carregou ≠ aterrissou.** A casa mede se **guarda dispara** (shell que REPROVA, com bancada) e
   mal mede se **doutrina aterrissa** (markdown que ACONSELHA). O mais perto que existe é o
   `instructions-loaded-census`, que mede se a doutrina **entrou no contexto** — nunca se mudou o
   comportamento. A diferença é medida: em 2026-10-02 a doutrina do dogfood estava carregada no
   CLAUDE.md e a sessão a violou quatro vezes no mesmo dia. Achado do evolve sobre doutrina tem de
   dizer **qual das duas** coisas mediu.

4. **Informado ≠ verificado, e o corpus não é isenção.** Achado de fonte externa entra como
   *informado* até medição no vivo. E ler `tier=` de um nó do corpus não autoriza pular a medição:
   **tier alto é qualidade da FONTE, nunca extensão da COBERTURA** (lição da rodada 6 do radar).

5. **Proposta é nó, não prosa.** Toda lacuna sai como nó `decision`/`question` **open** com gatilho
   nomeado no grafo de auditoria. O relatório em `docs/analysis/` é **projeção** do grafo — e o
   nome dele é contrato: `onion-evolution-<YYYY-MM-DD>.md`, que a REGRA 97 lê para saber se esta
   auditoria está vencida. Mudar o nome sem mudar a guarda a deixa cega.

6. **Seguir e confrontar, como guardião.** Antes de propor mudança, procure no corpus o `confirmed`
   que ela contraria (a REGRA 87 cobra isso no PR). Proposta que derruba decisão selada fica
   **proposta** — o flip é humano. E toda superação passa por refutador adversarial antes de selar:
   nesta casa ele reprovou entregas inteiras que iam ser seladas, com gate mecânico verde.

## O que esta doutrina NÃO promete

- **Não mede qualidade.** O raio-X mede presença, ligação, frescor e carga — o julgamento é do evolve.
- **Não sabe de artefato que ninguém anotou.** Os censos medem o que o corpus declara.
- **Não decide a cadência.** A REGRA 97 avisa quando a auditoria venceu; **avisar ou agendar** é
  escolha do maestro. Relógio/cron **não é vedado** ao evolve (ele é read-only; o MOAT W7 escopa o
  driver que executa) — mas também não é decidido aqui.
- **Não muta `.claude/`.** O evolve propõe; a cura é o fluxo normal (nó → Elenxo → dogfood → PR).
- **Não substitui os órgãos.** Ele os lê e os confronta; quem mede cada pergunta continua sendo o
  órgão dela.

## 🔗 Peças

Medidor (peça 3): `.claude/validation/evolve-census.sh` · Gatilho: REGRA 97,
`.claude/validation/evolve-staleness-check.sh` · Lente (peça 6): `.claude/rules/evolve-lens.md` ·
Bancada (peça 7): `run_evolve_census_selftests` · Superfície: [`/meta:evolve`](../../meta/evolve.md)
