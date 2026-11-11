# Operador de dados na LGPD: o Onion hospedado exige pessoa jurídica?

Data do levantamento: 2026-11-11. Natureza: levantamento para o maestro decidir **com um advogado**. Não é parecer jurídico.

Legenda de fonte: **[PRIM]** = texto oficial lido (planalto.gov.br, DOU, gov.br/anpd); **[SEC]** = escritório, contabilidade, blog ou resumo (opinião ou paráfrase, não vale como norma); **[MEM]** = conhecimento geral, não conferido nesta rodada (está também na seção NÃO-VERIFICADOS).

## Resposta curta

**Não.** Nem a LGPD nem a ANPD exigem que o operador seja pessoa jurídica. A lei define operador como "pessoa natural ou jurídica" e o guia da ANPD diz que "não há óbices" a uma pessoa natural ser operadora. A pergunta que pesa não é "pode?", é "com que patrimônio eu respondo?" e "o cliente vai aceitar?". Aí a pessoa jurídica (em especial a sociedade limitada unipessoal) pesa muito a favor, por razões civis e comerciais, não por exigência da LGPD.

---

## 1. A LGPD exige pessoa jurídica para o operador?

- **Art. 5º, VII [PRIM]**: operador é a "pessoa natural ou jurídica, de direito público ou privado, que realiza o tratamento de dados pessoais em nome do controlador". O mesmo vale para o controlador (art. 5º, VI). Art. 5º, IX: agentes de tratamento são "o controlador e o operador".
  URL: https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709compilado.htm
- **Guia Orientativo da ANPD, "Definições dos Agentes de Tratamento e do Encarregado", 2ª versão, abril/2022 (retificada, 26 págs.) [PRIM]**, item 58: "pessoas físicas e jurídicas de direito público e privado podem atuar como operadoras. Na maior parte das vezes, o operador é uma pessoa jurídica [...]. Contudo, não há óbices para que uma pessoa natural contratada como prestadora de serviços para uma finalidade específica possa ser considerada operadora de dados." O guia é orientativo, não vinculante.
  URL: https://www.gov.br/anpd/pt-br/documentos-e-publicacoes/Segunda_Versao_do_Guia_de_Agentes_de_Tratamento_retificada.pdf/@@download/file
- **O que o operador não pode ser** (guia, item 60 [PRIM]): empregado, administrador, sócio ou quem atua "como profissional subordinado a este ou como membro de seus órgãos" do controlador. "O operador será sempre uma pessoa distinta do controlador." Para o Onion: o maestro, prestando serviço a um cliente como terceiro, é operador. Funcionário do cliente que usa o serviço não é.
- **Art. 39 [PRIM]**: o operador trata "segundo as instruções fornecidas pelo controlador", que verifica a observância. Se o Onion decidir finalidade ou meios essenciais por conta própria (por exemplo, usar dados de um cliente para treinar ou melhorar o serviço de todos), passa a ser **controlador** daquele tratamento, com mais obrigações. O guia (item 57) admite que o operador defina elementos não essenciais, como medidas técnicas.
- **Art. 42, §1º, I [PRIM]**: o operador responde solidariamente "pelos danos causados pelo tratamento" quando descumpre a lei ou as instruções lícitas do controlador (e então se equipara a ele). §1º, II: controladores diretamente envolvidos respondem solidariamente. §4º: quem repara o dano tem direito de regresso proporcional à participação de cada um. Art. 43: exclusão se provar que não tratou, que não violou a lei, ou culpa exclusiva do titular ou de terceiro.
- **Guia, item 62 [PRIM]**: a solidariedade do operador "pode ser considerada como uma excepcionalidade, já que em regra a responsabilidade é do controlador", ocorrendo quando há tratamento irregular do operador. Em princípio é a única hipótese em que o operador é equiparado ao controlador.
- **Art. 44 [PRIM]**: tratamento irregular inclui não oferecer a segurança esperada; parágrafo único responsabiliza quem, por não adotar as medidas do art. 46, der causa ao dano de segurança.
- **Arts. 38 e 40**: o art. 40 (ANPD pode dispor sobre padrões e tempo de guarda dos registros) foi lido. O art. 38 (relatório de impacto, a critério da ANPD, a pedido) não foi lido nesta rodada.

