CREATE OR REPLACE TABLE `httparchive.almanac.jamstack_sites` AS
(
  WITH potential_jamstack_sites AS (
    SELECT DISTINCT
      client,
      date,
      page AS url,
      rank
    FROM
      `httparchive.almanac.requests`
    WHERE
      firstHtml AND
      (
        (
          resp_age IS NOT NULL AND
          resp_age != ''
        )
        OR
        (
          resp_cache_control IS NOT NULL AND
          resp_cache_control != '' AND
          expAge IS NOT NULL AND
          resp_cache_control NOT LIKE 'no-store' AND
          resp_cache_control NOT LIKE 'no-cache' AND
          expAge > 0
        )
      ) AND
      _cdn_provider IS NOT NULL
  ),

  fast_jamstack_sites AS (
    SELECT
      s.*,
      p75_lcp,
      fast_lcp,
      avg_lcp,
      slow_lcp,
      p75_fcp,
      fast_fcp,
      avg_fcp,
      slow_fcp
    FROM
      potential_jamstack_sites s
    JOIN
      `chrome-ux-report.materialized.device_summary` c
    ON
      url = CONCAT(origin, '/') AND
      s.date = c.date AND
      (
        (s.client = 'mobile' AND c.device = 'phone')
        OR
        (s.client = 'desktop' AND c.device = 'desktop')
        OR
        c.device IS NULL
      )
    WHERE
      p75_lcp <= 2500 AND
      p75_fcp <= 1800
  )

  SELECT
    *
  FROM
    fast_jamstack_sites
  ORDER BY
    client,
    date
)
