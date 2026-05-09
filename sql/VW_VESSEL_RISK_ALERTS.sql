-- =============================================================================
-- View   : VW_VESSEL_RISK_ALERTS
-- Schema : SMART
-- Purpose: Spatially joins live vessel positions (VW_VESSEL_ENRICHED) to
--          ecological risk zones (VW_ECOLOGICAL_RISK_ZONES) using Oracle
--          Spatial SDO_RELATE. Generates alert level and message for each
--          vessel currently inside a monitored zones
-- =============================================================================

CREATE OR REPLACE VIEW SMART.VW_VESSEL_RISK_ALERTS AS
SELECT
    v.TRANSIT_ID,
    v.TS_CLEAN,
    v.TRAFFIC_YEAR,
    v.MMSI,
    v.VESSEL_NAME,
    v.VESSEL_TYPE,
    v.FLAG,
    v.LENGTH_M,
    v.SPEED_KNOTS,
    v.HEADING_DEG,
    v.DRAFT_M,
    v.LATITUDE,
    v.LONGITUDE,
    v.IMPACT_WEIGHT,
    z.ZONE_ID,
    z.ZONE_NAME,
    z.HABITAT_TYPE,
    z.RISK_SCORE,
    z.RISK_CLASS,
    z.WILDLIFE_SCORE,
    z.MICROPLASTIC_SCORE,
    z.WATER_STRESS_SCORE,
    z.VESSEL_PRESSURE_SCORE,
    CASE
        WHEN z.RISK_CLASS = 'HIGH' AND NVL(v.IMPACT_WEIGHT, 0) >= 0.8 THEN 'CRITICAL'
        WHEN z.RISK_CLASS = 'HIGH'                                      THEN 'HIGH'
        WHEN z.RISK_CLASS = 'MEDIUM'                                    THEN 'MEDIUM'
        ELSE 'INFO'
    END AS ALERT_LEVEL,
    CASE
        WHEN z.RISK_CLASS = 'HIGH' AND NVL(v.IMPACT_WEIGHT, 0) >= 0.8
            THEN 'Critical vessel impact in high ecological risk zone'
        WHEN z.RISK_CLASS = 'HIGH'
            THEN 'Vessel currently inside high ecological risk zone'
        WHEN z.RISK_CLASS = 'MEDIUM'
            THEN 'Vessel currently inside medium ecological risk zone'
        ELSE 'Vessel inside monitored zone'
    END AS ALERT_MESSAGE

FROM SMART.VW_VESSEL_ENRICHED v
JOIN SMART.VW_ECOLOGICAL_RISK_ZONES z
    ON SDO_RELATE(
        z.BOUNDARY_GEOM,
        SDO_GEOMETRY(
            2001,
            4326,
            SDO_POINT_TYPE(v.LONGITUDE, v.LATITUDE, NULL),
            NULL,
            NULL
        ),
        'mask=INSIDE+TOUCH'
    ) = 'TRUE'
WHERE v.MMSI IS NOT NULL
  AND v.SPEED_KNOTS <= 50;
