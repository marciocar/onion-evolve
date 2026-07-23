---
description: >
  Ajuda alguém a CONHECER e USAR o Onion — orienta a família (papéis), situa o papel do repo atual e
  conduz aos primeiros valores. É a face "ajuda a CONHECER" da Condução (par da onion-wizard, "ajuda a
  FAZER"). Ative quando a pessoa quer ENTENDER/começar (ex.: "o que é isso?", "como uso?", "por onde
  começo?", um adotante abrindo o repo pela 1a vez, pós-clone/pós-adoção), mesmo sem dizer "onboarding".
  NÃO executa movimentos (isso é o wizard) — ensina e ENTREGA ao wizard quando é hora de fazer.
allowed-tools: Read AskUserQuestion Bash(bash .claude/utils/wizard/*) Bash(bash .claude/validation/onion-version.sh*) Bash(bash .claude/validation/lint-artifacts.sh*) Skill
---

# Onion Onboarding — a Condução que ensina (ajuda a CONHECER/USAR)

Não é um wizard (não é um passo a completar); é um **sistema contínuo** (Orient → Activate → Reinforce),
multi-sessão. A métrica é *"a pessoa alcançou valor repetível"*, não *"terminou uma tela".*

## A lei (anti-dessincronização)

**Você PROJETA da fonte única, nunca hand-descreve a família.** Os papéis vêm do KG-topologia via
`bash .claude/utils/wizard/topology-projection.sh --roles`; os movimentos, sem `--roles`. Se a topologia
mudar, o que você ensina muda **sozinho**. É fonte≠derivação (a mesma fonte que o wizard executa; a REGRA 41
a guarda). Sem python, degrade: ensine pela KB `onion-guided-lifecycle.md`, não invente a família.

## Orient — "onde você está e o que é possível" (não pergunta ainda)

1. **Papel deste repo:** `bash .claude/validation/onion-version.sh | grep '^role:'` (`source`/`hub`/`adopted`;
   sem stamp = source).
2. **A família (projeção `--roles`):** apresente o mapa, mas **progressivo** — comece pelo papel DELE ("você é
   um `hub` — a empresa que controla os próprios projetos"), depois a cadeia `source → hub → consumer` e só
   então os demais se perguntarem. Não despeje os 6 papéis de uma vez.
3. **O que este papel pode fazer:** as transições **válidas** para o papel (projeção default) — em linguagem de
   valor ("daqui você adota seus projetos"), não de comando.

## Activate — a 1ª ação de valor (e o handoff pro wizard)

Leve à **primeira vitória** do papel — e aqui está a divisão da tríade: onboarding **não faz**, ensina e
**entrega**. Quando a ação é um movimento (adotar/promover/atualizar), diga o valor e **acione o wizard**
(`onion-wizard` via Skill) para conduzir o fazer. Ex.: um `adopted` que quer adotar a Aura → "seu 1º passo é
virar hub; deixa eu te conduzir" → wizard.
- Rampa canônica pós-adoção: `LEIA-ME-PRIMEIRO.md` (se existir) → `bash .claude/validation/lint-artifacts.sh`
  (verde = íntegro) → `/warm-up` → `/onion`. Você **unifica** esses — não os substitui.

## Reinforce — fixar o hábito (multi-sessão)

- **Comprove o valor**, não a conclusão: rodou o lint verde? adotou um projeto? o hook disparou?
- Feedback curto + **o próximo passo natural** (não um checklist a vencer). Volte em sessões seguintes pelo
  ponto onde parou (o papel do repo evolui: `adopted → hub`, `hub → …`).

## Elenxo — admita a fronteira

- **Não finja completude:** aponte o que se aprende **usando/perguntando**, não lendo ("isto você pega no 1º
  adopt real"). Onboarding honesto marca o que não cobre.
- **Distinga-se do wizard sempre:** se a pessoa quer FAZER agora, não ensine em círculos — **entregue ao
  wizard**. Se quer ENTENDER, não execute — ensine.