## 2. Obrigações do operador

| Tema | Fonte | O que diz |
|---|---|---|
| Registro das operações | Art. 37 [PRIM] | "controlador e o operador devem manter registro das operações de tratamento de dados pessoais que realizarem". O guia (item 61) reforça que ambos partilham a obrigação. |
| Instruções | Art. 39 [PRIM] | Tratar só conforme instruções do controlador. |
| Segurança | Art. 46 [PRIM] | Medidas técnicas e administrativas "aptas a proteger os dados pessoais" contra acessos não autorizados e situações acidentais ou ilícitas, desde a concepção. Art. 47: dever de segurança vale também após o fim do tratamento. |
| Incidente | Art. 48 e Res. CD/ANPD nº 15/2024 [PRIM] | O dever de comunicar à ANPD e ao titular é do **controlador**. Art. 6º da Res. 15: "pelo controlador no prazo de três dias úteis", contado "do conhecimento pelo controlador de que o incidente afetou dados pessoais". Art. 9º: mesmo prazo para o titular. Art. 10: o controlador mantém registro do incidente por no mínimo cinco anos. O formulário prevê "a identificação do operador, quando aplicável" (art. 6º, §2º, X). **O regulamento não traz prazo próprio para o operador avisar o controlador.** O dever de avisar "sem demora injustificada" vem de FAQ/orientação da ANPD, e eu só o vi em resumo [SEC]. Na prática, o contrato é que fixa o prazo (ver seção 5). |
| Contrato | Guia, itens 54 a 56 [PRIM] | A LGPD não exige expressamente contrato, mas ele é "boa prática": "as cláusulas contratuais impõem limites à atuação do operador, fixam parâmetros objetivos para a alocação de responsabilidades". Pode definir "objeto, duração, natureza e finalidade do tratamento, os tipos de dados pessoais envolvidos e os direitos e obrigações e responsabilidades". Obrigação do operador: "dar ciência ao controlador em caso de contrato com suboperador". |
| Suboperador | Guia, itens 64 a 67 [PRIM] | A LGPD não define suboperador. É quem o operador contrata para auxiliá-lo em nome do controlador; a relação direta é com o operador. Recomenda-se "autorização formal (genérica ou específica) do controlador", que pode constar do contrato, para não atrair ao operador responsabilidades do controlador. Para o Onion: a VPS, o provedor de nuvem, o backup e o provedor de e-mail do serviço são suboperadores. |
| Sanções | Art. 52 [PRIM] | Advertência, multas, bloqueio, eliminação etc., aplicáveis aos agentes de tratamento. |
| Encarregado | Art. 41 [PRIM] | É dever do **controlador**. O operador não tem essa obrigação legal direta (a ANPD tem regulamento próprio do encarregado, Res. nº 18/2024, citada em resumo [SEC]; não lida). |

Direitos do titular (art. 18) são exercidos contra o controlador. O operador deve, na prática, apoiar o cliente a atendê-los (portabilidade, eliminação, acesso). Isso vira requisito do produto e do contrato.

## 3. Regulamento de pequeno porte (Res. CD/ANPD nº 2/2022)

Texto lido no DOU de 28/01/2022 [PRIM] (arts. 1º a 16 do anexo). URL do texto no DOU: https://in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562019

**Quem se enquadra (art. 2º, I):** "microempresas, empresas de pequeno porte, startups, pessoas jurídicas de direito privado, inclusive sem fins lucrativos [...], bem como **pessoas naturais** e entes privados despersonalizados que realizam tratamento de dados pessoais, assumindo obrigações típicas de controlador ou de operador". Portanto **pessoa física se enquadra**. O MEI se enquadra como microempresa (art. 2º, II inclui expressamente "o microempreendedor individual").

**Quem fica de fora (art. 3º):** (I) quem realiza **tratamento de alto risco**, (II) quem passa do teto de receita da LC 123 (ME/EPP R$ 4,8 milhões, art. 3º II [PRIM]; startups, o teto da LC 182), (III) quem integra grupo econômico acima do teto.

