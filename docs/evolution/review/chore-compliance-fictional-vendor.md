---
reviewed_diff_sha256: 624cf1bdf00e0e4ea6855b3dbe6705ea3ae2b293a730d78bf228b0a01b087575
reviewed_code_sha256: f8aa3a6b562fe9c656779d23b3e08e855167aa7c866124e51b6799fd2b8c312a
findings_total: 4
findings_real: 4
tokens: 0
duration_min: 10
verdict: APROVADO
elenxo: sim
nota: >
  Passada adversarial feita pelo próprio autor, no contexto da execução, sem refutador independente
  (declarado: a independência é menor que a de um subagente com default REPROVADO). O mandato tinha
  três perguntas: o fictício colide com empresa real, sobrou o nome real em URL, sigla ou CNPJ de
  exemplo, e algum exemplo perdeu o sentido. Cada uma foi respondida por medição. Uma rendeu cura no
  mesmo laço (o cabeçalho "Exemplo Real"); o resto fica declarado.
---

# Resíduo — `chore/compliance-fictional-vendor`

Executa a decisão do maestro de 2026-10-13 («Trocar por fictício»): o birô de crédito real citado como
exemplo de due diligence nos especialistas de compliance vira o fornecedor fictício **CrediFicta**, o
mesmo em todos os arquivos, e `empresa.com` vira `empresa.example` (RFC 2606) nesses arquivos.

| # | achado | desfecho |
|---|---|---|
| 1 | Pergunta 1, o fictício colide com empresa real? Busca na web por "CrediFicta" não achou empresa com esse nome exato. Os vizinhos mais próximos: CrediFi (dados de imóveis comerciais em Nova York, encerrada em 2019 e adquirida em 2020), Credifinanciera (Colômbia) e CredFIC Technologies. | Aceito: o nome carrega "Ficta" (latim para fictício), a 1ª menção diz "birô de crédito fictício", e todo domínio do exemplo é `.example`, que não pode ter dono. Declarado: não foi feita consulta ao INPI nem a registro de marca; a busca foi só na web. |
| 2 | Pergunta 2, sobrou o nome real em URL, sigla ou CNPJ? Busca sem caixa pelo nome e pela marca composta na árvore rastreada inteira: zero. Busca por CNPJ, por padrão `NN.NNN.NNN/`, por outros birôs e bancos e por URL nos 6 arquivos: só sobram `api.empresa.example`, `status.empresa.example`, a API pública do Pingdom e a doc do Claude Code. | Curado. Os nomes de arquivo de exemplo (`credificta-requirements.md`, `contrato-credificta-2024.pdf`, `anexo-credificta-contract.pdf`, `credificta-response.md`) também trocaram. A história do git guarda o nome, e reescrevê-la não estava no pedido. |
| 3 | Pergunta 3, algum exemplo perdeu o sentido? Os cabeçalhos diziam "Exemplo Real", o que ficaria falso com um nome inventado. | Curado: viraram "Exemplo ilustrativo", e a 1ª menção diz que é um birô de crédito fictício. As contas (5 de 8 requisitos no ISO 22301, 3 de 8 no SOC2, 8/8 somados) e as cláusulas de SLA seguem iguais e coerentes. |
| 4 | Fora do mandato, medido: `empresa.com` segue em outros arquivos que viajam (iso-27001, pmbok, jira-specialist, `docs/help`, forge detector, KB do task-manager, `.env.example`). E a forma do checklist (8 requisitos, divididos 5+3 entre ISO 22301 e SOC2) é a do material original, o que pode sugerir a origem para quem a conhece. | Declarado, não curado: a decisão nomeou os 4 arquivos de compliance. Os outros `empresa.com` vão como achado no PR. |

Nenhuma superfície core-only (grafo, análise, diário) citava o nome real: a busca na árvore inteira já
dava zero fora dos 6 arquivos trocados. Os dois guias de `docs/onion/` (`agents-reference.md` e
`commands-guide.md`) não estão nas raízes de varredura do manifesto de vendor, mas descrevem os próprios
agentes e foram trocados para não divergirem deles. Nenhuma guarda da bancada lê esses exemplos.
