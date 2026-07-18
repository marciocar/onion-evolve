# Pesquisa: camada de sync local-first do life-KG (deep-research, 2026-07-18)

> Fonte: deep-research `wlgpeo1sj` — 104 agentes, verificação adversarial, quase tudo em fonte primária
> (docs de vendor / artefatos GitHub, maioria 3-0). Resolve `Q_SYNC_STD`; re-escopa `Q_GITSYNC`.

## Veredito: **git FICA o SoT.** O problema é *executar git no device*, não o modelo de sync.

O caso — **git-já-SoT + KG append-mostly (REFUTES/SUPERSEDES) + N=1 multi-device + RN + soberano** — resolve as
3 perguntas duras de forma limpa:

1. **CRDT é over-engineering p/ N=1?** Sim. CRDTs existem p/ co-edição concorrente multi-usuário; N=1 single-user
   sem co-edição não precisa da máquina de merge concorrente. No máximo **complementa** git (buffer de edição offline).
2. **git é a escolha natural?** Sim. O KG append-mostly (REFUTES/SUPERSEDES ~ commits/merges) mapeia direto em git.
   O problema é **execução** ("git no device"), não o modelo de dados.
3. **CRDT/local-first-DB complementa ou substitui git?** Os engines maduros **SUBSTITUEM** git — todos exigem um
   **DB no servidor como SoT** → **quebram "origin = fonte única"**. Logo: complementar (talvez), substituir (não).

**Ink & Switch valida:** a definição canônica de local-first (device = cópia primária; servidor = secundário)
faz **git-como-SoT ser um design local-first legítimo, não um compromisso**. (Caveat 2-1: "origin = fonte única"
tende a server-primary vs o paper que põe o servidor como secundário — tensão leve, defensável p/ 1 usuário soberano.)

## Ranking por fit
| # | Padrão | Veredito |
|---|---|---|
| 1 | **git-sync robusto** (git no device) | ✅ **recomendado** — mantém o SoT, alinha à doutrina |
| 2 | CRDT-complementa-git (buffer offline que commita) | 🟡 só se merges offline concorrentes virarem reais; Jazz é candidato (não-verificado) |
| 3 | local-first-DB substitui git | ❌ **desqualificado** — server-DB vira SoT, quebra "origin = fonte única" |

**Desqualificados como SoT (mas RN-capazes):** PowerSync (Postgres/Mongo/… SoT; RN GA), ElectricSQL (Postgres SoT,
read-path só), Zero (server-authoritative), Jazz (sync server próprio). Nenhum aceita git como backend.

**CRDTs em RN:** **Automerge NÃO roda em produção RN** (Rust→WASM, Hermes sem WASM; PR #1099 draft dormente,
issue #574 aberta). ⚠️ **Yjs NÃO foi coberto** — é pure-JS/sem-WASM, provavelmente **bem mais viável** que Automerge;
fica como pergunta aberta (o veredito "CRDT não roda em RN" vale só p/ Automerge).

## Caminho REAL de execução (resolve o modelo do `Q_GITSYNC`)
**isomorphic-git dentro do `nodejs-mobile`:**
- `isomorphic-git` é BYOFS, **sem suporte RN oficial**, real-mas-áspero (bugs iOS #1994/#1997).
- **Rota robusta = `nodejs-mobile`:** embarca um **Node.js real (v18.20.4) no device** (Android/iOS), plugin RN oficial
  (`nodejs-mobile-react-native`) roda Node em thread de fundo com messaging bi-direcional. isomorphic-git (JS puro)
  roda **trivial** ali, com `fs` real — **evita o fs-shim**.
- ⚠️ Maturidade: nodejs-mobile core último release **out/2024** (Node 18 perto do EOL); adoção **modesta (~213 stars)**;
  **sem Expo Go** → exige **prebuild/bare (dev-client)** — o que o stack já assume (executorch também exige dev build).

## Caveats honestos + perguntas que ficam
- Recomendação = confiança **média** (síntese sobre fatos primários fortes).
- **Yjs em RN** não verificado (pure-JS, provavelmente viável) — vale um check antes de descartar o caminho CRDT-complementa.
- **Rota mais leve** (fs-shim sobre expo-file-system + isomorphic-git em Hermes, **sem** nodejs-mobile) aceitando os bugs iOS —
  tradeoff (tamanho do app, robustez) **não quantificado**. Vale um spike comparativo.
- **Perf** do isomorphic-git+nodejs-mobile num KG crescente de muitos `.kg.yaml` (clone/commit/latência/RAM) — sem benchmark.
- **Design de reconciliação N=1 multi-device:** como históricos offline divergentes de 2 devices do mesmo dono fazem merge
  em git (sem CRDT) — é o desenho concreto a fazer.
