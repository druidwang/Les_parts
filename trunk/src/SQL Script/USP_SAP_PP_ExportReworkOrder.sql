USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_PP_ExportReworkOrder]    Script Date: 12/08/2014 10:33:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_SAP_PP_ExportReworkOrder]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
BEGIN
	----返工的产品料号和投入料号设置为一样，SAP同时需要者两个信息创建订单	----0001
	SET NOCOUNT ON
	DECLARE @CurrDate datetime=GETDATE()
	Declare @ExecutionTime  datetime = @CurrDate--varchar(20)=dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS')
	Declare @WERKS varchar(50)
	Declare @ZMESGUID varchar(50)=dbo.FormatDate(GETDATE(),'YYYYMMDDHHNNSS0000')
	Select @WERKS=Value from SYS_EntityPreference where Id = 90107
	--select @ExecutionTime,@ExecutionTime,@StartTime,@EndTime 
	--?????一个问题是等所有PPMES_0001全部都收集好之后再更新UniqueCode还是每一个部分（炼胶，挤出，后加工）收集好就更新
	----ISM传0还是''
	----正常返工单
	Insert into SAP_Interface_PPMES0001(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, BWART_H, 
		LGORT_H, ERFMG_H, ZComnum, LMNGA_H, ISM, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType)
		Select MiscOrdMstr.MiscOrderNo As ZMESSC,MiscOrdDet.Seq As ZMESLN,'BUSFG02' As ZPTYPE,
			'SY04' As AUFART,@WERKS As WERKS,MiscOrdDet.Item As MATNR_H,--0001....
			Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) As GAMNG_H,MiscOrdDet.BaseUom As GMEIN_H,MiscOrdMstr.CreateDate As GLTRP,
			MiscOrdMstr.CreateDate As GSTRP,MiscOrdMstr.EffDate As BLDAT,
			MiscOrdMstr.CloseDate As BUDAT,MiscOrdMstr.MiscOrderNo As LFSNR,Case when MiscOrdMstr.MoveType ='261' then '101' else '102' End As BWART_H ,
			isnull(MiscOrdDet.Location,MiscOrdMstr.Location) As LGORT_H,Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) As ERFMG_H,
			MiscOrdMstr.MiscOrderNo+right('00'+CAST(MiscOrdDet.Seq As varchar(10)),2) As ZComnum,
			Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) As LMNGA_H,0 As ISM,MiscOrdMstr.MoveType As BWART_I,MiscOrdDet.Item As MATNR_I,
			Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) As ERFMG_I,MiscOrdDet.BaseUom As GMEIN_I,isnull(MiscOrdDet.Location,MiscOrdMstr.Location) As LGORT_I,
			@ZMESGUID As ZMESGUID,@ExecutionTime As ZCSRQSJ ,@BatchNo As BatchNo , NULL As UniqueCode,'0' As Status,'RWKOrder' As OrderType
			from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr
			Where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo
			and MiscOrdMstr.SubType=40
			and MiscOrdMstr.MoveType in ('261','262')
			--and MiscOrdMstr.Status=1
			and MiscOrdMstr.CloseDate>@StartTime AND MiscOrdMstr.CloseDate<=@EndTime
			and MiscOrdMstr.CreateUser<>3910
	Insert into SAP_Interface_PPMES0001(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, BWART_H, 
		LGORT_H, ERFMG_H, ZComnum, LMNGA_H, ISM, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType)	
		Select MiscOrdMstr.MiscOrderNo As ZMESSC,MiscOrdDet.Seq As ZMESLN,'BUSFG01' As ZPTYPE,
			'SY04' As AUFART,@WERKS As WERKS,MiscOrdDet.Item As MATNR_H,--0001....
			Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) As GAMNG_H,MiscOrdDet.BaseUom As GMEIN_H,MiscOrdMstr.CreateDate As GLTRP,
			MiscOrdMstr.CreateDate As GSTRP,MiscOrdMstr.EffDate As BLDAT,
			MiscOrdMstr.CloseDate As BUDAT,MiscOrdMstr.MiscOrderNo As LFSNR,MiscOrdMstr.MoveType As BWART_H ,
			isnull(MiscOrdDet.Location,MiscOrdMstr.Location) As LGORT_H,Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) As ERFMG_H,
			MiscOrdMstr.MiscOrderNo+right('00'+CAST(MiscOrdDet.Seq As varchar(10)),2) As ZComnum,
			Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) As LMNGA_H,0 As ISM,Case when MiscOrdMstr.MoveType ='101' then '261' else '262' End As BWART_I,MiscOrdDet.Item As MATNR_I,
			Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) As ERFMG_I,MiscOrdDet.BaseUom As GMEIN_I,isnull(MiscOrdDet.Location,MiscOrdMstr.Location) As LGORT_I,
			@ZMESGUID As ZMESGUID,@ExecutionTime As ZCSRQSJ ,@BatchNo As BatchNo , NULL As UniqueCode,'0' As Status,'RWKOrder' As OrderType
			from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr
			Where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo
			and MiscOrdMstr.SubType=40
			and MiscOrdMstr.MoveType in ('101','102')
			--and MiscOrdMstr.Status=1 
			and MiscOrdMstr.CloseDate>@StartTime AND MiscOrdMstr.CloseDate<=@EndTime
			and MiscOrdMstr.CreateUser<>3910
	/*Insert into SAP_Interface_PPMES0001(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, BWART_H, 
		LGORT_H, ERFMG_H, ZComnum, LMNGA_H, ISM, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType)
		Select MiscOrdMstr.MiscOrderNo As ZMESSC,MiscOrdDet.Seq As ZMESLN,'BUSFG02' As ZPTYPE,
			'SY04' As AUFART,@WERKS As WERKS,MiscOrdDet.Item As MATNR_H,
			Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) As GAMNG_H,MiscOrdDet.BaseUom As GMEIN_H,MiscOrdMstr.CreateDate As GLTRP,
			MiscOrdMstr.CreateDate As GSTRP,MiscOrdMstr.EffDate As BLDAT,
			MiscOrdMstr.EffDate As BUDAT,'' As LFSNR,MiscOrdMstr.MoveType As BWART_H ,
			MiscOrdMstr.Location As LGORT_H,Left(cast(abs(MiscOrdDet.Qty*MiscOrdDet.UnitQty ) As varchar),13) As ERFMG_H,
			MiscOrdMstr.MiscOrderNo+right('00'+CAST(MiscOrdDet.Seq As varchar(10)),2) As ZComnum,
			Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) As LMNGA_H,0 As ISM,MiscOrdMstr.MoveType As BWART_I,'' As MATNR_I,
			'' As ERFMG_I,'' As GMEIN_I,'' As LGORT_I,@ZMESGUID As ZMESGUID,@ExecutionTime As ZCSRQSJ ,@BatchNo As BatchNo , 
			NULL As UniqueCode,'0' As Status,'RWKOrder' As OrderType
			from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr
			Where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo
			and MiscOrdMstr.SubType=40
			and MiscOrdMstr.MoveType in ('101','102')
			and MiscOrdMstr.Status =1
			and MiscOrdDet.CreateDate between @StartTime and @EndTime */	
	----冲销
	Insert into SAP_Interface_PPMES0002(ZMESSC, ZMESLN, ZPTYPE, ZComnum, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType,CancelDate)
		Select MiscOrdMstr.MiscOrderNo As ZMESSC,MiscOrdDet.Seq As ZMESLN,'BUSCX01' As ZPTYPE,
			MiscOrdMstr.MiscOrderNo+right('00'+CAST(MiscOrdDet.Seq As varchar(10)),2) As ZComnum,
			@ZMESGUID As ZMESGUID,@ExecutionTime As ZCSRQSJ,@BatchNo As BatchNo , 
			NULL As UniqueCode,'0' As Status,'RWKOrder' As OrderType,MiscOrdMstr.LastModifyDate
			from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr
			Where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo
			and MiscOrdMstr.SubType=40
			and MiscOrdMstr.MoveType in ('101','261','102','262')
			and MiscOrdMstr.Status=2
			----
			and MiscOrdMstr.CancelDate>@StartTime AND MiscOrdMstr.CancelDate<=@EndTime
			and MiscOrdMstr.CancelUser<>3910
	--更新SAP 库位
	Update a
		Set a.LGORT_H=b.SAPLocation from SAP_Interface_PPMES0001 a, MD_Location b where a.LGORT_H=b.Code and a.ZCSRQSJ=@ExecutionTime
	Update a
		Set a.LGORT_I=b.SAPLocation from SAP_Interface_PPMES0001 a, MD_Location b where a.LGORT_I=b.Code and a.ZCSRQSJ=@ExecutionTime
	---Update UniqueCode	
		--Delete ,Update在测试阶段启用下面的代码，测试完后要把所有存储整合在一起，一起更新
		Update SAP_Interface_PPMES0001 Set MTSNR =LFSNR where BatchNo =@BatchNo 
			
		SELECT s1.ZComnum INTO #TEMP1 FROM SAP_Interface_PPMES0001 s1 
			INNER JOIN SAP_Interface_PPMES0002 s2 ON s1.ZComnum=s2.ZComnum
			WHERE s1.BatchNo=@BatchNo AND s2.BatchNo=@BatchNo
			And s1.ZPTYPE in('BUSFG01','BUSFG02')
		
		IF @@ROWCOUNT>0
		BEGIN
			--如果同一个时间段内存在冲销都不传
			DELETE a FROM SAP_Interface_PPMES0001 a INNER JOIN #TEMP1 b ON a.ZComnum=b.ZComnum
			DELETE a FROM SAP_Interface_PPMES0002 a INNER JOIN #TEMP1 b ON a.ZComnum=b.ZComnum
		END
		
		DECLARE @UniqueCode varchar(50)
		WHILE EXISTS(SELECT * FROM SAP_Interface_PPMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL)
		BEGIN
			DECLARE @LastOrderNo varchar(50)
			SET @UniqueCode=REPLACE(NEWID(),'-','')
			UPDATE TOP(5000) SAP_Interface_PPMES0001 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			SELECT TOP 1 @LastOrderNo=ZMESSC FROM SAP_Interface_PPMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			PRINT @LastOrderNo
			IF EXISTS(SELECT 1 FROM SAP_Interface_PPMES0001 WHERE BatchNo=@BatchNo AND UniqueCode=@UniqueCode AND ZMESSC=@LastOrderNo )
			BEGIN
				UPDATE SAP_Interface_PPMES0001 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND ZMESSC=@LastOrderNo
			END
		END
		WHILE EXISTS(SELECT * FROM SAP_Interface_PPMES0002 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL)
		BEGIN
			SET @UniqueCode=REPLACE(NEWID(),'-','')
			UPDATE TOP(5000) SAP_Interface_PPMES0002 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			SELECT TOP 1 @LastOrderNo=ZMESSC FROM SAP_Interface_PPMES0002 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			PRINT @LastOrderNo
			IF EXISTS(SELECT 1 FROM SAP_Interface_PPMES0002 WHERE BatchNo=@BatchNo AND UniqueCode=@UniqueCode AND ZMESSC=@LastOrderNo )
			BEGIN
				UPDATE SAP_Interface_PPMES0002 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND ZMESSC=@LastOrderNo
			END
		END
	SELECT Status=1,BatchNo=@BatchNo,'生成返工单数据成功。'
END