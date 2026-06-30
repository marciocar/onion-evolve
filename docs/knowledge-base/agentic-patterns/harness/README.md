# 🔧 Harness — Internals de Execução

## O que é um harness

**Harness** (arnês) é o sistema de execução que envolve o modelo de IA:
gerencia ferramentas, armazena contexto, roteia mensagens, controla permissões
e expõe a interface ao usuário. O modelo "nu" (pesos + inferência) é apenas o motor;
o harness é o veículo completo.

Entender o harness é entender **onde a IA tem autonomia e onde não tem**, como o
contexto chega até ela e como seus outputs são processados.

---

## Harnesses mapeados

| Harness | Fabricante | Status | Arquivo |
|---------|-----------|--------|---------|
| **Claude Code** | Anthropic | ✅ Mapeado (v1) | [claude-code-internals.md](claude-code-internals.md) |
| Cursor | Anysphere | 🔜 A mapear | — |
| GitHub Copilot | Microsoft | 🔜 A mapear | — |
| Codex CLI | OpenAI | 🔜 A mapear | — |

---

## Por que mapear harnesses?

1. **Previsibilidade:** saber onde o harness armazena o quê elimina surpresas (ex: onde
   foi parar o output do background task?)
2. **Debugging:** quando o agente faz algo inesperado, o harness frequentemente é o
   responsável — não o modelo
3. **Portabilidade:** ao migrar de harness, conhecer os internals do anterior acelera
   a adaptação ao novo
4. **Dogfood:** o Onion roda sobre o Claude Code; entender o Claude Code é entender
   o substrate do próprio Onion
