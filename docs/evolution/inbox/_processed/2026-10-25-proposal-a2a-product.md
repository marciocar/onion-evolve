---
title: 'Proposta da curadoria: A2A do core como produto próprio — parquear; a fronteira do código quase separa, a do registro e do MOAT não'
date: 2026-10-25
from: onion-curation
to: onion-evolve (core)
type: proposal
issue: SAC-247 (Linear, estudo curation-dissect, família ideia)
kg: docs/evolution/dissect/a2a-product-2026-10/a2a-product-2026-10.kg.yaml
decision_node: D_A2A_PRODUCT_VERDICT (open; o core sela)
---

# A2A como produto próprio: o que a escada mediu e o que propomos

A pergunta era se vale extrair a federação A2A do core (transporte, convite, aceite, fila, chaves, doutor, console)
como projeto próprio, com repo, versões e vendor de volta no core, no molde do KG-SSOT. Esse ganho foi comparado a
duas saídas: manter a federação no core, ou usar só o SDK oficial do protocolo. O plano foi pré-registrado em
`STAGE0.md` (`c650e34`) e o desenho do N2 entrou como emenda antes de rodar (`N2-PLAN.md`, `aefa8f9`). Usamos o
estado medido que vocês mandaram (`CORE-STATE.md`) como dado e conferimos uma amostra dele por comando no commit
`49dfa06b`, só em leitura.

## Veredito proposto

**Parquear.** O eliminatório E2 disparou no N2 pela régua pré-registrada, e não há consumidor fora do Onion. Nenhuma
superação foi medida. Escolhemos parquear em vez de rejeitar porque o Elenxo mostrou que o que prende é o registro,
o MOAT e o bridge, não o código, e porque nenhuma decisão do core veda a extração. Gatilho: o parque reabre quando
um nó superar `E_N2_E2_FIRES` (`--around …#E_N2_E2_FIRES --edge-type SUPERSEDES`, `min_count: 2`). Isso acontece,
por exemplo, com uma rodada nova do N2 depois de o core separar a identidade do `members.yaml` e redesenhar a
fronteira MOAT. Também reabriria se surgisse um consumidor fora do Onion.

Pontuados, só para registro (o eliminatório decide): P1=1, P2=1, P3=0, P4=1 provisório, P5=1 provisório, total 4.

## Evidência por nível

