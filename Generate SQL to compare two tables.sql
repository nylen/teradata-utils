/* Generate a query which will compare two tables.
 * The tables must have the same columns, and they
 * must both have a unique primary index that
 * references the same columns.
 */

CREATE VOLATILE TABLE cols AS (
	SEL TRIM(c.columnname) col, colindex,
		'N' firstcol, 'N' lastcol,
		'N' firstindex, 'N' lastindex,
		'N' skipcmp,
		CASE
			WHEN indextype = 'P' AND uniqueflag = 'Y' THEN 'Y'
			ELSE 'N'
		END AS isindex
	FROM (
		SEL databasename, tablename, columnname,
			ROW_NUMBER() OVER(ORDER BY columnid) colindex
		FROM dbc.COLUMNS
		WHERE TRIM(databasename) || '.' || TRIM(tablename) = '?table_a'
	) c
	LEFT JOIN dbc.indices i
	ON i.databasename = c.databasename
	AND i.tablename = c.tablename
	AND i.columnname = c.columnname
) WITH DATA ON COMMIT PRESERVE ROWS;


-- Add columns to skip here as follows:
-- UPDATE cols SET skipcmp = 'Y' WHERE col IN ('col1', 'col2', ...);
-- This will exclude the specified columns from the comparison.


CREATE VOLATILE TABLE cols_count AS (
	SEL COUNT(*) colcount,
		SUM(CASE WHEN isindex = 'Y' THEN 1 ELSE 0 END) AS indexcount
	FROM cols
) WITH DATA ON COMMIT PRESERVE ROWS;

UPDATE cols SET firstcol = 'Y' WHERE colindex = 1;
UPDATE cols SET lastcol = 'Y' WHERE colindex IN (
	SEL colcount FROM cols_count
);
UPDATE cols SET firstindex = 'Y' WHERE colindex IN (
	SEL MIN(colindex) FROM cols
	WHERE isindex = 'Y'
);
UPDATE cols SET lastindex = 'Y' WHERE colindex IN (
	SEL MAX(colindex) FROM cols
	WHERE isindex = 'Y'
);


SEL 10(INT) section,
	1(INT) line,
	''(VARCHAR(35)) col,
	''(VARCHAR(6000)) "-- Compare 2 tables"
FROM cols_count

UNION ALL SEL 10, 2, '', '-- Table "a": ?table_a' FROM cols_count
UNION ALL SEL 10, 3, '', '-- Table "b": ?table_b' FROM cols_count
UNION ALL SEL 10, 4, '', '' FROM cols_count
UNION ALL SEL 10, 5, '', 'SEL' FROM cols_count

UNION ALL SEL 20, colindex, col,
	'    ' || CASE WHEN firstcol = 'Y' THEN '' ELSE '+ ' END ||
	CASE WHEN skipcmp = 'Y' THEN '0--' ELSE '' END ||
	'CASE WHEN diff_' || col || ' = ''Y'' THEN 1 ELSE 0 END'
FROM cols

UNION ALL SEL 30, 1, '', '    AS _num_mismatches,' FROM cols_count
UNION ALL SEL 30, 2, '', '    ' FROM cols_count
UNION ALL SEL 30, 3, '', '    CASE' FROM cols_count
UNION ALL SEL 30, 4, '', '        WHEN ' || col || '_b' ||
	' IS NULL THEN ''(Row only in ?table_a)''' FROM cols WHERE firstindex = 'Y'
UNION ALL SEL 30, 5, '', '        WHEN ' || col || '_a' ||
	' IS NULL THEN ''(Row only in ?table_b)''' FROM cols WHERE firstindex = 'Y'
UNION ALL SEL 30, 6, '', '        ELSE TRIM(TRAILING '','' FROM TRIM(' FROM cols_count

UNION ALL SEL 40, colindex, col,
	'            ' || CASE WHEN firstcol = 'Y' THEN '' ELSE '|| ' END ||
	CASE WHEN skipcmp = 'Y' THEN '''''--' ELSE '' END ||
	'CASE WHEN diff_' || col || ' = ''Y'' THEN ''' || col || ' (' ||
		TRIM(colindex) || '/' || TRIM(colcount) || '), '' ELSE '''' END'
FROM cols
INNER JOIN cols_count
ON 1 = 1

UNION ALL SEL 50, 1, '', '            ))' FROM cols_count
UNION ALL SEL 50, 2, '', '    END AS _mismatches,' FROM cols_count
UNION ALL SEL 50, 3, '', '    ' FROM cols_count

UNION ALL SEL 60, colindex, col,
	'    a.' || col || ' ' || col || '_a, ' ||
	'b.' || col || ' ' || col || '_b, ' ||
	'CASE '
		|| 'WHEN a.' || col || ' = b.' || col
		|| ' OR (a.' || col || ' IS NULL AND b.' || col || ' IS NULL)'
		|| ' THEN ''N'' ELSE ''Y'' ' ||
	'END AS diff_' || col || CASE WHEN lastcol = 'Y' THEN '' ELSE ',' END
FROM cols

UNION ALL SEL 70, 1, '', '' FROM cols_count
UNION ALL SEL 70, 2, '', 'FROM ?table_a a' FROM cols_count
UNION ALL SEL 70, 3, '', '' FROM cols_count
UNION ALL SEL 70, 4, '', 'FULL OUTER JOIN ?table_b b' FROM cols_count

UNION ALL SEL 80, colindex, col,
	CASE WHEN firstindex = 'Y' THEN 'ON' ELSE 'AND' END ||
	' a.' || col || ' = b.' || col
FROM cols
WHERE isindex = 'Y'

UNION ALL SEL 90, 1, '', '' FROM cols_count

UNION ALL SEL 100, colindex, col,
	CASE WHEN firstcol = 'Y' THEN 'WHERE' ELSE 'OR' END ||
	CASE WHEN skipcmp = 'Y' THEN ' 1=0--' ELSE '' END ||
	' diff_' || col || ' = ''Y'''
FROM cols

UNION ALL SEL 110, 1, '', '' FROM cols_count
UNION ALL SEL 110, 2, '', 'ORDER BY' FROM cols_count

UNION ALL SEL 120, colindex, col,
	'COALESCE(' || col || '_a, ' || col || '_b)' ||
	CASE WHEN lastindex = 'Y' THEN '' ELSE ',' END
FROM cols
WHERE isindex = 'Y'

ORDER BY 1,2;

DROP TABLE cols;
DROP TABLE cols_count;
