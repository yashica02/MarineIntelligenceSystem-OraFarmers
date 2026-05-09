-- =============================================================================
-- View   : VW_ECOLOGICAL_RISK_ZONES
-- Schema : SMART
-- Purpose: Master ecological risk scoring view. Combines wildlife, habitat,
--          water quality, microplastics, and vessel pressure into a single
--          normalized risk score (0-100) per habitat zone.
--
-- Risk Score Formula (weighted):
--   WILDLIFE_SCORE      x 0.35
--   HABITAT_SENSITIVITY x 0.20
--   MICROPLASTIC_SCORE  x 0.20
--   WATER_STRESS_SCORE  x 0.20
--   VESSEL_PRESSURE     x 0.05
--
-- Risk Classification:
--   < 33  = LOW
--   < 66  = MEDIUM
--   >= 66 = HIGH
--
-- Source Views:
--   VW_HABITAT_ZONES_CLEAN      (SMART)
--   OTTER.VW_ZONE_WILDLIFE_RISK (OTTER - cross-schema)
--   OTTER.VW_ZONE_WATER_STRESS  (OTTER - cross-schema)
-- =============================================================================

CREATE OR REPLACE VIEW SMART.VW_ECOLOGICAL_RISK_ZONES AS
WITH base AS (
    SELECT
        z.ZONE_ID,
        z.ZONE_NAME,
        z.HABITAT_TYPE,
        z.VESSEL_TRAFFIC_LEVEL,
        z.BOUNDARY_GEOM,
        NVL(wr.SPECIES_COUNT, 0)          AS SPECIES_COUNT,
        NVL(wr.PRIMARY_SPECIES_COUNT, 0)  AS PRIMARY_SPECIES_COUNT,
        NVL(wr.YEAR_ROUND_SPECIES, 0)     AS YEAR_ROUND_SPECIES,
        NVL(wr.TOTAL_SIGHTINGS, 0)        AS TOTAL_SIGHTINGS,
        NVL(wr.CONFIRMED_SIGHTINGS, 0)    AS CONFIRMED_SIGHTINGS,

        NVL(ws.TOTAL_READINGS, 0)         AS TOTAL_READINGS,
        NVL(ws.AVG_TEMP, 18)              AS AVG_TEMP,
        NVL(ws.AVG_DISSOLVED_OXYGEN, 5)   AS AVG_DISSOLVED_OXYGEN,
        NVL(ws.AVG_PH, 8.1)              AS AVG_PH,
        NVL(ws.AVG_TURBIDITY, 0)          AS AVG_TURBIDITY,
        NVL(ws.AVG_SALINITY, 35)          AS AVG_SALINITY,
        NVL(ws.TOTAL_MP_SAMPLES, 0)       AS TOTAL_MP_SAMPLES,
        NVL(ws.AVG_MICROPLASTICS_PER_M3, 0) AS AVG_MICROPLASTICS_PER_M3,
        (
            NVL(wr.TOTAL_SIGHTINGS, 0)     * 0.40 +
            NVL(wr.CONFIRMED_SIGHTINGS, 0) * 0.30 +
            NVL(wr.SPECIES_COUNT, 0)       * 0.30
        ) AS WILDLIFE_RAW,
        NVL(ws.AVG_MICROPLASTICS_PER_M3, 0) AS MICRO_RAW,
        (
            LEAST(1, ABS(NVL(ws.AVG_TEMP, 18) - 18) / 6)                           * 0.20 +
            LEAST(1, GREATEST(0, (5 - NVL(ws.AVG_DISSOLVED_OXYGEN, 5)) / 5))       * 0.35 +
            LEAST(1, ABS(NVL(ws.AVG_PH, 8.1) - 8.1) / 0.5)                       * 0.15 +
            LEAST(1, NVL(ws.AVG_TURBIDITY, 0) / 20)                                * 0.15 +
            LEAST(1, ABS(NVL(ws.AVG_SALINITY, 35) - 35) / 5)                      * 0.15
        ) AS WATER_STRESS_RAW_01,
        CASE
            WHEN UPPER(NVL(z.HABITAT_TYPE, 'UNKNOWN')) LIKE '%CORAL%'      THEN 1.00
            WHEN UPPER(NVL(z.HABITAT_TYPE, 'UNKNOWN')) LIKE '%SEAGRASS%'   THEN 0.90
            WHEN UPPER(NVL(z.HABITAT_TYPE, 'UNKNOWN')) LIKE '%MANGROVE%'   THEN 0.85
            WHEN UPPER(NVL(z.HABITAT_TYPE, 'UNKNOWN')) LIKE '%REEF%'       THEN 0.90
            WHEN UPPER(NVL(z.HABITAT_TYPE, 'UNKNOWN')) LIKE '%OPEN WATER%' THEN 0.40
            ELSE 0.60
        END AS HABITAT_SCORE_01,
        CASE
            WHEN UPPER(NVL(z.VESSEL_TRAFFIC_LEVEL, 'LOW')) = 'HIGH'   THEN 1.00
            WHEN UPPER(NVL(z.VESSEL_TRAFFIC_LEVEL, 'LOW')) = 'MEDIUM' THEN 0.60
            ELSE 0.20
        END AS VESSEL_SCORE_01

    FROM SMART.VW_HABITAT_ZONES_CLEAN z
    LEFT JOIN OTTER.VW_ZONE_WILDLIFE_RISK wr ON z.ZONE_ID = wr.ZONE_ID
    LEFT JOIN OTTER.VW_ZONE_WATER_STRESS  ws ON z.ZONE_ID = ws.ZONE_ID
),
bounds AS (
    SELECT
        MIN(WILDLIFE_RAW) AS MIN_WILDLIFE_RAW,
        MAX(WILDLIFE_RAW) AS MAX_WILDLIFE_RAW,
        MIN(MICRO_RAW)    AS MIN_MICRO_RAW,
        MAX(MICRO_RAW)    AS MAX_MICRO_RAW
    FROM base
),
normalized AS (
    SELECT
        b.*,
        CASE
            WHEN bd.MAX_WILDLIFE_RAW = bd.MIN_WILDLIFE_RAW THEN 0
            ELSE GREATEST(0, LEAST(1,
                (b.WILDLIFE_RAW - bd.MIN_WILDLIFE_RAW) /
                NULLIF(bd.MAX_WILDLIFE_RAW - bd.MIN_WILDLIFE_RAW, 0)
            ))
        END AS WILDLIFE_SCORE_01,
        CASE
            WHEN bd.MAX_MICRO_RAW = bd.MIN_MICRO_RAW THEN 0
            ELSE GREATEST(0, LEAST(1,
                (b.MICRO_RAW - bd.MIN_MICRO_RAW) /
                NULLIF(bd.MAX_MICRO_RAW - bd.MIN_MICRO_RAW, 0)
            ))
        END AS MICRO_SCORE_01,
        GREATEST(0, LEAST(1, b.WATER_STRESS_RAW_01)) AS WATER_SCORE_01
    FROM base b
    CROSS JOIN bounds bd
)
SELECT
    ZONE_ID,
    ZONE_NAME,
    HABITAT_TYPE,
    BOUNDARY_GEOM,
    SPECIES_COUNT,
    PRIMARY_SPECIES_COUNT,
    YEAR_ROUND_SPECIES,
    TOTAL_SIGHTINGS,
    CONFIRMED_SIGHTINGS,
    TOTAL_READINGS,
    AVG_TEMP,
    AVG_DISSOLVED_OXYGEN,
    AVG_PH,
    AVG_TURBIDITY,
    AVG_SALINITY,
    TOTAL_MP_SAMPLES,
    AVG_MICROPLASTICS_PER_M3,
    ROUND(WILDLIFE_SCORE_01  * 100, 2) AS WILDLIFE_SCORE,
    ROUND(HABITAT_SCORE_01   * 100, 2) AS HABITAT_SENSITIVITY_SCORE,
    ROUND(MICRO_SCORE_01     * 100, 2) AS MICROPLASTIC_SCORE,
    ROUND(WATER_SCORE_01     * 100, 2) AS WATER_STRESS_SCORE,
    ROUND(VESSEL_SCORE_01    * 100, 2) AS VESSEL_PRESSURE_SCORE,
    ROUND((
        WILDLIFE_SCORE_01 * 0.35 +
        HABITAT_SCORE_01  * 0.20 +
        MICRO_SCORE_01    * 0.20 +
        WATER_SCORE_01    * 0.20 +
        VESSEL_SCORE_01   * 0.05
    ) * 100, 2) AS RISK_SCORE,
    CASE
        WHEN (WILDLIFE_SCORE_01 * 0.35 + HABITAT_SCORE_01 * 0.20 +
              MICRO_SCORE_01 * 0.20 + WATER_SCORE_01 * 0.20 +
              VESSEL_SCORE_01 * 0.05) * 100 < 33 THEN 'LOW'
        WHEN (WILDLIFE_SCORE_01 * 0.35 + HABITAT_SCORE_01 * 0.20 +
              MICRO_SCORE_01 * 0.20 + WATER_SCORE_01 * 0.20 +
              VESSEL_SCORE_01 * 0.05) * 100 < 66 THEN 'MEDIUM'
        ELSE 'HIGH'
    END AS RISK_CLASS
FROM normalized;