- **N0 (análogos).**
  - A spec A2A 1.0.0 deixa ao implementador o que a camada Onion faz. Pelo §8.4.3, a chave do cartão vem de `kid`
    e `jku` ou de um "trusted key store" opcional que a spec não define. A spec também não tem registro de pares,
    convite, aceite humano, fila de entrada nem diagnóstico. Logo, o E1 não dispara pela spec
    (`E_N0_A2A_SPEC_LEAVES_TRUST`).
  - O análogo externo é a AGNTCY: uma camada de identidade, descoberta, mensagem e observabilidade sobre o A2A e o
    MCP. A Cisco abriu o código em 2025-03 e o projeto foi para a Linux Foundation em 2025-07-29, com 65+ empresas
    apoiadoras e 5 membros formativos. Esse resultado é declarado, não medido. A AGNTCY toca a identidade, mas não
    convite, aceite, fila nem doutor (`E_N0_AGNTCY_ANALOG`).
  - O análogo interno tem medida. Aqui, o aceite de uma só release do kg-ssot (4.26.0) custou 6 PRs (#72 a #77),
    25 arquivos e 5 emendas em 2 dias. É um teto, porque inclui uma bancada vetorial (`E_N0_KG_SSOT_PRECEDENT`).
- **N1 (valor e para quem).**
  - O consumidor nomeado é só de dentro do Onion. O `members.yaml` tem 5 blocos `a2a:` (l.69, 105, 166, 820, 845).
    O `/meta:federation-a2a` está só no conjunto adoption (`roles.yaml:114`), e o vendor corta
    `federation-transport/` (`vendor-manifest.sh:205-216`). Conferido em `E_N1_CONSUMERS_ONLY_ONION`.
  - Nenhuma decisão veda a extração: o grep nos `.kg.yaml` dá 0 arquivo, e a RFC-0004 segue accepted. O E3 não
    dispara (`E_N1_NO_EXTRACTION_DECISION`).
  - Há uma divergência a reconciliar: medimos 30 entradas `- id:` no `members.yaml`, e vocês informaram 28
    (`C_CORE_STATE_MEMBERS_COUNT_DIVERGES`).
- **N2 (menor experimento).**
  - Pela régua, 6 dos 7 arquivos do conjunto A (o par verify/accept e o contrato de transporte) citam um caminho do
    core fora do conjunto e do contrato (0,857). Por isso o E2 dispara e P3 = 0. O diretório inteiro dá 0,895
    (`E_N2_E2_FIRES`).
  - O Elenxo testou a ressalva do jwks: contado o prefixo, a fração não muda (`E_N2_ELENXO_JWKS`).
  - O Elenxo também testou um fecho maior. Contando só código executável (referências `.sh`/`.py` sem comentário,
    sem o `lint-selftest.sh`), o par verify/accept fecha em **8 arquivos, com profundidade 2**. Seis estão em
    `federation-transport/` (accept, invite, keygen, send, ssrf-check, verify), mais `onion-untrusted-wrap.sh` e
    `trust-topology-check.sh` (`E_N2_ELENXO_EXEC_CLOSURE`). Com doc e comentário, o fecho lexical explode para 2.946
    arquivos.
  - Fora do léxico, há o acoplamento MOAT. O `moat-judge.py` reconhece pelo nome `a2a-invite.sh` (l.323) e
    `a2a-queue-live` (l.326), e o lint põe `/utils/federation-transport/` no `moat_path` (l.1960). Ver
    `E_N2_MOAT_COUPLING`.
  - O código é pequeno: 2.484 linhas de shell em `federation-transport/` e 614 em `ops/a2a-*`, como vocês
    informaram (`E_N2_CODE_SIZE`).
  - Leitura: a hipótese de vocês (extrair só verify/accept e o contrato) não passa na régua lexical. Ela sobrevive
    como redesenho de fronteira dentro do core: separar a identidade do `members.yaml` e tirar o MOAT do nome do
    motor. Esse passo vem antes de qualquer repo novo.
- **N3.** Não foi subido: a §7 da Etapa 0 para a escada quando um eliminatório dispara. P4 e P5 ficam provisórios,
  lidos do N0.

## O porquê do maestro (chegou depois da dissecação)

O maestro explicou a motivação: a independência do A2A serve à **comunicação entre sessões de desenvolvimento que
não dependa de o agente ser o Claude** (Codex e outros). O estudo não mediu esse eixo: o P2 contava consumidor fora
do Onion, e uma sessão Codex dentro do ecossistema já é o consumidor que importa. Isso não muda a régua nem o
veredito deste estudo, mas muda a pergunta seguinte. Propomos um estudo próprio, com Etapa 0, sobre o **canal entre
sessões neutro do agente**: quanto a federação de hoje depende do runtime do Claude Code (hooks, harness,
`moat-judge`) e o que falta para uma sessão Codex falar e ouvir por ela (`C_MAESTRO_AGENT_NEUTRAL_MOTIVE`).

## Duas leituras do E2

Pela régua pré-registrada (`N2-PLAN.md`, que conta **citação**), o E2 dispara (0,857). Pela redação da Etapa 0
(**dependência**), lida pelo Elenxo depois da rodada, só 2 dos 7 arquivos têm dependência executável fora
(`a2a-verify.sh` → `trust-topology-check.sh`; `a2a-accept.sh` → `onion-untrusted-wrap.sh`; 0,286): o E2 não
dispararia e o total iria a 5. As duas leituras dão **parquear**; vale a régua pré-registrada, e a divergência
fica nomeada (`E_OBJECAO_N2_CITATION_NOT_DEPENDENCY`).

## Análogos que o N0 não viu (Elenxo)

Fora do repo há camadas mais próximas da Onion sobre o A2A, nenhuma juntando convite, aceite, fila, pinagem e
doutor: a federação da Agoragentic (revisão humana antes de pinar chave), o PR #3706 do inflect-compliance
(pinagem do hash do cartão só após aprovação humana), o OyadotAI/A2ARegistry (sync de registro par a par) e a
discussão #924/#741 do a2aproject (registro e token de bootstrap de uso único). Vale o core olhar antes de
redesenhar a fronteira (`E_OBJECAO_N0_LAYER_ANALOGS_MISSED`).

## Superação

Nenhuma medida. Buscamos no corpus (`kg_query --text` com A2A, federação, identidade agente, relay hospedado,
agente protocolo e kg-ssot vendor) e na web (a busca da AGNTCY e da LF, o comunicado da AGNTCY e a spec A2A). A
AGNTCY Identity é a candidata parcial para a peça de chaves e identidade, mas não a medimos.

## Não verificado

- Os dues da AAIF foram confirmados pelo Elenxo na página primária, mas o elo A2A–AAIF (se e quando o A2A virou
  projeto da AAIF) segue sem fonte primária, e os 305 membros vieram só do resumo da busca.
- Da spec A2A, não lemos a §7 nem o trecho de 100000 a 170000 caracteres.
- Da AGNTCY, lemos só o comunicado: não medimos o repositório, o componente Identity nem a adoção real.
- O arquivamento do ACP pela AGNTCY (2026-04) e o A2A 1.0 com cartão assinado vieram só de fonte secundária.
- Não medimos se os 3 hubs registrados usam o A2A de fato.
- As 697 linhas de validação não foram reproduzidas (nosso recorte dá 1.135).
- Os 2 handshakes e o re-teste 54/54 foram informados, não abertos.
- O bridge e o Caddyfile foram informados, não lidos, e o inventário lexical não os vê.
- O custo recorrente de um repo A2A separado não foi medido.

## Quem paga

Hoje ninguém paga pela camada Onion do A2A além do próprio core, que a mantém e opera o receptor
`app.onionevolve.com`. Não há cliente, preço nem membro pagante. O protocolo é pago por dues de fundação: a AAIF (LF)
cobra Gold de US$ 200 mil a 220 mil e Platinum de US$ 350 mil a 370 mil, com 8 vagas (AWS, Anthropic, Block,
Bloomberg, Cloudflare, Google, Microsoft, OpenAI), pela página de membros. Os vendedores monetizam a plataforma ou o
gateway, não a cola; o corpus já tinha medido o A2A embutido em gateway, sem preço próprio (`cross-session-channel`,
`E_N0_CAPITAL`). Para o Onion, a via de bilhetagem é **indireta e não verificada**: operar uma rede ou um receptor
hospedado de governança para hubs. Extrair a camada como biblioteca não abre via nenhuma.

A palavra final é do core, pela lente de Aristóteles. Aqui nada é selado.
