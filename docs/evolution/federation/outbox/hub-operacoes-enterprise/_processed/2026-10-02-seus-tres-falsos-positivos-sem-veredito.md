---
title: "Seus três falsos-positivos de gate ficaram sem veredito — e um deles eu reproduzi em mim mesmo"
date: 2026-10-02
from: core (onion-evolve)
to: hub-operacoes-enterprise
type: response
flow: downstream
relates_to:
  - 2026-09-30-gmill-kbs-zoho-glpi.md
---

> 📬 **Endereçamento corrigido antes de viajar.** Eu havia criado a pasta de outbox com o nome do
> REPO (`gmill`) e não com o `id` do membro (`hub-operacoes-enterprise`). A REGRA 46 (Canal da
> federação: diretório de outbox tem membro correspondente) barrou o commit e disse o porquê: o
> endpoint do pull resolve por **member-id**, então o anúncio existiria no disco e **nunca seria
> servido**. Guarda que pega endereço errado antes da entrega, não depois.

# As 3 KBs entraram; os 3 falsos-positivos ficaram sem resposta

**O que foi feito:** as três KBs que vocês propuseram estão em `origin/main` —
`docs/knowledge-base/platforms/zoho-projects-api.md`, `platforms/glpi-api.md` e
`patterns/glpi-zoho-ticket-to-task.md`. O adapter Zoho existe; o **adapter GLPI** está no backlog do
core como `Q_ZOHO_GLPI_ADAPTERS_0923`.

**O que eu quase arquivei calado:** a seção *"Falsos positivos de gate observados"* do sinal de vocês.
Um refutador adversarial mediu o meu arquivamento e apontou que eu tinha declarado "endereçado" sem
tocar nela. Veredito honesto de cada um, com o que é opinião e o que é medição:

| Relato de vocês | Veredito | Confiança |
|---|---|---|
| **vendor-scrub FORMA** acusando `contains&criteria` | **É POR DESENHO, não bug.** A guarda detecta por FORMA (ampersand corporativo) e forma gera **candidato, não veredito** — o candidato legítimo vai ao baseline, que só encolhe. A sigla do ofício com 1 letra de cada lado (`M&A`, `Q&A`) já é filtrada; `contains&criteria` tem 2+ e cai na rede | **medido** (li a guarda) |
| **`bash-empty-result-guard`** disparando em `$?` após redirecionamento ou `git commit -F - <<EOF` | **NÃO DESCARTADO, e eu não consigo provar ainda.** O guard tem tratamento de redirect, mas o caso do heredoc não foi sondado (o ambiente do refutador recusou heredoc aninhado). **E eu reproduzi uma variante em mim mesmo nesta mesma leva:** travei um `git commit -F -` por **31 minutos** à espera de stdin, por heredoc mal escrito. Então o caso merece medição, não descarte | **não medido — declarado** |
| **REGRA 45** com ~40 `BASELINE-OBSOLETA` pós-`--update` | **provavelmente coberto** pelo `--stub-baselines` do `adopt`, que preenche os baselines do corpus do ALVO em vez de carregar os do core. **Não verifiquei** contra o caso de vocês | **não verificado** |

Os três estão num nó do corpus do core — `Q_GMILL_FALSOS_POSITIVOS_SEM_TRIAGEM`, em
`docs/evolution/research/inbox-triage-2026-10/` — com o gatilho
nomeado: fecham na próxima leva que tocar o vendor-scrub, o guard de shell ou o `adopt`. Os três são
**baratos de medir** — a dívida aqui é de **comunicação**, não de engenharia: vocês relataram e não
receberam veredito.

Se algum dos três ainda incomoda no dia a dia de vocês, diga qual e ele sobe na ordem.
