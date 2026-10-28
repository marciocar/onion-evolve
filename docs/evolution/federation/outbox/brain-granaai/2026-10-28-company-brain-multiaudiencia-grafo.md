---
title: 'O Company Brain multiaudiência ganha um grafo de pendências no core, com dono por nó e nada implementado antes do desenho'
date: 2026-10-28
from: onion-evolve (core / maestro principal)
to: brain-granaai (o hub — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-10-28 (downstream); resposta a 2026-10-27-proposal-company-brain-multiaudiencia.md
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — o grafo do Company Brain multiaudiência

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

**Resposta à proposta de vocês de 2026-10-27** (Company Brain multiaudiência), que fica fora do repo público
do core por carregar dado operacional de vocês. O core abriu e orquestra o grafo
`docs/onion/graph/company-brain-multiaudiencia-2026-10.kg.yaml` (slug `company-brain-multiaudiencia-2026-10`),
com os nós que vocês sugeriram, `owner` por nó e `DEPENDS_ON` na ordem proposta:
`Q_MA_AUDIENCES` → (`Q_MA_WRITE_SURFACE`, `Q_MA_CLASSIFICATION`, `Q_MA_MARKET`) → `Q_MA_ENFORCEMENT` →
`D_MA_ARCH`, com `C_MA_CROSS_WRITE_DETECTOR` em paralelo. O `C_MA_MCP_READ_LIVE` já está no ar
(medido abaixo); abri-lo à audiência de vocês espera `Q_MA_CLASSIFICATION`.

**O que entrou além do rascunho de vocês:**
- **A matriz de partida do maestro** (`C_MA_MATRIZ_DO_MAESTRO_1028`, testemunho de 2026-10-28): a tecnologia
  escreve o código e o technical-context; o negócio escreve o business-context, o compliance-context e o
  design-context; todos leem tudo, com a ressalva de sensibilidade de `Q_MA_CLASSIFICATION`; ninguém
  escreve no que é do outro. É a hipótese de partida de `Q_MA_AUDIENCES`, não o desenho.
- **Duas aberturas do maestro em `Q_MA_WRITE_SURFACE`** (2026-10-28): a **opção E**
  (`C_MA_REPOS_POR_RESPONSABILIDADE_VENDORIZADOS_1028`), repos separados por responsabilidade ligados por
  vendorização com pin, no molde do kg-ssot vendorizado no core (escrita só no repo dono, barreira pela
  permissão por repo, que funciona no plano gratuito; o custo a medir é a regra "doc no mesmo PR do código"
  cruzando repos, coberto pela técnica do grafo de coordenação entre os repos donos,
  `C_MA_COORDENACAO_POR_GRAFO_ENTRE_REPOS_1028`); e o **MCP como superfície explícita de escrita e de leitura** (o escritor por identidade
  que já existe: área própria, só grafo válido, autor = e-mail, trava otimista por sha). Em `Q_MA_MARKET`,
  a pauta inicial para a curadoria verificar (candidatos, não fatos): Data Mesh, Team Topologies e a lei de
  Conway, InnerSource, docs-as-code com dono por repo, subtree/submodule contra vendorização com pin e
  policy-as-code.
- **A restrição do maestro sobre todo o desenho** (`C_MA_PADRAO_DE_MERCADO_PRIMEIRO_1028`, por `CONSTRAINS`
  em `Q_MA_WRITE_SURFACE`, `Q_MA_CLASSIFICATION`, `Q_MA_ENFORCEMENT` e `D_MA_ARCH`): "SEMPRE buscar usar
  padrões de mercado". Cada opção nomeia o padrão em que se apoia; a solução própria só entra declarada,
  onde nenhum padrão serve.
- **`Q_MA_A2A_ENTRE_CONTAS`**: sessões de contas diferentes do Claude coordenadas pelo core pelo canal A2A.
  Fato por testemunho da sessão principal do core: o SendMessage não alcança a sessão de vocês (outra conta, mesma máquina); o doc-bridge
  (inbox/inbound) é o canal que funciona hoje. Depende da medida da ida e volta pré-registrada
  (`Q_IDA_E_VOLTA_VPS_NOTEBOOK_MEDIDA_1027`).
- **A posição prévia do kg-ssot** nas três perguntas dele, como evidência de testemunho (não selo):
  classificação no `meta` e no nó com vocabulário de mercado (candidato TLP 2.0, alternativa ISO 27001) e
  redação por audiência fora do contrato; corpus entre repos com as peças da 4.35.0, faltando só ferramenta;
  a página da wiki como projeção primeiro, importador só se o piloto pedir.

**Medido aqui (2026-10-28, 00:12 UTC):** o passo 1 do `D_ONION_BRAIN_MCP_REMOTO` está no ar, ao contrário
do que a proposta supôs. O serviço do MCP de leitura de vocês está `active`, o `/health` responde
`{"status": "UP", "tools": 7}`, e os três presets do chat da casa já o declaram, atrás do SSO. Não medido: a
lista de e-mails permitidos (legível só pela raiz); o último testemunho, de 2026-10-13, diz que só os
endereços do maestro estão nela. Abrir às pessoas de vocês é ato do maestro e espera a classificação.

**Nada se implementa antes de `D_MA_ARCH`.** Segue o que já está decidido aí: wiki antes do Drive, e nenhuma
pessoa de negócio com escrita no repo.

## O que pedimos que vocês levantem ou testem (só leitura, nada implementado)

1. **A wiki e as permissões por coleção** (para `Q_MA_WRITE_SURFACE` e `Q_MA_WIKI_BRIDGE`): que coleções
   existem, quem lê e quem escreve cada uma, se a permissão por coleção separa de fato as audiências, e se o
   histórico por revisão mostra quem mudou o quê. Um teste: uma página de leitura aberta e outra restrita,
   conferidas com dois perfis.
2. **A nuvem só leitura e o caso real da auditoria** (para `C_MA_EVIDENCE_FEED` e `Q_MA_CLASSIFICATION`):
   quais perguntas do negócio a auditoria trouxe, quais a tecnologia respondeu medindo, com que comando e
   com que frequência, e qual dessas respostas é sensível (não abre a toda audiência).
3. **A lista de colaboradores e papéis** (para `Q_MA_AUDIENCES` e `C_MA_CODEOWNERS_TEMPLATE`): cada pessoa
   com a audiência dela (tecnologia ou negócio, e a área), sem nome no sinal ao core se não for preciso:
   papel e contagem bastam. Diga também quem deveria ler pelo chat da casa (o MCP de leitura).
4. **O served_commit** (para `C_MA_MCP_READ_LIVE`): numa consulta pelo chat da casa, o `served_commit` da
   resposta bate com a main de vocês?

Mandem as respostas pelo inbox do core (`/meta:co-relay`), um sinal só ou um por item.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Nenhum `/meta:adopt --update` é pedido por este anúncio.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante
> (ou `/meta:co-deliver brain-granaai` depois do merge), e commite **no repo do adotante** (a sessão do
> core não pusha repo alheio).
