SEL x.databasename,
	y.CreatorName,
--	z.commentstring,
	x.tablename,
	x.maxavail,
	x.current_size,
	CAST(y.LastAlterTimeStamp AS   DATE) lastalterdate,
	CAST(y.createtimestamp AS DATE) createdate,
	x.tableskew
--	y.CommentString
--	z.spoolspace
FROM (
	SEL databasename, tablename,
		SUM(maxperm) AS maxavail,
		SUM(currentperm) AS Current_Size,
		SUM(peakperm) AS peak_size,
		100*(CAST(MAX(currentperm) AS DECIMAL(18,3)) - CAST(AVE(currentperm) AS DECIMAL(18,3)))
			/ (NULLIF(CAST(MAX(currentperm) AS DECIMAL(18,3)),0)) AS tableskew
	FROM dbc.allspace
	WHERE databasename = 'aa'
	--	and tablename = 'CF_NEW'
	GROUP BY databasename,tablename
) x
LEFT JOIN (
	SEL DatabaseName, TableName, CreatorName,
		LastAlterTimeStamp, CreateTimeStamp,
		CommentString
	FROM dbc.Tables
	WHERE DatabaseName = 'aa'
) y
ON x.databasename=y.databasename
AND x.tablename=y.tablename
/*LEFT JOIN (
	SEL databasename,spoolspace,commentstring
	FROM dbc.databases
	WHERE databasename = 'prodwrk'
) z
ON y.creatorname=z.databasename
--*/    
ORDER BY y.CreatorName,x.tablename
