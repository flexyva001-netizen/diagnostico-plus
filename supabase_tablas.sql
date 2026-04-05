-- ══════════════════════════════════════════════════════════════
--  FlexyStudio · Diagnóstico+ — Tablas Supabase
--  Ejecutar en: Supabase > SQL Editor > New Query
--  Este script limpia y recrea todo desde cero
-- ══════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS diagnostico_respuestas CASCADE;
DROP TABLE IF EXISTS log_actividad          CASCADE;
DROP TABLE IF EXISTS diagnosticos           CASCADE;
DROP TABLE IF EXISTS leads                  CASCADE;

-- ══════════════════════════════════════════════════════════════
--  1. LEADS — Registro del formulario inicial
-- ══════════════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════════════
--  2. DIAGNOSTICOS — Cabecera + JSON completo del diagnóstico
-- ══════════════════════════════════════════════════════════════
CREATE TABLE diagnosticos (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id         UUID        REFERENCES leads(id) ON DELETE SET NULL,
  nombre          TEXT,
  email           TEXT,
  empresa         TEXT,
  sector          TEXT,
  respuestas      JSONB       NOT NULL,
  total_preguntas INT         DEFAULT 34,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════
--  3. DIAGNOSTICO_RESPUESTAS — Una fila por diagnóstico
--     Cada columna = una pregunta del cuestionario
-- ══════════════════════════════════════════════════════════════
CREATE TABLE diagnostico_respuestas (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  diagnostico_id      UUID        REFERENCES diagnosticos(id) ON DELETE CASCADE,
  lead_id             UUID        REFERENCES leads(id) ON DELETE SET NULL,

  -- Datos de identificación (desnormalizados para consulta rápida)
  nombre              TEXT,
  email               TEXT,
  empresa             TEXT,
  sector              TEXT,

  -- ── SECCIÓN 1: Tu Empresa ───────────────────────────────────
  historia_origen     TEXT,   -- Q01 ¿Cómo nació tu empresa?
  mision              TEXT,   -- Q02 ¿Cuál es la misión?
  vision              TEXT,   -- Q03 ¿Cuál es la visión?
  valores             TEXT,   -- Q04 ¿Cuáles son los valores?
  publico_objetivo    TEXT,   -- Q05 ¿A qué público se dirige?
  eslogan             TEXT,   -- Q06 ¿Qué frase o eslogan representa tu marca?

  -- ── SECCIÓN 2: Situación Actual ────────────────────────────
  anos_operando       TEXT,   -- Q07 ¿Cuántos años lleva operando?
  cantidad_empleados  TEXT,   -- Q08 ¿Cuántas personas trabajan?
  ubicacion_operacion TEXT,   -- Q09 ¿Dónde opera principalmente?
  mayor_reto          TEXT,   -- Q10 ¿Cuál es el mayor reto hoy?
  objetivos_12_meses  TEXT,   -- Q11 ¿Cuáles son los 3 objetivos próximos 12 meses?
  area_mejora         TEXT,   -- Q12 ¿En qué área hay mayor oportunidad de mejora?
  urgencia            TEXT,   -- Q13 ¿Cuán urgente es resolver este problema?

  -- ── SECCIÓN 3: Ventas y Marketing ──────────────────────────
  adquisicion_clientes  TEXT, -- Q14 ¿Cómo adquieres la mayoría de tus clientes?
  clientes_nuevos_mes   TEXT, -- Q15 ¿Cuántos clientes nuevos por mes?
  rango_ingresos        TEXT, -- Q16 ¿Rango de ingresos mensuales?
  proceso_ventas        TEXT, -- Q17 ¿Tienes proceso de ventas documentado?
  frecuencia_publicacion TEXT, -- Q18 ¿Con qué frecuencia publicas contenido?
  presupuesto_marketing  TEXT, -- Q19 ¿Tienes presupuesto asignado para marketing?

  -- ── SECCIÓN 4: Branding e Identidad Visual ─────────────────
  identidad_visual    TEXT,   -- Q20 ¿Tienes identidad visual definida?
  colores_marca       TEXT,   -- Q21 ¿Cuáles son los colores de tu marca?
  tipografias         TEXT,   -- Q22 ¿Qué tipografías utiliza tu marca?
  tiene_logo          TEXT,   -- Q23 ¿Tienes logo actualmente?
  sensaciones_marca   TEXT,   -- Q24 ¿Qué sensaciones quieres transmitir visualmente?
  marcas_referencia   TEXT,   -- Q25 ¿Hay marcas cuyo estilo te inspire?
  materiales_marketing TEXT,  -- Q26 ¿Tienes materiales de marketing actuales?
  tono_comunicacion   TEXT,   -- Q27 ¿Palabras que describen tu tono de comunicación?

  -- ── SECCIÓN 5: Presencia Digital y Tecnología ──────────────
  redes_sociales        JSONB, -- Grilla de perfiles en redes sociales (objeto)
  plataforma_resultados TEXT,  -- Q28 ¿En cuál plataforma obtienes mejores resultados?
  red_social_crecer     TEXT,  -- Q29 ¿Red social en la que quieras crecer?
  nivel_digitalizacion  TEXT,  -- Q30 ¿Nivel de digitalización de operaciones?
  procesos_automatizar  TEXT,  -- Q31 ¿Procesos que podrían automatizarse?

  -- ── SECCIÓN 6: Visión y Colaboración ───────────────────────
  vision_3_anos         TEXT,  -- Q32 ¿Cómo visualizas tu negocio en 3 años?
  tipo_apoyo_buscado    TEXT,  -- Q33 ¿Qué tipo de apoyo externo estás buscando?
  informacion_adicional TEXT,  -- Q34 ¿Algo más importante que compartir?

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════
--  4. LOG_ACTIVIDAD — Auditoría completa
-- ══════════════════════════════════════════════════════════════
CREATE TABLE log_actividad (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo          TEXT        NOT NULL,
  referencia_id UUID,
  datos         JSONB       NOT NULL,
  user_agent    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════
--  PERMISOS RLS
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

CREATE POLICY "anon_insert_leads"        ON leads                  FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_select_leads"        ON leads                  FOR SELECT TO anon USING (true);
CREATE POLICY "anon_insert_diagnosticos" ON diagnosticos           FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_select_diagnosticos" ON diagnosticos           FOR SELECT TO anon USING (true);
CREATE POLICY "anon_insert_respuestas"   ON diagnostico_respuestas FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_select_respuestas"   ON diagnostico_respuestas FOR SELECT TO anon USING (true);
CREATE POLICY "anon_insert_log"          ON log_actividad          FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_select_log"          ON log_actividad          FOR SELECT TO anon USING (true);

CREATE POLICY "auth_all_leads"           ON leads                  FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all_diagnosticos"    ON diagnosticos           FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all_respuestas"      ON diagnostico_respuestas FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all_log"             ON log_actividad          FOR ALL TO authenticated USING (true);

-- ══════════════════════════════════════════════════════════════
--  ÍNDICES
-- ══════════════════════════════════════════════════════════════
CREATE INDEX idx_leads_email       ON leads(email);
CREATE INDEX idx_leads_created     ON leads(created_at DESC);
CREATE INDEX idx_diag_lead         ON diagnosticos(lead_id);
CREATE INDEX idx_diag_email        ON diagnosticos(email);
CREATE INDEX idx_diag_created      ON diagnosticos(created_at DESC);
CREATE INDEX idx_resp_diagnostico  ON diagnostico_respuestas(diagnostico_id);
CREATE INDEX idx_resp_lead         ON diagnostico_respuestas(lead_id);
CREATE INDEX idx_resp_email        ON diagnostico_respuestas(email);
CREATE INDEX idx_resp_created      ON diagnostico_respuestas(created_at DESC);
CREATE INDEX idx_log_tipo          ON log_actividad(tipo);
CREATE INDEX idx_log_created       ON log_actividad(created_at DESC);

-- ══════════════════════════════════════════════════════════════
--  VERIFICACIÓN
-- ══════════════════════════════════════════════════════════════
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('leads','diagnosticos','diagnostico_respuestas','log_actividad')
ORDER BY table_name;
