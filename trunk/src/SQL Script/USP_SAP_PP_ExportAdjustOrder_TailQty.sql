USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_PP_ExportAdjustOrder_TailQty]    Script Date: 12/08/2014 10:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_SAP_PP_ExportAdjustOrder_TailQty]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
BEGIN
	--2014/04/27	MES端对生产调整单所产生的261和262类型的计划外出入库，按照#*订单实际耗量*#分摊	2014/04/27	--0001
	--过账日期设在当天???????
	--2014/10/27	 
	--接口传给SAP的调整原因描述
	--调整原因描述长度
	--翻箱后过滤--[物料号]翻箱后过滤差异--20
	--盘点调整[MES生产调整原因]--人工输入
	--尾差调整261--[SAP库位]尾差调整出库16
	--尾差调整262--[SAP库位]尾差调整入库16--0002
	SET NOCOUNT ON
	DECLARE @CurrDate datetime=GETDATE()
	Declare @ExecutionTimeStr datetime = @CurrDate--varchar(20)=dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS')
	Declare @WERKS varchar(50)
	Declare @MonthStart DateTime 
	Declare @MonthEnd DateTime
	Declare @ZMESGUID varchar(50)=dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS0000')
	Select @WERKS=Value from SYS_EntityPreference where Id = 90107
	Select  @MonthStart=dbo.FormatDate(@CurrDate,'YYYY-MM-01 00:00:00'),
		@MonthEnd= dbo.FormatDate(Dateadd(month,1,@CurrDate),'YYYY-MM-01 00:00:00')
		--select Code ,GETDATE (),@CurrDate from MD_Location as l where Code in(select distinct(LocFrom) from SCM_FlowMstr where type=4) 
	Print @MonthStart
	Print @MonthEnd
	 
	----***********
	----传送尾差Begin生产收货尾差直接根据TailQty Sum,因为他们的移动类型就是Sum后根据正负得来的
	----调整单的尾差要注意移动类型然后再Sum
	----冲销上个月的报工单引起的尾差管不了
	--调整尾差
	/*Insert into SAP_Interface_PPMES0005(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, 
		ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,TailQty,Type)
	Select dbo.FormatDate(@CurrDate,'YYYYMMDDHH') As ZMESSC, 1 As ZMESLN, 'BUSTZ01' As ZPTYPE,'SY05'As AUFART, '8000'As WERKS, ''AS MATXT,''AS GAMNG_H, 
		'' As GMEIN_H,''AS GLTRP,''AS GSTRP, ''AS BLDAT, ''AS BUDAT, 
		Case when sum(cast(TailQty As decimal(28,18))) <0 then  '261' else '262' End As BWART_I, MATNR_I, 
		sum(cast(TailQty As decimal(28,18))) As ERFMG_I, GMEIN_I, LGORT_I,
		@ZMESGUID As ZMESGUID,@ExecutionTimeStr ZCSRQSJ,@BatchNo BatchNo,null as UniqueCode, '0' As status,0 As tailQty,'1'
		from SAP_Interface_PPMES0005
		where cast(TailQty As decimal(28,18)) !=0
		and ZCSRQSJ between @MonthStart and @MonthEnd
		Group by  ZPTYPE, AUFART, WERKS,MATNR_I,GMEIN_I,LGORT_I*/
	Select top 0 * into #SAP_Interface_PPMES0005 from SAP_Interface_PPMES0005 where 1=2

	--生产收货尾差---,'AdjustOrder')看来是不可以传的,因为平摊过后,它就是有误差的,所以它对应的尾差是不准的
 	Insert into #SAP_Interface_PPMES0005(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, 
		ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,TailQty,Type)
	Select dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS') As ZMESSC, ROW_NUMBER()Over(Order by MATNR_I) As ZMESLN, 'BUSTZ01' As ZPTYPE,'SY05'As AUFART,@WERKS As WERKS, 'MATXT'AS MATXT,'1'AS GAMNG_H, 
		GMEIN_I As GMEIN_H,GetDate()AS GLTRP,GetDate()AS GSTRP, GetDate()AS BLDAT, GetDate()AS BUDAT, 
		Case when sum(Case when OrderType='AdjustOrder' and BWART_I = '261' then -1 else 1 End*cast(TailQty As decimal(28,18))) <0 then  '261' else '262' End As BWART_I, MATNR_I, 
		left(Cast(ABS(sum(Case when OrderType='AdjustOrder' and BWART_I = '261' then -1 else 1 End *cast(TailQty As decimal(28,18)))) as varchar),13) As ERFMG_I, GMEIN_I, LGORT_I,
		@ZMESGUID As ZMESGUID,@ExecutionTimeStr ZCSRQSJ,@BatchNo BatchNo,null as UniqueCode, '0' As status,0 As tailQty,'2'
		from SAP_Interface_PPMES0001 a
		where cast(TailQty As decimal(28,18)) !=0
		and OrderType in ('EXOrder','MIOrder','FIOrder'/*,'AdjustOrder'*/)
		and ZCSRQSJ between @StartTime and @EndTime
		and not exists(select 0 from SAP_Interface_PPMES0002 b where a.ZComnum=b.ZComnum)
		and MATNR_I!=''
		Group by WERKS,MATNR_I,GMEIN_I,LGORT_I
		--having ABS(sum(cast(TailQty As decimal(28,18))))>0.001
	------XXXX特殊处理
	--	Select dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS') As ZMESSC, ROW_NUMBER()Over(Order by MATNR_I) As ZMESLN, 'BUSTZ01' As ZPTYPE,'SY05'As AUFART,@WERKS As WERKS, 'MATXT'AS MATXT,'1'AS GAMNG_H, 
	--	GMEIN_I As GMEIN_H,GetDate()AS GLTRP,GetDate()AS GSTRP, GetDate()AS BLDAT, GetDate()AS BUDAT, 
	--	Case when sum(Case when OrderType='AdjustOrder' and BWART_I = '261' then -1 else 1 End*cast(TailQty As decimal(28,18))) <0 then  '262' else '261' End As BWART_I, MATNR_I, 
	--	left(Cast(ABS(sum(Case when OrderType='AdjustOrder' and BWART_I = '261' then -1 else 1 End *cast(TailQty As decimal(28,18)))) as varchar),13) As ERFMG_I, GMEIN_I, LGORT_I,
	--	@ZMESGUID As ZMESGUID,@ExecutionTimeStr ZCSRQSJ,@BatchNo BatchNo,null as UniqueCode, '0' As status,0 As tailQty,'2'
	--	from SAP_Interface_PPMES0001 a
	--	where cast(TailQty As decimal(28,18)) !=0
	--	and OrderType in ('EXOrder','MIOrder','FIOrder'/*,'AdjustOrder'*/)
	--	and ZCSRQSJ between @StartTime and @EndTime
	--	and exists(select 0 from SAP_Interface_PPMES0002 b where a.ZComnum=b.ZComnum and a.BUDAT<'' and b.ZCSRQSJ >'')
	--	and MATNR_I!=''
	--	--and MATNR_I in (select * from _PPAJ?)
	--	Group by WERKS,MATNR_I,GMEIN_I,LGORT_I
 --	Insert into #SAP_Interface_PPMES0005(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, 
	--	ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,TailQty,Type)
	--Select dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS') As ZMESSC, ROW_NUMBER()Over(Order by MATNR_I) As ZMESLN, 'BUSTZ01' As ZPTYPE,'SY05'As AUFART,@WERKS As WERKS, 'MATXT'AS MATXT,'1'AS GAMNG_H, 
	--	GMEIN_I As GMEIN_H,GetDate()AS GLTRP,GetDate()AS GSTRP, GetDate()AS BLDAT, GetDate()AS BUDAT, 
	--	Case when sum(cast(TailQty As decimal(28,18))) <0 then  '261' else '262' End As BWART_I, MATNR_I, 
	--	left(Cast(ABS(sum(cast(TailQty As decimal(28,18)))) as varchar),13) As ERFMG_I, GMEIN_I, LGORT_I,
	--	@ZMESGUID As ZMESGUID,@ExecutionTimeStr ZCSRQSJ,@BatchNo BatchNo,null as UniqueCode, '0' As status,0 As tailQty,'3'
	--	from SAP_Interface_PPMES0003 a
	--	where cast(TailQty As decimal(28,18)) !=0
	--	and ZCSRQSJ between @StartTime and @EndTime
	--	and  exists(select 0 from SAP_Interface_PPMES0003 b where a.ZComnum=b.ZComnum and b.ZPTYPE= 'BUSCX02'
	--	and a.BUDAT<'' and b.ZCSRQSJ >'')
	--	and MATNR_I!=''
	--	Group by WERKS,MATNR_I,GMEIN_I,LGORT_I	
	--废品报工尾差
 	Insert into #SAP_Interface_PPMES0005(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, 
		ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,TailQty,Type)
	Select dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS') As ZMESSC, ROW_NUMBER()Over(Order by MATNR_I) As ZMESLN, 'BUSTZ01' As ZPTYPE,'SY05'As AUFART,@WERKS As WERKS, 'MATXT'AS MATXT,'1'AS GAMNG_H, 
		GMEIN_I As GMEIN_H,GetDate()AS GLTRP,GetDate()AS GSTRP, GetDate()AS BLDAT, GetDate()AS BUDAT, 
		Case when sum(cast(TailQty As decimal(28,18))) <0 then  '261' else '262' End As BWART_I, MATNR_I, 
		left(Cast(ABS(sum(cast(TailQty As decimal(28,18)))) as varchar),13) As ERFMG_I, GMEIN_I, LGORT_I,
		@ZMESGUID As ZMESGUID,@ExecutionTimeStr ZCSRQSJ,@BatchNo BatchNo,null as UniqueCode, '0' As status,0 As tailQty,'3'
		from SAP_Interface_PPMES0003 a
		where cast(TailQty As decimal(28,18)) !=0
		and ZCSRQSJ between @StartTime and @EndTime
		and not exists(select 0 from SAP_Interface_PPMES0003 b where a.ZComnum=b.ZComnum and b.ZPTYPE= 'BUSCX02')
		and MATNR_I!=''
		Group by WERKS,MATNR_I,GMEIN_I,LGORT_I
		--having ABS(sum(cast(TailQty As decimal(28,18))))>0.001
	----按照库位合并调整单
	Select top 0 * into #SAP_Interface_PPMES0005_Tem from SAP_Interface_PPMES0005 where 1=2
		Insert into #SAP_Interface_PPMES0005_Tem
			Select ZMESSC, 1 As ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GETDATE() GLTRP,GETDATE() GSTRP, GETDATE()BLDAT,DATEADD(hour,-12,GETDATE())BUDAT, 
			Case when sum(cast(ERFMG_I As decimal(28,18))*case when BWART_I='261' then -1 else 1 end) <0 then  '261' else '262' End As BWART_I, MATNR_I,
			left(Cast(ABS(sum(cast(ERFMG_I As decimal(28,18))*case when BWART_I='261' then -1 else 1 end)) as varchar),13) As ERFMG_I,
			  GMEIN_I, LGORT_I, 
			@ZMESGUID As ZMESGUID,@ExecutionTimeStr ZCSRQSJ,@BatchNo BatchNo,null as UniqueCode, '0' As status,0 As tailQty,'4' 
			from #SAP_Interface_PPMES0005
			Group by ZMESSC,ZPTYPE,AUFART,WERKS,MATXT,GAMNG_H,GMEIN_H,MATNR_I,   GMEIN_I, LGORT_I
		Update #SAP_Interface_PPMES0005_Tem
			Set Status =1 from #SAP_Interface_PPMES0005_Tem where CAST(ERFMG_I As decimal(18,8))<0.001
		Select *,Dense_rank()Over(Partition by ZMESSC Order by LGORT_I) As ZMESLNSEQ into #SAP_Interface_PPMES0005_Insert from #SAP_Interface_PPMES0005_Tem
		Update a
		Set MATXT =b.saplocdesc, ZMESLN=ZMESLNSEQ from #SAP_Interface_PPMES0005_Insert a,MD_SAPlocdesc b where a.LGORT_I=b.saploc
		
		--Select * from #SAP_Interface_PPMES0005_Insert
		Insert into SAP_Interface_PPMES0005(
			ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, ERFMG_I, 
			GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status, TailQty, Type)
			Select ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, ERFMG_I, 
				GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status, TailQty, Type from #SAP_Interface_PPMES0005_Insert
	----更新3个必输字段
	----传送尾差End
 
	-----
		Declare @uniqueCode1 varchar(200) =replace(newid(),'-','')
		Update SAP_Interface_PPMES0002 Set UniqueCode =@uniqueCode1 where BatchNo =@BatchNo
			--Delete ,Update在测试阶段启用下面的代码，测试完后要把所有存储整合在一起，一起更新
		DECLARE @LastOrderNo varchar(50)
		/*SELECT s1.ZComnum INTO #TEMP1 FROM SAP_Interface_PPMES0001 s1 
			INNER JOIN SAP_Interface_PPMES0002 s2 ON s1.ZComnum=s2.ZComnum
			WHERE s1.BatchNo=@BatchNo AND s2.BatchNo=@BatchNo
		
		IF @@ROWCOUNT>0
		BEGIN
			--如果同一个时间段内存在冲销都不传
			DELETE a FROM SAP_Interface_PPMES0001 a INNER JOIN #TEMP1 b ON a.ZComnum=b.ZComnum
			DELETE a FROM SAP_Interface_PPMES0002 a INNER JOIN #TEMP1 b ON a.ZComnum=b.ZComnum
		END*/
			
		DECLARE @UniqueCode varchar(50)
		WHILE EXISTS(SELECT * FROM SAP_Interface_PPMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL)
		BEGIN
			SET @UniqueCode=REPLACE(NEWID(),'-','')
			UPDATE TOP(5000) SAP_Interface_PPMES0001 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			SELECT TOP 1 @LastOrderNo=ZMESSC FROM SAP_Interface_PPMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			PRINT @LastOrderNo
			IF EXISTS(SELECT 1 FROM SAP_Interface_PPMES0001 WHERE BatchNo=@BatchNo AND UniqueCode=@UniqueCode AND ZMESSC=@LastOrderNo )
			BEGIN
				UPDATE SAP_Interface_PPMES0001 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND ZMESSC=@LastOrderNo
			END
		END	
		/*SELECT s1.ZMESSC INTO #TEMP2 FROM SAP_Interface_PPMES0005 s1 
			INNER JOIN SAP_Interface_PPMES0002 s2 ON s1.ZMESSC=s2.ZMESSC
			WHERE s1.BatchNo=@BatchNo AND s2.BatchNo=@BatchNo
		
		IF @@ROWCOUNT>0
		BEGIN
			--如果同一个时间段内存在冲销都不传
			DELETE a FROM SAP_Interface_PPMES0005 a INNER JOIN #TEMP2 b ON a.ZComnum=b.ZMESSC
			DELETE a FROM SAP_Interface_PPMES0002 a INNER JOIN #TEMP2 b ON a.ZComnum=b.ZMESSC
		END*/
		WHILE EXISTS(SELECT * FROM SAP_Interface_PPMES0005 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL)
		BEGIN
			
			SET @UniqueCode=REPLACE(NEWID(),'-','')
			UPDATE TOP(5000) SAP_Interface_PPMES0005 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			SELECT TOP 1 @LastOrderNo=ZMESSC FROM SAP_Interface_PPMES0005 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			PRINT @LastOrderNo
			IF EXISTS(SELECT 1 FROM SAP_Interface_PPMES0005 WHERE BatchNo=@BatchNo AND UniqueCode=@UniqueCode AND ZMESSC=@LastOrderNo )
			BEGIN
				UPDATE SAP_Interface_PPMES0005 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND ZMESSC=@LastOrderNo
			END
		END		
	--Select top 100 * from SAP_Interface_AdjustDet
	--Select top 100 * from SAP_Interface_PPMES0002
	--Select top 100 * from SAP_Interface_PPMES0005
	--Select top 100 * from SAP_Interface_PPMES0001  where batchno='9FAA6B087100436689B98292AFC467CF'
	--0002
	Update SAP_Interface_PPMES0005
	Set MATXT =LGORT_I+'尾差调整出库' from SAP_Interface_PPMES0005 where ZMESSC like '2%' and BatchNo =@BatchNo and BWART_I ='261'
	Update SAP_Interface_PPMES0005
	Set MATXT =LGORT_I+'尾差调整入库',ZMESLN ='2' from SAP_Interface_PPMES0005 where ZMESSC like '2%' and BatchNo =@BatchNo and BWART_I ='262'
	--0002
		SELECT Status=1,BatchNo=@BatchNo,'生成调整尾差数据成功。'
	
END