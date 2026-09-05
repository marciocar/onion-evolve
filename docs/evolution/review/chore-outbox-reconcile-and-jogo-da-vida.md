---
title: "Revisão — o dogfood de uma adoção achou 3 defeitos que 6 rodadas de LEITURA não acharam; e a passada seguinte achou 13 nas minhas curas"
date: 2026-09-05
branch: chore/outbox-reconcile-and-jogo-da-vida
reviewer: "1 refutador (opus, mandato de REFUTAR, default REPROVADO na dúvida) sobre o artefato COMPLETO, seguindo a calibração da sessão anterior (a 1ª passada rende os achados de PRODUTO). Antes dele, o próprio DOGFOOD da adoção — executar o artefato, não ler o diff — achou 3 defeitos."
reviewed_diff_sha256: 43360d81d1c19568bac7fa421094e701bc5dd1d49f4e458ef53f360b4f44c255
findings_total: 16
findings_real: 16
verdict: APROVADO
tokens: 0
duration_min: 96
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O que esta revisão ensinou

**Executar acha o que ler não acha.** O dogfood da adoção (rodar `/meta:adopt` de verdade num repo
real) achou **3 defeitos** que as 6 rodadas adversariais do PR anterior — todas de leitura — não
acharam. Depois, uma passada adversarial sobre as minhas curas achou **13 mais**, e a maioria era
das curas, não do código original. Dos 16, **3 mudaram produto** e **2 eram invariante quebrado por mim**.

## Os 3 do DOGFOOD (executar a adoção)

1. **`__fixtures__` do Vitest reprovava a REGRA 52** — 5 fixtures deliberadamente inválidas (o teste
   do radar-JS do adotante) viraram 5 HARD no dia 1, e as saídas eram apagar o teste ou desligar a
   guarda. O `grep -v '/fixtures/'` estava copiado em **6 consumidores**, um vocabulário só.
2. **O passo que regenera baselines lia `role:` ANTES do carimbo** — sem stamp o `onion-version.sh`
   devolve `role: source` e o helper recusava achando que o alvo era o core. Medido: 114 chaves de
   dívida do core herdadas se ninguém re-rodasse (`kg-verification` 28 + `plugin-bare-path` 86).
3. **REGRA 15 sem catraca** — quem já escreveu contexto de domínio antes de adotar nasce HARD-vermelho
   (29 arquivos do adotante). Carimbados com data **derivada do git**, não inventada.

## Os 3 de PRODUTO da passada adversarial

4. **O plugin público nascia MORTO** — o predicado não estava no `VALIDATION[]`; medido dentro do
   host: `rc=2` sem ele, `rc=0` com.
5. **A guarda de dependência do assembler só via `lib/`** — aceitou montar o bundle morto. A guarda
   cujo texto é "o bundle nao fecha o grafo de dependencias" falhou pela classe que persegue.
6. **`seed-adoption-graph` CANCELAVA a semente do KG** — o único sítio onde a isenção incompleta não
   afrouxa um gate: fixture respondia "o alvo já tem grafo" e a semente nunca nascia. Reproduzido.

## Os 2 invariantes que EU quebrei (os melhores achados do lote)

7. **`members.yaml` declarava `pin-ok` sobre árvore que eu divergi.** Copiei 6 scripts do meu ramo
   não-mergeado para o adotante; o pin não os contém e `onion/vendor` — base do 3-way — também não,
   então o próximo `--update` veria a mudança do CORE como customização local do adotante. É o
   modo-de-falha que o `pin-integrity-check` existe para pegar, declarado limpo por mim. **Revertido.**
8. **O relatório dizia "curado" para o que ainda não chegou.** Verbos separados nos dois documentos.

## Os 8 de mecanismo/guarda (todos meus)

Predicado com OR errado (`onion-validate.yml` não emite `onion-review-verdict`) e o outro ramo
**negando um gate que existe** (a REGRA 56 vem do lint vendorizado) · **mudez** alcançável por 1
caractere (`case` sem `*)`) · a cura da mudez matando a API `source` documentada · **perf** (1 fork
por grafo: 1898→2234 ms; curado a 1147 ms, saída byte-idêntica) · **flaky** por CWD no caso (d) ·
guarda casando **menção** em vez de invocação · `|| true` engolindo o rc=2 do `regen-baselines` ·
lista de consumidores digitada em vez de derivada.

## Duas decisões de escopo, contra o impulso de curar tudo

- **7º sítio revertido**: alcance zero e quebrava 4 guardas boas de outra família. Dívida declarada
  no código, com gatilho escrito.
- **Fixtures da bancada na árvore viva**: 3 casos criam artefato no dir real de propósito (é o que
  prova que o LINT acusa) e um `git add -A` concorrente os stajava — 3 interrupções nesta sessão.
  Cobertas por CONVENÇÃO no `.gitignore`, não pelos 3 nomes; e o gate PROVA por comportamento que o
  índice fica limpo após a bancada.

## O padrão da sessão, nomeado

**Lista que envelhece é o defeito — e ele reaparece uma camada acima a cada cura.** Na guarda
(vocabulário), no piso da guarda (número digitado que reprovou o estado correto no mesmo dia), e no
comentário da guarda (a nota de dívida citava o nome do arquivo e criava um consumidor falso na
derivação). As três curas: classe em vez de lista, sítios nomeados em vez de contagem, e descrição
sem o literal.

## Limites DECLARADOS

- **O adotante está a 6 HARD**, não a 0. Chegou a 0 durante a sessão com a cópia manual, que foi
  revertida pelo achado 7. A cura chega por `/meta:adopt --update` **depois** do merge — e essa é a
  ordem certa, não uma pendência.
- **Dogfood do `--update` não rodado**: o caminho que entrega a cura ao adotante só existe pós-merge.
  **Gatilho:** rodar `--update` no `jogo-da-vida` assim que este PR mergear, e conferir que o 3-way
  não produz conflito espúrio (é o que o achado 7 previu).
- **`tokens: 0`** — o custo do refutador não foi instrumentado (sem run de workflow com journal).
  Declarado, não estimado.
- A REGRA 15 foi curada **no adotante** (carimbos), não no core: dar catraca a ela é fio aberto.
  **Gatilho:** o próximo adotante que já tenha contexto de domínio escrito.

## Fora de escopo (com gatilho nomeado)
- CI do Onion no adotante (`✓ APLICÁVEL`, mas custa minutos da conta dele — decisão do dono).
- Teto dos 2 grafos do adotante (valores iniciais postos, marcados como ajustáveis).
- `Q_PLUGIN_SEM_DRIVE_NEM_ADOPT` · `Q_MARKETPLACE_PUBLICO_EM_GERACAO_ANTIGA` — nós com gatilho.
