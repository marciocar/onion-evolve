# A fórmula do problema — v1

Fixada antes de abrir a amostra. Quem aplica responde às perguntas **na ordem**. A primeira resposta que decide, decide.

**Atos protegidos** (são do maestro, em qualquer tamanho): merge em repo alheio ou no ramo principal; deploy, publicação,
push de porta; segredo, chave, credencial; mudança de segurança do host (firewall, acesso, sudo, serviço exposto); decisão de
valor (escopo, produto, o que entra, cliente, dinheiro, comunicação externa, doutrina); agendar por relógio; escrever em repo de
outra sessão ou de terceiro. **Autorização datada** só libera o que nomeia, dentro da validade escrita.

"É pequeno" não libera. "Está claro" não libera. "É urgente" não libera. Na dúvida se é protegido, é protegido.

## As cinco perguntas

**1. É real?** Reproduza ou meça no vivo. Aviso de ferramenta, relato e relatório são declaração, não medida.
- Não reproduz, ou já está curado → **R0**.
- Não dá para medir com o que se tem aqui → diga isso, e siga tratando como "pode ser real".

**2. Está causando dano agora?** (segredo exposto, serviço aberto, dado saindo, disco enchendo, produção fora)
- Sim → **R5**. Conter vem antes de entender.

**3. De quem é o ato que resolve?** Quebre o problema em atos; cada ato tem o seu dono.
- Ato protegido → **R6** para esse ato; os demais atos seguem nas perguntas abaixo.
- De outra sessão, repo ou pessoa → **R4**.
- Desta sessão → pergunta 4.

**4. Sabe-se a causa?**
- Não → **R2**.

**5. Quanto pesa?** Dê a nota mais alta que couber, em cada eixo:

| Eixo | 0 | 1 | 2 |
|---|---|---|---|
| Alcance | só esta worktree | o core | viaja: adotantes, portas, público |
| Volta atrás | `git revert` resolve | exige trabalho | não volta |
| Repetição | 1ª vez | 2ª vez | 3 ou mais |

- Repetição ≥ 1 → **R3**.
- Soma ≤ 2 e nada de nota 2 → **R1**.
- Sem custo de esperar, e há algo maior em voo → **R7**.
- Outro caso → **R1**, com revisão independente antes do PR, e a nota escrita no PR.

## As rotas

| Rota | O que é | Quem age | Sem perguntar ao maestro? |
|---|---|---|---|
| **R0 Arquivar** | registra a medida que descartou, com o comando, e fecha | a sessão | sim |
| **R1 Consertar** | conserta na própria worktree, com teste que reprova sem o conserto; abre PR | a sessão | sim, até o PR; o merge segue o caminho da casa |
| **R2 Sondar** | experimento seguro, isolado e de tempo marcado, para achar a causa; depois volta à pergunta 1 | a sessão | sim |
| **R3 Mecanizar** | R1, mais guarda que barra a repetição (`/meta:forge-guard`) | a sessão | sim, até o PR |
| **R4 Encaminhar** | avisa o dono com a evidência; não toca | o dono | sim |
| **R5 Conter e levar** | só a contenção reversível que não seja ato protegido (parar a própria tarefa, tirar do próprio PR, isolar a própria worktree); leva o card ao maestro na hora | a sessão contém, o maestro resolve | avisa já |
| **R6 Levar** | prepara o que dá (evidência, opções, recomendação) e leva por `/meta:decide`; não executa o ato | o maestro | não |
| **R7 Parquear** | nó aberto, com gatilho que se mede | a sessão | sim |

## Limites da rota

- **Duas tentativas.** Dois consertos ou duas sondagens sem fechar → **R6**, com o que se aprendeu.
- **Recurso.** Antes de rodar: carga da máquina, agentes em voo, um pesado por vez. Sem folga, a rota fica e o ato espera.
- **Veto é fim de linha.** Um hook, uma guarda ou um dono barrou → não contorne; vira **R6**.
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
