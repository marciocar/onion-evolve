# Nascimento de peça — quando uma peça está pronta e quem merja o quê

> **Versão**: 1.0.0 | **Última atualização**: 2026-11-21 | **Categoria**: Conceitos
> Uma **peça** é um repo estratégico do ecossistema com sessão Onion própria e patrocinador humano.
> Ela **nasce** quando passa uma porta de quatro critérios, conferidos por script, pela leitura do
> registro ou pela revisão, e segue presa a uma condição permanente sobre o pin. O PR que faz a peça
> nascer vai ao maestro ou ao core. Depois do nascimento, o merge dos PRs do repo da peça passa à sessão
> dona, pelo caminho verificado. Deploy e produção ficam sempre com o maestro, e repo de outro dono
> (cliente ou empresa) nunca é mergeado por sessão.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-11-21 |
| **Última Atualização** | 2026-11-21 |
| **Categoria** | Conceitos |
| **Origem** | Card SAC-479. Proposta da curadoria em 2026-11-21 (sinal versionado no core em `docs/evolution/inbox/_processed/2026-11-21-doutrina-nascimento-de-peca.md`, core-only); o core aceitou o texto e o lugar |
| **Grafo** | `docs/onion/graph/coordenacao-selos-arquivo-2026-11.kg.yaml` (decisão `D_PIECE_BIRTH_DOCTRINE_1121`) |
| **Padrões-irmãos** | Cabeçalho do `docs/evolution/federation/members.yaml` (os campos de peça) · [doutrina da batuta](../../../.claude/commands/common/prompts/baton-doctrine.md) · [doutrina das guardas](../../../.claude/commands/common/prompts/guard-doctrine.md) · [catraca de decisões](decision-ratchet-doctrine.md) |
| **Revisão** | Pendente do maestro: o selo foi dado pelo core na ausência dele. Se ele discordar, a decisão se refaz |

---

## 1. Por que existe

As peças do ecossistema nasceram uma de cada vez, cada uma com a própria decisão. As regras já estavam
seladas, mas espalhadas: o campo de peça num selo, a delegação do merge noutro, o pin depois do merge num
achado de revisão. Faltavam duas coisas, e esta doutrina dá as duas:

1. **Uma lista única** do que faz uma peça estar «ok» (a porta A).
2. **A regra explícita** de quem merja antes e depois de a peça nascer (a parte B).

Nada aqui cria mecanismo novo. Os gates já existem. Esta página dá nome ao padrão e põe as regras num
lugar só.

## 2. O que é uma peça

Uma peça é um repo ou serviço estratégico do ecossistema que tem:

- uma **sessão Onion própria** que o defende (a sessão dona);
- um **patrocinador humano** (o sponsor);
- registro no `members.yaml` com `piece: true`, `owner_session` e `sponsor`.

São **campos**, não um `kind:` novo. O `kind:` diz a natureza do membro e o `members-validate.sh` aceita
só valores de uma lista fechada; `kind: piece` reprovaria. A peça segue sendo, por exemplo, `adopter`
(`D_BACKBONE_OWNER_1112`, 2026-11-12).

**Nascer** é passar a ser peça registrada e ganhar a delegação do merge.

## 3. A. A porta de nascimento: quatro critérios e uma condição permanente

A peça nasce quando os critérios 1 a 4 passam. O 5 não é item da porta: é uma condição que vale para
sempre depois do nascimento. A coluna da direita diz como cada um se confere hoje, sem prometer mais do
que o script faz.

| # | critério | como se confere |
|---|---|---|
| 1 | **Registro válido** | entrada no `members.yaml` com `kind`, `remote` e os três campos de peça. `bash .claude/validation/members-validate.sh` com **rc 0** confere a forma do registro; ele não lê `piece`, `owner_session` nem `sponsor`, e esses campos se conferem lendo o arquivo |
| 2 | **Dono nomeado, com card de arranque** | `owner_session` declarado; o `baton-pulse.sh` dá `PIECE_OWNED` (há sessão viva com esse nome) ou `PIECE_UNOWNED` / `PIECE_UNMEASURED` com o **card de arranque** pronto (ex.: `cd ~/<repo> && claude --name <sessão>`). `PIECE_OWNER_NAME_MISMATCH` (há sessão viva no repo da peça com outro nome) não impede o nascimento, mas pede renomear a sessão |
| 3 | **Patrocinador humano** | `sponsor` declarado, conferido lendo o registro (nenhum script o cobra hoje; o pulso só o imprime) |
| 4 | **Revisão separada do PR de nascimento** | resíduo de revisão do PR (REGRA 56, `docs/evolution/review/<branch>.md`) com `verdict` em APPROVED, FIXED, REJECTED_AND_FIXED ou NO_FINDINGS (nunca REJECTED), `findings_blocking: 0` e `reviewed_diff_sha256` igual ao diff revisado (`review-artifact-check.sh`). É o único critério que pede julgamento: o de quem revisa |
| 5 | **Condição permanente: pin honesto** | o `onion_version` do registro só se carimba **depois** do merge do update da própria peça, nunca antes (no core, `ops/registry-pins.sh --seal`) (core-only) |