**Alto risco (art. 4º):** exige, cumulativamente, ao menos um critério geral (larga escala **ou** afetar significativamente direitos fundamentais) **e** um específico (tecnologias emergentes ou inovadoras; vigilância de zona pública; decisões unicamente automatizadas; **dados sensíveis ou de crianças, adolescentes e idosos**). Para o Onion: se um cliente guardar dados sensíveis (saúde, biometria) em larga escala, ou se "tecnologia inovadora" for lida de forma ampla, o operador pode perder o regime. A ANPD publicou guia de alto risco; eu não li o texto final [SEC].

**O que é simplificado ou dispensado:**
- Registro das operações (art. 37): "podem cumprir [...] de forma simplificada" (art. 9º); a ANPD fornece modelo. **Simplificado, não dispensado.**
- Encarregado: "não são obrigados a indicar" (art. 11), mas devem oferecer **canal de comunicação** com o titular (§1º). A indicação voluntária conta como boa prática (§2º). Como o encarregado é dever do controlador, isso pesa mais sobre o cliente.
- Segurança: medidas "essenciais e necessárias" e **política simplificada** (arts. 12 e 13). Não é dispensa.
- Prazos em dobro (art. 14): atendimento ao titular, comunicação de incidente (agora "nos termos do Regulamento" da Res. 15, por alteração do art. 14, II feita pelo art. 2º da Res. 15/2024 [PRIM]), declarações do art. 19 e prazos de resposta à ANPD. O prazo em dobro **não vale** se houver risco à integridade física ou moral ou à segurança nacional.
- Art. 5º: quando a ANPD pedir, o agente comprova o enquadramento em 15 dias. Art. 6º: a flexibilização não afasta bases legais, princípios, direitos dos titulares e obrigações contratuais. Art. 16: a ANPD pode exigir o que foi dispensado, conforme natureza, volume e risco.

**Ponto de atenção comercial:** o enquadramento é do agente, mas o **contrato com o cliente pode exigir mais** que a flexibilização (art. 6º cobra as obrigações contratuais). Clientes grandes tendem a pedir DPA, política de segurança e evidências.

## 4. Responsabilidade civil: pessoa física × empresa; MEI

**Pessoa física operadora.** A reparação do art. 42 recai sobre quem trata. Sem pessoa jurídica, a responsabilidade é direta e **ilimitada sobre o patrimônio pessoal** [MEM, regra geral do direito civil: o devedor responde com todos os bens]. A solidariedade do §1º, I faz o titular ou o controlador poderem cobrar o todo do operador, que fica com o direito de regresso do §4º. O art. 45 [PRIM] preserva o regime do consumidor quando a relação for de consumo (improvável em B2B, mas o titular final do dado, se for consumidor do cliente, pode alcançar toda a cadeia).

**Pessoa jurídica.** Art. 49-A do Código Civil [PRIM]: "A pessoa jurídica não se confunde com os seus sócios, associados, instituidores ou administradores"; a autonomia patrimonial é instrumento lícito de "alocação e segregação de riscos" (parágrafo único, lido via resumo [SEC]). Limite, art. 50 [PRIM]: o juiz pode desconsiderar a personalidade em caso de "desvio de finalidade ou confusão patrimonial". Para sociedade limitada, a responsabilidade do sócio é restrita ao valor das suas quotas, mas todos respondem solidariamente pela integralização do capital (CC art. 1.052) [MEM, não conferido]. A **sociedade limitada unipessoal (SLU)** existe desde a Lei 13.874/2019 e a Lei 14.195/2021 (art. 41) transformou as antigas EIRELIs em SLU [PRIM, só o art. 41 lido]; permite um único sócio com limitação de risco, sem exigir capital mínimo [MEM].

Limites do escudo, que o advogado deve explicar: (a) responsabilidade **própria** do administrador por ato ilícito, (b) desconsideração por confusão patrimonial (misturar conta pessoal e da empresa), (c) em dados e segurança, o dano costuma vir de falha de processo da própria empresa, que o patrimônio dela absorve, mas isso significa que o capital e o seguro da empresa é que pagam, não o do maestro [raciocínio, não fonte].

