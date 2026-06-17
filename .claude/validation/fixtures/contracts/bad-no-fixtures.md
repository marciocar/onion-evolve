# Contract: selftest-bad

- **id:** selftest-bad
- **version:** 1.0.0
- **producer:** m-aaa
- **consumers:** [m-bbb]

## interface
Contrato de exemplo SEM a seção obrigatória `## fixtures`.

## types
```ts
interface Probe { id: string }
```

## tests
- repo/test/contracts/selftest-bad.spec.ts
