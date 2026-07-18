---
title: 'ADR — Telescópio: observação read-only de sessões vivas (observar ≠ comunicar)'
date: 2026-07-18
type: adr
status: accepted (doutrina) — GATED até 1 dogfood de recall + cabeamento (P0); nome confiança média-alta
decision-scope: co-evolution / observability (o maestro/core observar sessões vivas no loop de evolução)
supersedes: none
extends:
  - onion-adr-work-models-session-topologies-2026-07.md (farol/W-topologias; telescópio é o PAR do farol)
origin-signal: 'orquestração wf_35e1e7a2 (avaliação multi-lente) — docs/evolution/research/telescope-doctrine-2026-07/SYNTHESIS.md'
deciders: maestro
related:
  - docs/evolution/research/telescope-doctrine-2026-07/telescope-doctrine.kg.yaml (o write(KG), arestas SUPERSEDES)
  - .claude/validation/session-beacon.sh (o FAROL — o par por oposição)
---

# ADR — Telescópio

## Contexto

No loop de evolução, o maestro/core precisa **ver o que uma sessão viva está fazendo** (dogfood: assistir o
framework sendo usado em granaai/onion-pessoal ao vivo, pegar o gap). Hoje isso é copy-paste manual de telas.
Formalizar isso **fortalece** o modelo — se, e só se, respeitar o invariante que o separa de "IA-fala-IA".

Decidido por **avaliação multi-lente + verificação adversarial** (o padrão vivo — ver `onion-patterns`), com o
resultado persistido no KG-SSOT (`telescope-doctrine.kg.yaml`, arestas `SUPERSEDES` = a superação auditável).

## Decisão — o nome (mechanism, not advice)

- **`telescópio`** — o **conceito/doutrina**. Par por **oposição** com o `farol`: o farol é **emissão** que a
  observada levanta (metadado consentido: quem-está-vivo); o telescópio é **recepção** unilateral de conteúdo
  pleno (tela + raciocínio) pelo observador. Capacidade **categoricamente nova** (metadado→conteúdo) — não
  sinônimo do farol (respeita gênero×espécie). O nome carrega o invariante `observar≠comunicar` *por construção*
  (não se fala através de um telescópio; o alvo é indiferente a ser visto; é operado por alguém).
- **`vislumbre`** — a **unidade do ato** (espécie): "dá-se **um vislumbre** pelo telescópio", **nunca**
  "telescópio ligado". Carrega a efemeridade (#2/#5).
- **Slug:** `/meta:telescope` (inglês, `onion-patterns`) — o verbo marca **pontualidade**; **nunca "observar" solto**.
- Tagline: *"olhar-sem-tocar"*.

## Decisão — a doutrina (10 invariantes)

1. **OBSERVAR ≠ COMUNICAR** — read-only, unidirecional; a ação nascida de um vislumbre volta pelo canal **async**
   (inbox/beacon/commit), jamais injeta na observada. (Ancora I3 + "sem IA-fala-IA".)
2. **DECLARADO ≠ VERIFICADO** — a tela é declarada (transiente, pode estar no meio de um raciocínio); o artefato
   commitado é o verificado. **Um vislumbre prova nada.**
3. **Soberania da observada** — inconsciente e intacta; nunca depende de ser vista.
4. **Mediado pelo maestro** — o core invoca; **não é daemon** (senão vira vigilância / IA-vigia-IA).
5. **Efêmero** — o vislumbre não se persiste cru; achado que vale → artefato normal (sinal/migalha).
6. **Assimetria de consentimento** — farol = metadado que a observada ESCOLHE emitir; telescópio = conteúdo que
   ela NUNCA escolheu mostrar. Privacidades distintas.
7. **Não substitui o farol** — nunca participa da arbitragem de escrita; posse/colisão continua 100% do farol.
8. **On-demand, nunca daemon** — vislumbre pontual em checkpoint; polling contínuo recria o W7 rejeitado e torna
   `observar≠comunicar` um escudo falso.
9. **Opt-in da observada + LOCAL-ONLY** *(corrigido pela verificação adversarial — furos A e B):*
   - **Consentimento (furo A):** pertencer à federação **não** implica consentir em ser telescopado. A observada
     precisa de **opt-in explícito** — campo **`telescope: allowed`** que o **próprio membro** seta no seu
     `.onion-version`/`members.yaml` (espelha que o farol é dela levantar). Ausência = **veto** (fail-safe).
   - **Local-only (furo B):** telescopar sessão viva **é** um live-pull → restrito à **leitura LOCAL same-machine
     pelo maestro humano** (`capture-pane` em localhost ≠ transporte de federação; `never-live-pull` não se
     aplica). Remoto, se um dia: **exceção NOMEADA e gated** (território a2a-live), nunca coerência em silêncio.
10. **Mechanism, not advice** — os invariantes precisam ser **cabeados** (allowed-tools restrito a
    `tmux capture-pane` + leitura do JSONL, só sob invocação do maestro), não só escritos. A reincidência
    KG-first (≥4× após a doutrina escrita) prova: prosa não basta. Detalhe: preferir `capture-pane` a `attach -r`
    (o tmux documenta `-r` como "convenience, not security" — a garantia mora na convenção + allowed-tools).

> **Herança da NOTE-04 (furo C, reuso sobre reinvenção):** *"guardar ≠ aceitar ≠ aplicar"* — o vislumbre (intake)
> degrada **SKIP** (falhar não faz dano); só a AÇÃO derivada degrada **VETO**.

## Forma (P0-P3) e gate
- **P0 — helper `session-telescope.sh`**: dado um alvo local consentido, `capture-pane` + localiza o transcript
  + resume "o que a sessão faz". Cabeado (allowed-tools restrito) — **é a forcing function** (#10).
- **P1 — `/meta:telescope`** (a invocação do maestro, com o gate da doutrina). Ou seção cabeada em `/meta:co-evolve`.
- **P3 — esta doutrina** (KB, o conceito `telescópio`).
- **GATE de selagem:** não promover de rascunho a canônico até **(a)** furos A e B implementados (campo opt-in +
  local-only), **(b)** 1 **dogfood de recall** — uma sessão federada reidentifica os invariantes ao ouvir só o
  nome, sem reler a fonte (o gate testa `telescópio` E `vislumbre`).

## Invariantes
- **Observar nunca vira falar** — a ação sempre volta async; sem isso, é IA-vigia-IA.
- **A observada tem o interruptor** — `telescope: allowed` (ausência = veto). Sem opt-in, telescópio é assimétrico
  com o farol e quebra a soberania que diz honrar.
- **Local-only** até um desenho remoto explícito e gated.
- **Cabear, não só escrever** (#10).
