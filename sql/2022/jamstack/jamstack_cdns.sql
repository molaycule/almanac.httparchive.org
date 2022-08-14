#standardSQL
WITH cdns AS (
  SELECT DISTINCT
    client,
    page AS url,
    _cdn_provider AS cdn
  FROM
    `httparchive.almanac.requests`
  WHERE
    firstHTML AND
    date = '2022-06-01'
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
  cdn,
  COUNT(0) AS num_jamstack_sites,
  total_jamstack_sites,
  COUNT(0) / total_jamstack_sites AS pct_jamstack_sites
FROM
  `httparchive.almanac.jamstack_sites`
JOIN
  cdns
USING (client, url)
JOIN
  jamstack_totals
USING (client, date)
WHERE
  date = '2022-06-01'
GROUP BY
  client,
  cdn,
  total_jamstack_sites
ORDER BY
  client,
  cdn,
  total_jamstack_sites
