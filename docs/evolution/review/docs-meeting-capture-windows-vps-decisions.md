---
branch: docs/meeting-capture-windows-vps-decisions
pr: pendente
date: 2026-10-17
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 5
tokens: 93116
duration_min: 1
findings_fixed: 5
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose opus, mandato REFUTAR, 1 passada curta
nota: "PR de registro (grafo, sinal e preâmbulo); sem código, sem bancada nova e sem mutante. O M4 (teto sem folga) é coerente com o gatilho declarado e não exige ação."
---

# Passada adversarial: `docs/meeting-capture-windows-vps-decisions`

## O que muda

- As três decisões do maestro de 2026-10-17 sobre o sinal da curadoria (SAC-164), seladas pelo `kg-decide-seal.sh` no grafo `meeting-capture-2026-10`:
  - `D_MC_CAPTURA_WINDOWS_LOTE_VPS_1017`, com o selo que fecha `Q_CAPTURA_WINDOWS_CLIENTE_VPS_SERVIDOR_1016`;
  - `D_MC_STT_PARAKEET_ADAPTADOR_CORE_1017`;
  - `D_MC_DIARIZACAO_MEDIR_OS_DOIS_1017`.
- O `Q_DIARIZACAO_SHERPA_X_SORTFORMER_1017` fica aberto.
- O teto sobe de 5 para 9.
- O sinal vai para `_processed/`.
- O preâmbulo do agente de execução ganha a regra de logs com nome único, a pedido da sessão principal.
- O selador grava uma pergunta por nó. Por isso as respostas livres ("quero usar o modelo da nvidia" e "Opção 1 ou NVidia?") e as primeiras perguntas, com as opções delas, foram escritas à mão nas narratives, verbatim, com os textos literais passados pela sessão principal.
- O 1º selo de D1 foi refeito: tinha saído com a pergunta resumida. Reverti o grafo pelo git e selei de novo com o texto literal.

## Achados

- **G1, grave, curado.** A frase "D_ANARLOG_2610 não reabre" contrariava o x_gatilho de `Q_ANARLOG_PORTAO_EXPORT`, que pede o STT sem sair da máquina de captura. Saiu. A narrative agora declara a colisão como pendente do maestro, sem julgá-la.
- **G2, grave, curado.** "O anarlog TEM caminho no Windows" aparecia como fato. Virou "pela leitura de código no pin, NÃO executado no Windows".
- **M1, curado.** A aresta `Q_DIARIZACAO → D_MC_DIARIZACAO` trocou `DEPENDS_ON` por `CONSTRAINS`, o mesmo padrão do portão do anarlog.
- **M2, curado.** O label do adaptador afirmava como decidido o desenho de operação (wrapper, TLS, token). Agora o label traz só a escolha, e a narrative diz que esse desenho vem do sinal.
- **M3, curado.** "Rodada pedida à curadoria" virou "a pedir": não existe pedido feito com rastro.
- **M4, não é defeito.** O teto ficou em 9/9, coerente com o gatilho.

## Mutantes

Nenhum: o PR não traz caso de bancada nem guarda nova.

## Limites declarados

- Não mexi no grafo do anarlog. Emendar o portão ou reabrir o veredito é decisão do maestro.
- O pedido de rodada de diarização à curadoria não foi feito neste PR.
