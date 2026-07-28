---
title: "ADR — transporte da federação: downstream por PULL, upstream por a2a assinado"
date: 2026-07-28
status: PROPOSTO (desenho ratificado; construção gated na palavra do maestro)
origem: enunciado do maestro 2026-07-28 — "a troca com arquivos por branch está insustentável"
kg: docs/onion/graph/m2-bridge-logto-2026-07.kg.yaml
---

# ADR — transporte da federação sem filesystem compartilhado

## Contexto: a topologia que o correio de arquivo impõe

O doc-bridge entrega por **cópia de arquivo**: `/meta:co-deliver` escreve no `inbound/` do
adotante, `/meta:co-relay` escreve no `inbox/` do core. Isso funciona — e cobra um preço
estrutural que só aparece quando se mede:

```
membros com local_path declarado : 12 de 12
de fato clonados NESTA máquina   : 12
hospedam endpoint para receber   : 1 (o core)
```

**Todos os 12 membros da federação estão clonados numa única máquina.** A federação escala
hoje até *"o que couber num VPS que pertence a uma pessoa"*.

E a alternativa que o desenho atual deixa é pior: para entregar sem filesystem compartilhado,
o core precisaria de **credencial de push no repo alheio** — o que fura o invariante I3 (*um
escritor por repo*) que o próprio protocolo declara.

Não é inconveniência operacional. É um teto.

## O que o a2a resolve, e o que não

O canal a2a existe e **não é vaporware**: o endpoint `/a2a` do core invoca o
`a2a-verify.sh` por `spawnSync`, rejeita fail-safe nomeando a camada que falhou, e o state de
replay registra um handshake **real** aceito em 2026-07-11 21:40 (`hs-real-1783806004`). As
chaves `metagamify-1.pem` e `granaai-1.pem` estão pinadas em disco.

Mas ele resolve **uma direção só**:

| direção | hoje | por quê |
|---|---|---|
| **upstream** (adotante → core) | a2a push, assinado | o core hospeda endpoint |
| **downstream** (core → adotante) | cópia de arquivo | **ninguém mais hospeda endpoint** |

Exigir que cada adotante hospede um endpoint é irreal — eles não têm servidor, e não vão
subir um só para receber changelog.

## Decisão

**D1 — Downstream por PULL, não por push.** A sessão do adotante busca os próprios anúncios
no endpoint do core:

```
GET /federation/inbox/<member-id>      (autenticado)
```

Ninguém precisa hospedar nada além do core, que já hospeda. Some o filesystem compartilhado,
some a credencial cruzada, some a exigência de 12 clones na mesma máquina. O hook de
SessionStart que hoje conta arquivos passa a consultar o que o core tem para aquele membro.

**D2 — Upstream segue push assinado, e ganha o remetente que falta.** Existe
`a2a-verify.sh`, `a2a-accept.sh`, `a2a-ssrf-check.sh` e as chaves pinadas — e **nenhum script
do core assina e posta**. Construímos o receptor e a alfândega, nunca o remetente. Um
`a2a-send` que viaje vendorizado é pré-requisito de "o adotante pode enviar" deixar de ser
declaração.

**D3 — Uma credencial M2M por adotante, no Logto.** Cada adotante é um chamador de rede
distinto: app próprio, revogável sozinho, com `sub` que nomeia quem chamou no log. É
exatamente a fatia 1 (*um app por chamador*) ganhando o consumidor que lhe faltava.

**D4 — Organização por adotante volta, mas SOB DEMANDA.** O escopo do `inbox` é
por-organização. As 7 organizações removidas em 2026-07-28 voltam **uma a uma, na primeira
matrícula** — pelo mecanismo já construído (`--enroll` cria sob demanda). Nada do que foi
desfeito precisa ser refeito à mão.

**D5 — Puxar ≠ aplicar.** Membro `mode: regulated` (granaai) tem `never-live-pull`. Buscar um
anúncio é **leitura**; aplicá-lo é outro ato, com gate humano. A camada 6 do `a2a-verify` já
separa os dois, e o pull herda a separação — não a dissolve.

**D6 — O `members.yaml` continua sendo o SSOT.** O Logto guarda a porta; a política de trust
(`can_advise_to`, `can_correct_to`, `diary_readable_by`) **não** migra para org roles. Isso
repetiria o segundo-registro-editável-dos-dois-lados que o ADR `logto-as-projection` (D1/D5)
existe para impedir.

## Revisão registrada — uma posição minha que caiu

Horas antes deste ADR, na mesma sessão, eu afirmei que *"os adotantes não autenticam em lugar
nenhum, logo o Logto não se aplica a eles"*, e usei isso para justificar a remoção das 7
organizações.

**A afirmação era verdadeira do desenho atual, e falsa do problema.** Sob D1, cada adotante
vira chamador de rede autenticado. A remoção das 7 organizações **segue correta** — elas
eram esqueleto sem consumidor no momento em que foram criadas — mas a conclusão de que
"adotante não autentica" não se sustenta uma vez que o transporte muda.

A distinção importa: o erro não foi remover; foi generalizar de *"não autentica hoje"* para
*"não autentica"*.

## Fronteiras declaradas

**O bootstrap da credencial é irredutivelmente manual, uma vez.** O adotante precisa receber
o segredo M2M de algum jeito, e o único honesto é **na adoção, fora de banda** (o
`/meta:adopt` já escreve no alvo). Não há como evitar o primeiro contato; há como evitar que
ele se repita.

**O core vira dependência de disponibilidade.** Hoje o correio funciona offline: o arquivo
está lá, o adotante lê quando quiser. Com pull, bridge fora do ar = federação muda. Se o
arquivo continuar valendo como fallback, é preciso decidir **qual é a verdade quando os dois
divergirem** — e essa pergunta não está respondida neste ADR.

**Nada disto foi construído.** D1-D5 são desenho. O único elemento medido é o diagnóstico (12
clones, 1 endpoint, o handshake real). Não afirmar que o pull funciona antes de ele existir.

## Gatilho

Construir quando o maestro ratificar a direção. Ordem sugerida, do que dói mais para o que
dói menos: **D1 (pull downstream)** — tem 23 + 14 anúncios parados esperando e é o lado onde
o arquivo mais dói — depois **D2 (`a2a-send`)**, e só então a fatia 4 (endurecer a porta do
`/a2a`), que hoje guardaria trânsito de uma carta a cada vinte dias.
