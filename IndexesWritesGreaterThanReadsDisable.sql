/*==================================================================
IndexesWritesGreaterThanReadsDisable.sql

Script for showing and/or disabling indexes where writes > reads
==================================================================*/

/*
@WriteGreaterThanReadThreshold

Determines the threshold of what is considered a burdomesome index.
Defaults to 0.
Formula: (User Updates) - ((User Seeks) + (User Scans) + (User Lookups))

The results of the formula must be greater than the value of @WriteGreaterThanReadThreshold.
For example, leaving the default of 0 then the number of user updates must be greater than
the total number of user seeks, scans, and lookups for an index to be included in the results.
*/
DECLARE @WriteGreaterThanReadThreshold int = 0


/*
@ShowDisabledIndexes

Simply determines if disabled indexes are shown in the results.
Defaults to 0.
*/
DECLARE @ShowDisabledIndexes bit = 0


/*
@AlterIndexes

Determines if the indexes returned in the results will be altered using the @AlterCmd.
Defaults to 0.

Set to 1 to alter the indexes in the results.  This should only be done when you are
positive that the results list indexes that you wish to alter.
*/
DECLARE @AlterIndexes bit = 0


/*
@AlterCmd

If @AlterIndexes = 1, then @AlterCmd determines how the index will be altered.
Defaults to 'DISABLE'.

SET @AlterCmd = 'DISABLE' to disable all indexes in the results.  Re-enabling these
indexes later will reset the user update statistics.

SET @AlterCmd = 'REBUILD' to rebuild all indexes in the results, which will enable them 
but will also clear the user updates statistics.
*/
DECLARE @AlterCmd nvarchar(7) = 'DISABLE'




SELECT
	sch.name + '.' + t.name AS [Table Name]
	, i.name AS [Index Name]
	, INDEXPROPERTY(OBJECT_ID(sch.name + '.' + t.name), i.name,'IsDisabled') AS [Is Disabled]
	, i.type_desc AS [Index Type]
	, ISNULL(user_updates,0) AS [Total Writes], ISNULL(user_seeks + user_scans + user_lookups,0) AS [Total Reads]
	, ISNULL(user_updates,0) - ISNULL((user_seeks + user_scans + user_lookups),0) AS [Difference]
	, 'ALTER INDEX [' + i.name + '] ON [' + sch.name + '].[' + t.name + '] ' + @AlterCmd + ' ;' AS [AlterCMD]
INTO #INDEXES
FROM sys.indexes AS i WITH (NOLOCK)
LEFT OUTER JOIN sys.dm_db_index_usage_stats AS s WITH (NOLOCK) ON s.object_id = i.object_id AND i.index_id = s.index_id AND s.database_id=db_id() AND objectproperty(s.object_id,'IsUserTable') = 1
INNER JOIN sys.tables AS t WITH (NOLOCK) ON i.object_id=t.object_id
INNER JOIN sys.schemas AS sch WITH (NOLOCK) ON t.schema_id=sch.schema_id
WHERE ISNULL(user_updates,0) - ISNULL((user_seeks + user_scans + user_lookups),0) > @WriteGreaterThanReadThreshold
AND i.index_id > 1
AND i.is_primary_key<>1
AND i.is_unique_constraint<>1
AND (@ShowDisabledIndexes = 1 OR INDEXPROPERTY(OBJECT_ID(sch.name + '.' + t.name), i.name,'IsDisabled') = 0)
ORDER BY [Table Name], [index name]

SELECT * FROM #INDEXES

IF @AlterIndexes = 1
BEGIN
	DECLARE @Fetch1 int, @CMD nvarchar(max)
	DECLARE tempcursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT [AlterCMD] FROM #INDEXES

	OPEN tempcursor 

	FETCH NEXT FROM tempcursor INTO @CMD
	SET @Fetch1 = @@FETCH_STATUS

	WHILE @Fetch1 = 0
	BEGIN 
		PRINT 'Executing....  ' + @CMD
		EXEC dbo.sp_executeSQL @CMD

		FETCH NEXT FROM tempcursor INTO @CMD
		SET @Fetch1 = @@FETCH_STATUS
	END

	CLOSE tempcursor
	DEALLOCATE tempcursor
	
END

DROP TABLE #INDEXES