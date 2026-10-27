---
branch: docs/manual-canais-a2a
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 8
findings_real: 8
tokens: 145678
duration_min: 4
findings_fixed: 8
verdict: CORRIGIDO
elenxo: sim
reviewer: agente refutador independente (contexto novo, só leitura), conferindo cada afirmação do manual contra o vivo
nota: "tokens = só os do refutador; cerca de 62 afirmações conferidas: 54 confirmadas, 6 mais fortes que a evidência, 2 sem fonte"
---

# Passada adversarial: `docs/manual-canais-a2a`

## O que muda

- `docs/knowledge-base/concepts/inter-session-channels-a2a.md`: o manual de canais entre sessões e A2A
  (Agent-to-Agent), com os três casos, o doc-bridge, a confiança, o quadro de decisão e a seção "Em estudo".
- `docs/knowledge-base/index.md` e as contagens escritas à mão (112 para 113 KBs) em `docs/INDEX.md`,
  `docs/onion/getting-started.md`, `docs/onion/agents-reference.md`, `docs/technical-context/01-core/project-charter.md`
  e `docs/knowledge-base/meta/onion-framework-identity.md`; `docs/onion/inventory.md` regenerado.
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: três selos pelo `kg-decide-seal.sh` (os nós
  `D_A2A_EMPRESA_PESQUISA_DECISION_1027` e `D_MANUAL_CANAIS_A2A_AGORA_1027` e o fechamento de
  `Q_COMPOSICAO_IDA_E_VOLTA_VIVA_1025` por resposta livre) e a pergunta aberta
  `Q_IDA_E_VOLTA_VPS_NOTEBOOK_MEDIDA_1027`, escrita à mão porque o selador só cria nós `D_` (recusou com rc 2).

## Achados

O refutador conferiu cada afirmação contra os comandos, os hooks, os nós dos grafos, a máquina
(`cc-socks`, `claude --version`, settings do usuário) e a descrição atual da `SendMessage` (2.1.311).
Todos os oito foram corrigidos no manual.

1. **Omissão:** o manual dizia que entre máquinas o doc-bridge depende de alguém transportar o arquivo. No
   sentido core para adotante existe o pull autenticado (`inbox-pull.sh`, chamado pelo hook
   `co-evolution-inbox-check.sh`). Corrigido: os dois sentidos separados.
2. **Sem fonte:** a forma `uds:` do endereço não está na descrição da ferramenta, que diz que o nome é o
   endereço. Corrigido: marcada como observação do maestro, e o passo de resposta ganhou o plano B pelo nome.
3. **Mais forte que a evidência:** "ida provada entre pessoas e empresas". A medida de 2026-10-21 foi um
   usuário descartável do SO no notebook do próprio maestro. Corrigido na tabela e no título da bala.
4. **Mais forte que a evidência:** "o socket não atravessa usuários do SO" foi medido com o Remote Control
   desligado. Corrigido com a condição.
5. **Mais forte que a evidência:** "igual ao nativo é impossível por construção" vem de um claim `open` do
   spike. Corrigido para "a tese do spike, ainda aberta".
6. **Gatilho enfraquecido:** o parque do A2A como produto exige separar a identidade do registro **e** tirar
   a fronteira MOAT do nome do motor. Corrigido.
7. **Subestimado:** a volta de 2026-10-22 foi pelo bridge de produção, não só no harness do spike. Corrigido.
8. **Sem fonte:** "o harness acha o `<pid>.sock` atual" é mecanismo não documentado. Corrigido para o que se
   sabe: o nome segue valendo depois do reinício (relato do maestro).

## Mutantes

Não se aplica: o PR não traz guarda nem código executável. As guardas que julgam a KB nova rodaram sobre
ela: `door-leak-scan.sh` (nenhum id de adotante nem caminho de conta), `ops-citation-travel-check.sh`
(nenhuma citação a `ops/`), `kb-vendored-link-check.sh` (nenhum link vivo para caminho core-privado) e
`kb-index-check.sh` (índice em dia).

## Limites declarados

- Dois fatos vêm de relato do maestro e não têm como ser conferidos no repo: o PID que mudou em 2026-10-26 e
  a sessão na nuvem que hoje recebe e não responde. A KB os atribui assim. O "não responde" tem também a
  descrição do `ListAgents` lida em 2026-10-07 (2.1.293), que esta sessão não pôde reler.
- O comando `/meta:federation-a2a` diz "9 cláusulas" no cabeçalho, e a doutrina tem dez. É defeito do
  comando, fora do escopo deste PR; a KB diz dez.
- A KB não entrou na lista world-facing do gate de frescor doutrinário (REGRA 42 (Gate de FRESCOR
  DOUTRINÁRIO, com catraca)): carrega `verified_at` e `source` no frontmatter, mas a lista mora em
  `.claude/validation/`, que outro agente está mexendo em paralelo.
