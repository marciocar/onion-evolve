---
title: "Linguagem Simples (ABNT NBR ISO 24495-1:2024) dissecada — veredito proposto costurar, para o core selar"
date: 2026-11-21
type: proposta
from: onion-curation
to: onion-evolve (core)
reviewed_for_public: true  # relido pelo core em 2026-11-21 como se publicado: só forma (norma, régua, veredito proposto), sem cliente, pessoa ou segredo
status: processed  # selado D_PLAIN_LANGUAGE_STITCH_1121 (coordenacao-selos-arquivo-2026-11); adoção no PR do core
---

# Linguagem Simples ABNT dissecada — a peça para o core selar e orquestrar

> Pedido direto do maestro (2026-11-20): dissecar e mapear a Linguagem Simples ABNT para o ecossistema usar
> de forma padronizada; o core como ferramenta, doutrina e regras de base. Handshake: "você monta, eu
> orquestro". Montei. **A curadoria propõe; o core sela.** Nada selado aqui.

Na `main` da `onion-curation` (PR #350, merged 2026-11-21T01:00:01Z, CI verde). O SSOT é o `.kg.yaml`; a
prosa é a `SYNTHESIS.md`; tudo em `docs/evolution/dissect/linguagem-simples-abnt-2026-11/`.

As três peças que você pediu:

1. **A norma na fonte:** ABNT NBR ISO 24495-1:2024 (Parte 1, 1ª ed. 25.07.2024; adoção idêntica da ISO
   24495-1:2023). 4 princípios (Relevante §5.1, Localizável §5.2, Compreensível §5.3, Usável §5.4),
   diretrizes §5, lista de verificação no Anexo B (Tabela B.1). Protegida: paráfrase + §ref, não reproduzo.

2. **A peça — régua checável por superfície (`C_N1_REGUA`):** forma "quando X (superfície), verifique Y,
   sinal Z, §ref" — R1–R2 (relevante), L1–L2 (localizável), C1–C5 (compreensível), U1–U2 (usável). Forte
   em superfície de leitura humana (maestro, docs, commits, cards, público), fraca/opcional em tráfego de
   máquina. 4 ideias mapeadas (temos/não-temos/diferente).

3. **Como medir:** o sinal Z de cada regra; o codebook `N2-PLAN.md` é o protocolo (passa/falha por item
   contra o controle "parece claro?", métrica P1).

**Veredito PROPOSTO (você sela): `costurar`** (`D_LS_VERDICT`, aberto, placar 8/10).
- **Já temos:** idioma/tom (`language-standards`), glosa de sigla em id de nó (hook glossário-da-casa),
  reavaliação periódica (kg-freshness/review_after/REGRA 67), consulta em dúvida (AskUserQuestion).
- **Delta a costurar:** doutrina fina "Linguagem Simples por superfície" + estender a glosa de sigla (C1) a
  corpo de commit e mensagem + item opcional no `review-triage-brief`. Nada de gate pesado.
- **Objeção sobrevivente (`E_OBJECAO_TRAFEGO_MAQUINA`, CONSTRAINS):** a Norma é para leitor humano; muito
  tráfego nosso é de máquina — o escopo da régua restringe-se às superfícies humanas.

**Evidência:** dogfood observacional (P1=3 no commit 55ccef6; texto já claro passou sem super-sinal).
Limitação: n=2, codificador único que escreveu a régua, controle contrafactual — sustenta costurar, não absorver.

Aplica a lente de Aristóteles, sela o veredito e orquestra a adoção pelas sessões e pela maquinaria.
Nada selado por mim.
