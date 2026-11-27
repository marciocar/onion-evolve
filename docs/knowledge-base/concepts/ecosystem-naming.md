# Nomes do ecossistema — prefixo por tipo, alias em vez de rename

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-11-27 |
| **Última Atualização** | 2026-11-27 |
| **Categoria** | Concepts |
| **Aplicação** | Sistema Onion: como nomear cada peça do ecossistema no registro da federação (`members.yaml`) |

### Fontes

- Decisão do maestro de 2026-11-27, nó `D_ECOSYSTEM_NAMING_PATTERN_1127` no grafo `docs/onion/graph/onion-identity-2026-07.kg.yaml` (card SAC-567).
- Padrão de mercado de prefixo por tipo de recurso: [Azure Cloud Adoption Framework: define your naming convention](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming) (nov/2026).
- KBs irmãs: [Onboarding do adotante](adopter-onboarding.md).

---

## 1. O padrão

Cada peça nova leva no nome um prefixo que diz o tipo dela:

| Tipo | Forma do nome | Exemplo |
|---|---|---|
| Company Brain de uma empresa | `company-brain-<empresa>` | `company-brain-acme` |
| Second Brain de uma pessoa | `second-brain-<pessoa>` | `second-brain-ana` |
| Peça do Onion | `onion-<peça>` | `onion-<peça>` |
| Serviço da VPS | `onion-vps-<serviço>` | `onion-vps-<serviço>` |

A **Persona do Onion Evolve** é uma categoria à parte. Ela é o cérebro do próprio Onion Evolve, que não
é company brain nem second brain. O nome dela é fixo e está no registro da federação.

O projeto comum de um adotante (o produto de um cliente, um site, um experimento) **não** entra no
padrão. Ele não é peça do ecossistema, então o nome dele segue sendo o slug do projeto.

## 2. Por que o nome importa tanto

O `id` de um membro no registro da federação é **termo de varredura**. As guardas do lint leem os ids
do registro e procuram cada um deles no que viaja para os adotantes:

- a REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) procura os ids de adotante;
- a REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação) procura os ids
  `onion-*` de adotante;
- a REGRA 119 (O diff não acrescenta nome de repo ou de clone de adotante não federado) usa os ids como a
  lista do que já é público.

Por isso, renomear custa caro. O nome antigo some do registro, mas continua escrito em grafos,
mensagens e históricos. A guarda deixa de procurar por ele, e esse nome vira um ponto cego.

## 3. A regra do alias e do gatilho

**O que já existe não é renomeado.** Uma peça antiga que fica fora do padrão ganha dois campos no
registro:

- `aliases:` é a lista dos nomes do padrão. Ela é escrita **numa linha só**, por exemplo
  `aliases: [company-brain-acme]`, porque os leitores das guardas são scripts awk e só leem essa forma.
- `rename_trigger:` é o evento com nome em que o rename vai acontecer, por exemplo «renomear na migração
  para a AWS».

O alias é um nome registrado de verdade:

- as guardas procuram o alias do mesmo jeito que procuram o id;
- um alias não pode ser igual a nenhum id nem a outro alias, sem diferença de maiúscula e minúscula;
- um alias começa e termina em letra ou dígito, e não pode ser só o prefixo (`company-brain`, `second-brain`,
  `onion`, `onion-vps`, `brain`), porque isso colide com nomes do próprio framework (o Company Brain também é
  nome de vertical);
- o alias precisa ser lido igual pelo validador e pelos leitores awk das guardas. Por isso a chave fica
  simples (`aliases:`, sem aspas, sem tag, sem escape) e direto no membro, nunca aninhada noutro bloco;
- alias sem gatilho é erro, e gatilho sem alias também.

Quando o gatilho chega, o rename é um ato próprio: o id passa a ser o alias, e todas as referências
mudam no mesmo movimento.

## 4. Quem confere

O `bash .claude/validation/members-validate.sh` confere o registro. A REGRA 66 (Registro da federação
validado no gate) o roda no lint.

| O que ele confere | Efeito |
|---|---|
| Forma do alias, colisão com id ou alias, prefixo nu, alias sem gatilho, leitura divergente entre o validador e as guardas | **reprova** |
| Membro **novo** fora dos prefixos do padrão | **aviso** (não reprova) |
| No core, o mapa de nomes ao lado do registro (obrigatório): todo membro uma vez, com os mesmos aliases e o mesmo gatilho | **reprova** |

O aviso de membro novo não reprova por uma razão concreta. O registro não tem um campo com o tipo da
peça, e o projeto comum de um adotante não tem prefixo no padrão. Um erro que reprovasse acusaria todo
adotante novo legítimo. O aviso só aparece no PR que registra o membro, porque compara com o registro
da `origin/main`.

**O mapa** fica no core, em `docs/evolution/federation/ecosystem-naming-map.md`. Ele lista todas as
peças com estas colunas: id atual, tipo, conforme o padrão, alias e gatilho de rename. Esse arquivo não
viaja no `/meta:adopt`, porque cita ids de adotante, e as guardas que varrem o que viaja o reprovariam.

## 5. Como registrar uma peça nova

1. Escolha o prefixo pelo tipo da peça (seção 1).
2. Antes de registrar, faça o grep do nome contra o framework (`.claude/` e `docs/`). O id vira termo
   de varredura, e um nome que já aparece no que viaja faz a REGRA 36 ou a REGRA 106 reprovar.
3. Registre no `members.yaml` e acrescente a linha no mapa, no mesmo PR.
4. Rode `bash .claude/validation/members-validate.sh`.
