-- ══════════════════════════════════════════════════════════════
--  FlexyStudio · Diagnóstico+ — Tablas Supabase
--  Ejecutar en: Supabase > SQL Editor > New Query
--  Este script limpia y recrea todo desde cero
-- ══════════════════════════════════════════════════════════════

-- ─── Limpiar tablas existentes ────────────────────────────────
DROP TABLE IF EXISTS diagnostico_respuestas CASCADE;
DROP TABLE IF EXISTS log_actividad          CASCADE;
DROP TABLE IF EXISTS diagnosticos           CASCADE;
DROP TABLE IF EXISTS leads                  CASCADE;

-- ══════════════════════════════════════════════════════════════
--  TABLAS
-- ══════════════════════════════════════════════════════════════

-- ─── 1. LEADS — Registro inicial del formulario ────────────────
CREATE TABLE leads (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre     TEXT        NOT NULL,
  apellido   TEXT,
  email      TEXT        NOT NULL,
  empresa    TEXT        NOT NULL,
  sector     TEXT,
  reto       TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 2. DIAGNOSTICOS — Cabecera del diagnóstico completo ───────
--   Guarda el JSON completo + datos del cliente para acceso rápido
CREATE TABLE diagnosticos (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id         UUID        REFERENCES leads(id) ON DELETE SET NULL,
  nombre          TEXT,
  email           TEXT,
  empresa         TEXT,
  sector          TEXT,
  respuestas      JSONB       NOT NULL,   -- JSON completo con todas las respuestas
  total_preguntas INT         DEFAULT 34,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 3. DIAGNOSTICO_RESPUESTAS — Respuestas individuales ───────
--   Una fila por cada pregunta respondida
CREATE TABLE diagnostico_respuestas (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diagnostico_id  UUID        REFERENCES diagnosticos(id) ON DELETE CASCADE,
  lead_id         UUID        REFERENCES leads(id) ON DELETE SET NULL,
  seccion_num     INT         NOT NULL,       -- número de sección (1–6)
  seccion_nombre  TEXT,                       -- ej: "Tu Empresa"
  pregunta_num    TEXT,                       -- ej: "1", "2", "R" (redes)
  pregunta_texto  TEXT,                       -- texto completo de la pregunta
  tipo_respuesta  TEXT,                       -- 'texto' | 'opcion_unica' | 'opcion_multiple' | 'objeto'
  respuesta_texto TEXT,                       -- valor si la respuesta es un string simple
  respuesta_json  JSONB,                      -- valor si la respuesta es array u objeto
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 4. LOG_ACTIVIDAD — Auditoría completa en JSON ─────────────
CREATE TABLE log_actividad (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo          TEXT        NOT NULL,     -- 'lead_registrado' | 'diagnostico_enviado'
  referencia_id UUID,
  datos         JSONB       NOT NULL,
  user_agent    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════
--  PERMISOS — RLS + GRANT para rol anon (browser)
-- ══════════════════════════════════════════════════════════════

ALTER TABLE leads                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE diagnosticos           ENABLE ROW LEVEL SECURITY;
ALTER TABLE diagnostico_respuestas ENABLE ROW LEVEL SECURITY;
ALTER TABLE log_actividad          ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO anon;

GRANT INSERT, SELECT ON leads                  TO anon;
GRANT INSERT, SELECT ON diagnosticos           TO anon;
GRANT INSERT, SELECT ON diagnostico_respuestas TO anon;
GRANT INSERT, SELECT ON log_actividad          TO anon;

-- Políticas anon
CREATE POLICY "anon_insert_leads"         ON leads                  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_select_leads"         ON leads                  FOR SELECT TO anon USING (true);
CREATE POLICY "anon_insert_diagnosticos"  ON diagnosticos           FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_select_diagnosticos"  ON diagnosticos           FOR SELECT TO anon USING (true);
CREATE POLICY "anon_insert_respuestas"    ON diagnostico_respuestas FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_select_respuestas"    ON diagnostico_respuestas FOR SELECT TO anon USING (true);
CREATE POLICY "anon_insert_log"           ON log_actividad          FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_select_log"           ON log_actividad          FOR SELECT TO anon USING (true);

-- Políticas autenticado (dashboard Supabase)
CREATE POLICY "auth_all_leads"         ON leads                  FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all_diagnosticos"  ON diagnosticos           FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all_respuestas"    ON diagnostico_respuestas FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all_log"           ON log_actividad          FOR ALL TO authenticated USING (true);

-- ══════════════════════════════════════════════════════════════
--  ÍNDICES
-- ══════════════════════════════════════════════════════════════
CREATE INDEX idx_leads_email          ON leads(email);
CREATE INDEX idx_leads_created        ON leads(created_at DESC);
CREATE INDEX idx_diag_lead            ON diagnosticos(lead_id);
CREATE INDEX idx_diag_email           ON diagnosticos(email);
CREATE INDEX idx_diag_created         ON diagnosticos(created_at DESC);
CREATE INDEX idx_resp_diagnostico     ON diagnostico_respuestas(diagnostico_id);
CREATE INDEX idx_resp_lead            ON diagnostico_respuestas(lead_id);
CREATE INDEX idx_resp_seccion         ON diagnostico_respuestas(seccion_num);
CREATE INDEX idx_log_tipo             ON log_actividad(tipo);
CREATE INDEX idx_log_created          ON log_actividad(created_at DESC);

-- ══════════════════════════════════════════════════════════════
--  VERIFICACIÓN FINAL
-- ══════════════════════════════════════════════════════════════
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('leads','diagnosticos','diagnostico_respuestas','log_actividad')
ORDER BY table_name;
