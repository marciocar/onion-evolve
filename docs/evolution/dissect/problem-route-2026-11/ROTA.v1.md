# A rota do problema — v1

Derivada de `FORMULA.v2.md` por um agente que viu as falhas dela. Congelada no commit do plano, sem emenda depois da
abertura. Quem aplica responde às perguntas **na ordem**. A primeira resposta que decide, decide.

A rota não é cerca. Parte dos atos é barrada por hook, na hora de executar. Ato barrado é fim de linha: vira **R6**, sem
contorno. A rota não repete o que os hooks barram.

## O que a rota não decide

Cada item vai a **R6**, em qualquer tamanho e em qualquer repo, porque nenhum hook o barra:

1. **Decisão de valor:** escopo, produto, o que entra, cliente, dinheiro, comunicação externa, risco de conta, efeito
   legal, contrariar selo vigente, mudar a identidade da casa (CLAUDE.md, meta-spec).
2. **Fato que falta:** um fato que não se mede daqui e muda o ato (licença, termo de uso, o risco que o dono da conta
   aceita). Diga qual fato falta. Fato público que se lê daqui é **R2**.
3. **A própria régua:** decidir sobre critério ou peça que a própria sessão mantém ou forjou; renovar a própria
   autorização.
4. **Ato que sai por caminho aprovado:** rodar script de deploy ou de publicação, fazer o merge no ramo principal, agendar
   por relógio.
5. **Segredo:** abrir, mover, remover ou trocar segredo, chave, credencial, ou arquivo que possa contê-los.
6. **Segurança do host:** firewall, acesso, sudo, serviço exposto, inclusive escolher como fazer.
7. **Enfraquecer** uma guarda, um veto ou uma regra.

Ordem e autorização liberam só o que nomeiam, dentro da validade escrita.

**Fora desses sete, na dúvida, o ato é da sessão.** Ela faz na própria worktree e informa. Informar não espera resposta.

## As cinco perguntas

**1. É real?** Reproduza ou meça no vivo. Aviso de ferramenta, relato e relatório são declaração, não medida.
- Não reproduz, ou já está curado → **R0**.
- Não dá para medir com o que se tem aqui → diga isso, e siga tratando como "pode ser real".

**2. Está causando dano agora?** (segredo exposto, serviço aberto, dado saindo, disco enchendo, produção fora)
- Sim → **R5**.

**3. Quais atos fecham o problema?** Liste só os necessários para fechar este problema. Para cada ato, nesta ordem:
- Cabe num dos sete → **R6** para ele.
- É de outra sessão, repo ou pessoa → **R4**.
- É desta sessão → pergunta 4.

O merge do próprio PR não é ato da rota: vem depois de R1 e R3, e o item 4 vale para ele.

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
| **R3 Mecanizar** | R1, mais guarda que barra a repetição | a sessão | sim, até o PR |
| **R4 Encaminhar** | avisa o dono com a evidência; não toca | o dono | sim |
| **R5 Conter e levar** | só a contenção reversível que não caiba nos sete (parar a própria tarefa, tirar do próprio PR, isolar a própria worktree); leva o card ao maestro na hora | a sessão contém, o maestro resolve | avisa já |
| **R6 Levar** | prepara evidência, opções e recomendação, e leva; não executa o ato | o maestro | não |
| **R7 Parquear** | nó aberto, com gatilho que se mede | a sessão | sim |

**Duas tentativas** sem fechar → **R6**, com o que se aprendeu. **Rota genérica não vale:** sem ator, ato e como saber que
acabou, não há rota.

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
