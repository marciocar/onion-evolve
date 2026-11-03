---
branch: docs/port-spikes-qwen-vibe-1103
pr: pendente
date: 2026-11-03
reviewed_diff_sha256: d3cca22222ad45039a19dceadbb10b56085eb52c19e0fbc88858db4872d0ba74
reviewed_code_sha256: 8e1fd279eb4ba790854df476b2a252f9da6af385f0e046888bc99367397880dd
findings_total: 80
findings_real: 70
tokens: 0
duration_min: 210
findings_fixed: 68
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "curadoria (Elenxo, agente separado, 3 passadas no pré-registro) e kg-ssot (revisor separado, 2 passadas no pré-registro e 4 no executor, reclassificando pelo git archive)"
nota: "tokens 0 = não medido do lado das revisões (correram nas sessões peer, cada uma declarou o próprio custo nas mensagens); as contagens de achados somam as passadas."
---

# Passada adversarial: `docs/port-spikes-qwen-vibe-1103`

## O que muda

O pré-registro dos spikes das portas (v3, 5 emendas), o executor (`harness/`: stub, hook, run_cell, classify,
aggregate e testes por mutantes, 153 de 153), a evidência de 137 células (m1, p5, braço real e fixtures), o grafo com
14 nós e a SYNTHESIS.

## Achados

As revisões reprovaram nove vezes antes de fechar (pré-registro 3, executor 6). As duas ressalvas não curadas (o efeito ligado pela ordem no S1-tn-matcher do Vibe e o contorno por outra ferramenta) estão na Emenda 6. Cada achado curado tem o mapa no `PRE-REGISTRO.md` (§9 e §9b) e nas
Emendas 1 a 5. Os de maior peso:
- BARRA sem prova de disparo do hook e sem controle positivo;
- o modo padrão recusando antes do hook;
- o push que não discriminava;
- evidência ausente virando veredito;
- os `.log` fora do commit pelo `.gitignore` da raiz;
- o hook certo conferido depois do efeito;
- o S1-tn medindo o script em vez do matcher;
- o S3c sem guarda;
- veredito criado depois do dado;
- procedência do classificador sobrescrita.

## Não curados, declarados

O S4 (subagente) ficou inconclusivo por janela. O MCP, a camada de permissões e o isolamento de rede não foram medidos.

## Mutantes

`harness/test_classify.py`: 218 de 218 e 7 mutantes de código mortos, rodando a partir do commit.

## Re-revisão do fechamento (2026-11-03)

A branch foi refeita num commit único a partir da origin/main. A única mudança de código depois da revisão foi a
retirada do `harness/.gitignore`, cuja regra `!evidence/**/*.log` ficou obsoleta: a evidência agora viaja em tar.gz.
Os outros ajustes são de documento: os caminhos para `evidence-archive/`, o TETO do grafo e o `trace:` para o
pré-registro. Conferido de novo pela sessão do core: `reproduce.sh` rc 0 (275 células, 112 famílias, match=True),
radar e contrato do grafo rc 0.
