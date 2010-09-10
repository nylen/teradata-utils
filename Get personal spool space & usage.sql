SEL vproc,
	SUM(currentspool) / (1024**3) (DECIMAL(10,5)) AS gb_current_spool,
	SUM(peakspool) / (1024**3) (DECIMAL(10,5)) AS gb_peak_spool,
	SUM(maxspool) / (1024**3) (DECIMAL(10,5)) AS gb_max_spool,
	SUM(currenttemp) / (1024**3) (DECIMAL(10,5)) AS gb_current_temp,
	SUM(maxtemp) / (1024**3) (DECIMAL(10,5)) AS gb_max_temp,
	SUM(currentperm) / (1024**3) (DECIMAL(10,5)) AS gb_curr_perm,
	SUM(maxperm) / (1024**3) (DECIMAL(10,5)) AS gb_max_perm 
FROM dbc.diskspace 
WHERE databasename = 'ajb08' 
--WHERE databasename = 'aa'
GROUP BY 1 ORDER BY 2 DESC
