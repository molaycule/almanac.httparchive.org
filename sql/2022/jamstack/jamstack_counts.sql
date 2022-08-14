WITH totals AS (
  SELECT
    client,
    date,
    IFNULL(rank, 0) AS rank_grouping,
    COUNT(0) AS total_sites
  FROM
    `httparchive.almanac.requests`
  WHERE
    firstHtml
  GROUP BY
    client,
    date,
    rank
),

jamstack_sites AS (
  SELECT
    client,
    date,
    IFNULL(rank, 0) AS rank_grouping,
    COUNT(0) AS num_sites
  FROM
    `httparchive.almanac.jamstack_sites`
  GROUP BY
    client,
    date,
    rank

)

SELECT
  client,
  date,
  rank_grouping,
  CASE
    WHEN rank_grouping = 0 THEN ''
    WHEN rank_grouping = 10000000 THEN 'all'
    ELSE FORMAT("%'d", rank_grouping)
  END AS ranking,
  num_sites,
  total_sites,
  SAFE_DIVIDE(num_sites, total_sites) AS rank_pct
FROM
  jamstack_sites
JOIN
  totals
USING (client, date, rank_grouping)
ORDER BY
  client,
  date,
  rank_grouping
