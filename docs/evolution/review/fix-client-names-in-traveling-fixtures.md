---
title: 'Resíduo — a guarda contra nome de cliente continha nomes de cliente, e estava pública'
date: 2026-09-18
branch: fix/client-names-in-traveling-fixtures
reviewed_diff_sha256: 6bfc098f868ccb8fd5d15b76bff2d1823a6e964fd176a8e38eb02acc8705515b
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Exposição PÚBLICA e ATIVA, achada pelo USO — adotar um repo novo e varrer o alvo por nome de
  cliente. Quatro nomes comerciais reais, um deles sob NDA, dentro da própria guarda que existe
  para impedir nome de cliente de viajar. Nada acusou porque a REGRA 36 deriva os termos do
  members.yaml e nenhum daqueles clientes está registrado.
---

# A guarda continha o que ela existe para barrar

```
.claude/validation/vendor-scrub-form-check.sh   ← VIAJA
  HPE Autos · Prodfiel Sistemas · Itau Digital · Zelda
```

Verificado **no remoto público**, não no disco: `gh api repos/marciocar/onion-core/contents/...`
devolvia as fixtures com os quatro nomes. Publicar *"PoC \<cliente\>"* e *"adotante: \<cliente\>"*
revela **carteira de clientes** — comercialmente sensível e, para o cliente sob NDA,
potencialmente quebra.

## Por que nada acusou, e não é defeito da guarda

A REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) deriva os termos do
`members.yaml`. **Nenhum daqueles clientes está registrado.** É `[[vendor-scrub-blind-spot]]` com
dano **consumado** em vez de hipótese — e irmão do nó que já media *9 de 19 adotantes fora do
registro*.

**Como apareceu:** não por leitura, não por refutador. Por **adotar um repo novo** e varrer o alvo
por nome de cliente. O uso achou o que a inspeção não acharia.

## A cura tem duas metades, porque uma só seria meia-cura

**(1) As fixtures usam nomes fictícios que preservam a FORMA testada** — sigla caixa-alta + 2º token,
nome normal + 2º token, conector, acento UTF-8. A bancada da guarda segue **11/11**: a cura não
cegou nada. Trocar nome sem preservar forma teria matado o teste em silêncio.

**(2) Uma terceira fonte de termos, DECLARADA**, em `docs/evolution/federation/client-terms.txt` —
que **não viaja**, e essa é a invariante que torna a cura possível em vez de ser o vazamento. Uma
lista de nomes de cliente dentro de `.claude/` seria, ela mesma, o problema.

**Registrar no `members.yaml` não serviria:** o `name:` de um membro é **projetado** para o
`federation-console.html` e o `federation-map.md` públicos. Trocaria um vazamento por outro. Aqui o
nome entra para ser **procurado**, nunca exibido.

Provado ao vivo: injetei `PoC HPE Autos` num agente e a REGRA 36 **pegou**. Antes, passava calada.

## Achado 3 — eu escrevi o nome do cliente na fronteira de NDA

No repo do adotante, o comentário do `.gitignore` que **cria** a fronteira citava o cliente — assim
como o README do `material/`. O texto que existe para manter o nome fora carregava o nome. Curado
lá também; o precedente continua registrado sem nomear ninguém.

## Limite declarado

O **histórico público** do `onion-core` mantém os nomes até o GC do GitHub. Force-push torna
**inalcançável**, nunca inexistente — e quem clonou tem cópia. A porta precisa de re-materialização
para que o HEAD público saia limpo.
