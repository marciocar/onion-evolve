# 🧩 Doutrina do estado de uma peça — exclusiva, vendorizada, adotada, porta ou produto, e o gatilho que a move

Fragmento canônico. Nasceu de duas respostas do maestro em 2026-11-10. A primeira veio à pergunta se duas peças de
comunicação deviam ganhar adoção própria: «isso deve virar maquinaria ou doutrina do Onion então de identificar
peças que ele deve adotar e/ou vendorizar. O desenvolvimento do kg-ssot mostra isso, não?». A segunda
decidiu a forma: «Siga com doutrina e coluna no mapa, nos criterios da doutrina deve também entrar a
opção de promoção ou troca, afinal, uma peça exclusiva pode virar para outros adotantes ou clientes ou
funções com o tempo ou se mostrar diferente?». O selo é `D_PIECE_STATE_DOCTRINE_1110`, no grafo do
perfil de interconexão (core-only). A coluna que aplica esta doutrina a cada peça vive em `PIECES.md`,
ao lado do perfil.

**É doutrina, não guarda.** Nenhum check reprova uma peça por estado. A regra é lida por quem decide
(o core propõe e o maestro sela) e aplicada na coluna do mapa.

## 1. Os quatro estados

| estado | o que é | quem escreve | como os outros a recebem |
|---|---|---|---|
| **exclusiva do core** | vive só no core, sem consumidor fora dele | o core | não recebem |
| **vendorizada** | o código de um repo chega a outro por vendor com **carimbo por arquivo** e check | o dono da origem | cópia carimbada, nunca cópia solta, cópia do framework sem carimbo por arquivo, nem leitura viva do caminho |
| **adotada** | tem **repo e sessão donos**, registro no `members.yaml` e grafo próprio | a sessão da peça | pela versão que a peça publica |
| **porta ou produto** | distribuída para fora: porta pública, plugin, produto com semver | o dono, com release | por release com tag e versão |

Os estados se combinam: o kg-ssot é **adotado** (repo e sessão próprios) e chega ao core **vendorizado**.

## 2. As transições, nos dois sentidos

- **Promoção** (exclusiva → vendorizada → adotada → porta ou produto): a peça passa a servir a outros.
- **Rebaixamento** (o caminho inverso): a peça perdeu os consumidores que justificavam o estado e volta a
  ser mais simples. Adoção sem consumidor é uma sessão a mais sem trabalho que a pague.
- **Troca**: um padrão de mercado passou a cobrir o mesmo papel, e a peça nossa sai pelo padrão. É a escada
  de adoção de mercado (`D_ESCADA_DE_ADOCAO_1105`: adotar o padrão → perfil por cima → costurar → vendorizar
  peça nossa → parque) aplicada a uma peça que já existe.

## 3. Cada transição só com GATILHO MEDIDO

| gatilho | move para | como se mede |
|---|---|---|
| **consumidor novo** | vendorizada ou adotada | outro repo passa a usar o código (cópia, leitura viva ou chamada), ou a peça aparece em mais de uma ligação do mapa |
| **adotante ou cliente que pede** | porta ou produto | pedido registrado (sinal no inbox, issue, decisão), não suposição de demanda |
| **função nova** | adotada ou porta | a peça passa a cumprir um papel que não tinha (outro canal, outro público) |
| **padrão de mercado que cobre** | troca | o padrão faz o mesmo papel medido na bancada da peça, com ida e volta |
| **dívida sem dono** | adotada | a peça roda em produção ou tem dívida aberta, e quem escreve nela não é o dono da especificação (commits da peça vindos de sessão do core) |
| **reclassificação** | o estado que a evidência mostrar, nos dois sentidos | evidência medida de que a peça **é outra coisa** do que se pensava (o «se mostrar diferente» do maestro): não ganhou função, foi mal classificada. Ex.: o que se tratava como ferramenta interna é na verdade um contrato que três repos consomem |
| **perda de consumidores** | rebaixamento | o último consumidor saiu |

**Sem gatilho, a peça fica como está.** O estado não muda por simetria, por elegância nem por antecipação.
Cada proposta de transição leva o gatilho e a evidência, e é selada pelo maestro (`/meta:decide`) antes do
ato, que é do `/meta:adopt`, de uma publicação ou de um PR de vendor.

## 4. O caso que mostra o custo: o kg-ssot, promovido

O kg-ssot nasceu como maquinaria do core e foi **promovido**: repo e sessão próprios desde 2026-10-06,
semver, schemas e suíte de conformidade, e a volta ao core por `vendor/kg-ssot/tools/kg_vendor.py`, com o
carimbo `vendor/kg-ssot/.kg-ssot-version` (sha256 por arquivo) e check. **O custo, declarado:** 64 commits
de vendor no core desde 2026-10-10 (`git log --oneline --since='2026-10-10 00:00:00 +0000' origin/main -- vendor/kg-ssot | wc -l`, medido em 2026-11-10; sem a hora, o `--since` corta na hora atual do dia e devolve menos), uma sessão a mais para
manter, e a diretriz de independência do produto (`D_KG_SSOT_INDEPENDENTE_DE_HARNESS`, no grafo do próprio
kg-ssot), que proíbe o contrato de depender do Claude Code. A promoção se paga quando os consumidores pagam
esse custo; quando não pagam, o rebaixamento é a resposta certa, não a vergonha.

## 5. O que NÃO muda

- **O deploy segue do maestro.** Mudar o estado de uma peça em produção não muda quem a implanta (MOAT).
- **A arquitetura do core segue do core**, pelo perfil de interconexão (`D_INTERCONNECT_PROFILE_A_V1_1110`,
  `D_INTERCONNECT_EXEC_ORDER_1110`). A doutrina diz em que estado a peça está e por qual gatilho ela anda;
  a forma do contrato entre as peças é do perfil.
- **O invariante I3** (o core nunca commita em repo alheio) vale antes e depois. Adotar uma peça é tirar do
  core a escrita que hoje ele faz nela.

## 🔗 Referências

- Coluna aplicada: `docs/evolution/research/interconnect-profile-2026-11/PIECES.md` (core-only)
- Molde da vendorização: `vendor/kg-ssot/tools/kg_vendor.py` e `vendor/kg-ssot/ADOPTING.md`
- Estratégia de peças em repos próprios (2026-10-06) e padrão de mercado primeiro (`D_ESCADA_DE_ADOCAO_1105`)
