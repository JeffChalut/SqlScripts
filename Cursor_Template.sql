-- CURSOR TEMPLATE
-- Jeff Chalut
DECLARE @Fetch1 int, @ID int

SELECT [ID]
INTO #tempTable
FROM [dbo].[Table] (NOLOCK)
ORDER BY [ID]

DECLARE tempcursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
SELECT ID FROM #tempTable

OPEN tempcursor 

FETCH NEXT FROM tempcursor INTO @ID
SET @Fetch1 = @@FETCH_STATUS

WHILE @Fetch1 = 0
BEGIN 
	PRINT @ID

	FETCH NEXT FROM tempcursor INTO @ID
	SET @Fetch1 = @@FETCH_STATUS
END

CLOSE tempcursor
DEALLOCATE tempcursor
DROP TABLE #tempTable