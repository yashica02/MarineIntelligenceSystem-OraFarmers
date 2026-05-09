-- =============================================================================
-- View   : VW_VESSEL_ENRICHED
-- Schema : SMART
-- Purpose: Joins VESSEL_TRAFFIC with VESSELS registry to produce a clean,
--          enriched vessel dataset with a computed IMPACT_WEIGHT score.
-- =============================================================================

CREATE OR REPLACE VIEW SMART.VW_VESSEL_ENRICHED AS
SELECT
    vt.TRANSIT_ID,

    -- Clean timestamp from VARCHAR
    CASE
        WHEN REGEXP_LIKE(vt.TIMESTAMP_VAL, '^\d{4}-\d{2}-\d{2}')
            THEN TO_TIMESTAMP(SUBSTR(vt.TIMESTAMP_VAL,1,19), 'YYYY-MM-DD HH24:MI:SS')
        ELSE NULL
    END AS TS_CLEAN,
    EXTRACT(YEAR FROM
        CASE WHEN REGEXP_LIKE(vt.TIMESTAMP_VAL, '^\d{4}-\d{2}-\d{2}')
            THEN TO_TIMESTAMP(SUBSTR(vt.TIMESTAMP_VAL,1,19), 'YYYY-MM-DD HH24:MI:SS')
        END
    ) AS TRAFFIC_YEAR,
    vt.MMSI,
    COALESCE(v.VESSEL_NAME, vt.VESSEL_NAME)                     AS VESSEL_NAME,
    UPPER(TRIM(COALESCE(v.VESSEL_TYPE, vt.VESSEL_TYPE)))        AS VESSEL_TYPE,
    v.FLAG,
    v.LENGTH_M,
    CASE WHEN vt.SPEED_KNOTS BETWEEN 0 AND 40
        THEN vt.SPEED_KNOTS END                                  AS SPEED_KNOTS,
    CASE WHEN vt.HEADING_DEG BETWEEN 0 AND 360
        THEN vt.HEADING_DEG END                                  AS HEADING_DEG,
    vt.DRAFT_M,
    vt.LATITUDE,
    vt.LONGITUDE,
    CASE
        WHEN vt.SPEED_KNOTS < 5   THEN 1
        WHEN vt.SPEED_KNOTS < 10  THEN 2
        WHEN vt.SPEED_KNOTS < 15  THEN 3
        WHEN vt.SPEED_KNOTS < 20  THEN 4
        WHEN vt.SPEED_KNOTS <= 40 THEN 5
        ELSE NULL
    END
    *
    CASE
        WHEN v.LENGTH_M < 20  THEN 1
        WHEN v.LENGTH_M < 50  THEN 2
        WHEN v.LENGTH_M < 100 THEN 3
        WHEN v.LENGTH_M < 200 THEN 4
        ELSE 5
    END                                                          AS IMPACT_WEIGHT

FROM SMART.VESSEL_TRAFFIC vt
LEFT JOIN SMART.VESSELS v
    ON v.MMSI = vt.MMSI
WHERE vt.LATITUDE  BETWEEN 37.0 AND 38.5
  AND vt.LONGITUDE BETWEEN -123.5 AND -121.5;