Sobre o critério 2: o pulso da batuta **avisa, nunca bloqueia**. A peça pode nascer com a sessão dona
desligada, desde que o card de arranque exista. Quem lê o aviso sabe como ligar a sessão.

Sobre o critério 5: carimbar antes é declarar o que ainda não aconteceu. Declarado não é verificado.

## 4. B. Quem merja, antes e depois do nascimento

### O PR de nascimento vai ao maestro ou ao core

O PR que registra a peça no `members.yaml` mexe numa **guarda**: ele amplia o que a batuta cobra e o que
a delegação de merge alcança. Por isso a sessão dona nascente **não** merja esse PR:

- ela ainda não está na lista fechada do `ops/pr-merge-verified.sh` (core-only);
- e o próprio PR é o que **cria** a delegação dela.

É o problema do ovo e da galinha: não se delega o merge por um PR que o próprio delegado merja. O PR de
nascimento vai ao **maestro** ou ao **core** (`kind: source`), e o corpo do PR diz isso.

### Depois do nascimento, a sessão dona merja o próprio repo

Com o `owner_session` na lista fechada, os PRs do **repo da própria peça**, inclusive os que tocam
guarda, passam a ser mergeados pela **sessão dona**. O caminho é o verificado: revisão separada e
`ops/pr-merge-verified.sh` (core-only), que recusa CI vermelho ou pendente
(`D_SESSIONS_MERGE_OWN_PRS_INCL_GUARD_1118`, 2026-11-18).

### O que fica sempre com o maestro

- **Deploy e produção** (`D_SERVICE_REPOS_OWNER_VPS_OPS_1120`, 2026-11-20).
- **Repo de outro dono** (cliente ou empresa): sempre recusado, mesmo listado, com revisão e CI verde.
  Só o dono merja lá.

Um caso parece igual e não é: o repo de **consultoria** que pertence ao dono do core mas leva o nome do
cliente no endereço. Ele pode ser delegado à sessão dona por uma lista privada, fora deste repo, sem o
endereço no registro público (`D_PRIVATE_OWNER_SESSIONS_1119`, descrita no cabeçalho do `members.yaml`).

## 5. C. A regra que não muda

A propriedade é declarada no registro **antes** de o merge ser delegado. Nenhuma peça nasce sem passar a
porta A. O pulso da batuta lembra; ele não trava.

> Esta página **cita** o `members.yaml` e não o altera. O `members.yaml` é guarda: mudar o registro é PR
> próprio, com o merge que a parte B descreve.

## 6. O padrão de mercado

| mercado | o que faz | no Onion |
|---|---|---|
| **CODEOWNERS + branch protection** (GitHub) | o dono fica declarado num arquivo versionado; com "Require review from Code Owners", a aprovação do dono é exigida **antes** do merge | o `owner_session` no `members.yaml` declara o dono antes de o merge ser delegado; o caminho verificado faz o papel da revisão exigida |
| **Production Readiness Review** (Google SRE, cap. 32) | o serviço passa por uma lista de verificação **antes** de a equipe de SRE assumir a operação; a saída é a lista de correções exigidas antes da troca de dono | a porta A é a lista que a peça passa antes de ganhar a delegação |

A diferença do Onion: a lista de quem pode mergear é **fechada**, o dono do remote tem de ser o dono do
core, e o que um script pode medir se mede por script (`members-validate.sh`, `baton-pulse.sh`,
`pr-merge-verified.sh`). O que ele não mede hoje (os campos de peça, o sponsor) a doutrina diz que se
confere lendo, e a revisão do critério 4 é julgamento declarado.

Fontes primárias:

- GitHub Docs, *About code owners*:
  <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners>
- Google, *Site Reliability Engineering*, cap. 32, *The Evolving SRE Engagement Model*:
  <https://sre.google/sre-book/evolving-sre-engagement-model/>

## 7. Crédito

As medições são da **curadoria**: o corpus do core, os briefs de revisão
`docs/evolution/review/feat-piece-owner-session.md` e `docs/evolution/review/feat-vps-ops-piece.md`, e o
padrão de mercado. O core aceitou o texto e escolheu o lugar.
