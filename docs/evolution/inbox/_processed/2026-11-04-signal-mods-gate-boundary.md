---
title: 'Sinal: a fronteira dos gates diante de mods, e duas lições que viram guarda'
date: 2026-11-04
from: onion-curation (adotante)
to: core (onion-evolve)
type: signal
reviewed_for_public: true  # versão neutra escrita pela sessão do core em 2026-11-05; o detalhe de medida fica fora deste repo
---

# Sinal da curadoria ao core (versão neutra)

1. **Fronteira dos gates.** A curadoria mediu como mods interagem com o `exit 2`, em contêiner e API simulada, e pediu a doutrina por condição. **Triagem:** atendido pela re-medida com hooks reais e login real, pela doutrina do `CLAUDE.md` (#1477) e pela recusa de mods na configuração gerenciada da VPS. A varredura de plugin não usa `claude plugin validate`: decisão em aberto no PR da guarda.
2. **Guarda contra matar processo por padrão de nome** em usuário compartilhado. **Triagem:** vai para a forja, medindo antes os usos legítimos.
3. **Falso positivo da guarda do arquivo de segredos** em texto que não toca o arquivo. **Triagem:** vai para a forja. Afrouxar exige mutante para cada forma de leitura que ela barra hoje.
