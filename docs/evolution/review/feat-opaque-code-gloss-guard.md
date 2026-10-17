---
branch: feat/opaque-code-gloss-guard
pr: pendente
date: 2026-10-17
reviewed_diff_sha256: 9f498eec4c6ce6e2547eb12300aa3f8ee866307064aaadea272ee3296d136605
reviewed_code_sha256: a0ee991910a33230b4f0f914ba813c33c3eb0b1d3f00fd7c0a905242443e3e3b
findings_total: 14
findings_real: 14
tokens: 296137
duration_min: 13
findings_fixed: 14
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "subagente general-purpose, modelo opus, mandato REFUTAR, 2 passadas (19cf879f e cdd63eec)"
nota: "tokens e duração somam as duas passadas (129702 + 166435 tokens; 4,5 + 8,0 min). Todos os achados curados no mesmo laço, com caso de bancada e mutante; os tetos restantes estão declarados no grafo da forja."
---

# Passada adversarial: `feat/opaque-code-gloss-guard`

## O que muda

Guarda nova, irmã da guarda de título de REGRA: sigla da casa na prosa ao maestro vem com a glosa.
Pedido do maestro de 2026-10-17 e reforço do mesmo dia ("isso é para você escrever certo e não para
ficar travando toda hora"). Por isso o caminho normal é um **lembrete antes de escrever** (o
UserPromptSubmit injeta a glosa das siglas em uso) e o bloqueio no Stop é **rede rara**: só a sigla de
opacidade alta que o lembrete deste turno trouxe e que voltou sem glosa.

- `.claude/validation/house-codes.tsv`: glossário, fonte única (kind, code, opacity, gloss, accept, domain).
- `.claude/hooks/lib/house_codes.py`: o que conta como glosa e o que não é prosa.
- `.claude/hooks/house-code-gloss.sh`: os modos `prompt` e `stop`, `--selftest` e `--scan`.
- `.claude/settings.json`: registro nos dois eventos; `lint-selftest.sh`: família `house_code_gloss`.
- Grafo `docs/evolution/research/guard-house-code-gloss-2026-10/`: defeito, reforço, medida, decisão,
  tetos, as duas passadas e o selo da decisão do maestro.

## Achados

**1ª passada (19cf879f), REPROVA, 7 achados, todos reais e curados:**
1. (alta) O Stop recalculava o lembrete e barrava em turno de aviso de tarefa de fundo (7 de 10). Cura:
   estado observado e consumido, só em turno do maestro. Casos (p) e (i).
2. (alta) A resposta a "o que é I3?" travava. Cura: cópula conta como glosa, e sigla escrita pelo
   maestro não barra. Caso (q).
3. (média) "REGRA N (Título)" não glosava o RN. Cura no lib. Caso (e).
4. (média) Palavra comum colidia (o teste E3 do formulário). Cura: coluna `domain`. Caso (s).
5. (média) Glosa de fachada passava ("(ok)", versão depois de dois-pontos, E3/E4, ênfase). Caso (r).
6. (média) Números divergentes entre cabeçalho e grafo. Cura: a taxa mora só no nó da medida.
7. (baixa) JSON não-objeto quebrava, e o enum de política era aberto. Casos (l) e (n).

**2ª passada (cdd63eec), REPROVA, 7 achados, todos reais e curados:**
1. (alta) Mensagem do maestro em fila dispara o UserPromptSubmit no meio do turno, e a 1ª menção
   barrava mesmo glosada depois. Cura: marca no estado (o Stop julga só depois do lembrete). Caso (u).
2. (média) Glosas comuns em pt-BR recusadas (vírgula + cópula, "ou seja", "=", janela curta). Caso (y).
3. (baixa) A compactação abria turno e apagava a glosa já lida. Caso (v).
4. (média) O diretório de estado aceitava modo 777 e a escrita seguia link. Cura: dono e 0700,
   `O_NOFOLLOW` e 0600. Caso (w).
5. (baixa) O caminho lento da leitura da cauda perdia o lembrete. Caso (x).
6. (baixa) O caso de id de nó dependia do corpus do core e quebrava no adotante. Cura: fixture. Caso (m).
7. (baixa) "26 linhas" e o número de turnos do maestro estavam errados no grafo. Corrigidos; o
   `--scan` imprime o total do glossário.

Achado do próprio laço, fora das passadas: o `.pyc` do lib é validado por mtime em segundos e tamanho,
e uma edição do mesmo tamanho no mesmo segundo rodava o código velho. O motor não grava mais bytecode.

## Mutantes

26 mutantes plantados por `ops/mutate-and-restore.sh` com `LC_ALL=C`, um por cura, e **26 mordem**:
cada um reprova o caso nomeado. Uma primeira rodada teve 5 que não mordiam. Dois tinham âncora
desatualizada depois da reescrita. Um era sintaticamente inválido. Dois eram casos que passavam por
outra razão: o (v) passava pela checagem de origem, e o (y) porque uma frase glosava a outra. Os
casos foram afiados e as âncoras corrigidas, e então os 26 morderam. A bancada roda 24 casos na família.

## Limites declarados

- A glosa é julgada por **forma**, não por sentido. "r13 (uma coisa qualquer)" passa, e a menção de
  passagem perto da sigla também conta.
- Só conhece o glossário. Sigla nova sem linha passa calada. Sigla da casa num bloco sem o domínio
  dela também cala.
- A política padrão **não barra a 1ª vez**. O caso literal do maestro recebe o lembrete no turno
  seguinte e só barra na reincidência ou com `ONION_HOUSE_CODE_STOP=alta`.
- O `--scan` não simula o lembrete de meio de turno.
- A taxa de 0,3% foi medida **antes** de o lembrete existir. O efeito real do lembrete fica para a
  revisita do grafo (`review_after` 2026-11-16).
