---
name: build-company-brain-docs
description: Gerar o contexto do Company Brain (persona de serviço, audiências, canais, regras de voz e conduta) a partir das fontes reais, pelo padrão «exemplo primeiro». Opcional; só roda onde o projeto tem um Company Brain.
allowed-tools: Read Write Bash(find *) Bash(python3 -I vendor/company-brain/tools/voice_conduct_check.py *)
# A ferramenta do resolvedor de pasta de contexto é acrescentada pelo core ao instalar a superfície.

parameters:
  - name: sources
    description: Caminhos, links ou descrições das fontes reais (regras da persona em prosa, matriz de acesso, grafo de audiências, canais)
    required: true

category: docs
tags: [company-brain, context, persona, documentation]
version: "0.1.0"
output_path: docs/company-brain-context/
---

# 🧠 Construtor do contexto do Company Brain

Fonte desta especificação: o produto Onion Company Brain (motor vendorizado em `vendor/company-brain`). A superfície
do comando entra no core por PR do core; o template, o esquema e o validador vêm do motor, por tag.

## 0. Opcional: o core funciona sem Company Brain

Nem todo projeto tem um Company Brain. Este comando só roda **quando alguém o chama** num projeto que tem
(ou quer ter) uma persona de serviço. Nada no core exige o que ele gera:
- quem chama o validador num projeto que pode não ter persona usa `--if-present`: arquivo ausente sai 0;
- o comando não roda sozinho, nem em `/warm-up`, nem em hook.

Se o projeto não tem persona de serviço e ninguém pediu uma, **pare** e diga isso numa linha.

## 1. Pasta-alvo

Use o resolvedor de pasta de contexto do core, na dimensão `company-brain`: a declaração do projeto vence a
convenção (`docs/company-brain-context/`). Declaração inválida: pare e mostre o erro, não grave no default.

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
3. **Propor com as lacunas.** Preencha a página de contexto (`vendor/company-brain/templates/company-brain-context/README.md`) e
   liste, na seção 8, o que a fonte não trouxe. Para cada lacuna, dê uma sugestão e diga como medir. Duas ou três
   sugestões, sem enfeite.
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
