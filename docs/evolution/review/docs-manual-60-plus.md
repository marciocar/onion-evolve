---
branch: docs/manual-60-plus
pr: pendente
date: 2026-10-12
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_fixed: 2
tokens: 0
duration_min: 60
verdict: CORRIGIDO
nota: rascunho; achado 2 (tarefas 2-4 não rodadas no app) e os critérios humanos ficam com o maestro
reviewer: passada do autor contra a doutrina de material para cliente e contra a documentação oficial dos plugins
REVISOU: true
---

# Resíduo — `docs/manual-60-plus`

Rascunho do manual do Onion para pessoas 60+ (SAC-51), na superfície que o maestro decidiu em
2026-10-12: o app do Claude com os plugins do marketplace público `onion-plugins`.

**Achado 1 — a premissa de bloqueio não se confirmou, mas o carregamento é parcial.** A pergunta era se
plugins de marketplace funcionam fora do Claude Code. Medido na documentação oficial
(`claude.com/docs/plugins/overview` e `claude.com/docs/plugins/platform-support`, lidas em 2026-10-12):
funcionam no chat da web, do desktop e do celular. Só que o chat carrega **skills e comandos** (o
comando vira skill) e **ignora agentes e hooks**. Também exige plano pago e "Code execution and file
creation" ligado (`claude.com/docs/skills/overview`). O manual ficou só com o que o chat carrega, e os
dois requisitos estão no passo 1. Curado.

**Achado 2 — os comandos escolhidos foram escritos para outro ambiente.** O `collect` quer salvar num
gerenciador de tarefas, o `extract-meeting` espera um caminho de arquivo e o `create-task-structure`
sugere camadas técnicas. No chat, o Claude os recebe como instrução e precisa adaptar. A cura parcial
está no texto: as tarefas pedem pelo jeito natural (descrever) e trazem a frase de saída para quando o
Claude falar de "gerenciador de tarefas" ou "repositório". **Não curado por inteiro:** nenhuma das
tarefas 2 a 4 foi rodada no app. Pela cláusula 4 da doutrina (exemplo é promessa), elas são hipótese
até o teste humano. A skill `onion` ficou fora das tarefas porque usa injeção de shell, que o chat pode
não executar.

**Achado 3 — o primeiro número de contraste registrado estava errado.** Escrevi 14.18:1 para texto
sobre a caixa de captura no tema escuro. O script deu 13.52:1. Corrigi antes do commit. É a mesma
classe de "número de cabeça" que a casa já registrou. Todos os números do comentário do HTML agora
saem do script (fórmula WCAG 2.x), e todo par de texto fica acima de 7:1 (AAA).

**Limite declarado:** os rótulos da tela vêm da documentação **em inglês**. Não vi a tela real nem a
tradução pt-BR (cláusula 3: o texto da tela se escreve olhando a tela). O render foi conferido com
Chromium headless em 1280px e 390px, além da impressão em PDF (21 páginas, uma seção por página).
Perfil de público (2-3 pessoas) e teste de uso (2+ pessoas) são critérios humanos e ficam com o maestro.
