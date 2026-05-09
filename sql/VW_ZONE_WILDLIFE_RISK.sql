-- =============================================================================
-- View   : VW_ZONE_WILDLIFE_RISK
-- Schema : OTTER
-- Purpose: Aggregates marine wildlife sightings and species habitat data
--          per habitat zone. Provides biodiversity metrics used as inputs
--          to the ecological risk score.
--
-- Access: GRANT SELECT ON OTTER.VW_ZONE_WILDLIFE_RISK TO SMART;
-- =============================================================================

CREATE OR REPLACE VIEW OTTER.VW_ZONE_WILDLIFE_RISK AS
SELECT
    hz.ZONE_ID,
    hz.ZONE_NAME,
    hz.HABITAT_TYPE,
    COUNT(DISTINCT shm.SPECIES_ID)                                          AS SPECIES_COUNT,
    SUM(CASE WHEN shm.PREFERENCE_RANK = 1 THEN 1 ELSE 0 END)               AS PRIMARY_SPECIES_COUNT,
    SUM(CASE WHEN shm.SEASONAL_PRESENCE = 'year_round' THEN 1 ELSE 0 END)  AS YEAR_ROUND_SPECIES,
    COUNT(DISTINCT w.SIGHTING_ID)                                           AS TOTAL_SIGHTINGS,
    SUM(CASE WHEN w.CONFIDENCE_LEVEL = 'confirmed' THEN 1 ELSE 0 END)      AS CONFIRMED_SIGHTINGS
FROM OTTER.HABITAT_ZONES hz
LEFT JOIN OTTER.SPECIES_HABITAT_MAP shm
    ON shm.ZONE_ID = hz.ZONE_ID
LEFT JOIN OTTER.MARINE_WILDLIFE_SIGHTINGS w
    ON  w.SPECIES_ID = shm.SPECIES_ID
    AND w.LATITUDE   BETWEEN 37.0 AND 38.5
    AND w.LONGITUDE  BETWEEN -123.5 AND -121.5
    AND REGEXP_LIKE(w.SPECIES_ID, '^SP-')
GROUP BY
    hz.ZONE_ID,
    hz.ZONE_NAME,
    hz.HABITAT_TYPE,
    hz.AVG_DEPTH_M;

-- Grant cross-schema access to SMART
GRANT SELECT ON OTTER.VW_ZONE_WILDLIFE_RISK TO SMART;