**MEI.** Para a LC 123, o MEI é "empresário individual" (art. 18-A, §1º [PRIM]). Empresário individual **não tem separação patrimonial** entre a pessoa e o negócio [MEM, regra geral; não conferi nesta rodada]. Logo o MEI **não protege o patrimônio** como a SLU. Além disso:
- Teto de receita: R$ 81.000/ano (LC 123, art. 18-A, §1º [PRIM]). Há projeto elevando o teto (R$ 110 mil a R$ 140 mil conforme a fonte), previsto para 2027, sem sanção confirmada por mim [SEC].
- Vedações do §4º [PRIM]: participar de outra empresa como titular, sócio ou administrador; mais de um estabelecimento; constituir-se como startup.
- Atividade: a lista de CNAEs permitidos ao MEI é a do CGSN (não lida). Fontes de contabilidade dizem que **hospedagem e processamento de dados (CNAE 6311-9/00) não são permitidos ao MEI** e que desenvolvimento de software sob encomenda em geral também não [SEC]. Usar um CNAE permitido para fazer outra atividade é risco fiscal de desenquadramento [SEC]. **Resposta provisória: MEI provavelmente não pode prestar o serviço de hospedagem; precisa conferir a tabela oficial do CGSN e com contador.**

**Prática de mercado.** Em SaaS B2B brasileiro, o operador quase sempre é Ltda ou SLU (Simples Nacional ou lucro presumido), porque (i) contrata com nota fiscal e CNPJ, (ii) assina DPA e responde com patrimônio separado, (iii) clientes de médio porte exigem CNPJ no fornecedor de TI [MEM/raciocínio; não achei estatística]. MEI aparece em prestação de serviço individual, não em plataforma hospedada.

## 5. Como operadores pequenos fazem: DPA e cláusulas mínimas

Não existe modelo oficial da ANPD de contrato entre controlador e operador (busca não achou). O guia da ANPD lista o que o contrato **pode** fixar (item 56, seção 2). Fontes comerciais e públicas (confidata, Prefeitura de SP, AGU) convergem em [SEC]:

1. Partes, papéis (cliente = controlador; Onion = operador) e **objeto, duração, natureza, finalidade**, categorias de dados e de titulares (guia item 56 [PRIM]).
2. **Tratar só conforme instruções documentadas** do controlador; vedar uso próprio (treino, analytics) e declarar que o operador avisa se a instrução parecer ilegal (art. 39 [PRIM] para o primeiro ponto).
3. **Segurança (art. 46)**: anexo com medidas mínimas (criptografia, controle de acesso, logs, backup, isolamento por cliente), confidencialidade das pessoas autorizadas.
4. **Incidente**: prazo curto para o operador avisar o controlador (consultorias sugerem 24 a 48 horas; é prática, não regra), conteúdo mínimo (natureza, dados e titulares afetados, medidas), cooperação para o controlador cumprir o prazo de três dias úteis (Res. 15, art. 6º [PRIM]).
5. **Suboperadores**: lista (VPS, nuvem, backup), autorização geral ou específica com aviso prévio de troca e direito de objeção; mesmas obrigações repassadas (guia item 67 [PRIM]).
6. **Apoio aos direitos dos titulares** (art. 18): prazo para encaminhar solicitações recebidas e ferramentas de exportação e exclusão.
7. **Devolução ou eliminação** ao fim do contrato, com prazo e certificação; retenção só por obrigação legal.
8. **Auditoria**: aviso prévio, frequência máxima, procedimento; ou entrega de evidências (relatórios, certificações).
9. **Transferência internacional (art. 33)**: se o servidor ou subcontratado estiver fora do Brasil, a base e as cláusulas-padrão da ANPD [SEC; art. 33 e as cláusulas-padrão não lidos]. **Relevante: onde fica a VPS?**
10. **Responsabilidade e limites**: repartição conforme art. 42 e direito de regresso (§4º [PRIM]); teto de responsabilidade e seguro, a negociar. Cuidado: cláusula de limitação não vale contra o titular, só entre as partes [MEM].
11. Registro das operações (art. 37) e canal de contato do titular (Res. 2, art. 11, §1º [PRIM]).

Apoio de mercado a verificar com o advogado: modelos da Prefeitura de SP (manual de controle 14), parecer AGU nº 4/2022 sobre LGPD em contratos administrativos, material de consultorias. Nenhum é modelo oficial para SaaS.

---

