---
title: "O contrato v3 está pronto para o core adotar por pin: tag contract-v3.0.0, vendor com carimbo e gate por grafo — o core vivo já passa 142/142, e o radar sozinho aceita 55 casos que o contrato reprova"
date: 2026-10-08
type: signal
from: onion-kg-ssot (adopted, pin 51c663555584)
to: core (onion-evolve)
flow: upstream
severity: high
decision_owner: core (maestro sela)
---

# A graduação do contrato: o core passa a validar contra ele

O primeiro marco do KG-SSOT (`Q_KG_SCHEMA_FORMAL_SPIKE`) fecha quando **o core valida contra o contrato**. O
lado do produto está pronto e publicado (`A_ADOPTION_KIT`, PR #31 mergeado). O que falta é o PR de adoção
**no core**. O maestro escolheu (2026-10-08) que quem o implementa é a sessão do core, a partir deste sinal.

## 1. O que adotar

A tag **`contract-v3.0.0`** de `marciocar/onion-kg-ssot` (commit `820de3bbb967`). O `spec/release.json` da tag
lista 179 arquivos:
- o contrato v3 (MUST e SHOULD, JSON Schema 2020-12);
- a suíte de conformidade;
- o leitor de referência (`kg_validate.py`, `kg_conformance.py`);
- o vendor (`kg_vendor.py`) e o gate (`kg_gate.py`);
- `requirements.txt` (PyYAML e jsonschema fixados);
- `ADOPTING.md`, o guia completo, com os rc de cada ferramenta.

Foi verificada vendorizando direto da URL do GitHub: 179 arquivos, `check` íntegro.

O mecanismo é **vendor por pin, como o Onion**, mas sem merge de três vias: o contrato não se customiza no
adotante. O vendor substitui o diretório e grava um carimbo com tag, commit e sha256 de cada arquivo. O `check`
reprova qualquer edição local, inclusive bytecode plantado em `__pycache__`. Uma mudança que o core precisar
volta como sinal para o produto e vira caso ou decisão de contrato.

O carimbo `vendor/kg-ssot/.kg-ssot-version` é **o lado do core no pin mútuo**. Hoje só o adotante fixa o core.

## 2. Como (os comandos, prontos)

Na raiz do core, num PR próprio:

```bash
python3 -I /home/marcio/onion-kg-ssot/tools/kg_vendor.py update --tag contract-v3.0.0 --dest vendor/kg-ssot
#   (ou --source https://github.com/marciocar/onion-kg-ssot.git a partir de qualquer clone/vendor; o repo é privado)
git add vendor/kg-ssot
pip install -r vendor/kg-ssot/tools/requirements.txt
python3 -I vendor/kg-ssot/tools/kg_gate.py --update      # grava .kg-ssot/gate.json
git add .kg-ssot/gate.json
```

Passo proposto para o `onion-validate.yml`, ao lado do radar. O CI do core não precisa de token: os arquivos
ficam commitados no core.

```yaml
- name: Contrato KG-SSOT (vendor íntegro + gate por grafo)
  run: |
    python3 -m pip install --quiet -r vendor/kg-ssot/tools/requirements.txt
    python3 -I vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot
    python3 -I vendor/kg-ssot/tools/kg_gate.py
```

O gate mede os `.kg.yaml` rastreados por git, deixando de fora `*/fixtures/*` e `docs/materials/*`, como no
spike. Isso também exclui as fixtures do próprio vendor. A catraca é **por grafo**:
- um grafo novo ou que passou a falhar no MUST reprova;
- um código MUST novo num grafo herdado reprova;
- a dívida SHOULD que sobe por código reprova;
- um contrato mudado reprova (nome ou sha256 dos schemas).

Consertar um grafo não compensa quebrar outro. rc 2 é entrada quebrada e nunca passa verde.

## 3. A bancada (medida no core vivo, `33057daa0892`, só leitura)

**O gate no core:** **142 de 142 grafos passam no MUST.** A linha de base nasce com `failing` vazio: zero dívida
herdada. No pin `51c663555584` eram 135 de 140, então as migrações que o core fez depois dos sinais anteriores
fecharam a distância.

**Dívida SHOULD por código** (número de grafos, chaves desconhecidas agregadas por escopo):

| código | grafos | rampa |
|---|---|---|
| `form.required.node.provenance` | 142 | MUST no v4 para confirmed/PROD (`Q_CONTRACT_STRUCTURED_PROVENANCE`) |
| `yaml.unquoted-date` | 138 | data sem aspas: string em YAML 1.2, data em 1.1 |
| `form.range.node.label` | 113 | label com mais de 280 caracteres: a narrativa vai para `narrative` |
| `form.unknown-key.meta.*` | 31 | chave fora do contrato e sem `x_` |
| `form.required.node.verified_at` | 12 | PROD sem `verified_at` |
| `form.unknown-key.node.*` · `top.*` · `edge.*` | 9 · 4 · 1 | idem |

Nada disso bloqueia. A catraca só impede que a dívida suba.

**O radar sozinho não checa forma.** No mesmo commit, `kg-radar.sh --integrity --schema` concorda com o contrato
em **87 de 144** vereditos da suíte:
- **aceita 55 casos que o contrato reprova**: nó sem `label`, tipos errados, datas fora do padrão, `provenance`
  malformada, chave repetida, `trigger` órfão…
- **recusa 2 válidos**.

Reproduzir: `python3 -I tools/kg_matrix.py` neste repo, com um registro apontando o radar para esse commit. Esse é
o buraco que o gate fecha. O radar continua sendo o leitor da semântica e da integridade; o gate cobre a forma.

## 4. O que pedimos ao core

1. **O PR de adoção:** vendor da tag, `.kg-ssot/gate.json`, o passo de CI acima. Vale decidir se ele entra também
   no hook de pre-commit, ao lado do lint.
2. **Não editar o vendor.** Se algo do contrato atrapalhar, sinal para cá.
3. **Decidir o caminho do radar:**
   - (a) o gate fica ao lado do radar, que é a proposta e não exige mudar o radar;
   - (b) o radar passa a chamar o leitor de referência.
   A matriz mede as duas.
4. **Avisar quando mergear**, com o commit. Aqui vamos:
   - re-medir a matriz com o gate do core como leitor;
   - atualizar o pin;
   - oferecer ao maestro o flip de `Q_KG_SCHEMA_FORMAL_SPIKE` e `EPIC_6_CORE_GRADUATION`.

## 5. Como atualizar depois

Uma tag nova (`contract-vX.Y.Z`) vem como sinal daqui. O PR do core faz três coisas:
1. roda `kg_vendor.py update --tag <nova> --source <este repo>`;
2. roda o gate;
3. explica a diferença e grava a base com `--update`, porque a identidade do contrato muda.

Um aviso novo no SHOULD sobe a dívida por desenho. As rampas chegam assim, medidas.

## Fronteiras

- Esta sessão **não escreveu no core**. A prova de ponta a ponta foi num clone descartável (`git clone --shared`).
  Nenhum arquivo do core mudou e nenhuma tag foi criada lá.
- O secret `ONION_CORE_READ_TOKEN` daqui segue vazio, então a camada do core da catraca deste repo continua
  sendo medida só localmente. Isso não afeta a adoção: o CI do core lê o vendor commitado.
