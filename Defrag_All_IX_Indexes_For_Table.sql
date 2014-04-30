--=========================================================
-- Jeff Chalut
-- 2005.01.20
-- Defrag all indexes on a table
--=========================================================
DECLARE @Name sysname, @Table varchar(128), @DB sysname
SET @DB = 'Database'
SET @Table = 'Table'

DECLARE CurTemp CURSOR LOCAL FOR
SELECT I.[Name]
FROM sysobjects T, sysindexes I
WHERE T.type = 'U'
AND T.[id] = I.[id]
AND T.[Name] = @Table
AND LEFT(I.[Name],2) = 'IX'
ORDER BY T.[Name]

OPEN CurTemp
FETCH NEXT FROM CurTemp Into @Name
WHILE @@Fetch_Status = 0
BEGIN
	PRINT @Name
	DBCC INDEXDEFRAG (@DB,@Table,@Name)
	FETCH NEXT FROM CurTemp Into @Name
END

DBCC SHOWCONTIG (@Table) WITH ALL_INDEXES, TABLERESULTS