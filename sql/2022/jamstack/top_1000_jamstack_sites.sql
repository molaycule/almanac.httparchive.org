SELECT
  date,
  client,
  url
FROM
  `httparchive.almanac.jamstack_sites`
WHERE
  date = '2022-06-01' AND
  rank = 1000
ORDER BY
  date,
  client,
  url
