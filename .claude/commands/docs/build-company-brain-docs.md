---
name: build-company-brain-docs
description: Gerar o contexto do Company Brain (persona de serviço, audiências, canais, regras de voz e conduta) na pasta declarada (default `docs/company-brain-context/`), pelo padrão «exemplo primeiro». Opcional; só roda onde o projeto tem ou quer um Company Brain.
allowed-tools: Read Write Bash(find *) Bash(ls *) Bash(bash .claude/utils/scope/resolve-context-dir.sh *) Bash(python3 -I vendor/company-brain/tools/voice_conduct_check.py *)

parameters:
  - name: sources
    description: Caminhos, links ou descrições das fontes reais (regras da persona em prosa, matriz de quem pede e quem aprova, grafo de audiências, canais)
    required: true

category: docs
tags:
  - company-brain
  - context
  - persona
  - documentation

version: "0.1.0"
updated: "2026-11-22"

output_path: docs/company-brain-context/

related_commands:
  - /company-brain:persona
  - /docs:build-business-docs
  - /meta:inventory

related_agents:
  - product-agent
---

# 🧠 Construtor do contexto do Company Brain

Superfície do comando no core. A especificação, o template, o esquema e o validador são do motor do produto
Onion Company Brain, vendorizado por tag em `vendor/company-brain/` (a versão e o sha256 de cada arquivo estão em
`vendor/company-brain/.company-brain-version`). Fonte desta superfície: `vendor/company-brain/builder/build-company-brain-docs.md`;
o que este arquivo acrescenta é o resolvedor de pasta de contexto do core e a saída quando o motor falta.

## 📥 Input

<arguments>
#$ARGUMENTS
</arguments>

## 0. Opcional: o core funciona sem Company Brain

Nem todo projeto tem um Company Brain. Este comando só roda **quando alguém o chama** num projeto que tem
(ou quer ter) uma persona de serviço. Nada no core exige o que ele gera:

- quem chama o validador num projeto que pode não ter persona usa `--if-present`: arquivo ausente sai 0;
- o comando não roda sozinho, nem no `/warm-up`, nem em hook.

Se o projeto não tem persona de serviço e ninguém pediu uma, **pare** e diga isso numa linha.

**Motor ausente:** sem `vendor/company-brain/tools/voice_conduct_check.py` (projeto que recebeu o Onion sem o
motor), **pare** e diga numa linha que o motor do Company Brain não está instalado neste projeto. Não escreva
regra sem o validador para conferi-la.

## 1. Pasta-alvo (resolva antes de gravar)

A pasta não é fixa. O repo pode declará-la em `.claude/onion-context.yaml` (`context.company-brain`), e a
declaração vence a convenção (skill `onion-company-brain-context` §1):

```bash
bash .claude/utils/scope/resolve-context-dir.sh company-brain --source   # → "<caminho><TAB><onion-context|default>"
```

Neste comando, **`<pasta>` quer dizer a pasta que ele imprimiu** (o default `docs/company-brain-context/` só vale
quando ele diz `default`). Saída `3` = declaração inválida: **pare** e mostre o erro, não grave no default.

Antes de gerar, confira o que já existe, sem cobrar quem não tem:

```bash
python3 -I vendor/company-brain/tools/voice_conduct_check.py <pasta>/voice-conduct.yaml --if-present
```

rc 0 sem o arquivo: comece do template. Com o arquivo: o dono já tem regras, então **reconcilie** (mostre o diff
antes de gravar, nunca sobrescreva). rc 2 é «não deu para julgar», nunca verde.

## 2. «Exemplo primeiro»

1. **Ir à fonte real.** Leia as fontes passadas em `sources`: as regras da persona (em prosa, se houver), a matriz
   de quem pede e quem aprova, o grafo de audiências e os canais em uso. Não invente: cada linha gerada cita a
   fonte ou o id do nó.
2. **Voltar com o exemplo concreto.** Gere primeiro o `voice-conduct.yaml` a partir do template
   (`vendor/company-brain/templates/company-brain-context/voice-conduct.yaml`) como **rascunho**
   (`status: draft`, sem `approved_by` nem `approved_at`) e rode o validador:
   ```bash
   python3 -I vendor/company-brain/tools/voice_conduct_check.py <pasta>/voice-conduct.yaml --allow-draft
   ```
   rc 0 quer dizer que a forma e o sentido conferem; ainda **não** quer dizer aprovado. rc 1 lista os achados
   (corrija pela fonte, não pelo validador). rc 2 é «não deu para julgar», nunca verde.
3. **Propor com as lacunas.** Preencha a página de contexto
   (`vendor/company-brain/templates/company-brain-context/README.md`) e liste, na seção 8, o que a fonte não
   trouxe. Para cada lacuna, dê uma sugestão e diga como medir. Duas ou três sugestões, sem enfeite.
4. **Perguntar o formato** ao dono. Só com o aceite dele: tire `status: draft`, preencha `approved_by` (o dono) e
   `approved_at`, e acerte a entrada do histórico. A partir daí o validador roda **sem** `--allow-draft`.

## 3. Regras

- **Papel, nunca nome.** Pessoas, e-mails e telefones ficam fora dos arquivos gerados.
- **Pedir não é aprovar.** Ninguém aprova como «qualquer pessoa»; cada tipo de ato tem um só aprovador. As regras
  em si são aprovadas pelo dono.
- **Canal sem os cinco pontos** (hora do pedido; quem pede e o papel; contexto do lugar; fio com assinatura;
  quem mais vê) entra na tabela de canais com o que falta, e ainda não usa o padrão.
- **Número sem fonte é hipótese**: `max_chars_basis: hypothesis` até haver medida.
- O dado da empresa fica no repositório dela. O produto só recebe de volta sinais de forma, sem conteúdo.

## 4. Saída

```
📁 <pasta>/README.md            página de contexto
📁 <pasta>/voice-conduct.yaml   regras de voz e conduta (validador rc 0)
🕳️ lacunas: <n>, com sugestão e medida
⏱️ tempo até o 1º exemplo: <do pedido>, ciência: <hora em que viu>
```

> **Limite declarado (2026-11-22):** este comando gera o arquivo no esquema **v2** do motor
> (`onion/voice-conduct/v2`). O warm-up `/company-brain:persona` do core ainda confere pelo validador **v1** do
> core (`.claude/validation/voice-conduct-check.sh`), que recusa a v2 (medido: `VC-FIELD-TYPE` no `schema`).
> O validador do motor aceita a v1. Até a migração do core para o validador vendorizado, confira o arquivo
> gerado pelo validador do motor, como no passo 2.

## 🔗 Referências

- Motor vendorizado: `vendor/company-brain/README.md` (esquema v2, validador, conformidade, template)
- Carimbo e conferência do vendor: `python3 -I .claude/validation/company-brain-vendor-check.py check`
- Resolvedor da dimensão: skill `onion-company-brain-context`
- Warm-up da persona (lê o que este comando gera): `/company-brain:persona`
