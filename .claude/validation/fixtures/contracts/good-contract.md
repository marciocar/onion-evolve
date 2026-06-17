# Contract: selftest-probe

- **id:** selftest-probe
- **version:** 1.0.0
- **producer:** m-aaa
- **consumers:** [m-bbb]

## interface
Integração de exemplo usada apenas pelo auto-teste do validador de contratos.

## types
```ts
interface Probe { id: string }
```

## tests
- repo/test/contracts/selftest-probe.spec.ts

## fixtures
```json
{ "id": "x" }
```
