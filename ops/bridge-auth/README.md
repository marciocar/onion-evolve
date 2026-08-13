# bridge-auth — provisionamento Logto do onion-bridge

`logto-provision.sh` provisiona o tenant/escopos do bridge no Logto.

**A cópia `bridge-src/` FOI ELIMINADA (2026-08-13).** Era um espelho manual de 6 dos 11
fontes do bridge, sem detector de deriva — e derivou nas DUAS direções (o `chat.ts` daqui
ficou sem o fix de workspace `e09d4c7`; o `identity.ts` daqui ficou MAIS novo que produção).
A razão de existir (revisar auth quando "o bridge não era repo") morreu: o código canônico
vive em **`marciocar/onion-bridge`** (privado), e é lá que se lê, revisa e abre PR. O ciclo
de update é `ops/update-bridge.sh` (execução manual, sem agendamento — a igualdade
`main == produção` só vale depois de rodá-lo, e é ele quem a MEDE: fase 5 compara os HEADs
com origin/main). Espelho sem consumidor é mentira em câmera lenta.

**Teto declarado (7º Elenxo):** os `trace:` dos grafos que apontavam para a cópia agora usam
o path absoluto da VPS (`/home/onion/onion-bridge/src/…`) — a REGRA 55 os põe "fora de
julgamento" (contados, nunca silenciosos): 14 âncoras saíram do alcance dos mecanismos do
repo, e esse balde não tem baseline que vigie crescimento.
