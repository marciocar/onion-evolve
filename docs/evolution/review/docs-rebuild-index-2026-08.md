---
branch: docs/rebuild-index-2026-08
pr: 587
date: 2026-08-13
reviewed_diff_sha256: abd68b0d3b74dea5ca53a13e95e77901e740aa432cc3533881a73324d5b488e7
findings_total: 13
findings_real: 13
findings_fixed: 10
tokens: 67239
duration_min: 8
verdict: CORRIGIDO-E-RE-VALIDADO
reviewer: code-reviewer (opus, adversarial)
---

# Passada adversarial — `docs/rebuild-index-2026-08`

## O achado principal: a cura pegou 1 de 4 sítios

O commit inicial reescaneou o filesystem **corretamente** e aplicou os valores **só no primeiro
bloco**. O hub tem **quatro sítios independentes** de contagem, e o resultado foi o pior caso
possível: `641` na linha 26 e `585` na linha 68 — **contradição dentro do mesmo arquivo**, sob um
rodapé afirmando *"contagens reescaneadas do filesystem, nunca digitadas"*.

| # | sev | achado | status |
|---|---|---|---|
| 1 | **ALTA** | `### Total` (linha 68) continuava `585`, contradizendo a linha 26 | corrigido |
| 2 | **ALTA** | `tools/` 5 → **6** — escapou do bloco que o PR declarou ter reescaneado | corrigido |
| 3 | **ALTA** | árvore ASCII: **8 contagens** intactas na safra antiga | corrigido |
| 4 | **ALTA** | lista de Knowledge Bases: 3 contagens + **enumeração nominal** de `tools/` listando 5 e omitindo `vps-tool-repo-skeleton.md` | corrigido |
| 5 | **ALTA** | um **terceiro** valor para `analysis/` na prosa (90) | corrigido |
| 6 | **ALTA** | **regressão introduzida pelo PR**: blockquote sem linha em branco engolia `**Mantido por:**` (lazy continuation do CommonMark) | corrigido |
| 7 | MÉDIA | `sdaal/` ausente do bloco de estatísticas — sem ele a soma não fecha em 641 | corrigido |
| 8 | MÉDIA | breakdown de `agentic-patterns` removido em vez de atualizado (perdia o dígito verificador) | corrigido |
| 9 | MÉDIA | `onion/` declara 21 e a árvore navega 19 nominalmente | **não corrigido** — navegação nominal é escopo maior |
| 10-12 | BAIXA | feeder do comando reintroduz drift de contexto; tabelas de navegação incompletas (pré-existentes); `design-context` "3 tokens.json" impreciso | **não corrigidos** — pré-existentes, fora do escopo |

## A lição, e ela é aritmética

**Os sub-bullets somavam 90 contra os 91 declarados.** Faltava exatamente 1 — o `tools/`. Somar
teria encontrado o defeito sem revisor nenhum.

Reescanear o filesystem estava certo. O erro foi aplicar o resultado na **primeira lista** e não
varrer **todas as formas** em que o número aparece. É a mesma classe que esta casa já registrou
três vezes em 24h: a cura para no sítio óbvio e deixa os irmãos.

E uma ironia registrada: o meu próprio `grep` de verificação deu falso alarme por casar
**substring** (`125 arquivos` contém `5 arquivos`) — falha de vocabulário dentro do PR sobre
cegueira de vocabulário.

## Confirmado limpo, por execução

- As **7 contagens** da primeira passada: todas certas
- As **6 declaradas "sem drift"**: todas certas
- **SSOT**: `inventory.sh --env` devolve 102/51/11/90, batendo com as linhas 13-16, 46, 57, 58, 71
- **Breakdown de comandos e agentes: 100% correto** — as 11 categorias somam 102, as 9 somam 51
- **133 links, 0 mortos** — reproduzido. *Ressalva honesta do revisor:* `main` também tem 133 e
  zero mortos; a validação é verdadeira, mas não é resultado deste PR
- **A tese do rodapé sobre o lint: VERIFICADA.** O revisor rodou em `main` (com as 7 contagens
  erradas) e obteve `HARD 0 / SOFT 5`, nenhuma relacionada a contagem do INDEX

## Achado nº 13 — do revisor de CI, e é o mesmo defeito em segunda ordem

O `onion-review` do PR notou o que nenhuma passada anterior podia notar: **o resíduo de revisão é
um `.md` dentro de `docs/evolution/`**, então o ato de escrevê-lo mudou `docs/` 641→642 e
`evolution/` 293→294 — invalidando os números que este PR acabou de corrigir.

Contagem de um diretório que contém o registro do próprio trabalho é **auto-referente por
construção**. Corrigido nos quatro sítios; a soma fecha em 642. Fica a regra prática no rodapé do
hub: rodar `/docs:build-index` **por último**, depois de todos os arquivos do PR existirem.

⚠️ **Este resíduo foi re-carimbado por isso.** O `review-artifact-check` acusou `ARTEFATO-CADUCO`
— corretamente: o código mudou depois de revisado. O hash acima é o do diff final.

## Teto declarado

Três achados BAIXA e um MÉDIA ficam **abertos por escopo**, não por descuido: a navegação nominal
da árvore de `onion/` (19 de 21), as tabelas de navegação por categoria (pré-existentes,
incompletas), e o fato de que o próprio `/docs:build-index` manda descrever os três contextos como
"template" — o que **reintroduziria** um drift já curado em 2026-08-03. Este último é fio para
mecanismo, não para este PR.

Não houve segunda passada adversarial após as correções: a re-validação foi por gate mecânico
(lint 0 HARD, 133 links, e **as duas somas fechando** — 91 nos sub-bullets, 641 nas seções) mais
varredura dirigida de cada valor antigo. Cobre o sintático; não substitui verificador semântico.
