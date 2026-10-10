---
title: 'Resíduo — F2 das portas: manifestos por papel'
date: 2026-10-10
branch: feat/doors-role-manifests-f2
reviewed_diff_sha256: e3c2470aec7d75c0e83621c5dab7c6befc839d8d800c927d5f5a53bdda0daee0
reviewed_code_sha256: 1760bb76b7a82efe9dd7b389f6638b9dd49aadcd21ee7a7225cb136d78e78280
findings_total: 10
findings_real: 10
findings_fixed: 8
tokens: 0
duration_min: 240
verdict: CORRIGIDO
elenxo: nao
---

# Resíduo — REGRA 56

## O que o PR faz

É a F2 do plano das portas (SAC-91), pela matriz `D_MATRIZ_DE_PORTAS_2026_10`.

- **`roles.yaml`:** os conjuntos particionam `commands/meta/` em `full`, `meta_factory`, `federation`,
  `adoption` e `pending`. Entram os papéis `plugins`, igual ao standalone, e `mini`, por allowlist.
- **`vendor-manifest.sh`:**
  - standalone e plugins perdem adoção e federação e passam a levar a meta-fábrica;
  - `source` é igual ao `hub`;
  - `mini` inclui só a allowlist;
  - `--list` e `--diff` contam do transporte real.
- **REGRA 37:** passa a cobrar a partição.
- **REGRA 61:** a fronteira muda. Antes barrava a meta-fábrica; agora barra adoção e federação.
- **Wizard:** a projeção de transições passa a depender do papel.
- **`write-stamp.sh`:** aceita os papéis de porta, mas só com `--kind door`.
- **`materialize-door.sh`:**
  - calcula o corte na própria ref;
  - copia o `settings.json` dessa ref e poda os hooks que não viajaram;
  - escreve o README conforme o papel;
  - não exige projeção numa porta sem lint.

## Passada adversarial

Um refutador independente (`branch-code-reviewer`) leu o diff e materializou cinco portas em diretório
temporário. Achou dez defeitos, e todos foram confirmados pela medição.

1. **ALTA, CORRIGIDO.** O corte de comandos falhava ABERTO quando o resolvedor não respondia. Sem PyYAML,
   o `--list standalone` saía com rc 0, stderr vazio e os 12 comandos de adoção e federação de volta.
   - Cura: `_emit_command_excludes` devolve rc 3, e o chamador LÊ esse rc (antes o `< <(…)` o engolia).
   - Bancada: caso role-cut (t), com resolvedor ausente e com resolvedor em erro; mutante (t-MUT).
2. **ALTA, CORRIGIDO.** A porta `--role source` era julgada como o core: 12 HARD. O regen-baselines a
   recusava como "é o CORE" e, mesmo assim, o script dizia ✅.
   - Cura: `kind: door` distingue a porta. Ela entra no porteiro `IS_DERIVED` (sucede a onion-core, hoje
     `hub` e já derivada), e `_role` passa a devolver `source-door`.
   - O regen-baselines aceita a porta.
   - O `_regen` devolve o rc do regenerador, e uma recusa (rc 2) aborta.
   - Medido: a porta source sai com rc 0 e 0 HARD.
3. **MÉDIA, CORRIGIDO.** A REGRA 37 cobrava os comandos que a matriz tira do papel. Medido num standalone
   que publica o próprio catálogo: 12 HARD falsos.
   - Cura: o caso TOOL cobra só os conjuntos do papel do repo.
4. **MÉDIA, CORRIGIDO.** O corte vinha do HEAD local e do `roles.yaml` do disco, e o archive vinha da ref.
   - Cura: o corte é calculado numa worktree destacada na ref. Um papel que a ref não conhece recusa com
     rc 3.
5. **MÉDIA, CORRIGIDO.** A SKILL do wizard dizia que a lista vazia era a resposta. Numa porta, porém, a
   projeção sai com rc 3, porque o grafo da topologia não viaja.
   - Cura: a SKILL passa a dizer que o movimento não é deste papel, nos dois casos.
6. **MÉDIA, CORRIGIDO EM PARTE.** O detector de ponteiro morto do mini só via caminhos `.claude/`.
   - Cura: passa a contar também `/categoria:comando`. Medido: 32 comandos e 6 caminhos.
   - **Não curado:** o README e o CLAUDE.md que o materializador gera para o mini ainda mandam rodar o
     lint que o mini não leva. Isso fica para a F5 (SAC-94) e está declarado no nó.
7. **BAIXA-MÉDIA, CORRIGIDO.** O vocabulário de "repo derivado" não conhecia `plugins` nem `mini` em
   `review-artifact-check.sh`, `ladder-integrity-check.sh` e `bash-empty-result-guard.sh`.
   - Cura: `kind: door` entra nos três.
   - A porta source tinha 1 HARD da REGRA 44 por isso; agora tem 0.
8. **BAIXA, CORRIGIDO.** `--list` no fim dos argumentos entrava em laço infinito.
   - Cura: toda flag que exige valor confere `$# -ge 2`.
9. **BAIXA, CORRIGIDO EM PARTE.** O AVISO contava pathspecs, não arquivos, e dizia 72 onde eram 70. O
   `--list` também descartava o stderr do manifesto.
   - Cura: a conta sai da diferença real, e o stderr é repassado.
   - **Não curado:** `commands/meta/README.md` segue cortado no standalone, como já era antes.
10. **BAIXA, CORRIGIDO EM PARTE.** As contagens do nó estavam defasadas depois do rebase. Foram
    recontadas: 782 e 712.
    - **Declarados para depois:** a REGRA 61 trata `utils/marketplace/` como moat, e o `create-vertical`
      depende dele (colide na F4, SAC-93); o `members-validate.sh` aceita adotante com `role: source`.

## Hipóteses refutadas pela passada

- O `--list` não diverge do transporte.
- O mini não recebe o core.
- O standalone não vaza adoção nem federação no caminho feliz.
- O `settings.json` podado é JSON válido e só perde o hook do inbox.
- `_publishes_marketplace` não abre buraco no core.
- As âncoras de todos os mutantes casam.

## Dogfood

O lint de cada porta materializada em diretório temporário:

| porta | arquivos | lint |
|---|---|---|
| standalone | 720 | rc 0 · 0 HARD · 12 SOFT |
| source | 793 | rc 0 · 0 HARD · 11 SOFT |
| mini | 44 | sem lint, por desenho |
