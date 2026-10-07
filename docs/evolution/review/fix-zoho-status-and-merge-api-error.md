---
branch: fix/zoho-status-and-merge-api-error
pr: pendente
date: 2026-10-07
reviewed_diff_sha256: 1c9ff9172fd749a22b9f9b96bde6d3da851aa50183422caae0718d90ed3a8ea9
reviewed_code_sha256: 6ba7bb5d68fe7ca7c78d5ae0a18fd9ad7390c625b6aab55e09f091a5e524cb36
findings_total: 6
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 20
verdict: CONFORME-COM-DOIS-ACHADOS-CURADOS
reviewer: passada adversarial manual (6 ataques dirigidos) + mutantes executados; sem subagente refutador porque o executor é um fork, e fork não abre subagente (declarado, não escondido)
REVISOU: true
---

# Resíduo — `fix/zoho-status-and-merge-api-error`

**Origem:** sinal `2026-10-07-zoho-status-automatico-e-merge-500.md` (um adotante), triado pelo maestro
como "Zoho + merge agora". Quatro achados medidos contra o portal real e o core vivo.

## Limite do método, declarado antes dos achados

Passada **manual**, não por subagente independente: o executor é um fork, e fork não abre subagente. É a
revisão mais fraca que esta casa aceita. O revisor do CI é a segunda opinião, e o veredito abaixo é
hipótese até ele falar.

## Gate deste PR, por ordem do maestro (declarado)

Os commits saíram com `--no-verify` (checkpoint, ordem do maestro em 2026-10-07): o pre-commit **não**
rodou. A validação que valeu foi: as famílias tocadas (`pr_merge_verified`, `zoho_token`,
`zoho_adapter`, `env_exposure`: 53 casos, 0 falhas, `LC_ALL=C`) + os mutantes abaixo, o
`pr-finalize --push` (lint 0 HARD sobre o commit) e o **CI completo verde** antes do merge pelo
`ops/pr-merge-verified.sh`. A bancada inteira só roda no CI.

## Mutantes (executados, todos morderam)

| cura | mutante | caso que reprovou |
|---|---|---|
| rc do `gh api` lido à parte | voltar ao `2>/dev/null` sem rc | `pr-merge-verified: (o)` — a saída voltou a ser "ZERO check-runs… use --ci-inoperante" |
| cache do token | `if false &&` no ramo CACHE-HIT | `zoho-token: (a)(b)(f)` — 2 emissões para 2 chamadas |
| env-check pelo helper | `env-check.sh` de `origin/main` | `zoho-token: (g)` — 2 emissões em 2 testes |
| achados escritos no adapter | `zoho.md` de `origin/main` | `zoho-adapter: (l)(m)(n)` |

## Achado 1 — 4xx e 5xx recebiam a mesma ação (REAL, curado)

A 1ª redação dizia "tente de novo quando a API voltar" para qualquer erro do `gh api`. Um 404 (repo ou
head errados) ou um 401 (credencial) não se resolvem esperando: é o mesmo tipo de diagnóstico errado que
o sinal reportou, só que deslocado. Curado: 4xx diz que a leitura foi RECUSADA e manda conferir repo,
head e credencial; 5xx manda esperar.

## Achado 2 — falso positivo do vendor-scrub na própria cura (REAL, curado)

`module=tasks&layout_id` foi lido pela REGRA 36 como candidato a nome comercial (`tasks&layout`).
Reescrito como `module=tasks` e `layout_id=…` separados.

## Ataques que NÃO acharam defeito (e por quê)

3. **Corrida de duas fases emitindo juntas.** `flock` serializa. Teto: sem `flock` (macOS sem util-linux),
   duas emissões simultâneas ainda podem ocorrer — declarado no cabeçalho do helper como fronteira.
4. **Arquivo de cache corrompido.** `read` falha ou `exp` não é número → o teste numérico é falso → emite
   de novo. Não serve token lixo.
5. **Segredo exposto.** Vai ao curl por `-K -` (bancada (e) olha o argv do curl esboçado); ao helper, pelo
   ambiente do filho (legível só pelo mesmo uid). Nada impresso em stderr (bancada (d)).
6. **`mktemp` falhando no merge verificado.** O redirecionamento falha, o `gh` não roda, rc≠0 → morre
   dizendo API indisponível. Diagnóstico impreciso num caso raro, mas **fail-closed**: não mergeia.

## Teste ao vivo (só-leitura, credenciais autorizadas de um adotante)

Duas chamadas ao helper devolveram o **mesmo** token (comparado por hash, nunca impresso), o
`env-check --test zoho` disse `conexão OK` reusando o cache, e o arquivo nasceu `600`.

## Tetos declarados

- Os achados de status, token e milestone foram medidos **num portal só**, de teste, no layout padrão.
- O limite de ~30 emissões é estimativa do adotante, não número documentado.
- O ciclo do engineer **já** chama `updateStatus` (`/engineer:start` → `in_progress`; `/engineer:work` →
  `done` por subtask). O que ele **não** faz é gravar o % de progresso da task-mãe a cada fase; o adapter
  agora diz como (`completion_percentage`), mas ligar isso ao `/engineer:work` ficou **fora** deste PR.
