-- =============================================================================
-- View   : VW_ZONE_WATER_STRESS
-- Schema : OTTER
-- Purpose: Aggregates water quality readings and microplastics sampling
--          data per habitat zone via monitoring stations. Provides
--          environmental stress metrics used as inputs to the ecological
--          risk score.
--
-- Access: GRANT SELECT ON OTTER.VW_ZONE_WATER_STRESS TO SMART;
-- =============================================================================

CREATE OR REPLACE VIEW OTTER.VW_ZONE_WATER_STRESS AS
SELECT
    hz.ZONE_ID,
    hz.ZONE_NAME,
    COUNT(DISTINCT wq.READING_ID)                                           AS TOTAL_READINGS,
    ROUND(AVG(
        CASE WHEN wq.WATER_TEMP_CELSIUS BETWEEN 0 AND 40
             THEN wq.WATER_TEMP_CELSIUS END), 2)                            AS AVG_TEMP,
    ROUND(AVG(
        CASE WHEN wq.DISSOLVED_OXYGEN_MG_L BETWEEN 0 AND 20
             THEN wq.DISSOLVED_OXYGEN_MG_L END), 2)                         AS AVG_DISSOLVED_OXYGEN,
    ROUND(AVG(
        CASE WHEN wq.PH BETWEEN 6 AND 9.5
             THEN wq.PH END), 2)                                            AS AVG_PH,
    ROUND(AVG(
        CASE WHEN wq.TURBIDITY_NTU BETWEEN 0 AND 500
             THEN wq.TURBIDITY_NTU END), 2)                                 AS AVG_TURBIDITY,
    ROUND(AVG(
        CASE WHEN wq.SALINITY_PSU BETWEEN 0 AND 45
             THEN wq.SALINITY_PSU END), 2)                                  AS AVG_SALINITY,
    COUNT(DISTINCT mp.SAMPLE_ID)                                            AS TOTAL_MP_SAMPLES,
    ROUND(AVG(
        CASE WHEN mp.COUNT_PER_M3 >= 0
             THEN mp.COUNT_PER_M3 END), 2)                                  AS AVG_MICROPLASTICS_PER_M3

FROM OTTER.HABITAT_ZONES hz
LEFT JOIN OTTER.MONITORING_STATIONS ms
    ON  ms.ZONE   = hz.ZONE_NAME
    AND ms.STATUS = 'active'
LEFT JOIN OTTER.WATER_QUALITY_READINGS wq
    ON  UPPER(REGEXP_REPLACE(wq.STATION_ID, '[^A-Z0-9]', '')) =
        UPPER(REGEXP_REPLACE(ms.STATION_ID, '[^A-Z0-9]', ''))
    AND wq.DATA_QUALITY_FLAG = 'PASS'
LEFT JOIN OTTER.MICROPLASTICS_SAMPLING mp
    ON  UPPER(REGEXP_REPLACE(mp.STATION_ID, '[^A-Z0-9]', '')) =
        UPPER(REGEXP_REPLACE(ms.STATION_ID, '[^A-Z0-9]', ''))
    AND mp.COUNT_PER_M3 IS NOT NULL
    AND mp.COUNT_PER_M3 >= 0
GROUP BY
    hz.ZONE_ID,
    hz.ZONE_NAME;

-- Grant cross-schema access to SMART
GRANT SELECT ON OTTER.VW_ZONE_WATER_STRESS TO SMART;
