---
branch: fix/compliance-docs-field-signals
pr: 1221
date: 2026-10-20
reviewed_diff_sha256: 5967af438afd9cb952ae5b666b95cc2daf4fee0012d1a445a032b5492de24288
reviewed_code_sha256: 2db80789c112afe5653a4f4f437c1ef7d8e68eb85f8da3431ef923543bf4b01c
findings_total: 24
findings_real: 11
tokens: 140696
duration_min: 15
findings_fixed: 11
verdict: CORRIGIDO
elenxo: sim
reviewer: "branch-code-reviewer (subagente) com mandato adversarial sobre o diff inteiro contra origin/main; reproduziu cada achado por comando (assemble-plugin + plugin-bundle-check, timeout no helper, fixtures em mktemp)"
nota: "o achado 2 (confidencialidade do sinal processado num repo público) foi decidido pelo maestro em 2026-10-20 (Redigir, selado em D_SINAL_COMPLIANCE_REDIGIDO_NO_CORE_PUBLICO); a branch foi reescrita para o original não chegar à main"
---

# Passada adversarial: `fix/compliance-docs-field-signals`

## O que muda

Quatro curas da onda A sobre os dois sinais de 2026-10-19 do hub (C3, C5, C6, U7) e o registro da
triagem dos 16 no grafo `sinais-de-campo-2026-09.kg.yaml`.

## Achados

24 achados: 11 reais e 13 descartados com motivo (as 19 citações em 10 arquivos foram conferidas
contra `origin/main`; a normalização do 2º vocabulário, a semântica de `--retired-excludes`, CRLF e
aspas simples no resolver e as contas do grafo passaram).

Os 11 reais e a cura de cada um:

1. **(ALTA)** O plugin `onion-engineering` citava o helper sem levá-lo (REGRA 74 no bundle,
   reproduzido). Cura: `.claude/utils/scope` no `UTILS` do manifesto.
2. **(ALTA, decisão do maestro)** O sinal processado traz números de segurança de um adotante
   identificável num repo público. A prosa que viaja (comando, KB, exemplo do ISO 27001) foi
   generalizada. O arquivo do sinal fica como chegou: mexer no dado é decisão do maestro, e o PR a
   pede.
3. `--repo` sem valor deixava o helper em laço infinito. Cura: aridade checada (exit 2), caso (f).
4. Espaço no fim do valor entrava no caminho. Cura: aparado, caso (g).
5. Chave aninhada dentro de `context:` respondia no lugar da certa. Cura: só o filho direto, caso (g).
6. `#` dentro de aspas cortava o valor. Cura: comentário só fora de aspas.
7. BOM escondia o bloco, e comentário disparava AVISO. Cura: BOM tirado, comentário fora do grep.
8. O modo `reconcile` não se encaixava nos passos 1, 3 e 4. Cura: gatilho conta só `.md` além de
   `README.md` e `index.md`, combinação com `frameworks` e `due_diligence` dita, e um ramo de
   reconciliar nos Passos 3 e 4.
9. Os especialistas não têm Bash. Cura: chamados direto, leem `context.compliance` com Read.
10. O mutante do resolver era só prosa. Cura: o caso (m) aplica o mutante e exige a queda no default.
11. O rótulo "documentos gerados" contava README e index. Cura: "documentos na pasta".

## Mutantes

- REGRA 100: os 4 mutantes novos mordem ((xx), (xxi) duas vezes, (xxii)), e os 18 antigos seguem
  mordendo: `--families ops_citation_travel` 33/33 com `resolve_context_dir`.
- Resolver: o caso (m) troca a emissão do mapa por no-op, e a saída cai no default (o caso (b) o pega).

## Retomada de 2026-10-20 (depois da 1ª passada)

- **Sinal redigido.** Por decisão do maestro (`/meta:decide`, selada por `kg-decide-seal.sh` no nó
  `D_SINAL_COMPLIANCE_REDIGIDO_NO_CORE_PUBLICO`), o sinal de compliance processado troca números, nomes de
  controle, identificadores de lacuna e ferramentas internas do adotante por descrição genérica, com aviso no
  topo de que o original está no hub. O grafo de triagem citava as ferramentas de chat do adotante e foi
  redigido também; o resíduo não copiava nenhum desses dados.
- **História reescrita.** Os commits anteriores do PR traziam o sinal como chegou. Como o PR não foi
  mergeado, a branch foi achatada num commit só sobre a `origin/main` e empurrada com `--force-with-lease`:
  o texto original não chega à main.
- **CI vermelho curado, as duas causas medidas nos logs:**
  - faixa 2, `assemble-plugin: compliance estrutura`: o plugin passou a levar `utils/scope` por desenho (o
    Passo 0 chama o helper). O caso (b) agora exige `utils/scope/resolve-context-dir.sh` e nada mais em
    `utils/`, e segue sem `validation/`. Família `assemble_plugin`: 14/14.
  - faixa 4, `publish_release (r14)`: a lista de fallback da REGRA 100 citava a lente e a doutrina do
    `/meta:publish` pelo nome, e o derivador de companheiros do `vendor-manifest.sh` mantém viva no
    standalone a peça que um arquivo que viaja cita. O fallback agora nomeia só o comando e a skill.
    Famílias `publish_release` + `ops_citation_travel`: 57/57.

## Os `confirmed` do grafo editado

Conferidos os de maior impacto de `sinais-de-campo-2026-09.kg.yaml`: `E_SPIKE_SOBREVIVENCIA_PREMIA_O_TRIVIAL_1012`
(critério de valor em spike) e `E_RADAR_IGNORAVA_O_SEGUNDO_MODO` (radar que rodava um modo e dava exit 0) não
respondem nem refutam a triagem nova; o segundo é da mesma família do U7 (a guarda declara mais do que mede).
`E_HUB_1019_DEZESSEIS_FRICCOES_EM_DOIS_SINAIS` é o nó novo desta triagem, e a decisão e as perguntas abertas
apontam para ele.

## Limites declarados

- O leitor de YAML do resolver é de linha: YAML de fluxo (`context: {compliance: x}`) cai no default
  com AVISO.
- O 2º vocabulário cobre COMANDO cortado, não skill: `onion-publish` em prosa não se distingue de
  invocação.
- `cc-update.md` é Core-only no frontmatter e mesmo assim viaja ao hub; o corte dele é decisão
  separada, não tomada aqui.
