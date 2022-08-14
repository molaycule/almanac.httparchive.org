#standardSQL
WITH ssgs AS (
  SELECT DISTINCT
    _TABLE_SUFFIX AS client,
    url,
    app
  FROM
    `httparchive.technologies.2022_06_01_*`
  WHERE
    LOWER(category) = 'paas'
),

jamstack_totals AS (
  SELECT
    client,
    date,
    COUNT(0) AS total_jamstack_sites
  FROM
    `httparchive.almanac.jamstack_sites`
  GROUP BY
    client,
    date
)

SELECT
  client,
  app,
  COUNT(0) AS num_jamstack_sites,
  total_jamstack_sites,
  COUNT(0) / total_jamstack_sites AS pct_jamstack_sites
FROM
  `httparchive.almanac.jamstack_sites`
JOIN
  ssgs
USING (client, url)
JOIN
  jamstack_totals
USING (client, date)
WHERE
  date = '2022-06-01'
GROUP BY
  client,
  app,
  total_jamstack_sites
ORDER BY
  client,
  app,
  total_jamstack_sites
