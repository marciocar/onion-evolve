---
tipo: sinal-upstream (testemunho do maestro + observação de campo)
data: 2026-07-10
origem: maestro (Marcio) + sessão do core (observação no clone local da granaai)
assunto: granaai é MULTI-LINHAGEM (≥3 adoções distintas) — members.yaml não mapeia; stamp local diverge do registro
relacionado:
  - docs/analysis/onion-adr-granaai-consolidation-2026-07.md
  - docs/analysis/onion-parecer-rhilo-lineages-2026-07.md (precedente: metagamify multi-linhagem, decisão D2)
  - docs/evolution/federation/members.yaml (entrada granaai — linhagem única, adopted_at 2026-07-01)
---

# Sinal: granaai tem ≥3 linhagens de adoção — mapear antes que os carimbos confundam

## Observação de campo (o gatilho)

Durante o `adopt --update` de 2026-07-10 (sessão da granaai, branch `onion/adopt-update-74c470e`),
o stamp local ficou `adopted_at: 2026-07-10` **sem** `updated_at` — enquanto o `members.yaml` do
core registra `adopted_at: 2026-07-01`. Primeira leitura: regressão do fix do audit #5 (`--update`
preserva `adopted_at` + escreve `updated_at`). **O testemunho do maestro reframia**: pode não ser
bug — pode ser **outra linhagem**, legitimamente adotada em data diferente.

## Testemunho do maestro (a verdade do campo)

1. Houve uma **tentativa de adoção na máquina do Mauricio** (Mauricio Matos, Grana.Ai) — as trocas
   de mensagens estão no histórico/inbound da federação (ex.: review do PR #1094, reconciliação de
   2026-07-06/07).
2. Em algum momento o maestro **adotou um repo puro NESTE servidor** (KVM 8) e **continuou nele**
   (2026-07-09/10) — é o clone `/home/marcio/granaai`, a linhagem que a sessão da granaai opera
   agora. O `adopted_at: 2026-07-10` local pode ser o carimbo honesto DESTA linhagem.
3. O **Mauricio segue com a dele**, na máquina dele.
4. Existe **mais uma instância adotada OFFLINE, pelo Leonardo** (Grana.Ai) — âncora provável no
   próprio ADR de consolidação: `feature/onion-integration` (Leonardo Melo, 2025-11-06,
   "integração com o onion").

## Por que isto é sinal (e não só curiosidade)

- **É o caso metagamify de novo** (parecer rhilo-lineages, decisão D2): membro multi-linhagem sem
  mapa `lineages:` no `members.yaml` → pins/carimbos de linhagens diferentes se atropelam e viram
  "anomalia" ou, pior, **pin forjado acidental** (regra vigente: pin só entra VERIFICADO por
  `pin-integrity-check.sh`, nunca do stamp declarado).
- O `adopted_at` único no `members.yaml` não representa a realidade — qual adoção ele descreve?

## Proposta de triagem

1. **Mapear as linhagens da granaai** no `members.yaml` (formato do metagamify): `local-kvm8`
   (este servidor, sessão ativa, pin verificável agora) · `mauricio` (máquina dele — pin só quando
   verificável) · `leonardo-offline` (registrar existência + âncora no ADR; pin quando o repo
   aparecer). `adopted_at` por linhagem.
2. **Confirmar ou descartar a regressão** do fix adopted_at/updated_at: reproduzir o `--update` num
   sandbox e ver se `updated_at` é escrito — se não for, é bug real independente da história.
3. **Coordenar com a sessão da granaai** (viva agora) antes de qualquer escrita no members.yaml —
   ela tem o contexto do update em andamento.

— Depositado a pedido do maestro. Rode `/meta:co-evolve` para triar.