## O que isso implica para o Onion

**Fatos que sustentam as opções:** (1) pessoa física pode ser operadora (art. 5º VII; guia item 58); (2) responde solidariamente nos casos do art. 42 §1º I, sem escudo patrimonial; (3) pequeno porte pode ser aplicado a pessoa física, mas só se **não** houver alto risco (art. 3º, I), e dados sensíveis de clientes não são controláveis por nós; (4) MEI não separa patrimônio e provavelmente não cobre hospedagem; (5) o contrato (DPA) é o centro prático, não a natureza jurídica.

### Opção A: constituir pessoa jurídica antes do 1º cliente externo (SLU ou Ltda)

- **Custo:** abertura (Junta, CNPJ, contador, certificado): ordem de poucas centenas a poucos milhares de reais iniciais e mensalidade de contabilidade [estimativa minha, **não verificada**; peça cotação]. Tempo: dias a semanas. Obrigações fiscais contínuas (nota de serviço, impostos, balanço). Pró-labore e separação rigorosa de contas.
- **Risco:** o escudo é imperfeito (art. 50 CC; responsabilidade do administrador por ato próprio); custo fixo mesmo sem receita; tem que respeitar confusão patrimonial. Escolher o CNAE correto (hospedagem/processamento de dados) e o regime tributário (Simples nem sempre cabe a certos CNAEs; checar com contador).
- **Ganho:** separa risco; o cliente PJ contrata fornecedor com CNPJ e nota fiscal; DPA assinado pela empresa; seguro cibernético contratável em nome da PJ [MEM].

### Opção B: operar como pessoa física, com contrato (DPA) e seguro

- **Custo:** menor de entrada (advogado para o DPA e prêmio de seguro; cotação **não verificada**, e seguradoras podem exigir CNPJ [MEM]). Mas recebimento de pagamento de empresa por pessoa física implica RPA/autônomo e tributação de pessoa física (carnê-leão, INSS), geralmente pior e sem nota de serviço [MEM].
- **Risco:** responsabilidade ilimitada e solidária com o patrimônio pessoal (art. 42 §1º I). Seguro e cláusula de teto mitigam só entre as partes, não contra o titular nem contra a ANPD. Clientes empresariais podem recusar. A regra de pequeno porte alivia a burocracia (registro simplificado, sem encarregado), não a responsabilidade.
- **Quando faz sentido:** piloto fechado, um ou dois clientes conhecidos, dados de baixo risco, sem dados sensíveis, tetos por contrato e prazo curto.

### Opção C: esperar (não ter cliente externo ainda)

- **Custo:** zero agora; o custo é a oportunidade (nenhum cliente, nenhum aprendizado de campo).
- **Risco:** o risco jurídico de operar para terceiros é nulo enquanto não houver dado de terceiro. Se o serviço hospedar dados de terceiros "de teste" sem contrato, já há tratamento. Há risco de decidir tarde e atravessar o 1º contrato sem estrutura.
- **Variante útil:** continuar construindo o que serve a qualquer opção (registro de operações simplificado, política de segurança, lista de suboperadores, modelo de DPA, isolamento e eliminação por cliente, relatório de incidente), de modo que o dia em que houver PJ ou cliente, a conformidade técnica esteja pronta.

### Recomendação

**Opção A, em passo condicional:** não constituir agora, mas **constituir a SLU antes de assinar o primeiro contrato com dado de terceiro**, e manter a Opção C (esperar) até lá, preparando o pacote técnico-contratual (variante útil). Razões: a LGPD não obriga PJ, mas a solidariedade do art. 42 sem escudo é o pior risco, o MEI não resolve nem parece caber, e cliente empresarial vai exigir CNPJ e DPA. A decisão de **forma** (SLU × Ltda com sócio, regime tributário, CNAE) deve vir do advogado e do contador, junto com a análise de **alto risco** (se haverá dado sensível ou larga escala, o regime simplificado cai e o DPA precisa ser mais robusto). Peça também parecer sobre onde fica a VPS (transferência internacional) e sobre seguro.

