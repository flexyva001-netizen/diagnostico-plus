-- ══════════════════════════════════════════════════════════════
--  FlexyStudio · Diagnóstico+ — Tablas Supabase
--  Ejecutar en: Supabase > SQL Editor > New Query
-- ══════════════════════════════════════════════════════════════

-- ─── 1. LEADS — Registros del formulario inicial ───────────────
CREATE TABLE IF NOT EXISTS leads (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre       TEXT NOT NULL,
  apellido     TEXT NOT NULL,
  email        TEXT NOT NULL,
  empresa      TEXT NOT NULL,
  sector       TEXT,
  reto         TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 2. DIAGNOSTICOS — Respuestas completas del cuestionario ───
CREATE TABLE IF NOT EXISTS diagnosticos (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id      UUID REFERENCES leads(id) ON DELETE SET NULL,
  nombre       TEXT,
  email        TEXT,
  empresa      TEXT,
  sector       TEXT,
  respuestas   JSONB NOT NULL,        -- todas las respuestas en JSON
  total_preguntas INT DEFAULT 34,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 3. LOG_ACTIVIDAD — Auditoría completa en JSON ─────────────
CREATE TABLE IF NOT EXISTS log_actividad (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo         TEXT NOT NULL,         -- 'lead_registrado' | 'diagnostico_enviado'
  referencia_id UUID,                 -- ID del lead o diagnóstico relacionado
  datos        JSONB NOT NULL,        -- payload completo en JSON
  ip_origin    TEXT,
  user_agent   TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════
--  ROW LEVEL SECURITY (RLS) — Permite escritura pública anónima
-- ══════════════════════════════════════════════════════════════

ALTER TABLE leads         ENABLE ROW LEVEL SECURITY;
ALTER TABLE diagnosticos  ENABLE ROW LEVEL SECURITY;
ALTER TABLE log_actividad ENABLE ROW LEVEL SECURITY;

-- Solo INSERT permitido desde el browser (anon key)
CREATE POLICY "insert_leads"
  ON leads FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "insert_diagnosticos"
  ON diagnosticos FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "insert_log"
  ON log_actividad FOR INSERT TO anon WITH CHECK (true);

-- SELECT solo desde el dashboard de Supabase (authenticated)
CREATE POLICY "select_leads"
  ON leads FOR SELECT TO authenticated USING (true);

CREATE POLICY "select_diagnosticos"
  ON diagnosticos FOR SELECT TO authenticated USING (true);

CREATE POLICY "select_log"
  ON log_actividad FOR SELECT TO authenticated USING (true);

-- ══════════════════════════════════════════════════════════════
--  ÍNDICES útiles para búsquedas en el dashboard
-- ══════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_leads_email       ON leads(email);
CREATE INDEX IF NOT EXISTS idx_leads_created     ON leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_diag_lead_id      ON diagnosticos(lead_id);
CREATE INDEX IF NOT EXISTS idx_diag_email        ON diagnosticos(email);
CREATE INDEX IF NOT EXISTS idx_diag_created      ON diagnosticos(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_log_tipo          ON log_actividad(tipo);
CREATE INDEX IF NOT EXISTS idx_log_created       ON log_actividad(created_at DESC);

-- ══════════════════════════════════════════════════════════════
--  VERIFICACIÓN FINAL
-- ══════════════════════════════════════════════════════════════
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('leads','diagnosticos','log_actividad');
