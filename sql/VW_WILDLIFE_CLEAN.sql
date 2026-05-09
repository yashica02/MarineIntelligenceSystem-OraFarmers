-- =============================================================================
-- View   : VW_WILDLIFE_CLEAN
-- Schema : SMART
-- Purpose: Cleans and normalizes OTTER.MARINE_WILDLIFE_SIGHTINGS.
--          Handles 6 different timestamp formats found in the raw data
--          and standardizes them to a single TIMESTAMP type.
-- =============================================================================

CREATE OR REPLACE VIEW SMART.VW_WILDLIFE_CLEAN AS
SELECT
    SIGHTING_ID,
    SPECIES_ID,
    CASE
        WHEN REGEXP_LIKE(TRIM(SIGHTING_TIMESTAMP), '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$')
            THEN TO_TIMESTAMP(TRIM(SIGHTING_TIMESTAMP), 'YYYY-MM-DD HH24:MI:SS')
        WHEN REGEXP_LIKE(TRIM(SIGHTING_TIMESTAMP), '^\d{4}-\d{2}-\d{2}$')
            THEN TO_TIMESTAMP(TRIM(SIGHTING_TIMESTAMP) || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
        WHEN REGEXP_LIKE(TRIM(SIGHTING_TIMESTAMP), '^\d{2}/\d{2}/\d{4}, \d{2}:\d{2}:\d{2} (AM|PM)$')
            THEN TO_TIMESTAMP(TRIM(SIGHTING_TIMESTAMP), 'MM/DD/YYYY, HH:MI:SS AM')
        WHEN REGEXP_LIKE(TRIM(SIGHTING_TIMESTAMP), '^\d{2}/\d{2}/\d{4} \d{2}:\d{2} (AM|PM)$')
            THEN TO_TIMESTAMP(TRIM(SIGHTING_TIMESTAMP), 'MM/DD/YYYY HH:MI AM')
        WHEN REGEXP_LIKE(TRIM(SIGHTING_TIMESTAMP), '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}$')
            THEN TO_TIMESTAMP(TRIM(SIGHTING_TIMESTAMP), 'MM/DD/YYYY HH24:MI')
        WHEN REGEXP_LIKE(TRIM(SIGHTING_TIMESTAMP), '^\d{2}-[A-Za-z]{3}-\d{4}$')
            THEN CAST(TO_DATE(TRIM(SIGHTING_TIMESTAMP), 'DD-MON-YYYY') AS TIMESTAMP)
        ELSE NULL
    END AS SIGHTING_TIMESTAMP,
    LATITUDE,
    LONGITUDE,
    GROUP_SIZE,
    BEHAVIOR,
    OBSERVATION_METHOD,
    OBSERVER_NAME,
    WEATHER_CONDITION,
    SEA_STATE,
    CONFIDENCE_LEVEL,
    DISTANCE_FROM_SHORE_KM,
    WATER_DEPTH_M,
    NOTES,
    LOCATION_GEOM

FROM OTTER.MARINE_WILDLIFE_SIGHTINGS;
