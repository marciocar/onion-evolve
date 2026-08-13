# Fixture de drift — caso BAD (Regra 16, forma CONJUNTIVA cross-line, ordem INVERTIDA)

O guia afirma que o orquestrador entrega __ONION_COMMANDS_DRIFT__ comandos
e __ONION_AGENTS_DRIFT__ agentes, e nada mais.

DUAS coisas tornam esta fixture load-bearing, e a 1a versão dela não tinha nenhuma:

1. ORDEM INVERTIDA (`comandos … e … agentes`). O feeder IRMÃO (ordem canônica
   `N agentes e M comandos`, mesma linha) NÃO casa esta ordem — se o feeder conjuntivo
   for removido, esta fixture deixa de ser citada. A 1a versão usava a ordem canônica
   numa linha só: o irmão já a acusava com a MESMA keyword do manifesto, então o caso
   passava com a guarda deletada. Fixture que sobrevive à remoção do que ela testa é
   fixture vazia — provado por mutação pelo Elenxo, não suposto.

2. QUEBRA DE LINHA NO MEIO DO PAR, como no sítio fundador
   (`codebase-guide.md:111-112`). É o que exige a leitura por parágrafo: trocar o
   `awk RS=""` por `cat` faz esta fixture deixar de casar.
