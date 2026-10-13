---
title: 'Resíduo — o core ficou público e a árvore foi limpa: a lista de nomes privados saiu de dentro do repo'
date: 2026-10-13
branch: chore/public-core-tree-cleanup
reviewed_diff_sha256: e6014e140783b89f769e7c573c3184345215ca045cab321b968af57bdd41dcdf
reviewed_code_sha256: 4dbf10eac8ca7b6837aab896f01ee29f9d343638958b9caffae19d81316a032e
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Decisão do maestro de 2026-10-13: manter o core público e LIMPAR A ÁRVORE, sem reescrever histórico.
  A cura central não é o scrub, é o lugar da lista: a fonte de termos privados que as guardas de nome
  leem morava DENTRO do repo público e era o próprio vazamento. Ela saiu para fora da árvore, e as
  guardas passaram a DECLARAR quando não a têm.
---

# O core ficou público, e a lista que protegia os nomes era o vazamento

## O que muda

1. **Fonte privada de termos fora da árvore (P8 do `projection-safety.sh`).** As anotações confidenciais
   do `name:` no `members.yaml` e o `client-terms.txt` versionado saíram. A fonte agora é
   `${ONION_CLIENT_TERMS_FILE:-$HOME/.config/onion/client-terms.txt}` (0600 no host) e, no CI, o secret de
   repo `ONION_CLIENT_TERMS`, materializado em arquivo temporário pelo `onion-validate.yml`. Formato:
   `<termo>` (declarado) ou `<termo><TAB><id>` (nome de membro, o equivalente da anotação antiga).
   As REGRAS 30 (Segurança de PROJEÇÃO: nome comercial de membro privado não sai), 33 (Segurança de
   projeção no HISTÓRICO DE FEDERAÇÃO (mailbox-aware)) e 36 (Superfície VENDORIZADA sem nome comercial de
   cliente) e o `ops/publish-door.sh` leem dali.
2. **Sem a fonte, a guarda DECLARA.** `SOFT NAO-VERIFICADO` nomeado nas três regras; o P5 não vira HARD de
   NO-OP por isso. O `publish-door` falha FECHADO sem a fonte (publicar porta pública sem vocabulário não
   é medição). A lista que VOLTAR à árvore é HARD (`vendor-scrub/LISTA-NA-ARVORE`).
3. **O log do lint não imprime termo privado.** A REGRA 36 imprimia o termo na mensagem; num repo público o
   log do CI é público. Agora imprime só o id de adotante (público por P2); o nome privado sai como "nome
   da fonte privada de termos".
4. **Retirados da árvore (`git rm`):** dois achados de segurança sobre adotantes, as duas mensagens com
   segredo de fallback literal de adotante e os dois rascunhos correspondentes, a lista de termos e o
   estudo do Onion pessoal (33 arquivos, com cópia local fora do repo, 0700).
5. **Generalizados:** nomes de cliente terceiro em ~80 arquivos vivos, pelo selo O7 (labels e ids usam o
   id do `members.yaml`; o DOMÍNIO e o ARQUIVO DE DEPLOY ficam); a PoC sob NDA (cliente e parceiro);
   número de WhatsApp e LID mascarados; o incidente de rede da VPS sem endereço, tabela de serviços nem
   passo a passo do contorno. Dois arquivos com nome de cliente no caminho foram renomeados pelo id.
6. **Reconciliação (Aufhebung, nenhum nó apagado de grafo vivo):** todo `trace:`/`provenance` que apontava
   arquivo retirado virou o texto "arquivo retirado da árvore pública em 2026-10-13 (decisão do maestro)";
   links de `.md` viraram o próprio texto; o `--exclude` dos grafos proto saiu do CI.

## Achados da passada adversarial (refutador default: reprovado)

| # | Achado | Estado |
|---|---|---|
| 1 | A REGRA 49 (Nó plane:PROD de alto impacto carrega VERIFICAÇÃO, com catraca) reprova apagar grafo cujos nós estão no baseline (24 HARD `REMOVIDO`/`ID-AMBIGUO`), e a forma honesta que ela prescreve (`superseded` com aresta) manteria públicos ids que já são dado pessoal | curado: classe **RETIRADO** (SOFT declarada) com três travas — chave no ledger `docs/evolution/kg-retired-from-tree.tsv`, arquivo AUSENTE da árvore (nó apagado de grafo vivo segue HARD) e saída declarada |
| 2 | A REGRA 63 (Colheita de grafo emite os ids colhidos no resíduo de revisão) exigiria NOMEAR no resíduo os ~90 ids dos grafos pessoais — republicá-los | curado: grafo INTEIRO declarado por caminho no mesmo ledger sai da cobrança, com SOFT que declara a isenção |
| 3 | A fixture da REGRA 64 (Compose sem bind local ou com segredo em fallback literal) usava o fallback literal REAL de um adotante, em `.claude/validation/`, que viaja | curado: valor fictício; o literal não sobra em arquivo rastreado nenhum (conferido por varredura) |
| 4 | A REGRA 36 ecoava o termo privado no log | curado (item 3 acima), com caso que prova o não-eco |
| 5 | Um nó público do grafo de identidade da VPS carregava o mesmo achado de segurança do documento retirado (repo, linhas, variáveis, portas) | curado: label e narrative generalizados |
| 6 | O caso (P8a) passava pelo motivo errado (P5 reprovava por NO-OP) e o mutante que tirava os nomes de membro sobrevivia | curado: o caso afere a detecção; mutante morto |
| 7 | O extrator da REGRA 59 (Modo que a produção consome é exercitado pela bancada) era cego a prefixo de env na linha do selftest e lia uma dica na mensagem como invocação | curado: chamada sem prefixo; dica reescrita |

Mutantes (`ops/mutate-and-restore.sh`): 10 plantados, 10 mortos — sem nomes de membro na fonte, fonte
cega, P5 sem a P8, declaração silenciada, REGRA 36 sem o SOFT, sem a checagem da lista na árvore, eco do
termo, RETIRADO sem a trava do arquivo, RETIRADO sem o ledger, REGRA 63 sem a exclusão.

## O que fica, por ser operacional (declarado)

- O vhost versionado da demo em `ops/caddy/conf.d/` e as menções ao domínio da demo, ao arquivo de deploy, ao env de segredo,
  às entradas do `pass`, aos placeholders, ao cookie e ao usuário do Basic: o deploy os usa. Só os
  comentários mudaram (o vivo em `/etc/caddy` mostra a diferença de comentário até o próximo
  `ops/install-caddy-config.sh`).
- `remote:` e `local_path:` de três membros no `members.yaml`: o `ops/registry-pins.sh` e o carteiro
  local os leem; ficam até o repo/diretório ser renomeado.
- O resíduo do ramo de deploy da demo mantém o nome (é o do ramo).

## Fora do escopo (relatado ao maestro)

Reescrita de histórico (o histórico público segue com tudo o que saiu da árvore), branches públicas,
retenção de artefatos do Actions e rotação de chaves (PARADA POR ORDEM).
