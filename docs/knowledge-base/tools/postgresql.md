# PostgreSQL 17 — triggers, functions, migrations e performance (com Prisma)

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-10 | **Categoria**: Tools
> Conhecimento técnico de PostgreSQL 17 + Prisma ORM, **extraído do agente
> `@postgres-specialist`** na rodada shed-ceremony de 2026-07-10 (doutrina: agente mantém o grafo
> executável; conhecimento de fundo vive em KB citável — mesmo padrão de
> `platforms/gamma-app-api.md` e `patterns/presentation-orchestration.md`). O agente cita esta KB;
> consumidores humanos e IA leem daqui.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-10 |
| **Última Atualização** | 2026-07-10 |
| **Fonte** | Extração de `.claude/agents/development/postgres-specialist.md` v3.0.0 |
| **Agente relacionado** | `@postgres-specialist` |

---

## 📋 Índice

1. [Triggers — anatomia e criação](#1-triggers--anatomia-e-criação)
2. [Tipos de triggers por caso de uso](#2-tipos-de-triggers-por-caso-de-uso)
3. [Functions — tipos e padrões avançados](#3-functions--tipos-e-padrões-avançados)
4. [Schema design e migrations](#4-schema-design-e-migrations)
5. [Performance optimization](#5-performance-optimization)
6. [Debugging e monitoramento](#6-debugging-e-monitoramento)
7. [Exemplos completos](#7-exemplos-completos)
8. [Checklists de tarefas comuns](#8-checklists-de-tarefas-comuns)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Triggers — anatomia e criação

### Anatomia de um trigger PostgreSQL

```sql
CREATE OR REPLACE TRIGGER trigger_name
  {BEFORE | AFTER | INSTEAD OF} {INSERT | UPDATE | DELETE}
  ON table_name
  [FOR EACH {ROW | STATEMENT}]
  [WHEN (condition)]
  EXECUTE FUNCTION function_name();
```

### Processo para criar trigger

**Passo 1: criar a function trigger**

```sql
-- Function DEVE retornar TRIGGER
CREATE OR REPLACE FUNCTION function_name()
RETURNS TRIGGER AS $$
BEGIN
  -- OLD: registro antes da operação (UPDATE/DELETE)
  -- NEW: registro depois da operação (INSERT/UPDATE)

  -- Lógica do trigger

  RETURN NEW; -- ou OLD, ou NULL
END;
$$ LANGUAGE plpgsql;
```

**Passo 2: criar o trigger**

```sql
CREATE TRIGGER trigger_name
  BEFORE INSERT OR UPDATE ON table_name
  FOR EACH ROW
  EXECUTE FUNCTION function_name();
```

**Passo 3: integrar com Prisma**

Em projetos com Prisma, triggers devem ser criados via **migration SQL**:

```bash
# 1. Criar migration vazia
npx prisma migrate dev --create-only --name add_trigger_example

# 2. Editar arquivo SQL gerado
# prisma/migrations/[timestamp]_add_trigger_example/migration.sql

# 3. Adicionar SQL do trigger

# 4. Aplicar migration
npx prisma migrate dev
```

---

## 2. Tipos de triggers por caso de uso

### A. Audit trail (rastreamento de mudanças)

```sql
-- Function para audit
CREATE OR REPLACE FUNCTION audit_table_changes()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    INSERT INTO audit_log (
      table_name, operation, old_data, changed_by, changed_at
    ) VALUES (
      TG_TABLE_NAME, TG_OP, row_to_json(OLD), current_user, NOW()
    );
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO audit_log (
      table_name, operation, old_data, new_data, changed_by, changed_at
    ) VALUES (
      TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW), current_user, NOW()
    );
    RETURN NEW;
  ELSIF (TG_OP = 'INSERT') THEN
    INSERT INTO audit_log (
      table_name, operation, new_data, changed_by, changed_at
    ) VALUES (
      TG_TABLE_NAME, TG_OP, row_to_json(NEW), current_user, NOW()
    );
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER audit_users_changes
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW
  EXECUTE FUNCTION audit_table_changes();
```

### B. Validação e consistência

```sql
-- Validar email antes de insert/update
CREATE OR REPLACE FUNCTION validate_email()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$' THEN
    RAISE EXCEPTION 'Email inválido: %', NEW.email;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_email_format
  BEFORE INSERT OR UPDATE OF email ON users
  FOR EACH ROW
  EXECUTE FUNCTION validate_email();
```

### C. Timestamps automáticos

```sql
-- Atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();
```

### D. Cascade logic personalizado

```sql
-- Soft delete em cascade
CREATE OR REPLACE FUNCTION soft_delete_cascade()
RETURNS TRIGGER AS $$
BEGIN
  -- Quando user é soft deleted, soft delete related records
  IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    UPDATE orders SET deleted_at = NOW() WHERE user_id = NEW.id;
    UPDATE addresses SET deleted_at = NOW() WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cascade_user_soft_delete
  AFTER UPDATE OF deleted_at ON users
  FOR EACH ROW
  EXECUTE FUNCTION soft_delete_cascade();
```

### E. Business logic enforcement

```sql
-- Prevenir updates em campos específicos
CREATE OR REPLACE FUNCTION prevent_id_change()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.id <> OLD.id THEN
    RAISE EXCEPTION 'Não é permitido alterar o ID';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_user_id_update
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION prevent_id_change();
```

---

## 3. Functions — tipos e padrões avançados

### A. Scalar functions (retorna valor único)

```sql
CREATE OR REPLACE FUNCTION calculate_age(birth_date DATE)
RETURNS INTEGER AS $$
BEGIN
  RETURN EXTRACT(YEAR FROM AGE(birth_date));
END;
$$ LANGUAGE plpgsql;

-- Uso:
SELECT name, calculate_age(birth_date) AS age FROM users;
```

### B. Table functions (retorna tabela)

```sql
CREATE OR REPLACE FUNCTION get_active_users()
RETURNS TABLE (
  id UUID,
  name TEXT,
  email TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, u.name, u.email
  FROM users u
  WHERE u.is_active = true
  ORDER BY u.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Uso:
SELECT * FROM get_active_users();
```

### C. Stored procedures (não retorna valor)

```sql
CREATE OR REPLACE PROCEDURE cleanup_old_logs(older_than_days INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM logs
  WHERE created_at < NOW() - (older_than_days || ' days')::INTERVAL;

  RAISE NOTICE 'Deleted logs older than % days', older_than_days;
END;
$$;

-- Uso:
CALL cleanup_old_logs(30);
```

### D. Aggregate functions (personalizada)

```sql
CREATE OR REPLACE FUNCTION weighted_average_accumulator(
  state NUMERIC[],
  value NUMERIC,
  weight NUMERIC
)
RETURNS NUMERIC[] AS $$
BEGIN
  IF state IS NULL THEN
    state := ARRAY[0, 0];
  END IF;

  state[1] := state[1] + (value * weight);
  state[2] := state[2] + weight;

  RETURN state;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION weighted_average_finalizer(state NUMERIC[])
RETURNS NUMERIC AS $$
BEGIN
  IF state[2] = 0 THEN
    RETURN NULL;
  END IF;
  RETURN state[1] / state[2];
END;
$$ LANGUAGE plpgsql;

CREATE AGGREGATE weighted_avg(NUMERIC, NUMERIC) (
  SFUNC = weighted_average_accumulator,
  STYPE = NUMERIC[],
  FINALFUNC = weighted_average_finalizer
);
```

### Exception handling

```sql
CREATE OR REPLACE FUNCTION safe_divide(a NUMERIC, b NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
  IF b = 0 THEN
    RAISE EXCEPTION 'Divisão por zero não permitida';
  END IF;
  RETURN a / b;
EXCEPTION
  WHEN division_by_zero THEN
    RAISE NOTICE 'Tentativa de divisão por zero';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

### Dynamic SQL

```sql
CREATE OR REPLACE FUNCTION count_records(table_name TEXT)
RETURNS INTEGER AS $$
DECLARE
  count_result INTEGER;
BEGIN
  EXECUTE format('SELECT COUNT(*) FROM %I', table_name)
  INTO count_result;

  RETURN count_result;
END;
$$ LANGUAGE plpgsql;
```

### Loop e iteração

```sql
CREATE OR REPLACE FUNCTION generate_report()
RETURNS TABLE (user_id UUID, total_orders INTEGER) AS $$
DECLARE
  user_record RECORD;
BEGIN
  FOR user_record IN SELECT id FROM users LOOP
    user_id := user_record.id;

    SELECT COUNT(*) INTO total_orders
    FROM orders
    WHERE orders.user_id = user_record.id;

    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

---

## 4. Schema design e migrations

### Naming conventions

- Tables: plural, snake_case (`users`, `bank_accounts`)
- Columns: singular, snake_case (`user_id`, `created_at`)
- Indexes: `idx_table_column` (`idx_users_email`)
- Foreign keys: `fk_table1_table2` (`fk_orders_users`)
- Unique constraints: `uq_table_column` (`uq_users_email`)

### Timestamps padrão

```sql
created_at TIMESTAMP DEFAULT NOW() NOT NULL,
updated_at TIMESTAMP DEFAULT NOW() NOT NULL
```

### UUIDs vs Serial

```sql
-- Preferir UUIDs para distributed systems
id UUID DEFAULT gen_random_uuid() PRIMARY KEY

-- Serial/BigSerial para single-instance simples
id BIGSERIAL PRIMARY KEY
```

### Migrations seguras com Prisma

```bash
# 1. Modificar schema.prisma

# 2. Criar migration
npx prisma migrate dev --name descriptive_name

# 3. Revisar SQL gerado
cat prisma/migrations/[timestamp]_descriptive_name/migration.sql

# 4. Se necessário, editar SQL manualmente (triggers, functions, etc)

# 5. Aplicar migration
npx prisma migrate dev

# 6. Gerar Prisma Client
npx prisma generate
```

### Migration com zero downtime

```sql
-- BAD: Adicionar coluna NOT NULL sem default (causa downtime)
ALTER TABLE users ADD COLUMN phone VARCHAR(20) NOT NULL;

-- GOOD: Multi-step migration
-- Step 1: Adicionar coluna nullable
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Step 2: (Código app atualizado para popular phone)

-- Step 3: Atualizar nulls com valor default
UPDATE users SET phone = 'not-provided' WHERE phone IS NULL;

-- Step 4: Adicionar NOT NULL constraint
ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
```

### Rollback strategy

Sempre criar migration de rollback:

```sql
-- migration.sql (up)
CREATE TABLE new_table (...);

-- rollback.sql (down) - criar manualmente
DROP TABLE IF EXISTS new_table;
```

---

## 5. Performance optimization

### Indexing strategies

**A. Single column index:**

```sql
CREATE INDEX idx_users_email ON users(email);
```

**B. Composite index:**

```sql
-- Ordem importa! Mais seletivo primeiro
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Beneficia queries:
-- WHERE user_id = ? AND status = ?
-- WHERE user_id = ?
-- Mas NÃO beneficia: WHERE status = ?
```

**C. Partial index:**

```sql
-- Index apenas registros ativos (menor e mais rápido)
CREATE INDEX idx_active_users ON users(email)
WHERE is_active = true;
```

**D. Index para LIKE queries:**

```sql
-- Para LIKE 'prefix%'
CREATE INDEX idx_users_name ON users(name text_pattern_ops);

-- Para full-text search
CREATE INDEX idx_users_name_fulltext ON users
USING GIN (to_tsvector('portuguese', name));
```

**E. Unique index:**

```sql
CREATE UNIQUE INDEX idx_users_email_unique ON users(email);
```

### Query optimization — workflow EXPLAIN ANALYZE

```sql
-- 1. Identificar query lenta
EXPLAIN ANALYZE
SELECT u.name, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at > '2024-01-01'
GROUP BY u.id, u.name
ORDER BY order_count DESC
LIMIT 10;

-- 2. Analisar output:
-- - Seq Scan = BAD (precisa index)
-- - Index Scan = GOOD
-- - Execution Time alta = precisa otimizar

-- 3. Criar indexes necessários
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- 4. Re-executar EXPLAIN ANALYZE
-- 5. Comparar performance
```

### Padrões comuns de otimização

```sql
-- BAD: SELECT *
SELECT * FROM users; -- traz colunas desnecessárias

-- GOOD: Select apenas necessário
SELECT id, name, email FROM users;

-- BAD: N+1 queries
-- SELECT * FROM orders WHERE user_id = ? (executado N vezes)

-- GOOD: JOIN ou IN clause
SELECT o.* FROM orders o
WHERE o.user_id IN (SELECT id FROM users WHERE is_active = true);

-- BAD: Function call em WHERE (não usa index)
WHERE LOWER(email) = 'test@example.com'

-- GOOD: Index funcional
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
```

### Features específicas do PostgreSQL 17

**A. Incremental backup:**

```sql
-- Novo em PG 17: Backups incrementais nativos
-- Uso via pg_basebackup
```

**B. MERGE statement improvements:**

```sql
-- MERGE melhorado em PG 17
MERGE INTO target_table t
USING source_table s ON t.id = s.id
WHEN MATCHED THEN
  UPDATE SET value = s.value
WHEN NOT MATCHED THEN
  INSERT (id, value) VALUES (s.id, s.value);
```

**C. Logical replication enhancements:**

```sql
-- Melhorias em replicação lógica
-- Suporte para DDL replication
```

**D. JSON improvements:**

```sql
-- Novas funções JSON em PG 17
SELECT jsonb_path_query(data, '$.items[*].price')
FROM products;
```

---

## 6. Debugging e monitoramento

### Ver triggers ativos

```sql
-- Listar todos triggers de uma tabela
SELECT
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users';

-- Detalhes de trigger específico
\d+ users -- no psql
```

### Ver functions criadas

```sql
-- Listar functions
SELECT
  routine_name,
  routine_type,
  data_type
FROM information_schema.routines
WHERE routine_schema = 'public';

-- Ver código de function
\df+ function_name -- no psql
```

### Performance monitoring

```sql
-- Ver queries lentas
SELECT
  query,
  calls,
  mean_exec_time,
  max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Ver índices não usados
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0;
```

---

## 7. Exemplos completos

### Exemplo 1: Audit trail completo

```sql
-- 1. Criar tabela de audit
CREATE TABLE audit_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL,
  old_data JSONB,
  new_data JSONB,
  changed_by TEXT NOT NULL,
  changed_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- 2. Function genérica de audit
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    INSERT INTO audit_log (table_name, operation, old_data, changed_by)
    VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), current_user);
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO audit_log (table_name, operation, old_data, new_data, changed_by)
    VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW), current_user);
    RETURN NEW;
  ELSIF (TG_OP = 'INSERT') THEN
    INSERT INTO audit_log (table_name, operation, new_data, changed_by)
    VALUES (TG_TABLE_NAME, TG_OP, row_to_json(NEW), current_user);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. Aplicar trigger em tabelas específicas
CREATE TRIGGER audit_users
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW
  EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_orders
  AFTER INSERT OR UPDATE OR DELETE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION audit_trigger_func();

-- 4. Query audit logs
SELECT
  table_name,
  operation,
  new_data->>'email' as email,
  changed_by,
  changed_at
FROM audit_log
WHERE table_name = 'users'
  AND operation = 'UPDATE'
ORDER BY changed_at DESC
LIMIT 10;
```

### Exemplo 2: Soft delete com cascade

```sql
-- 1. Adicionar deleted_at nas tabelas (via Prisma)
-- Em schema.prisma:
-- deleted_at DateTime?

-- 2. Function para soft delete cascade
CREATE OR REPLACE FUNCTION cascade_soft_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Quando user é soft deleted
  IF NEW.deleted_at IS NOT NULL AND
     (OLD.deleted_at IS NULL OR OLD.deleted_at IS DISTINCT FROM NEW.deleted_at) THEN

    -- Soft delete related orders
    UPDATE orders
    SET deleted_at = NEW.deleted_at
    WHERE user_id = NEW.id
      AND deleted_at IS NULL;

    -- Soft delete related addresses
    UPDATE addresses
    SET deleted_at = NEW.deleted_at
    WHERE user_id = NEW.id
      AND deleted_at IS NULL;

    RAISE NOTICE 'Soft deleted related records for user %', NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger para aplicar cascade
CREATE TRIGGER soft_delete_user_cascade
  AFTER UPDATE OF deleted_at ON users
  FOR EACH ROW
  EXECUTE FUNCTION cascade_soft_delete();

-- 4. Uso no código (via Prisma)
-- await prisma.user.update({
--   where: { id: userId },
--   data: { deleted_at: new Date() }
-- });
-- ↑ Automaticamente soft delete orders e addresses
```

### Exemplo 3: Validation trigger

```sql
-- 1. Function para validar dados de conta bancária
CREATE OR REPLACE FUNCTION validate_bank_account()
RETURNS TRIGGER AS $$
BEGIN
  -- Validar formato da conta
  IF NEW.account !~ '^[0-9]{5,20}$' THEN
    RAISE EXCEPTION 'Número de conta inválido: %', NEW.account;
  END IF;

  -- Validar formato da agência
  IF NEW.branch !~ '^[0-9]{4}$' THEN
    RAISE EXCEPTION 'Número de agência inválido: %', NEW.branch;
  END IF;

  -- Validar documento
  IF NEW.document_type = 'CPF' THEN
    IF LENGTH(REGEXP_REPLACE(NEW.document_number, '[^0-9]', '', 'g')) != 11 THEN
      RAISE EXCEPTION 'CPF deve ter 11 dígitos';
    END IF;
  ELSIF NEW.document_type = 'CNPJ' THEN
    IF LENGTH(REGEXP_REPLACE(NEW.document_number, '[^0-9]', '', 'g')) != 14 THEN
      RAISE EXCEPTION 'CNPJ deve ter 14 dígitos';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Trigger
CREATE TRIGGER validate_bank_account_data
  BEFORE INSERT OR UPDATE ON bank_accounts
  FOR EACH ROW
  EXECUTE FUNCTION validate_bank_account();
```

### Exemplo 4: Calculated fields

```sql
-- 1. Function para calcular total do pedido
CREATE OR REPLACE FUNCTION calculate_order_total()
RETURNS TRIGGER AS $$
DECLARE
  items_total NUMERIC;
  tax_amount NUMERIC;
  discount_amount NUMERIC;
BEGIN
  -- Calcular soma dos items
  SELECT COALESCE(SUM(quantity * unit_price), 0)
  INTO items_total
  FROM order_items
  WHERE order_id = NEW.id;

  -- Calcular impostos (exemplo: 10%)
  tax_amount := items_total * 0.10;

  -- Aplicar desconto se houver
  discount_amount := COALESCE(NEW.discount_percentage, 0) * items_total / 100;

  -- Atualizar total do pedido
  NEW.subtotal := items_total;
  NEW.tax := tax_amount;
  NEW.discount := discount_amount;
  NEW.total := items_total + tax_amount - discount_amount;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Trigger quando order é criado/atualizado
CREATE TRIGGER calculate_order_totals
  BEFORE INSERT OR UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION calculate_order_total();

-- 3. Trigger quando items são modificados
CREATE OR REPLACE FUNCTION recalculate_order_on_items_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Forçar recalculo do order
  UPDATE orders
  SET updated_at = NOW()
  WHERE id = COALESCE(NEW.order_id, OLD.order_id);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER recalculate_order_items
  AFTER INSERT OR UPDATE OR DELETE ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION recalculate_order_on_items_change();
```

### Exemplo 5: Complex business logic function

```sql
-- Function para processar antecipação de recebível
CREATE OR REPLACE FUNCTION process_receivable_anticipation(
  p_receivable_id UUID,
  p_creditor_id UUID,
  p_discount_rate NUMERIC
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  anticipated_value NUMERIC,
  transaction_id UUID
) AS $$
DECLARE
  v_receivable RECORD;
  v_net_value NUMERIC;
  v_fee NUMERIC;
  v_transaction_id UUID;
BEGIN
  -- 1. Buscar receivable
  SELECT * INTO v_receivable
  FROM receivables
  WHERE id = p_receivable_id
    AND deleted_at IS NULL
  FOR UPDATE; -- Lock pessimista

  -- 2. Validações
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Recebível não encontrado', NULL::NUMERIC, NULL::UUID;
    RETURN;
  END IF;

  IF v_receivable.status != 'pending' THEN
    RETURN QUERY SELECT false, 'Recebível não está pendente', NULL::NUMERIC, NULL::UUID;
    RETURN;
  END IF;

  -- 3. Calcular valores
  v_fee := v_receivable.amount * p_discount_rate / 100;
  v_net_value := v_receivable.amount - v_fee;

  -- 4. Criar transação
  INSERT INTO transactions (
    type,
    receivable_id,
    creditor_id,
    gross_amount,
    fee_amount,
    net_amount,
    status
  ) VALUES (
    'anticipation',
    p_receivable_id,
    p_creditor_id,
    v_receivable.amount,
    v_fee,
    v_net_value,
    'completed'
  )
  RETURNING id INTO v_transaction_id;

  -- 5. Atualizar receivable
  UPDATE receivables
  SET
    status = 'anticipated',
    anticipated_at = NOW(),
    anticipated_by = p_creditor_id
  WHERE id = p_receivable_id;

  -- 6. Retornar sucesso
  RETURN QUERY SELECT true, 'Antecipação processada com sucesso', v_net_value, v_transaction_id;

EXCEPTION
  WHEN OTHERS THEN
    -- Rollback automático em caso de erro
    RETURN QUERY SELECT false, SQLERRM, NULL::NUMERIC, NULL::UUID;
END;
$$ LANGUAGE plpgsql;

-- Uso:
SELECT * FROM process_receivable_anticipation(
  'uuid-do-receivable',
  'uuid-do-creditor',
  2.5 -- taxa de desconto 2.5%
);
```

---

## 8. Checklists de tarefas comuns

### Adicionar audit trail a tabela

- Criar tabela `audit_log` (se não existe)
- Criar function `audit_trigger_func()`
- Criar trigger na tabela alvo
- Testar insert/update/delete
- Verificar logs gerados

### Implementar soft delete

- Adicionar `deleted_at DateTime?` no `schema.prisma`
- Migrar schema (`prisma migrate dev`)
- Criar function `cascade_soft_delete()`
- Criar triggers nas tabelas principais
- Atualizar queries para filtrar `deleted_at IS NULL`

### Otimizar query lenta

- Executar `EXPLAIN ANALYZE` na query
- Identificar Seq Scans
- Criar indexes apropriados
- Re-executar `EXPLAIN ANALYZE`
- Comparar performance (antes/depois)
- Monitorar em production

### Criar function de business logic

- Definir assinatura (params e return type)
- Implementar lógica em PL/pgSQL
- Adicionar error handling (`EXCEPTION`)
- Criar migration SQL
- Testar com dados reais
- Documentar uso

---

## 9. Troubleshooting

### Trigger não está sendo executado

```sql
-- Verificar se trigger existe
SELECT * FROM information_schema.triggers
WHERE event_object_table = 'table_name';

-- Verificar se function existe
\df+ function_name

-- Recriar trigger
DROP TRIGGER IF EXISTS trigger_name ON table_name;
CREATE TRIGGER trigger_name ...;
```

### Function retorna erro

```sql
-- Ver mensagens de erro detalhadas
\set VERBOSITY verbose

-- Testar function isoladamente
DO $$
BEGIN
  PERFORM function_name(params);
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error: %', SQLERRM;
END;
$$;
```

### Performance degradada após migration

```sql
-- Rebuild indexes
REINDEX TABLE table_name;

-- Atualizar statistics
ANALYZE table_name;

-- Verificar bloat
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Migration falhou

```bash
# Ver status das migrations
npx prisma migrate status

# Marcar migration como aplicada (use com cuidado!)
npx prisma migrate resolve --applied migration_name

# Reset database (desenvolvimento apenas!)
npx prisma migrate reset
```

---

## 🔗 Referências

- **Agente que cita esta KB**: `.claude/agents/development/postgres-specialist.md`
- **Docs oficiais PostgreSQL 17**: <https://www.postgresql.org/docs/17/>
- **Prisma Migrations**: <https://www.prisma.io/docs/orm/prisma-migrate>
- **KBs irmãs (shed-ceremony)**: [gamma-app-api.md](../platforms/gamma-app-api.md) · [presentation-orchestration.md](../patterns/presentation-orchestration.md)
