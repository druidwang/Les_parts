USE [sconit5_test]
GO
/****** Object:  StoredProcedure [dbo].[USP_GneeratorSP]    Script Date: 03/09/2012 13:58:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USP_GneeratorSP 'D:\sconit5.0\branch\Sconit5.0.0\src\Core.5.0.0\Entity\Base\INV\LocationTransactionDetail.hbm.xml'

ALTER PROCEDURE [dbo].[USP_GneeratorSP]
(
	@FileName varchar(1000)
)
AS
BEGIN
	SET NOCOUNT ON
	--DECLARE @FileName varchar(255) 
	DECLARE @Cmd VARCHAR(255) 
	DECLARE @xmlContent VARCHAR(max) 
	CREATE TABLE #tempXML(Id INT NOT NULL IDENTITY(1,1), Line VARCHAR(max)) 
	--DROP TABLE #tempXML
	--SELECT @FileName = 'C:\OrderMaster.hbm.xml' 
	SELECT @Cmd = 'type ' + @FileName 
	SELECT @xmlContent = '' 
	INSERT INTO #tempXML EXEC master.dbo.xp_cmdshell @Cmd 

	DECLARE @maxLine int
	DECLARE @tmp int=1
	DECLARE @line varchar(4000)

	DECLARE @beginMark int=0
	DECLARE @endMark int=0

	SELECT @maxLine=MAX(Id) FROM #tempXML
	WHILE(@tmp<=@maxLine)
	BEGIN
		SELECT @line=Line FROM #tempXML WHERE Id=@tmp
		
		IF CHARINDEX('hibernate-mapping',@line)>0
			OR CHARINDEX('<?',@line)>0 OR @line IS NULL
		BEGIN
			DELETE FROM #tempXML WHERE Id=@tmp
		END	
		IF CHARINDEX('<!--',@line)>0
		BEGIN
			IF CHARINDEX('-->',@line)>0
			BEGIN
				DELETE FROM #tempXML WHERE Id=@tmp
			END
			ELSE
			BEGIN
				SET @beginMark=@tmp
			END
		END

		IF CHARINDEX('-->',@line)>0 AND @beginMark<>0
		BEGIN
			SET @endMark=@tmp
			DELETE FROM #tempXML WHERE Id between @beginMark and @endMark
			SET @beginMark=0
		END	

		SET @tmp=@tmp+1
	END
	--SELECT * FROM #tempXML
	CREATE TABLE #temp(Id INT NOT NULL IDENTITY(1,1), Line VARCHAR(max))
	INSERT INTO #temp SELECT line FROM #tempXML
	SELECT @maxLine = MAX(Id) from #temp 
	SELECT @tmp = 1 
	WHILE @tmp<=@maxLine 
	BEGIN 
		SELECT @xmlContent = @xmlContent + Line from #temp WHERE Id = @tmp 
		SELECT @tmp = @tmp + 1 
	END 
	DECLARE @data xml
	SET @data = CAST(@xmlContent as xml)

	CREATE TABLE #Result(RowId int Identity(1,1),[name] varchar(50),[column] varchar(50),[type] varchar(50),[length] varchar(50),[update] varchar(50))
	INSERT INTO #Result([name],[column],[type],[length],[update])
	SELECT * FROM ( 
	SELECT T.c.value('@name','varchar(50)') as [name],
		T.c.value('@column','varchar(50)') as [column],
		T.c.value('@type','varchar(50)') as [type],
		T.c.value('@length','varchar(50)') as [length],
		T.c.value('@update','varchar(50)') as [update]
	FROM @data.nodes('/class/version') T(c)
	UNION ALL
	SELECT T.c.value('@name','varchar(50)') as [name],
		T.c.value('@column','varchar(50)') as [column],
		T.c.value('@type','varchar(50)') as [type],
		T.c.value('@length','varchar(50)') as [length],
		T.c.value('@update','varchar(50)') as [update]
	FROM @data.nodes('/class/property') T(c)
	UNION ALL
	SELECT T.c.value('@name','varchar(50)') as [name],
		T.c.value('@column','varchar(50)') as [column],
		T.c.value('@type','varchar(50)') as [type],
		T.c.value('@length','varchar(50)') as [length],
		T.c.value('@update','varchar(50)') as [update]
	FROM @data.nodes('/class/id') T(c)) as Result
	--SELECT CAST(@xmlContent as xml)
	DECLARE @tableName varchar(50)
	SELECT @tableName=@data.value ('((/class)/@table)[1]','varchar(max)')
	
	UPDATE #Result SET [type]='Int32' where [column]='TransType'
	SELECT * FROM #Result

	----CREATE INSERT SP
	DECLARE @SP varchar(max)
	DECLARE @where varchar(max)
	SET @SP='IF EXISTS(SELECT * FROM sys.objects WHERE name=''USP_'+SUBSTRING(@tableName,CHARINDEX('_',@tableName)+1,LEN(@tableName))+'_INSERT'')
	DROP PROCEDURE USP_'+SUBSTRING(@tableName,CHARINDEX('_',@tableName)+1,LEN(@tableName))+'_INSERT;'
	PRINT '-----DROP INSERT SP'
	PRINT @SP	
	exec(@SP)	

	SET @SP='CREATE PROCEDURE USP_'+SUBSTRING(@tableName,CHARINDEX('_',@tableName)+1,LEN(@tableName))+'_INSERT'
	SET @SP=@SP+CHAR(10)+'('
	--PRINT @SP

	DECLARE @allColumns varchar(max)
	DECLARE @allVars varchar(max)
	DECLARE @name varchar(50)
	DECLARE @column varchar(50)
	DECLARE @type varchar(50)
	DECLARE @length varchar(50)
	DECLARE @update varchar(50)
	SELECT @maxLine=MAX(RowId) FROM #Result
	SET @tmp=1
	WHILE(@tmp<=@maxLine)
	BEGIN
		--print @column
		SELECT @name=[name],@column=[column],@type=[type],@length=[length],@update=[update] 
			FROM #Result WHERE RowId=@tmp
		--print @column	
		IF @column<>'Id'
		BEGIN
			SET @SP=@SP+CHAR(10)
			SET @allColumns=ISNULL(@allColumns,'')+@column+','
			SET @allVars=ISNULL(@allVars,'')+'@'+@column+','
			
			IF(@type is NULL)
			BEGIN
				SET @SP=@SP+'	@'+@column+' tinyint,'
			END	
			ELSE IF(UPPER(@type)='INT32')
			BEGIN
				SET @SP=@SP+'	@'+@column+' int,'
			END		
			ELSE IF(UPPER(@type)='INT64')
			BEGIN
				SET @SP=@SP+'	@'+@column+' bigint,'
			END					
			ELSE IF(UPPER(@type)='STRING')
			BEGIN
				IF(@length IS NULL)
				BEGIN
					SET @SP=@SP+'	@'+@column+' varchar(4000),'
				END	
				ELSE
				BEGIN
					SET @SP=@SP+'	@'+@column+' varchar('+@length+'),'
				END
			END	
			ELSE IF(UPPER(@type)='DATETIME')
			BEGIN
				SET @SP=@SP+'	@'+@column+' datetime,'
			END	
			ELSE IF(UPPER(@type)='BOOLEAN')
			BEGIN
				SET @SP=@SP+'	@'+@column+' bit,'
			END	
			ELSE IF(UPPER(@type)='DECIMAL')
			BEGIN
				SET @SP=@SP+'	@'+@column+' decimal(18,8),'
			END	
		END	
		--print @sp				
		SET @tmp=@tmp+1	
	END

	SET @SP=SUBSTRING(@SP,1,LEN(@SP)-1)+CHAR(10)+')'
	SET @SP=@SP+CHAR(10)+'AS'
	SET @SP=@SP+CHAR(10)+'BEGIN'
	SET @SP=@SP+CHAR(10)+'	INSERT INTO '+@tableName+'('+SUBSTRING(@allcolumns,1,LEN(@allcolumns)-1)+')'
	SET @SP=@SP+CHAR(10)+'	VALUES('+SUBSTRING(@allVars,1,LEN(@allVars)-1)+')'
	SET @SP=@SP+CHAR(10)+'	SELECT SCOPE_IDENTITY()'
	SET @SP=@SP+CHAR(10)+'END'
		
	--SELECT @SP=SUBSTRING(@SP,1,LEN(@SP)-1)+')
	--AS
	--BEGIN
	--	INSERT INTO '+@tableName+'('+SUBSTRING(@allcolumns,1,LEN(@allcolumns)-1)+') 
	--	VALUES('+SUBSTRING(@allVars,1,LEN(@allVars)-1)+')
	--	SELECT SCOPE_IDENTITY()
	--END'
	PRINT '-----CREATE INSERT SP'
	PRINT @SP
	exec(@SP)


	----CREATE UPDATE SP
	DECLARE @allSetValue varchar(max)
	SET @SP='IF EXISTS(SELECT * FROM sys.objects WHERE name=''USP_'+SUBSTRING(@tableName,CHARINDEX('_',@tableName)+1,LEN(@tableName))+'_UPDATE'')
		DROP PROCEDURE USP_'+SUBSTRING(@tableName,CHARINDEX('_',@tableName)+1,LEN(@tableName))+'_UPDATE;'
	PRINT '-----DROP UPDATE SP'
	PRINT @SP	
	exec(@SP)	

	SET @SP='CREATE PROCEDURE USP_'+SUBSTRING(@tableName,CHARINDEX('_',@tableName)+1,LEN(@tableName))+'_UPDATE'
	SET @SP=@SP+CHAR(10)+'('
	SET @tmp=1
	WHILE(@tmp<=@maxLine)
	BEGIN
		--print @column
		SELECT @name=[name],@column=[column],@type=[type],@length=[length],@update=[update] 
			FROM #Result WHERE RowId=@tmp
		--print @column	
		
		IF(@update IS NULL AND @column<>'id')
		BEGIN	
			SET @SP=@SP+CHAR(10)
			--print @column	
			--print @SP
			SET @allSetValue=ISNULL(@allSetValue,'')+@column+'=@'+@column+','
			IF(@type is NULL)
			BEGIN
				SET @SP=@SP+'	@'+@column+' tinyint,'
			END	
			ELSE IF(UPPER(@type)='INT32')
			BEGIN
				SET @SP=@SP+'	@'+@column+' int,'
			END		
			ELSE IF(UPPER(@type)='INT64')
			BEGIN
				SET @SP=@SP+'	@'+@column+' bigint,'
			END			
			ELSE IF(UPPER(@type)='STRING')
			BEGIN
				IF(@length IS NULL)
				BEGIN
					SET @SP=@SP+'	@'+@column+' varchar(4000),'
				END	
				ELSE
				BEGIN
					SET @SP=@SP+'	@'+@column+' varchar('+@length+'),'
				END
			END	
			ELSE IF(UPPER(@type)='DATETIME')
			BEGIN
				SET @SP=@SP+'	@'+@column+' datetime,'
			END	
			ELSE IF(UPPER(@type)='BOOLEAN')
			BEGIN
				SET @SP=@SP+'	@'+@column+' bit,'
			END	
			ELSE IF(UPPER(@type)='DECIMAL')
			BEGIN
				SET @SP=@SP+'	@'+@column+' decimal(18,8),'
			END	
		END	
		--print @sp				
		SET @tmp=@tmp+1	
	END

	IF EXISTS(SELECT * FROM #Result WHERE [column]='Id')
	BEGIN
		SET @SP=@SP+CHAR(10)
		SET @SP=@SP+'	@Id int,'
		--SET @where=ISNULL(@where,'')+@column+'= @'+@column+' AND Version= @VersionBerfore'
	END
	
	IF EXISTS(SELECT * FROM #Result WHERE [column]='Version')
	BEGIN
		SET @SP=@SP+CHAR(10)
		SET @SP=@SP+'	@VersionBerfore int,'
		SET @where=ISNULL(@where,'')+@column+'=@'+@column+' AND Version=@VersionBerfore'
	END
	ELSE
	BEGIN
		SET @where=ISNULL(@where,'')+@column+'=@'+@column
	END
	
	SET @SP=SUBSTRING(@SP,1,LEN(@SP)-1)+CHAR(10)+')'
	SET @SP=@SP+CHAR(10)+'AS'
	SET @SP=@SP+CHAR(10)+'BEGIN'
	SET @SP=@SP+CHAR(10)+'	UPDATE '+@tableName+' SET '+SUBSTRING(@allSetValue,1,LEN(@allSetValue)-1)+''
	SET @SP=@SP+CHAR(10)+'	WHERE '+@where+''
	--SET @SP=@SP+CHAR(10)+'	SELECT SCOPE_IDENTITY()'
	SET @SP=@SP+CHAR(10)+'END'

	PRINT '-----CREATE UPDATE SP'
	PRINT @SP
	exec(@SP)
	----END

	DROP TABLE #tempXML
	DROP TABLE #temp
	DROP TABLE #Result
END
