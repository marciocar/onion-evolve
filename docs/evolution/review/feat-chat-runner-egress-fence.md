---
branch: feat/chat-runner-egress-fence
pr: 1168
date: 2026-10-16
reviewed_diff_sha256: f5ae82708847515bb17054be6c8a05e01702598db051fb4ebdfc471157e7f2a1
reviewed_code_sha256: 58fcdd4e73e4bda5ece574f1f22d5533ee02ffd8559aab87eb5b8411b5713926
findings_total: 15
findings_real: 13
tokens: 383000
duration_min: 150
findings_fixed: 11
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "refutador opus (general-purpose) em 2 passadas sobre os dois diffs (core e onion-bridge#75): 1ª 9 achados (1 derruba, 4 corrigem, 3 cosméticos, 1 teto), 2ª 5 achados (1 corrige, 4 cosméticos); mais 1 achado da própria bancada (o wait sem pid)"
nota: "tokens = soma dos dois subagentes do refutador (164.988 + 217.773, contados juntos como ~383 mil), sem o condutor. Achados reais 13 de 15: os 2 restantes são teto declarado, sem cura nesta mudança (AF_UNIX, forja dentro da slice)."
---

# Passada adversarial: `feat/chat-runner-egress-fence`

## O que muda

A opção A do degrau 3, escolhida pelo maestro em `D_DEGRAU3_SEM_OBJETO_NO_CONVIDADO_1016` («Parquear + fechar a
rede»): a **cerca de rede** do runner do convidado, **desligada por padrão**.

- `ops/chat-runner.sh`: `install --egress-fence` instala o drop-in `onion-chat@.service.d/60-egress-fence.conf`,
  renderizado do modelo do bridge servido (onion-bridge#75) com os endereços globais do host medidos agora. A cerca
  nega o loopback, o link-local, as faixas privadas e o próprio host, **sem nenhum `IPAddressAllow`**, e o DNS vai aos
  resolvedores públicos pelo `resolv.conf` de upstream. A allowlist do tipo `fence` é fechada.
  - O verify prova três coisas: o efetivo da instância e das slices-mãe; a perna de controle contra a cerca numa unit
    transitória na slice do runner (TCP barrado onde o controle vê o alvo aberto, DNS e TLS com a API); e o aperto de
    mão pelo socket.
  - Instalada, a cerca é estado: o install sem a flag a mantém. O rollback imprime a remoção dela.
- `runner_identity` só conta linha do journal vinda da slice do runner (`_SYSTEMD_SLICE`, campo confiável).
- `ops/moat-targets.tsv`: o diretório de drop-ins do template entra como alvo do `chat-runner.sh`.
- A família `chat_runner` da bancada ganha os casos r38–r58, cada um com mutante.
- Grafo: `E_CERCA_DE_REDE_CONSTRUIDA_1016` (teto 140 → 141, motivo no meta), emenda no `C_SUPERACAO_…` e o SYNTHESIS.

Os `confirmed` de maior impacto foram conferidos (REGRA 87 (PR que EDITA um `.kg.yaml` enxergou os `confirmed` dele)):
- `E_SPIKE2_SOCKET_LAUNCHER_DYNAMICUSER_1016` e `E_SYSTEMD_PROTECTPROC_HIDES_OTHER_USERS_ONLY` não são tocados: a cerca
  é de rede e soma ao UID distinto.
- `E_SPIKE3_APPARMOR_SANDBOX_REQUIREMENTS_1016` segue como o passo do degrau 3, sob gatilho.

## Achados

1ª passada:
1. DERRUBA: `IPAddressAllow=127.0.0.53/32` abria todo serviço escutando em 0.0.0.0 (o proxy reverso e o sshd), porque
   o filtro do cgroup julga só o endereço. CURADO: o furo saiu, e o DNS vai aos resolvedores públicos. O CLI real sob a
   cerca recebeu 401 da API com chave inválida; sem o bind, ele trava no DNS.
2. `IPAddressDeny=` vazio zera a lista no systemd e passava nos dois validadores. CURADO (r52 e mutante do bridge), e
   o ensaio passa o vazio fiel.
3. Um `IPAddressAllow` na slice-mãe vence o deny. CURADO: o verify exige vazio em três slices (r54) e a sonda roda na
   slice do runner (r58).
4. Timeout sozinho não prova a cerca. CURADO: perna de controle (r55) e alvos do stub e do IPv6 do host.
5. A bancada não exercitava o classificador. CURADO: `--classify-selftest` real (r56).
6. A identidade do runner no journal era forjável pelo identificador. CURADO: filtro por `_SYSTEMD_SLICE` (r57),
   medido com 5 de 5 linhas reais. Teto: dentro da slice ainda se forja, e isso está declarado no nó.
7. `host_addrs` não roda sozinho, e uma troca de IP só aparece no próximo verify. DECLARADO.
8. O nó e o SYNTHESIS afirmavam o furo e o EPERM. CURADO.
9. O AF_UNIX segue aberto (barramento do sistema, postgres, journal). TETO DECLARADO no nó.

2ª passada:
10. A âncora do mutante r38 não casava mais. CURADO.
11. Nenhum caso cobria o `--slice`. CURADO (r58, e o falso exige a slice).
12. O ramo `errno` do classificador era código morto. CURADO (removido).
13. Forja dentro da slice. TETO DECLARADO no nó.
14. O `C_SUPERACAO` ainda descrevia o furo. CURADO: emendado, com aresta CONSTRAINS vinda do nó novo.

Da bancada:
15. O `wait` sem pid do caso r24 esperava também o bridge falso. Com o `sleep` de 3600 s, a família travava; com o de
    600 s, ela gastava 10 minutos à toa e o processo morria antes dos últimos casos. CURADO: `wait` no pid da trava, e
    o `sleep` de 3600 s com motivo.

## Mutantes

Core: os 21 casos novos (r38–r58), cada um com mutante. A família `chat_runner` deu **116 passaram, 0 falharam**
(todos os mutantes mortos). Bridge: `chat-runner-mutants.sh` deu **59/59 mortos** (11 novos da cerca).

## Limites declarados

- Não houve `--apply` com a cerca no host real nem turno real de convidado com a API dentro dela. O CLI sob a cerca foi
  provado com chave inválida (401).
- O wrapper antigo reprova com a cerca instalada, então o merge deste PR vem **antes** do `--apply`.
- A bancada inteira do bridge falha só no `vendor-manifest` (`vendor/kg-ssot`). Essa falha já existia no `main` do
  bridge (b7d224d) e não vem desta mudança.
- O teto do AF_UNIX e o da forja dentro da slice estão no nó.
