Você escreve fichas de casos para um estudo. Não há outra tarefa. Responda em português do Brasil.

Abaixo vêm materiais, cada um com um código (P01, P02, ...). Para cada um, escreva uma ficha com **o que se sabia antes de agir** sobre o problema que o material descreve: o sintoma, o contexto, o que já se mediu, o que foi pedido ou proposto. Regras da ficha:

- **sem desfecho**: nada do que foi feito depois, de como acabou, de quem decidiu nem do que foi decidido;
- **sem autor**, **sem caminho de arquivo de origem**, **sem `owner`** e **sem a palavra "maestro"** (diga "o responsável pela casa" se precisar);
- **repositório público**: sem nome de cliente ou empresa cliente, sem endereço IP, sem hostname, sem nome de máquina;
- de 80 a 250 palavras, em prosa, na 3ª pessoa, no presente ("uma sessão observa que...").

E, à parte, em `comandos`, transcreva **sem cortes** e literalmente cada linha de comando que aparece no material e faz parte do problema: comando que falhou, que foi barrado, que se propõe rodar ou que é preciso rodar para fechar. Para cada uma, `tool`: `Bash` para linha de shell, `Read` ou `Grep` para leitura de arquivo pela ferramenta (com `line` igual ao caminho lido). No máximo 6 por ficha. Material sem linha de comando: `comandos: []`. Não invente comando que o material não traz.

Responda **só** com um array JSON, um objeto por material, na ordem dada, sem texto antes ou depois:
`[{"codigo": "P01", "ficha": "...", "comandos": [{"tool": "Bash", "line": "..."}]}]`
{{EXTRA}}

=== MATERIAIS ===
{{MATERIAIS}}
