USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_PP_ExportMIFilterOrder]    Script Date: 12/08/2014 10:33:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_SAP_PP_ExportMIFilterOrder]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
BEGIN
	SET NOCOUNT ON
	--######
	--过滤-收集数据的时间段内既有增重也有减轻的话，要汇总下看是增重还是减轻
	--SAP端:ZMESGUID+MES单号+ZColumn
	--好像没问题,需继续确认	,目前先给一个不同的ZGUID								-----0001
	--2014/06/17	OrderDet相同的料有多条明细这里Join会有重叠	----0002
	--2014/06/26	补传过滤必须的MES订单号	----0003
	--2014/08/16	BomDet被光,BackFlush没有记录的处理方式----0004
	--2014/08/17	找不到订单的走SY05 ----0005
	--2014/10/27	翻箱后过滤MAXT:[物料号]翻箱后过滤差异--0006


	--######
	DECLARE @CurrDate datetime=GETDATE()
	Declare @ExecutionTimeStr  datetime = @CurrDate--varchar(20)=dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS')
	Declare @WERKS varchar(50)
	Declare @ZMESGUID varchar(50)=dbo.FormatDate(GETDATE(),'YYYYMMDDHHNNSS0000')
	Select @WERKS=Value from SYS_EntityPreference where Id = 90107
	--select @ExecutionTime,@ExecutionTimeStr,@StartTime,@EndTime 
	--?????一个问题是等所有PPMES_0001全部都收集好之后再更新UniqueCode还是每一个部分（炼胶，挤出，后加工）收集好就更新
	----正常收货

	Insert into SAP_Interface_PPMES0004(ZMESSC, ZMESLN, ZPTYPE, BWART_H, LGORT_H, ERFMG_H,BLDAT,BUDAT, ZComnum, LMNGA_H, XMNGA,GRUND, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,LFSNR,Item)
		Select Distinct OrdDet.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSGL01' As ZPTYPE,Case when ItemEx.Qty*ItemEx.UnitQty >ItemEx.NewQty*ItemEx.NewUnitQty then '102' else '101' End As BWART_H,
			ItemEx.LocationTo As LGORT_H,Left(cast(abs(ItemEx.NewQty*ItemEx.NewUnitQty-ItemEx.Qty*ItemEx.UnitQty) As varchar),13) As ERFMG_H,
			ItemEx.EffDate As BLDAT,ItemEx.EffDate As BUDAT,
			'RF'+Right('0000000000'+CAST(ItemEx.Id As varchar(10)),10) As ZComnum,
			Left(cast(case when ItemEx.NewQty*ItemEx.NewUnitQty-ItemEx.Qty*ItemEx.UnitQty<0 then 0 else ItemEx.NewQty*ItemEx.NewUnitQty-ItemEx.Qty*ItemEx.UnitQty End As varchar),13) As LMNGA_H,
			Left(cast(case when ItemEx.Qty*ItemEx.UnitQty-ItemEx.NewQty*ItemEx.NewUnitQty <0 then 0 else ItemEx.Qty*ItemEx.UnitQty-ItemEx.NewQty*ItemEx.NewUnitQty End As varchar),13) As XMNGA ,
			Case when ItemEx.Qty*ItemEx.UnitQty>ItemEx.NewQty*ItemEx.NewUnitQty then 'MES11' Else '' End As GRUND,
			----0001 Begin
			@ZMESGUID As ZMESGUID,
			----
			GETDATE() As ZCSRQSJ 
			----0001 End
			,@BatchNo As BatchNo , NULL As UniqueCode,'0' As Status,InvHu.RecNo,ItemEx.ItemFrom
			from INV_Hu InvHu,INV_ItemExchange ItemEx,ORD_OrderDet_4 OrdDet ,ORD_RecDet_4 RecDet
			where InvHu.HuId = ItemEx.OldHu 
			and InvHu.OrderNo=OrdDet.OrderNo 
			and InvHu.Item=OrdDet.Item
			and ItemEx.ItemExchangeType=2
			and InvHu.RecNo =RecDet.RecNo 
			and InvHu.Item =RecDet.Item 
			and OrdDet.Id =RecDet.OrderDetId 
			--and ItemEx.IsVoid=0
			and ItemEx.CreateDate>@StartTime AND ItemEx.CreateDate<=@EndTime
			and ItemEx.CreateUser <> 3910 
			--and Not ItemEx.LastModifyDate between @StartTime and @EndTime
	Insert into SAP_Interface_PPMES0002(ZMESSC, ZMESLN, ZPTYPE, ZComnum, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType,CancelDate)
		Select Distinct OrdDet.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSCX01' As ZPTYPE,
			'RF'+Right('0000000000'+CAST(ItemEx.Id As varchar(10)),10) As ZComnum,
			@ZMESGUID As ZMESGUID,
			----0001 Begin
			GETDATE() As ZCSRQSJ ,
			@BatchNo As BatchNo , 
			----0001 End
			NULL As UniqueCode,'0' As Status,'FilterOrder' AS OrderType,ItemEx.LastModifyDate
			from INV_Hu InvHu,INV_ItemExchange ItemEx,ORD_OrderDet_4 OrdDet ,ORD_RecDet_4 RecDet
			where InvHu.HuId = ItemEx.OldHu 
			and InvHu.OrderNo=OrdDet.OrderNo 
			and InvHu.Item=OrdDet.Item
			and ItemEx.ItemExchangeType=2
			and InvHu.RecNo =RecDet.RecNo 
			and InvHu.Item =RecDet.Item 
			and OrdDet.Id =RecDet.OrderDetId 
			and ItemEx.IsVoid=1
			and ItemEx.LastModifyDate>@StartTime AND ItemEx.LastModifyDate<=@EndTime
			and ItemEx.LastModifyUser<> 3910 
	--0002Begin
	Delete a from  (Select *,ROW_NUMBER()over(partition by zmessc,zptype,bwart_h,lgort_h,zcomnum order by zmesln) As NONO 
		from SAP_Interface_PPMES0004 where BatchNo =@BatchNo) a 
		--where NONO =2
		where NONO !=1
	--0002End

	Update a
		Set a.LGORT_H=b.SAPLocation from SAP_Interface_PPMES0004 a, MD_Location b where a.LGORT_H=b.Code and a.BatchNo=@BatchNo
	--0003Begin
	--即没有变轻也没变重的筛选掉
	Delete from SAP_Interface_PPMES0004 where BatchNo =@BatchNo and Cast(ERFMG_H As Float)=0
	--
		Select distinct ZMESSC As OrderNO ,ZMESLN As ZMESLN into #OrderNO from SAP_Interface_PPMES0004 a
			where BatchNo =@BatchNo and not Exists (select 0 from SAP_Interface_PPMES0001 b where a.ZMESSC=b.ZMESSC and a.ZMESLN=b.ZMESLN)
	 Select top 0 * into #SAP_Interface_PPMES0001_Tmp from SAP_Interface_PPMES0001 where 1=2
		Insert into #SAP_Interface_PPMES0001_Tmp(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, BWART_H, 
			LGORT_H, ERFMG_H, ZComnum, LMNGA_H, ISM, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType,TailQty)
			Select distinct OrdMstr.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSCO01' As ZPTYPE,'SY01' As AUFART,@WERKS As WERKS,OrdDet.Item As MATNR_H,
				Left(Cast(OrdDet.OrderQty As varchar),13) As GAMNG_H,OrdDet.BaseUom As GMEIN_H,OrdMstr.WindowTime As GLTRP,
				OrdMstr.StartTime As GSTRP,OrdMstr.EffDate As BLDAT,
				OrdMstr.CreateDate As BUDAT,RecMstr.RecNo As LFSNR,Case when RecDet.RecQty*RecDet.UnitQty >0 then '101' else '102' End As BWART_H ,
				OrdDet.LocTo As LGORT_H,'0' As ERFMG_H,RecMstr.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) As ZComnum,
				'0' As LMNGA_H,'' As ISM,Case when 1=1 then  '261' else '262' End As BWART_I,BFDet.Item As MATNR_I,
				'0' As ERFMG_I,BFDet.BaseUom As GMEIN_I,BFDet.LocFrom As LGORT_I,
				@ZMESGUID As ZMESGUID,GETDATE() As ZCSRQSJ ,@BatchNo As BatchNo , NULL As UniqueCode,'0' As Status,'HistoryMIOrder',
				'0' As TailQty
				from ORD_RecDet_4 RecDet,ORD_RecMstr_4 RecMstr,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr,ORD_OrderBackflushDet BFDet,#OrderNO OrderNO
				Where RecDet.OrderDetId = OrdDet.Id 
				and RecDet.RecNo = RecMstr.RecNo 
				and OrdDet.OrderNo = OrdMstr.OrderNo 
				and RecDet.Id = BFDet.RecDetId
				and OrdMstr.ResourceGroup = 10
				and OrdMstr.SubType= 0
				and BFDet.IsVoid=0
				and OrdDet.OrderNo=OrderNO.OrderNO
				and OrdDet.Seq=OrderNO.ZMESLN
				--and OrdDet.Seq =1
				and OrdMstr.OrderNo in (select OrderNo from #OrderNO)
		--0004Begin	
		Select distinct ZMESSC As OrderNO ,ZMESLN As ZMESLN into #OrderNO1 from SAP_Interface_PPMES0004 a
			where BatchNo =@BatchNo and not Exists (select 0 from SAP_Interface_PPMES0001 b where a.ZMESSC=b.ZMESSC and a.ZMESLN=b.ZMESLN)
		If @@ROWCOUNT!=0
		Begin
		Insert into #SAP_Interface_PPMES0001_Tmp(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, BWART_H, 
			LGORT_H, ERFMG_H, ZComnum, LMNGA_H, ISM, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType,TailQty)
			Select distinct OrdMstr.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSCO01' As ZPTYPE,'SY01' As AUFART,@WERKS As WERKS,OrdDet.Item As MATNR_H,
				Left(Cast(OrdDet.OrderQty As varchar),13) As GAMNG_H,OrdDet.BaseUom As GMEIN_H,OrdMstr.WindowTime As GLTRP,
				OrdMstr.StartTime As GSTRP,OrdMstr.EffDate As BLDAT,
				OrdMstr.CreateDate As BUDAT,RecMstr.RecNo As LFSNR,Case when RecDet.RecQty*RecDet.UnitQty >0 then '101' else '102' End As BWART_H ,
				OrdDet.LocTo As LGORT_H,'0' As ERFMG_H,RecMstr.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) As ZComnum,
				'0' As LMNGA_H,'' As ISM,Case when 1=1 then  '261' else '262' End As BWART_I,'' As MATNR_I,
				'0' As ERFMG_I,'' As GMEIN_I,'' As LGORT_I,
				@ZMESGUID As ZMESGUID,GETDATE() As ZCSRQSJ ,@BatchNo As BatchNo , NULL As UniqueCode,'0' As Status,'HistoryMIOrder',
				'0' As TailQty
				from ORD_RecDet_4 RecDet,ORD_RecMstr_4 RecMstr,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr,#OrderNO1 OrderNO1 
				Where RecDet.OrderDetId = OrdDet.Id 
				and RecDet.RecNo = RecMstr.RecNo 
				and OrdDet.OrderNo = OrdMstr.OrderNo 
				and OrdMstr.ResourceGroup = 10
				and OrdMstr.SubType= 0
				and OrdDet.OrderNo=OrderNO1.OrderNO
				and OrdDet.Seq=OrderNO1.ZMESLN
		Select * into #PRD_BomDet from PRD_BomDet with(nolock) 
			where Bom in (select MATNR_H from #SAP_Interface_PPMES0001_Tmp where GMEIN_I='')
			and (StartDate is null or  StartDate<@CurrDate) 
			and (EndDate is null or  EndDate>@CurrDate) 
		Update a
			Set a.MATNR_I=b.Item,a.GMEIN_I=b.Uom,LGORT_I=LGORT_H 
			from #SAP_Interface_PPMES0001_Tmp a , #PRD_BomDet b 
			where a.MATNR_H=b.Bom  and GMEIN_I=''
		End
		--0004End	
		Delete a from (Select *,ROW_NUMBER()Over (partition by ZMESSC,ZMESLN Order by ZComnum) As NONO  from #SAP_Interface_PPMES0001_Tmp) a where a.NONO !=1
		Declare @NewBatchNo varchar(200)= replace(newID(),'-','')
		Update a
			Set a.LGORT_H=b.SAPLocation,UniqueCode =@NewBatchNo from #SAP_Interface_PPMES0001_Tmp a, MD_Location b where a.LGORT_H=b.Code  
		Update a
			Set a.LGORT_I=b.SAPLocation,UniqueCode =@NewBatchNo from #SAP_Interface_PPMES0001_Tmp a, MD_Location b where a.LGORT_I=b.Code  
		Update #SAP_Interface_PPMES0001_Tmp Set MTSNR =LFSNR 
		Insert into SAP_Interface_PPMES0001(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, LFSNR,MTSNR, BWART_H, 
			LGORT_H, ERFMG_H, ZComnum, LMNGA_H, ISM, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType,TailQty)
			Select Distinct ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, LFSNR,MTSNR, BWART_H, 
				LGORT_H, ERFMG_H, Replace(ZComnum,'R','S'), LMNGA_H, ISM, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, 
				UniqueCode, Status,OrderType,TailQty from #SAP_Interface_PPMES0001_Tmp
	--0003End
	----0005
	If Exists(select 0 from INV_ItemExchange ItemEx left join INV_Hu InvHu on InvHu.HuId = ItemEx.OldHu
			where ItemEx.ItemExchangeType=2 and InvHu.OrderNo is null
			and ItemEx.Qty !=ItemEx.NewQty
			and ItemEx.CreateDate>@StartTime AND ItemEx.CreateDate<=@EndTime)
			Begin
				Insert into SAP_Interface_PPMES0005(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, 
						ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,TailQty)
					Select 'RF'+Right('0000000000'+CAST(ItemEx.Id As varchar(10)),10) As ZMESSC,'1' As ZMESLN ,'BUSTZ01' As ZPTYPE,'SY05' As AUFART,'8000' As WERKS,
						ItemEx.ItemFrom + '翻箱后过滤差异' As MATXT/*--0006*/ ,'1' As GAMNG_H,InvHu.BaseUom As GMEIN_H,ItemEx.EffDate As GLTRP,ItemEx.EffDate As GSTRP,ItemEx.EffDate As BLDAT,ItemEx.EffDate As BUDAT,
						Case when ItemEx.Qty*ItemEx.UnitQty >ItemEx.NewQty*ItemEx.NewUnitQty then '261' else '262' End As BWART_I,InvHu.Item As MATNR_I,
						Left(cast(abs(ItemEx.NewQty*ItemEx.NewUnitQty-ItemEx.Qty*ItemEx.UnitQty) As varchar),13) As ERFMG_I,InvHu.BaseUom As GMEIN_I,ML.SAPLocation As LGORT_I
						,dbo.FormatDate(GETDATE(),'YYYYMMDDHHNNSS0000') As ZMESGUID,GETDATE() As ZCSRQSJ 
						----0001 End
						,@BatchNo As BatchNo , @BatchNo As UniqueCode,'0' As Status,'0' As TailQty
						from INV_ItemExchange ItemEx left join INV_Hu InvHu on InvHu.HuId = ItemEx.OldHu
						inner join MD_Location ML on ItemEx.LocationFrom=ML.Code
						where ItemEx.ItemExchangeType=2 and InvHu.OrderNo is null
						and ItemEx.Qty !=ItemEx.NewQty
						and ItemEx.CreateDate>@StartTime AND ItemEx.CreateDate<=@EndTime
						and ItemEx.CreateUser<> 3910 
			End
	Insert into SAP_Interface_PPMES0002(ZMESSC, ZMESLN, ZPTYPE, ZComnum, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType,CancelDate)		
		Select  'RF'+Right('0000000000'+CAST(ItemEx.Id As varchar(10)),10) As ZMESSC,'1' As ZMESLN ,'BUSCX01' As ZPTYPE,'' As ZComnum,
			@ZMESGUID,@CurrDate,@BatchNo,@BatchNo As UniqueCode,
			'0' AS Status, 'AdjustOrder' As OrderType,ItemEx.LastModifyDate
			from INV_ItemExchange ItemEx left join INV_Hu InvHu on InvHu.HuId = ItemEx.OldHu
			inner join MD_Location ML on ItemEx.LocationFrom=ML.Code
			where ItemEx.ItemExchangeType=2 and InvHu.OrderNo is null
			and ItemEx.Qty !=ItemEx.NewQty
			and ItemEx.IsVoid=1
			and ItemEx.LastModifyDate>@StartTime AND ItemEx.LastModifyDate<=@EndTime
			and ItemEx.LastModifyUser<> 3910 
	----0005
	---Update UniqueCode	
		--Delete ,Update在测试阶段启用下面的代码，测试完后要把所有存储整合在一起，一起更新
		SELECT s1.ZComnum INTO #TEMP1 FROM SAP_Interface_PPMES0004 s1 
			INNER JOIN SAP_Interface_PPMES0002 s2 ON s1.ZComnum=s2.ZComnum
			WHERE s1.BatchNo=@BatchNo AND s2.BatchNo=@BatchNo
		
		IF @@ROWCOUNT>0
		BEGIN
			--如果同一个时间段内存在冲销都不传
			DELETE a FROM SAP_Interface_PPMES0004 a INNER JOIN #TEMP1 b ON a.ZComnum=b.ZComnum
			DELETE a FROM SAP_Interface_PPMES0002 a INNER JOIN #TEMP1 b ON a.ZComnum=b.ZComnum
		END
		SELECT s1.ZMESSC INTO #TEMP2 FROM SAP_Interface_PPMES0005 s1 
			INNER JOIN SAP_Interface_PPMES0002 s2 ON s1.ZMESSC=s2.ZMESSC
			WHERE s1.BatchNo=@BatchNo AND s2.BatchNo=@BatchNo
		
		IF @@ROWCOUNT>0
		BEGIN
			--如果同一个时间段内存在冲销都不传
			DELETE a FROM SAP_Interface_PPMES0005 a INNER JOIN #TEMP2 b ON a.ZMESSC=b.ZMESSC
			DELETE a FROM SAP_Interface_PPMES0002 a INNER JOIN #TEMP2 b ON a.ZMESSC=b.ZMESSC
		END
		DECLARE @UniqueCode varchar(50)
		WHILE EXISTS(SELECT * FROM SAP_Interface_PPMES0004 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL)
		BEGIN
			DECLARE @LastOrderNo varchar(50)
			SET @UniqueCode=REPLACE(NEWID(),'-','')
			UPDATE TOP(5000) SAP_Interface_PPMES0004 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			SELECT TOP 1 @LastOrderNo=ZMESSC FROM SAP_Interface_PPMES0004 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			PRINT @LastOrderNo
			IF EXISTS(SELECT 1 FROM SAP_Interface_PPMES0004 WHERE BatchNo=@BatchNo AND UniqueCode=@UniqueCode AND ZMESSC=@LastOrderNo )
			BEGIN
				UPDATE SAP_Interface_PPMES0004 Set UniqueCode=@UniqueCode,ZMESGUID =@ZMESGUID WHERE BatchNo=@BatchNo AND ZMESSC=@LastOrderNo
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
	----即没变重也没变轻的过滤冲销不传
	Update SAP_Interface_PPMES0002
	Set Status ='1' from SAP_Interface_PPMES0002 where OrderType ='FilterOrder' and ZComnum not in(select ZComnum from SAP_Interface_PPMES0004) and BatchNo =@BatchNo

	SELECT Status=1,BatchNo=@BatchNo,'生成过滤数据成功。'
END