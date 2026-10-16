---
branch: docs/chat-degrau3-object-measured
pr: 1167
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 12
findings_real: 10
tokens: 317000
duration_min: 75
findings_fixed: 10
verdict: CORRIGIDO
elenxo: sim
reviewer: "refutador opus (general-purpose) em 2 passadas: 1ª 7 achados (4 corrigem, 1 cosmético, 2 sem violação), 2ª 5 achados (3 corrigem, 2 cosméticos), todos curados no texto; nenhum derrubou a tese"
nota: "tokens = soma dos dois subagentes do refutador (149.819 + 167.012), sem o condutor. PR só de grafo e projeção: sem código, sem caso de bancada e sem mutante (dito abaixo)."
---

# Passada adversarial: `docs/chat-degrau3-object-measured`

## O que muda

O grafo `chat-agent-isolation-2026-10` ganha 4 nós (teto 136 → 140, motivo no meta) e o SYNTHESIS é atualizado:

- `E_DEGRAU2_EM_PRODUCAO_1016` (PROD): o `--apply` do degrau 2 (11:31 UTC) e o verify repetido por esta sessão
  (rc 0, n_fail=0, aperto de mão pelo socket sob UID próprio, `CHAT_RUNNER_SOCKET` no MainPID, bridge b7d224db,
  /health 200). Não medido: turno real de convidado com a API.
- `E_DEGRAU3_OBJETO_MEDIDO_1016`: com os degraus 0 e 2 de pé, o sandbox nativo não protege nada no convidado. Ele
  cobre só Bash, PowerShell e Monitor, e o convidado não tem nenhum dos três. A rede que resta é a do WebFetch.
- `C_SUPERACAO_20261016_EGRESS_PELA_UNIT_NAO_PELO_SANDBOX`: `IPAddressDeny=` na unit do runner (spike medido),
  com o critério para reabrir o degrau 3.
- `D_DEGRAU3_SEM_OBJETO_NO_CONVIDADO_1016`: decisão aberta para o maestro, com 3 opções (A recomendada).

**Decisão tomada sem o maestro:** NÃO construir o degrau 3 (socat, bwrap privado, perfil AppArmor). O mandato
dizia que, sem objeto medido, a entrega é o nó de medição mais a decisão aberta. Nada foi instalado no host.

Confirmed de maior impacto conferidos (REGRA 87 (PR que EDITA um `.kg.yaml` enxergou os `confirmed` dele)):
`E_SPIKE3_APPARMOR_SANDBOX_REQUIREMENTS_1016` segue válido como o passo de instalação, sob gatilho;
`E_SPIKE2_SOCKET_LAUNCHER_DYNAMICUSER_1016` é suportado pelo nó PROD; `E_SYSTEMD_PROTECTPROC_HIDES_OTHER_USERS_ONLY`
não é tocado (o segredo continua fechado pelo UID distinto); `E_SANDBOXING_SHELL_ONLY` é suportado, com a
ressalva de `E_OBJECAO_07` (deny de permissão vale para o Read).

## Achados

1ª passada (refutador opus):
1. Grep/ripgrep cairia no sandbox? NÃO: só o executor de shell chama `wrapWithSandbox` (medido no CLI 2.1.232). Sem violação.
2. Redirect e IPv6 no WebFetch: guarda de mesmo protocolo, porta e host; literal IPv6 nunca passa. CURADO (precisão no nó).
3. O fecho é protocolo + verificação de certificado, e a sonda usava CERT_NONE. CURADO (o texto já não diz "só protocolo").
4. A opção A não cobre os endereços públicos do host (22/443 abertos sob a deny). CURADO (teto e cura no C_SUPERACAO e na opção A).
5. A deny quebra o CLI? NÃO: DNS pelo stub 127.0.0.53, socket AF_UNIX intacto, `initialize` do CLI real respondeu sob a deny. Precisão do degrau 5 CURADA.
6. 27/27 sem artefato e trace apontando o scratchpad. CURADO (critério e instante da contagem; trace como descrição).
7. REGRA 99 (Nó de .kg.yaml sem caminho de máquina, julgado pela classe) e REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente): 0 acusação. Sem violação.

2ª passada:
8. "22 e 443 em IPv4 e IPv6" esticava (IPv6 22 não testado). CURADO.
9. "verifica o certificado" era leitura, não exercício. CURADO ("por leitura, não exercitado", no nó e no SYNTHESIS).
10. SNI generalizado e atribuição das 27 portas ao refutador. CURADO.
11. A decisão dizia "só pelo protocolo" nas opções A e B. CURADO.
12. Equivalência `www.` no redirect. CURADO.

## Mutantes

Nenhum. O PR não muda código nem guarda, só o grafo e a projeção. O gate é o radar `--integrity --schema` rc 0,
o `kg-contract-check.sh` rc 0 e o `kg-machine-path-check.sh` com 0 acusação.

## Limites declarados

- Não houve chamada à API: nem turno real de convidado sob o runner, nem WebFetch chamado por um modelo contra o
  loopback. Foram medidos o código, o preflight, o TCP/TLS e o `initialize`.
- O `IPAddressDeny=` foi medido só em unit transitória, não na unit real do runner. A allowlist fechada do wrapper
  recusaria a diretiva até ser estendida.
- A contagem de portas é do instante da sonda (~11:45 UTC); as efêmeras mudam.

## Re-revisão (selo do maestro, 2026-10-16)

O maestro respondeu a `D_DEGRAU3_SEM_OBJETO_NO_CONVIDADO_1016` com «Parquear + fechar a rede (Recomendado)», selado pelo `kg-decide-seal.sh` (radar `--integrity --schema` exit 0 e contrato rc 0). O diff novo é só o selo no nó (escolhida, descartadas, data, pergunta); não há código. A tese revisada nas duas passadas não muda: a opção A passa a ser o próximo PR de execução (unit do runner com `IPAddressDeny=` atrás de flag no bridge e a allowlist do `chat-runner.sh` com bancada e mutante).
