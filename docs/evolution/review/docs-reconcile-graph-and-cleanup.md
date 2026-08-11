---
branch: docs/reconcile-graph-and-cleanup
date: 2026-08-11
reviewed_diff_sha256: 7d7eaedb14337032e0c7bcfa34b84c2b95690a15d1b2c9a7c36d2bec40179bce
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: UM-NO-ESTAVA-STALE-CONTRA-MEDICAO-DA-PROPRIA-SESSAO
reviewer: varredura dos nós abertos contra o que foi medido no dia; a guarda de branch pt-BR acusou a própria branch desta reconciliação
---

# O grafo conta a verdade de hoje, não a de ontem de manhã

Varrendo os nós `open` do grafo de identidade contra o que foi **medido** no dia, três estavam
desalinhados — e um deles **contradizia uma medição da própria sessão**.

## 1. `Q_METADE_DO_BRIDGE_FORA_DO_REPO` → **refutado**

O nó afirmava que `workspace.ts` e outros viviam só em produção. **Falso**: `/home/onion/onion-bridge`
é repo git limpo, remote **existe e é privado** (`gh repo view` → `PRIVATE`, `ls-remote` rc=0).

Eu já tinha corrigido isso na prosa e **não no nó** — que é exatamente o que a diretiva *"grafo
sempre atualizado"* existe para impedir. A origem do erro fica registrada porque importa: um agente
leu `remote -v` e concluiu ausência. **Remote configurado não é remote que existe**, e eu repassei
sem verificar nenhum dos dois lados.

A lacuna real é menor e continua: `ops/bridge-auth/bridge-src/` é cópia manual de 6 arquivos **sem
detector de deriva** — e já derivou.

## 2. `Q_MFA_EM_ZERO_MAS_QUANTIFICAR_ANTES` → **done**

O bloqueio caiu, e **na ordem que o nó prescrevia**: e-mail nas duas identidades → SMTP no tenant
`admin` → `forgot_password_methods` ligado → **só então** os fatores.

O que falta não é meu: a **inscrição** de um TOTP é ato do dono, e ligar política obrigatória antes
disso seria a troca invasão→lockout que este nó existia para evitar.

## 3. `Q_BACKUP_AINDA_NAO_SAI_DA_MAQUINA` → segue `open`, com carimbo novo

36 artefatos cifrados, 3 scripts cifrando na origem, pacote de 1,1 MB entregue. **O destino imutável
continua aberto** — é conta a contratar, e a decisão é do dono.

## A guarda me pegou na primeira oportunidade

A branch nasceu `docs/reconcilia-grafo-e-limpa`, e o `BACKUP-EM-CLARO`/`BRANCH-EM-PT-BR` que eu
tinha acabado de alargar **acusou `grafo`** — no momento certo, dizendo *"renomeie AGORA, enquanto é
grátis"*. Renomeada antes de publicar.

É a prova de campo que faltava para o vocabulário acrescentado nesta rodada: ele pegou o autor da
própria regra, uma hora depois de escrita.

## Limpeza

Removidos: `protege-chave.sh` (temporário) e o diretório de montagem do pacote; duas branches locais
já mergeadas.

**Deliberadamente NÃO removidos**, porque apagar antes de haver cópia seria destrutivo:
`chave-privada-onion.asc` e `onion-backup-offsite-20260811.tar.gz`.
