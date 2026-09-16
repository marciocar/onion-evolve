# 🧭 Decisões (ADR) — por que o mecanismo é como é

Esta categoria guarda os **ADRs que viajam**: as decisões de arquitetura que explicam **por que** a
maquinaria do Onion tem a forma que tem. Quem adota o framework recebe o mecanismo; aqui recebe o
**porquê** — sem o qual toda guarda parece arbitrária e a primeira fricção vira motivo para desligá-la.

## O que entra

Um ADR entra aqui quando as três valem:

1. **Explica uma decisão do FRAMEWORK**, não da casa que o escreveu.
2. **É citado por artefato que viaja** (comando, helper, guarda) — o leitor do artefato precisa dele.
3. **Não identifica ninguém**: sem nome de adotante, de cliente, nem caminho de máquina. A lição de
   campo permanece (*"medido num adotante em 2026-07"*); a identidade, não.

O critério 3 não é formalidade. Ao promover os 13 primeiros (2026-09-16), **32 ocorrências** de nome
precisaram de neutralização — entre elas o nome de um **cliente de um adotante**, exposição de segundo
grau que o registro da federação nunca conheceu. Promover sem essa passada teria publicado, para todos
os adotantes, quem são os outros.

## O que NÃO entra

Decisão sobre **este** repo (topologia da federação, quem adota quem, incidentes de adotante,
consolidação de um cliente específico) fica em `docs/analysis/`, que **não viaja**. Se o nome do
arquivo identifica, ele já respondeu à pergunta — nem promova.

## Como citar

De artefato que viaja, cite o **caminho relativo** para cá. De prosa, cite pelo **título**. Nunca
aponte para `docs/analysis/` a partir de superfície vendorizada: é a REGRA 45 (Link vendorizado não
aponta caminho core-privado, com catraca), e ela tem catraca.
