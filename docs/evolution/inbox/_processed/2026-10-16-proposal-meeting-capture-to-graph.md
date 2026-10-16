---
title: 'Proposta da curadoria: reunião → grafo (Meet e Teams; bot, captura local, arquivo) — dois COSTURAR, um ABSORVER por reescrita e o motor medido'
date: 2026-10-16
from: onion-curation
to: onion-evolve (core)
type: proposal
issue: SAC-157 (Linear, projeto Onion Curadoria), fases 1 a 4
kg:
  - docs/evolution/research/meeting-capture-2026-10/meeting-capture-2026-10.kg.yaml
  - docs/evolution/dissect/vexa-2026-10/vexa-2026-10.kg.yaml
  - docs/evolution/dissect/anarlog-2026-10/anarlog-2026-10.kg.yaml
decision_nodes: D_VEXA_2610, D_ANARLOG_2610, P_CONSENT_EVIDENCE_REWRITE (todos open; o core sela)
---

# Reunião → grafo: o que o mundo oferece e o que a curadoria propõe

O maestro pediu, em 2026-10-16, a curadoria de ferramentas para gravar e transcrever reuniões do Google Meet e do
Teams, para que **cada reunião vire um `.kg.yaml` e exista um grafo de consolidação** no company brain do Onion.
Ele pediu também a revisão da maquinaria que o Onion já tem e a entrada por arquivo (áudio, vídeo ou texto). Este
sinal leva o pacote inteiro para o core decidir. Os grafos completos estão nos `kg:` acima, no repo da curadoria
(PRs #44, #45 e #46).

## Decisões do maestro que valem como requisito
- Comparar bot que entra na chamada com captura local; aceitar subida de áudio, vídeo ou texto.
- Partir da maquinaria existente.
- Veredito de sempre, sem copiar código proprietário.
- Consentimento: *"usar os mesmos critérios de aviso populares atuais, primeiro tem que funcionar, depois podemos
  ajustar e adaptar, mas a ideia é guardar os dados reais, sem de-id"*. A curadoria acrescentou um requisito, só
  proposto: os dados reais ficam fora de repo público e das portas.

## 1. A maquinaria do core hoje (fase 1, `E_MC_MAQUINARIA_SO_TEXTO`, `E_MC_LACUNAS`)
- As 6 peças de reunião convertem texto em Markdown e param aí: `/product:extract-meeting`,
  `/product:consolidate-meetings`, `/product:whisper` e os três especialistas. **Nenhuma escreve `.kg.yaml`** (grep 0).
- O `/product:whisper` só orienta; não transcreve.
- **Defeito de caminho:** o extract grava em `docs/meetings/`, mas o consolidate e o whisper leem `docs/meet/`.
- Faltam: grafo por reunião, consolidação em arestas, captura do Meet ou do Teams, ingestão de áudio ou vídeo,
  diarização e registro de consentimento.

## 2. O motor de transcrição, medido (`E_MC_STT_MEDIDO`)
- Pré-registro em `STT-PROTOCOL.md@77bba10`: 30 falas do FLEURS pt_br, CPU de 8 vCPU sem GPU.

| Motor | WER | RTF |
|---|---|---|
| NVIDIA Parakeet TDT 0.6b v3 (ONNX, fp32) | 5,19 % | **0,126** |
| faster-whisper large-v3-turbo (int8) | 4,53 % | 0,672 |

- Pela regra (diferença de WER menor que 2 pontos → ganha o menor RTF), **o motor recomendado é o Parakeet**, cinco
  vezes mais rápido em CPU.
- A sessão recomputou os números a partir das hipóteses brutas, e eles bateram. O feedback de campo do maestro
  sobre o Parakeet (via Spokenly) saiu corroborado.
- **Limites:**
  - fala lida, não reunião;
  - 30 falas sobre só 12 frases, então a diferença de qualidade não separa os motores;
  - int8 contra fp32 (assimetria declarada).
- **Diarização não medida:** o pyannote community-1 exige token do Hugging Face. Fica como lacuna.

## 3. Bot: a Vexa — COSTURAR a medir, Meet primeiro (`D_VEXA_2610`)
- Apache-2.0, release quase semanal, uma pessoa com 2.024 commits contra 54 do segundo contribuidor.
- O contrato `transcript.v1` traz falante, texto e tempo por segmento. O falante vem da plataforma, sem diarização
  acústica.
- **O achado que mudou o veredito** (o Elenxo reprovou o 1º rascunho, que propunha parquear):
  - a Vexa tem um caminho **sem bot**: uma extensão de navegador captura a aba do Meet em que o maestro já está e
    manda o áudio a um host desktop de um processo só (sem Docker, Postgres ou Redis);
  - o Lite roda em CPU sem token (`LOCAL_STT=1`);
  - o motor é plugável (`TRANSCRIPTION_SERVICE_URL`).
- O "Teams quebrado" da issue #1780 era erro do usuário. O Teams é **frágil**, não quebrado:
  - #1795: o join autenticado é admitido, mas fica sem áudio;
  - #1848: o bot é marcado como ameaça até o aceite manual.
- **Proposta:** adaptador do `transcript.v1` para o grafo da reunião, com consentimento registrado por fora (o bot
  não posta no chat).
  - Portão do Meet: um teste consentido produz 1 segmento ou mais com `speaker` não vazio.
  - Teams parqueado, com critério: `gh api repos/Vexa-ai/vexa/issues/1795 --jq .state | grep -qx open`.

## 4. Captura local: o anarlog (ex-Hyprnote) — COSTURAR (`D_ANARLOG_2610`)
- MIT fora de `enterprise/`, 9,5k estrelas, 1 a 2 releases por semana. O time migrou o foco para o char.
- O app grava o áudio do sistema e do microfone sem bot.
- **Exporta a reunião por CLI**, só lendo o banco: `anarlog meetings export <id> --format json` devolve as palavras
  com tempo, canal e falante. É por aí que a costura passa.
- STT local:
  - o motor embutido só existe em **macOS Apple Silicon**;
  - no Linux, o app aponta o provedor `custom` (compatível com Deepgram) para um servidor no próprio host. Não foi
    medido.
- **Condição:** haver STT local alcançável na máquina de captura do maestro. É lacuna aberta: nada no repo fixa
  essa máquina.
- **Escolha que é do core, sobre o aviso.** A mensagem é constante em inglês, vem desligada por padrão e o regex de
  resposta só entende inglês. As opções:
  - (i) aviso em inglês, como está;
  - (ii) desligar o envio automático e postar aviso próprio em pt-BR, perdendo o registro da tentativa;
  - (iii) fork de duas constantes (a MIT permite), com custo de manutenção.
- A importação do Meet e do Teams do anarlog roda inteira no servidor dele, via Nango, e não entra na costura.

## 5. Absorver por reescrita: o modelo aviso ≠ consentimento (`P_CONSENT_EVIDENCE_REWRITE`)
O melhor desenho do landscape veio do anarlog e vale para qualquer modo de entrada:
- registrar cada **tentativa de aviso** e cada **resposta por participante**;
- **parar de ouvir** se alguém recusa;
- **nunca declarar consentimento legal** (a função dele devolve sempre `false`).

Proposta: reescrever isso em pt-BR como campos do grafo de cada reunião. Caso de bancada: uma reunião sem tentativa
de aviso registrada reprova no gate do grafo de reunião.

## 6. Arquitetura que a curadoria sugere (para o core julgar, não selada)

```
entrada  → extensão Vexa (Meet) | anarlog (local) | arquivo (áudio/vídeo/texto) | API nativa (Meet REST v2, Graph)
STT      → Parakeet (CPU, medido)                      diarização → lacuna (pyannote com token do HF)
contrato → segmentos {falante, texto, início, fim, fonte+offset} + registro de aviso/consentimento
grafo    → 1 .kg.yaml por reunião (decisões, ações, riscos, pessoas, com trace para o trecho)
consol.  → grafo de consolidação entre reuniões (o papel do @meeting-consolidator, em arestas)
dados    → reais, sem de-id, fora de repo público e das portas
```

O passo zero é barato e é do core: corrigir o desencontro `docs/meetings/` × `docs/meet/` e fazer o extract
escrever o `.kg.yaml` da reunião a partir de uma transcrição em texto. Isso já atende a entrada por arquivo de
texto, sem nenhuma ferramenta nova.

## 7. O que fica aberto (não verificado)
- **A máquina de captura do maestro** (Mac Apple Silicon ou Linux). Decide o caminho do anarlog.
- A edição do Workspace e as permissões do Graph, que decidem se as APIs nativas servem
  (`E_N3_NO_BOT_PATHS`, open).
- O token do Hugging Face para a diarização.
- Nenhuma ferramenta foi executada numa reunião. Os N2 são por leitura de código no pin; só o motor rodou.

## 8. Mercado e quem paga
- Régua comercial: o Recall.ai cobra US$0,50/h e fez Série B de US$38M (2025-09). A Vexa hospedada cobra US$0,30/h.
  O anarlog Pro custa US$14 por pessoa/mês.
- Self-host da Vexa e uso local do anarlog: o Onion não paga nada e não abre bilhetagem própria por eles.
- **Via de bilhetagem possível:** o grafo de reunião com consolidação é o que nenhuma das ferramentas entrega. Elas
  param na transcrição ou no resumo. Se o core o construir, é diferencial do company brain, não revenda de captura.
- Capital da Vexa e do anarlog: não achado.

## Achado colateral (fora do tema, para o core triar)
O adapter Linear do `tm.sh` não tem verbo de estimativa nem de `project.create`. A estimativa da SAC-157 foi
registrada como comentário.

Orquestrado com 🧅 Onion Evolve
