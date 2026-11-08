# A fórmula do problema — v2

Emenda única da v1, reescrita uma vez sob o `STAGE0.v3.md`. Quem a escreveu viu a falha da v1 e a do pré-teste. Fixada antes do sorteio. Quem aplica responde às perguntas **na ordem**. A primeira resposta que decide, decide.

**Atos protegidos** (são do maestro, em qualquer tamanho, e **não importa em que repo estejam**):

- merge em repo alheio; fazer por conta própria o merge no ramo principal;
- deploy, publicação, push de porta;
- abrir, mover, remover ou trocar segredo, chave, credencial, ou arquivo que possa contê-los;
- mudança de segurança do host (firewall, acesso, sudo, serviço exposto), inclusive **escolher como** fazê-la;
- **enfraquecer** uma guarda, um veto ou uma regra;
- decisão de valor: escopo, produto, o que entra, cliente, dinheiro, comunicação externa, risco de conta, efeito legal, contrariar selo vigente, mudar a identidade da casa (CLAUDE.md, meta-spec);
- **julgar a própria régua:** decidir sobre critério ou peça que a própria sessão mantém ou forjou;
- agendar por relógio;
- escrever em repo de outra sessão ou de terceiro.

**Ordem e autorização** liberam só o que nomeiam, dentro da validade escrita; a escolha que elas não nomeiam segue protegida. "É pequeno" não libera. "Está claro" não libera. "É urgente" não libera. Na dúvida se é protegido, é protegido.

**Não são protegidos, se nenhum item acima também couber:** fortalecer guarda, regra ou teste no próprio repo por PR; ajustar knowledge base por sinal de campo; aplicar o que o maestro já respondeu. Ato que cabe nas duas listas é protegido.

## As cinco perguntas

**1. É real?** Reproduza ou meça no vivo. Aviso de ferramenta, relato e relatório são declaração, não medida.
- Não reproduz, ou já está curado → **R0**.
- Não dá para medir com o que se tem aqui → diga isso, e siga tratando como "pode ser real".

**2. Está causando dano agora?** (segredo exposto, serviço aberto, dado saindo, disco enchendo, produção fora)
- Sim → **R5**. Conter vem antes de entender.

**3. Quais atos fecham o problema?** Liste só os **necessários para fechar este problema**. Não crie decisão que ninguém pediu. Para cada ato, nesta ordem:
- O ato é protegido? → **R6** para ele, mesmo que o repo seja de outro.
- É de outra sessão, repo ou pessoa? → **R4**.
- É desta sessão → pergunta 4.

O merge do próprio PR não é ato da rota: ele vem depois de R1 e R3, pelo caminho da casa.

**Fechar e informar:** o ato da sessão não espera resposta. Um desvio que o maestro precisa saber se informa, e a cura segue. Só a parte protegida espera; se um segredo foi exposto, a rotação é R6.

**4. Sabe-se a causa?**
- Não → **R2**.

**5. Quanto pesa?** Dê a nota mais alta que couber, em cada eixo:

| Eixo | 0 | 1 | 2 |
|---|---|---|---|
| Alcance | só esta worktree | o core | viaja: adotantes, portas, público |
| Volta atrás | `git revert` resolve | exige trabalho | não volta |
| Repetição | 1ª vez | 2ª vez | 3 ou mais |

Na ordem:
- Repetição ≥ 1, e nenhuma guarda barrou desta vez → **R3**.
- Sem custo de esperar, e há algo maior em voo → **R7**.
- Soma ≤ 2 e nada de nota 2 → **R1**.
- Outro caso → **R1**, com revisão independente antes do PR, e a nota escrita no PR.

## As rotas

| Rota | O que é | Quem age | Sem perguntar ao maestro? |
|---|---|---|---|
| **R0 Arquivar** | registra a medida que descartou, com o comando, e fecha | a sessão | sim |
| **R1 Consertar** | conserta na própria worktree, com teste que reprova sem o conserto; abre PR | a sessão | sim, até o PR |
| **R2 Sondar** | experimento seguro, isolado e de tempo marcado, para achar a causa; depois volta à pergunta 1 | a sessão | sim |
| **R3 Mecanizar** | R1, mais guarda que barra a repetição (`/meta:forge-guard`) | a sessão | sim, até o PR |
| **R4 Encaminhar** | avisa o dono com a evidência; não toca | o dono | sim |
| **R5 Conter e levar** | só a contenção reversível que não seja ato protegido (parar a própria tarefa, tirar do próprio PR, isolar a própria worktree); leva o card ao maestro na hora | a sessão contém, o maestro resolve | avisa já |
| **R6 Levar** | prepara o que dá (evidência, opções, recomendação) e leva por `/meta:decide`; não executa o ato | o maestro | não |
| **R7 Parquear** | nó aberto, com gatilho que se mede | a sessão | sim |

## Limites da rota

- **Duas tentativas.** Dois consertos ou duas sondagens sem fechar → **R6**, com o que se aprendeu.
- **Recurso.** Antes de rodar: carga da máquina, agentes em voo, um pesado por vez. Sem folga, a rota fica e o ato espera.
- **Veto é fim de linha.** Um hook, uma guarda ou um dono barrou → não contorne; vira **R6**. Usar o caminho que o próprio veto indica não é contornar.
- **Rota genérica não vale.** "Investigar e reportar" sem ator, sem ato e sem como saber que acabou é não ter rota.

## A saída, sempre nesta forma

```
real?       sim | não | não medi (o comando)
dano agora? sim | não
atos:       <ato> → <dono> → protegido? sim/não
nota:       alcance A · volta atrás V · repetição P
rota:       R? (uma por ato)
próximo ato:<verbo, alvo, ator>
fecha quando: <o que se mede>
```
