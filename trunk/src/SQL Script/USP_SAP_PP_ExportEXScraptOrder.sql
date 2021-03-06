USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_PP_ExportEXScraptOrder]    Script Date: 12/08/2014 10:32:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_SAP_PP_ExportEXScraptOrder]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @CurrDate datetime=GETDATE()
	Declare @ExecutionTime  datetime = @CurrDate-- varchar(20)=dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS')
	Declare @WERKS varchar(50)
	Declare @ZMESGUID varchar(50)=dbo.FormatDate(GETDATE(),'YYYYMMDDHHNNSS0000')
	Select @WERKS=Value from SYS_EntityPreference where Id = 90107
	--算出报工号和对应的SAP订单号
	Exec USP_SAP_PP_UpdateEXScraptInterim @BatchNo,@StartTime,@EndTime
	--select @ExecutionTime,@ExecutionTime,@StartTime,@EndTime 
	--
	----ScheduleType为(21,22,23,24,25),查找表MrpExScrap.只有废品报工,无投入.只需调用接口ZWS_PPMES0003
	--Select top 1000 * from SAP_Interface_PPMES0003 BUSBG01
	/*这一段放到USP_SAP_PP_UpdateEXScraptInterim 里,防止漏补历史的生产单Insert into SAP_Interface_PPMES0003(ZMESSC, ZMESLN, ZPTYPE, WERKS, XMNGA,GMEIN_H, GRUND, ZComnum, BLDAT, BUDAT, 
		MTSNR, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status)
		Select b.AdjustSAPOrder As ZMESSC,1 As ZMESLN ,'BUSBG01' As ZPTYPE,@WERKS As WERKS,ceiling(ScraptQty) As XMNGA,'KG' As GMEIN_H ,Reason As GRUND,
			MiscOrderDet As ZComnum,EffectDate As BLDAT,c.CreateDate As BUDAT,'' As MTSNR, '' As BWART_I, '' As MATNR_I,
			 '' As ERFMG_I, '' As GMEIN_I, '' AsLGORT_I ,@ZMESGUID As ZMESGUID ,
			GETDATE() As ZCSRQSJ,@BatchNo As BatchNo,NUll As UniqueCode,'0' as Status
			from SAP_Interface_ExscraptMstr a,SAP_Interface_ExscraptDet b ,MRP_MrpExScrap c
			where a.MiscOrder=b.MiscOrder
			and a.MiscOrderNo=c.Id
			and a.BatchNo=@BatchNo
			and a.Reason not in ('MES24','MES25')*/
			--Select * from SAP_Interface_ExscraptMstr a,SAP_Interface_ExscraptDet b 
			--where a.MiscOrder=b.MiscOrder
	----(21,22,23,24,25)BUSCX02冲销也走0003接口
	Insert into SAP_Interface_PPMES0003(ZMESSC, ZMESLN, ZPTYPE, WERKS, XMNGA, GRUND, ZComnum, BLDAT, BUDAT, 
	MTSNR, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status)
		Select Distinct b.AdjustSAPOrder As ZMESSC,1 As ZMESLN ,'BUSCX02' As ZPTYPE,@WERKS As WERKS,'' As XMNGA,Reason As GRUND,
			MiscOrderDet As ZComnum,c.LastModifyDate As BLDAT,c.LastModifyDate As BUDAT,'' As MTSNR, '' As BWART_I, '' As MATNR_I,
			 '' As ERFMG_I, '' As GMEIN_I, '' AsLGORT_I ,@ZMESGUID As ZMESGUID ,
			GETDATE() As ZCSRQSJ,@BatchNo As BatchNo,NUll As UniqueCode,'0' as Status
			from SAP_Interface_ExscraptMstr a,SAP_Interface_ExscraptDet b ,MRP_MrpExScrap c
			where a.MiscOrder=b.MiscOrder
			--and a.BatchNo=@BatchNo
			and a.MiscOrderNo=c.Id
			and a.MiscOrderNo in 
			(select Id
			from MRP_MrpExScrap where IsVoid=1 and LastModifyDate>@StartTime AND LastModifyDate<=@EndTime and LastModifyUser<>3910)
			and a.Reason not in ('MES26')
		--Delete ,Update在测试阶段启用下面的代码，测试完后要把所有存储整合在一起，一起更新
			
		SELECT s1.ZComnum INTO #TEMP1 FROM SAP_Interface_PPMES0003 s1 
			INNER JOIN SAP_Interface_PPMES0003 s2 ON s1.ZComnum=s2.ZComnum
			WHERE s1.BatchNo=@BatchNo AND s2.BatchNo=@BatchNo
			And s1.ZPTYPE ='BUSBG01'
			And s2.ZPTYPE ='BUSCX02'
			
		Update a
			Set a.Item=b.Item  from SAP_Interface_PPMES0003 a,SAP_EX001 b where a.ZMESSC =b.PlanNo and a.BatchNo=@BatchNo
		IF @@ROWCOUNT>0
		BEGIN
			--如果同一个时间段内存在冲销都不传
			DELETE a FROM SAP_Interface_PPMES0003 a INNER JOIN #TEMP1 b ON a.ZComnum=b.ZComnum
			DELETE a FROM SAP_Interface_PPMES0003 a INNER JOIN #TEMP1 b ON a.ZComnum=b.ZComnum
		END
		DECLARE @UniqueCode varchar(50)
		WHILE EXISTS(SELECT * FROM SAP_Interface_PPMES0003 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL)
		BEGIN
			DECLARE @LastOrderNo varchar(50)
			SET @UniqueCode=REPLACE(NEWID(),'-','')
			UPDATE TOP(5000) SAP_Interface_PPMES0003 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			SELECT TOP 1 @LastOrderNo=ZMESSC FROM SAP_Interface_PPMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			PRINT @LastOrderNo
			IF EXISTS(SELECT 1 FROM SAP_Interface_PPMES0003 WHERE BatchNo=@BatchNo AND UniqueCode=@UniqueCode AND ZMESSC=@LastOrderNo )
			BEGIN
				UPDATE SAP_Interface_PPMES0003 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND ZMESSC=@LastOrderNo
			END
		END
		SELECT Status=1,BatchNo=@BatchNo,'生成废品报工数据成功。'
END