USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_PP_ExportTrailMiscOrder]    Script Date: 12/08/2014 10:33:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_SAP_PP_ExportTrailMiscOrder]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @CurrDate datetime=GETDATE()
	Declare @ExecutionTime datetime = @CurrDate-- varchar(20)=dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS')
	Declare @WERKS varchar(50)
	Declare @ZMESGUID varchar(50)=dbo.FormatDate(GETDATE(),'YYYYMMDDHHNNSS0000')
	Select @WERKS=Value from SYS_EntityPreference where Id = 90107
	--select @ExecutionTime,@ExecutionTime,@StartTime,@EndTime 
	--?????一个问题是等所有PPMES_0001全部都收集好之后再更新UniqueCode还是每一个部分（炼胶，挤出，后加工）收集好就更新
	----正常试制单 Create = 0, Close = 1, Cancel = 2  数量
	----Note字段保存SAP订单号
	Insert into SAP_Interface_PPMES0006(ZMESSC, ZMESLN, ZPTYPE, AUFNR,WERKS, ZComnum, LMNGA_H, ISM, BWART,BLDAT,BUDAT, 
		NPLNR, VORNR, RSNUM, RSPOS, MATNR1,MTSNR,LFSNR, EPFMG, ERFME,LGORT, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status)
		Select MiscOrdMstr.MiscOrderNo As ZMESSC, MiscOrdDet.Seq as ZMESLN, 'BUSSZ01' as ZPTYPE, Isnull(MiscOrdMstr.Note,'') as AUFNR,@WERKS As WERKS,
			MiscOrdMstr.MiscOrderNo+right('00'+CAST(MiscOrdDet.Seq As varchar(10)),2) As ZComnum,
			Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) as LMNGA_H, Left(Cast (MiscOrdDet.WorkHour As varchar),13) as ISM, MiscOrdMstr.MoveType As BWART,
			MiscOrdMstr.EffDate As BLDAT,MiscOrdMstr.CloseDate As BUDAT,  
			Isnull(left(MiscOrdMstr.WBS,abs(CHARINDEX('/',ISNULL(MiscOrdMstr.WBS,''),1)-1)),'') as NPLNR, 
			Isnull(right(MiscOrdMstr.WBS,len(MiscOrdMstr.WBS)-CHARINDEX('/',ISNULL(MiscOrdMstr.WBS,''),1)),'') as VORNR, isnull(MiscOrdDet.ReserveNo,'') as RSNUM,
			isnull(MiscOrdDet.ReserveLine,'') as RSPOS, MiscOrdDet.Item as MATNR1,MiscOrdMstr.MiscOrderNo As MTSNR,MiscOrdMstr.MiscOrderNo As LFSNR, Left(cast(MiscOrdDet.Qty*MiscOrdDet.UnitQty As varchar),13) as EPFMG,
			MiscOrdDet.BaseUom as ERFME,MiscOrdMstr.Location As LGORT, @ZMESGUID as ZMESGUID, @ExecutionTime as ZCSRQSJ, @BatchNo as BatchNo , NULL As UniqueCode,  '0' as Status
			from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr
			Where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo
			and MiscOrdMstr.SubType=30
			and MiscOrdMstr.MoveType in ('281','282','581','582')
			and Status =1
			--and MiscOrdMstr.Flow not in ('FI51','FI51A')
			and MiscOrdMstr.CloseDate > @StartTime and MiscOrdMstr.CloseDate<=@EndTime 	
			and MiscOrdMstr.CloseUser<>3910
	--更新SAP 库位
	Update a
		Set a.LGORT=b.SAPLocation from SAP_Interface_PPMES0006 a, MD_Location b where a.LGORT=b.Code and a.BatchNo =@BatchNo and ZCSRQSJ =@ExecutionTime
	Delete SAP_Interface_PPMES0006 where LGORT='N/A' and BatchNo=@BatchNo
	--暂时先这样，须到程式里找bug
	Update SAP_Interface_PPMES0006 Set VORNR=replace(VORNR,'undefined',''),NPLNR=replace(NPLNR,'undefined','') where  BatchNo=@BatchNo
	/*----试制单冲销???业务类别BUSFP01
	Insert into SAP_Interface_PPMES0002
		Select MiscOrdDet.MiscOrderNo As ZMESSC,MiscOrdDet.Seq As ZMESLN,'BUSFP01' As ZPTYPE,
			MiscOrdMstr.MiscOrderNo+right('00'+CAST(MiscOrdDet.Seq As varchar(10)),2) As ZComnum,
			NewId() As ZMESGUID,@ExecutionTime As ZCSRQSJ ,@BatchNo as BatchNo , NULL As UniqueCode,'0' As Status
			from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr
			Where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo
			and MiscOrdMstr.SubType=30
			and MiscOrdMstr.MoveType in ('281','282','581','582')
			and Status = 2
			and MiscOrdDet.LastModifyDate between @StartTime and @EndTime */	
	---Update UniqueCode	
	--Update MES0004
		--Update MES0001测试完后要删除下面的代码，把所有存储整合在一起
		DECLARE @UniqueCode varchar(50)
		WHILE EXISTS(SELECT * FROM SAP_Interface_PPMES0006 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL)
		BEGIN
			DECLARE @LastOrderNo varchar(50)
			SET @UniqueCode=REPLACE(NEWID(),'-','')
			UPDATE TOP(5000) SAP_Interface_PPMES0006 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			SELECT TOP 1 @LastOrderNo=ZMESSC FROM SAP_Interface_PPMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			PRINT @LastOrderNo
			IF EXISTS(SELECT 1 FROM SAP_Interface_PPMES0006 WHERE BatchNo=@BatchNo AND UniqueCode=@UniqueCode AND ZMESSC=@LastOrderNo )
			BEGIN
				UPDATE SAP_Interface_PPMES0006 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND ZMESSC=@LastOrderNo
			END
		END
	SELECT Status=1,BatchNo=@BatchNo,'生成试制数据成功。'
 
END