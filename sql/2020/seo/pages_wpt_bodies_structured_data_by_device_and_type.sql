#standardSQL
# page wpt_bodies metrics grouped by device and structured data type

# helper to create percent fields
CREATE TEMP FUNCTION AS_PERCENT (freq FLOAT64, total FLOAT64) RETURNS FLOAT64 AS (
  ROUND(SAFE_DIVIDE(freq, total), 4)
);

# returns all the data we need from _wpt_bodies
CREATE TEMPORARY FUNCTION get_wpt_bodies_info(wpt_bodies_string STRING)
RETURNS STRUCT<
    jsonld_and_microdata_types ARRAY<STRING>
> LANGUAGE js AS '''
var result = {};


try {
    var wpt_bodies = JSON.parse(wpt_bodies_string);

    if (Array.isArray(wpt_bodies) || typeof wpt_bodies != 'object') return result;

    if (wpt_bodies.structured_data && wpt_bodies.structured_data.rendered) {
        var temp = wpt_bodies.structured_data.rendered.jsonld_and_microdata_types;
        result.jsonld_and_microdata_types = temp.map(a => a.name);
    }

} catch (e) {}
return result;
''';

SELECT
client,
type,
total,
COUNT(0) AS count,
AS_PERCENT(COUNT(0), total) AS pct

FROM
    (
      SELECT
        _TABLE_SUFFIX AS client,
        total,
        get_wpt_bodies_info(JSON_EXTRACT_SCALAR(payload, '$._wpt_bodies')) AS wpt_bodies_info
      FROM
        `httparchive.pages.2020_08_01_*`
        JOIN
  (SELECT _TABLE_SUFFIX, COUNT(0) AS total
  FROM
  `httparchive.pages.2020_08_01_*`
  GROUP BY _TABLE_SUFFIX) # to get an accurate total of pages per device. also seems fast
USING (_TABLE_SUFFIX)
    ), UNNEST(wpt_bodies_info.jsonld_and_microdata_types) AS type
GROUP BY
total,
type,
client
HAVING
count > 100
ORDER BY
count DESC
