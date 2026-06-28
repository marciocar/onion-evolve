# 📦 Tipos Compartilhados — De-identification

## 🔧 Enums e Constantes

```typescript
type DeIdentifierProvider = 'regex' | 'local-slm' | 'none';

/** Tipos de PII suportados pelo baseline determinístico (regex). O local-slm
 *  estende com PERSON, ADDRESS, ORG e outros sensíveis ao contexto/jurisdição. */
type PiiType =
  | 'EMAIL' | 'CPF' | 'CNPJ' | 'PHONE' | 'CARD' | 'IPV4'   // formato fixo (regex)
  | 'PERSON' | 'ADDRESS' | 'ORG';                          // contextual (local-slm)
```

---

## 📥 Tipos de Entrada

```typescript
interface RedactOptions {
  /** Restringe a redação a certos tipos (default: todos os suportados pelo provider). */
  types?: PiiType[];
  /** Override humano explícito p/ prosseguir SEM redação no provider 'none' (fail-safe). */
  allowUnredacted?: boolean;
}
```

---

## 📤 Tipos de Saída

```typescript
interface PiiEntity {
  type: PiiType;
  span: [number, number];   // [início, fim) no texto original
  value: string;            // o trecho detectado
  confidence: number;       // 1.0 p/ regex (formato fixo); <1.0 p/ local-slm
}

/** Mapa placeholder → original, para o round-trip restore(). */
type RestoreMap = Record<string, string>;   // ex: { "[[EMAIL_1]]": "a@b.com" }

interface RedactionOutput {
  redactedText: string;     // texto com PII substituída por placeholders tipados
  entities: PiiEntity[];    // o que foi encontrado
  restoreMap: RestoreMap;   // para reidentificar a resposta do Claude
  provider: DeIdentifierProvider;
}
```

---

## ⚙️ Configuração

```typescript
interface ProviderConfig {
  provider: DeIdentifierProvider;
  isConfigured: boolean;
  requiredEnvVars: string[];
  optionalEnvVars: string[];
  errorMessage?: string;
}
```

---

**Versão**: 0.1.0
