-- ══════════════════════════════════════════════════════════════
--  FlexyStudio · Diagnóstico+ — Tablas Supabase
--  Ejecutar en: Supabase > SQL Editor > New Query
--  Si las tablas ya existen, este script las recrea limpiamente
-- ══════════════════════════════════════════════════════════════

-- ─── Limpiar si ya existen ────────────────────────────────────
DROP TABLE IF EXISTS log_actividad CASCADE;
DROP TABLE IF EXISTS diagnosticos   CASCADE;
DROP TABLE IF EXISTS leads          CASCADE;

-- ─── 1. LEADS — Registros del formulario inicial ───────────────
CREATE TABLE leads (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre     TEXT NOT NULL,
  apellido   TEXT,
  email      TEXT NOT NULL,
  empresa    TEXT NOT NULL,
  sector     TEXT,
  reto       TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 2. DIAGNOSTICOS — Respuestas completas del cuestionario ───
CREATE TABLE diagnosticos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id         UUID REFERENCES leads(id) ON DELETE SET NULL,
  nombre          TEXT,
  email           TEXT,
  empresa         TEXT,
  sector          TEXT,
  respuestas      JSONB NOT NULL,
  total_preguntas INT DEFAULT 34,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 3. LOG_ACTIVIDAD — Auditoría completa en JSON ─────────────
CREATE TABLE log_actividad (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo          TEXT NOT NULL,
  referencia_id UUID,
  datos         JSONB NOT NULL,
  user_agent    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════
--  PERMISOS — Acceso completo al rol anon (browser)
-- ══════════════════════════════════════════════════════════════

-- Habilitar RLS
ALTER TABLE leads         ENABLE ROW LEVEL SECURITY;
ALTER TABLE diagnosticos  ENABLE ROW LEVEL SECURITY;
ALTER TABLE log_actividad ENABLE ROW LEVEL SECURITY;

-- Dar permisos de uso al schema público
GRANT USAGE ON SCHEMA public TO anon;

-- LEADS: anon puede INSERT y SELECT
GRANT INSERT, SELECT ON leads         TO anon;
GRANT INSERT, SELECT ON diagnosticos  TO anon;
GRANT INSERT, SELECT ON log_actividad TO anon;

-- Políticas RLS — anon puede insertar y ver sus propios registros
CREATE POLICY "anon_insert_leads"
  ON leads FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon_select_leads"
  ON leads FOR SELECT TO anon USING (true);

CREATE POLICY "anon_insert_diagnosticos"
  ON diagnosticos FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon_select_diagnosticos"
  ON diagnosticos FOR SELECT TO anon USING (true);

CREATE POLICY "anon_insert_log"
  ON log_actividad FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon_select_log"
  ON log_actividad FOR SELECT TO anon USING (true);

-- Usuarios autenticados (dashboard) ven todo
CREATE POLICY "auth_all_leads"
  ON leads FOR ALL TO authenticated USING (true);

CREATE POLICY "auth_all_diagnosticos"
  ON diagnosticos FOR ALL TO authenticated USING (true);

CREATE POLICY "auth_all_log"
  ON log_actividad FOR ALL TO authenticated USING (true);

-- ══════════════════════════════════════════════════════════════
--  ÍNDICES
-- ══════════════════════════════════════════════════════════════
CREATE INDEX idx_leads_email      ON leads(email);
CREATE INDEX idx_leads_created    ON leads(created_at DESC);
CREATE INDEX idx_diag_lead_id     ON diagnosticos(lead_id);
CREATE INDEX idx_diag_email       ON diagnosticos(email);
CREATE INDEX idx_diag_created     ON diagnosticos(created_at DESC);
CREATE INDEX idx_log_tipo         ON log_actividad(tipo);
CREATE INDEX idx_log_created      ON log_actividad(created_at DESC);

-- ══════════════════════════════════════════════════════════════
--  VERIFICACIÓN
-- ══════════════════════════════════════════════════════════════
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('leads','diagnosticos','log_actividad')
ORDER BY table_name;
