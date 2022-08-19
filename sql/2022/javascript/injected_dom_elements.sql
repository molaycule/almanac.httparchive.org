#standardSQL
# Number of injected DOM elements per page.

CREATE TEMPORARY FUNCTION getDom(payload STRING)
RETURNS STRUCT<initialElements INT64, elements INT64, contentLength INT64>
LANGUAGE js AS '''
try {
  const $ = JSON.parse(payload);
  const javascript = JSON.parse($._javascript);
  const elementCount = JSON.parse($._element_count);

  if (javascript) {
    // server-generated HTML elements
    const { length: contentLength, elements: initialElements } = javascript.document;

    // all elements including injected HTML
    const elements = Object.values(elementCount).reduce(
      (total, freq) => total + (parseInt(freq, 10) || 0),
      0
    );

    return {
      initialElements,
      elements,
      contentLength,
    };
  }

  return null;
} catch (e) {
  return null;
}
''';

WITH pageSizes AS (
  SELECT
    pages.client AS client,
    pages.page AS page,
    getDom(payload) AS dom
  FROM (
    SELECT
      _TABLE_SUFFIX AS client,
      url AS page,
      payload
    FROM
      `httparchive.pages.2022_06_01_*`
  ) AS pages
)

SELECT
  client,
  percentile,
  APPROX_QUANTILES(dom.elements, 1000)[OFFSET(percentile * 10)] AS elements,
  APPROX_QUANTILES(dom.initialElements, 1000)[OFFSET(percentile * 10)] AS initial_elements,
  APPROX_QUANTILES(SAFE_DIVIDE((dom.elements - dom.initialElements), dom.elements), 1000)[OFFSET(percentile * 10)] AS pct_injected_elements
FROM 
  pageSizes,
  UNNEST([10, 25, 50, 75, 90, 100]) AS percentile
WHERE
  dom IS NOT NULL
GROUP BY
  percentile,
  client
ORDER BY
  client,
  percentile