Perguntas objetivas para o advogado: (1) SLU cabe no Simples com o CNAE de hospedagem/processamento de dados? (2) cláusula de teto de responsabilidade e regresso no DPA; (3) quando o Onion vira controlador (uso de dados do cliente para melhorar o produto); (4) enquadramento de alto risco para o grafo de conhecimento; (5) cobertura de seguro cibernético para startup SLU.

---

## NÃO-VERIFICADOS (não conferi em fonte primária nesta rodada)

1. **CC art. 1.052** (limite da responsabilidade do sócio na Ltda; capital mínimo zero) e **a ausência de separação patrimonial do empresário individual/MEI**: citados de memória. Confirmar no Código Civil (art. 966 e seguintes, 1.052) e com o advogado.
2. **Art. 49-A parágrafo único** (autonomia patrimonial como "alocação e segregação de riscos"): vi só em resumo; o caput foi lido no Planalto. Duas fontes divergem sobre qual lei o incluiu (13.874/2019 ou 14.195/2021): não resolvi.
3. **Lista de CNAEs permitidos ao MEI (Res. CGSN 140)**: só fontes de contabilidade dizem que 6311-9/00 e desenvolvimento sob encomenda estão fora. Conferir no Portal do Empreendedor.
4. **Teto do MEI em 2027**: noticiado R$ 110 mil a R$ 140 mil; sanção não confirmada. Hoje vale R$ 81.000 [PRIM, LC 123].
5. **Dever do operador de avisar o controlador "sem demora injustificada"**: origem em FAQ da ANPD, vista só em resumo. O texto da Res. 15 não traz esse prazo (lido: arts. 4º, 5º, 6º, 8º, 9º, 10; art. 6º, §2º, X).
6. **Res. CD/ANPD nº 18/2024 (encarregado) e Res. nº 23/2024**, **guia de alto risco** e a **Nota Técnica nº 42/2026 da ANPD**: aparecem em resultados, não abertos. A NT 42/2026 pode trazer mudança sobre pequeno porte; **abrir antes de decidir**.
7. **LGPD arts. 33 (transferência internacional), 38 (RIPD)** e **art. 18**: só resumo. Cláusulas-padrão de transferência da ANPD: citadas por fonte secundária.
8. **Custos de abertura de empresa, contabilidade, seguro cibernético**: estimativas minhas, sem cotação.
9. **Pessoa física: tributação e RPA, seguradoras exigirem CNPJ, clientes exigirem CNPJ**: prática de mercado, sem estatística nem fonte.
10. **Existência de modelo oficial de DPA da ANPD**: a busca não achou, mas não é prova de ausência.
11. **Texto da Res. 2/2022 "atualizado"** (consolidado após a Res. 15): li o texto original do DOU de 2022 e o art. 2º da Res. 15 que altera o art. 14, II. Pode haver outras alterações (a Res. 23/2024 mexe no art. 4º, segundo resumo [SEC]).
12. Todo o conteúdo de **[SEC]** (confidata, Migalhas, Mayer Brown, contabilidade) é opinião ou resumo.

## Fontes

- LGPD (Lei 13.709/2018, compilada): https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709compilado.htm
- Res. CD/ANPD nº 2/2022 (DOU 28/01/2022): https://in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562019
- Res. CD/ANPD nº 15/2024 (cópia da Biblioteca Digital do MJ): https://bibliotecadigital.mj.gov.br/bitstream/1/12879/2/RES_ANPD_2024_15.html
- Guia de agentes de tratamento, 2ª versão, abr/2022: https://www.gov.br/anpd/pt-br/documentos-e-publicacoes/Segunda_Versao_do_Guia_de_Agentes_de_Tratamento_retificada.pdf/@@download/file
- LC 123/2006: https://www.planalto.gov.br/ccivil_03/leis/lcp/lcp123.htm
- Lei 14.195/2021: https://www.planalto.gov.br/ccivil_03/_ato2019-2022/2021/lei/l14195.htm
- Código Civil: https://www.planalto.gov.br/ccivil_03/leis/2002/l10406compilada.htm
- Secundárias: https://confidata.com.br/blog/como-elaborar-dpa-data-processing-agreement ; https://www.meucontadoronline.com.br/blog/servicos-hospedagem-infraestrutura-nuvem-processamento-dados-quais-cnaes-usa ; https://www.gov.br/memp/pt-br/teto-do-mei
