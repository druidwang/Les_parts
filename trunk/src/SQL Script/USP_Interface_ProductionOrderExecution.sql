USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Interface_ProductionOrderExecution]    Script Date: 12/08/2014 15:15:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<>
-- Create date: <2014/03/09>
-- Description:	<Received order information of interface for EX>
--EXEC USP_Interface_ProductionOrderExecution 
-- =============================================
-- EXEC [USP_Interface_ProductionOrderExecution] (Getdate())
ALTER PROCEDURE [dbo].[USP_Interface_ProductionOrderExecution]
(
	@ExecutionTime Datetime
)
AS
BEGIN
	SET NOCOUNT ON;
	--Declare @ExecutionTime datetime = GetDate()
	Declare @EndTime Datetime = dateadd(MINUTE,-0,@ExecutionTime)
	Declare @StartTime Datetime = dateadd(HOUR,-8,@ExecutionTime)
	Declare @ExecutionTimeStr varchar(20)=dbo.FormatDate(@ExecutionTime,'YYYYMMDDHHNNSS')
	Declare @WERKS varchar(50)
	Select @WERKS=Value from SYS_EntityPreference where Id = 90107
	select @ExecutionTime,@ExecutionTimeStr,@StartTime,@EndTime 
	--return
	--Get @StartTime from table SAP_TimeControl
	--.......To do 
	--
	--1. 炼胶正常工单 -- 收货和冲销:SAP_Interface_PPMES0001

	Insert into SAP_Interface_PPMES0001
		Select OrdMstr.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSCO01' As ZPTYPE,OrdDet.ScheduleType As AUFART,@WERKS As WERKS,OrdDet.Item As MATNR_H,
			Left(cast(OrdDet.OrderQty As varchar),13) As GAMNG_H,OrdDet.Uom As GMEIN_H,dbo.FormatDate(OrdMstr.StartDate,'YYYYMMDD')As GLTRP,
			dbo.FormatDate(OrdMstr.WindowTime ,'YYYYMMDD') As GSTRP,dbo.FormatDate(OrdMstr.EffDate ,'YYYYMMDD') As BLDAT,
			dbo.FormatDate(OrdMstr.CreateDate ,'YYYYMMDD') As BUDAT,RecMstr.RecNo As LFSNR,Case when OrdDet.OrderQty >0 then '101' else '102' End As BWART_H ,
			OrdDet.LocTo As LGORT_H,Left(cast(abs(RecDet.RecQty) As varchar),13) As ERFMG_H,RecMstr.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) As ZComnum,
			Left(cast(RecDet.RecQty As varchar),13) As LMNGA_H,'' As ISM,Case when BFDet.BFQty <0 then  '261' else '262' End As BWART_I,BFDet.Item As MATNR_I,
			Left(cast(abs(BFDet.BFQty) As varchar),13) As ERFMG_I,BFDet.Uom As GMEIN_I,BFDet.LocFrom As LGORT_I,NewId() As ZMESGUID,@ExecutionTimeStr As ZCSRQSJ ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from ORD_RecDet_4 RecDet,ORD_RecMstr_4 RecMstr,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr,ORD_OrderBackflushDet BFDet
			Where RecDet.OrderDetId = OrdDet.Id 
			and RecDet.RecNo = RecMstr.RecNo 
			and OrdDet.OrderNo = OrdMstr.OrderNo 
			and RecDet.Id = BFDet.RecDetId
			and OrdMstr.ResourceGroup = 10
			and OrdMstr.SubType= 0
			and RecMstr.Status=0
			and BFDet.IsVoid=0
			and RecDet.CreateDate between @StartTime and @EndTime
			--and Not RecDet.LastModifyDate between @StartTime and @EndTime
	Insert into SAP_Interface_PPMES0002
		Select OrdMstr.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSFP01' As ZPTYPE,
			RecMstr.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) As ZComnum,
			NewId() As ZMESGUID,@ExecutionTimeStr As ZCSRQSJ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from ORD_RecDet_4 RecDet,ORD_RecMstr_4 RecMstr,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr,ORD_OrderBackflushDet BFDet
			Where RecDet.OrderDetId = OrdDet.Id 
			and RecDet.RecNo = RecMstr.RecNo 
			and OrdDet.OrderNo = OrdMstr.OrderNo 
			and RecDet.Id = BFDet.RecDetId
			and OrdMstr.ResourceGroup = 10
			and OrdMstr.SubType= 0
			and RecMstr.Status=1
			and BFDet.IsVoid=1
			and RecDet.LastModifyDate between @StartTime and @EndTime
			--and Not RecDet.CreateDate between @StartTime and @EndTime
			

	--判断如果CreateDateTime & LastModifyDate 都在这个时间段内，需要补一笔101???....
	
	
	--2.过滤:SAP_Interface_PPMES0004
	--?有没有无OrderNo link 的HuID,从去年11月份到现在貌似没见
	--ZMESSC	ZMESLN		ZPTYPE		BWART_H			LGORT_H			RFMG_H			ZComnum			LMNGA_H			XMNGA			ZMESGUID	ZCSRQSJ
	--Hu		OrderDet	XXXXX		XXXXX			ItemExchange	ItemExchange	ItemExchange	ItemExchange	ItemExchange	XXXXX		XXXXX
	--MES订单号	MES行号		业务类别	产品移动类型	产品库位		收货数量		报工单号		确认数量		废品数量		GUID		接口传输日期时间
	Insert into SAP_Interface_PPMES0004
		Select OrdDet.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSGL01' As ZPTYPE,Case when ItemEx.Qty>ItemEx.NewQty then '102' else '101' End As BWART_H,
			ItemEx.LocationTo As LGORT_H,Left(cast(abs(ItemEx.NewQty-ItemEx.Qty) As varchar),13) As RFMG_H,'RF'+Right('0000000000'+CAST(ItemEx.Id As varchar(10)),10) As ZComnum,
			Left(cast(case when ItemEx.NewQty-ItemEx.Qty<0 then 0 else ItemEx.NewQty-ItemEx.Qty End As varchar),13) As LMNGA_H,
			Left(cast(case when ItemEx.Qty-ItemEx.NewQty <0 then 0 else ItemEx.Qty-ItemEx.NewQty End As varchar),13) As XMNGA ,
			NewId() As ZMESGUID,@ExecutionTimeStr As ZCSRQSJ ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from INV_Hu InvHu,INV_ItemExchange ItemEx,ORD_OrderDet_4 OrdDet 
			where InvHu.HuId = ItemEx.OldHu 
			and InvHu.OrderNo=OrdDet.OrderNo 
			and InvHu.Item=OrdDet.Item
			and ItemEx.ItemExchangeType=2
			and ItemEx.IsVoid=0
			and ItemEx.CreateDate between @StartTime and @EndTime
			--and Not ItemEx.LastModifyDate between @StartTime and @EndTime
	Insert into SAP_Interface_PPMES0002
		Select OrdDet.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSFP01' As ZPTYPE,
		'RF'+Right('0000000000'+CAST(ItemEx.Id As varchar(10)),10) As ZComnum,
		NewId() As ZMESGUID,@ExecutionTimeStr As ZCSRQSJ ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from INV_Hu InvHu,INV_ItemExchange ItemEx,ORD_OrderDet_4 OrdDet 
			where InvHu.HuId = ItemEx.OldHu 
			and InvHu.OrderNo=OrdDet.OrderNo 
			and InvHu.Item=OrdDet.Item
			and ItemEx.ItemExchangeType=2
			and ItemEx.IsVoid=1
			and ItemEx.LastModifyDate between @StartTime and @EndTime
			--and Not ItemEx.CreateDate between @StartTime and @EndTime
		
	--3. 挤出正常工单 -- 收货和冲销:SAP_Interface_PPMES0001
	--和炼胶一样,最后根据SAP_EX001更新批次号和订单号
	Insert into SAP_Interface_PPMES0001
		Select OrdMstr.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSCO01' As ZPTYPE,OrdDet.ScheduleType As AUFART,@WERKS As WERKS,OrdDet.Item As MATNR_H,
			Left(cast(OrdDet.OrderQty As varchar),13) As GAMNG_H,OrdDet.Uom As GMEIN_H,dbo.FormatDate(OrdMstr.StartDate,'YYYYMMDD')As GLTRP,
			dbo.FormatDate(OrdMstr.WindowTime ,'YYYYMMDD') As GSTRP,dbo.FormatDate(OrdMstr.EffDate ,'YYYYMMDD') As BLDAT,
			dbo.FormatDate(OrdMstr.CreateDate ,'YYYYMMDD') As BUDAT,RecMstr.RecNo As LFSNR,Case when OrdDet.OrderQty >0 then '101' else '102' End As BWART_H ,
			OrdDet.LocTo As LGORT_H,Left(cast(abs(RecDet.RecQty) As varchar),13) As ERFMG_H,RecMstr.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) As ZComnum,
			Left(cast(RecDet.RecQty As varchar),13) As LMNGA_H,'' As ISM,Case when BFDet.BFQty <0 then  '261' else '262' End As BWART_I,BFDet.Item As MATNR_I,
			Left(cast(abs(BFDet.BFQty) As varchar),13) As ERFMG_I,BFDet.Uom As GMEIN_I,BFDet.LocFrom As LGORT_I,NewId() As ZMESGUID,@ExecutionTimeStr As ZCSRQSJ ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from ORD_RecDet_4 RecDet,ORD_RecMstr_4 RecMstr,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr,ORD_OrderBackflushDet BFDet
			Where RecDet.OrderDetId = OrdDet.Id 
			and RecDet.RecNo = RecMstr.RecNo 
			and OrdDet.OrderNo = OrdMstr.OrderNo 
			and RecDet.Id = BFDet.RecDetId
			and OrdMstr.ResourceGroup = 20
			and OrdMstr.SubType= 0
			and RecMstr.Status=0
			and BFDet.IsVoid=0
			and RecDet.CreateDate between @StartTime and @EndTime
			--and Not RecDet.LastModifyDate between @StartTime and @EndTime
	Insert into SAP_Interface_PPMES0002
		Select OrdMstr.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSFP01' As ZPTYPE,
			RecMstr.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) As ZComnum,
			NewId() As ZMESGUID,@ExecutionTimeStr As ZCSRQSJ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from ORD_RecDet_4 RecDet,ORD_RecMstr_4 RecMstr,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr,ORD_OrderBackflushDet BFDet
			Where RecDet.OrderDetId = OrdDet.Id 
			and RecDet.RecNo = RecMstr.RecNo 
			and OrdDet.OrderNo = OrdMstr.OrderNo 
			and RecDet.Id = BFDet.RecDetId
			and OrdMstr.ResourceGroup = 20
			and OrdMstr.SubType= 0
			and RecMstr.Status=1
			and BFDet.IsVoid=1
			and RecDet.LastModifyDate between @StartTime and @EndTime
			--and not RecDet.CreateDate between @StartTime and @EndTime
		--更新批次号和订单数
		--EXEC dbo.USP_Interface_EX_ReceivedOrder
		UPdate a
			Set a.GAMNG_H=b.OrderQty,a.ZMESSC=b.PlanNo from SAP_Interface_PPMES0001 a,SAP_EX001 b 
				where a.LFSNR=b.RecNo and a.ZCSRQSJ=@ExecutionTimeStr 
				and a.ZCSRQSJ=b.ZCSRQSJ
		--UPdate a--待续
		--	Set a.GAMNG_H=b.OrderQty,a.ZMESSC=b.PlanNo from SAP_Interface_PPMES0002 a,SAP_EX001 b 
		--		where a.LFSNR=b.RecNo and a.ZCSRQSJ=@ExecutionTimeStr 
				--and b.ZCSRQSJ=@ExecutionTimeStr
		--4. 后加工正常工单 -- 收货和冲销:SAP_Interface_PPMES0001
		Insert into SAP_Interface_PPMES0001
			Select OrdMstr.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSCO01' As ZPTYPE,OrdDet.ScheduleType As AUFART,@WERKS As WERKS,OrdDet.Item As MATNR_H,
				Left(cast(OrdDet.OrderQty As varchar),13) As GAMNG_H,OrdDet.Uom As GMEIN_H,dbo.FormatDate(OrdMstr.StartDate,'YYYYMMDD')As GLTRP,
				dbo.FormatDate(OrdMstr.WindowTime ,'YYYYMMDD') As GSTRP,dbo.FormatDate(OrdMstr.EffDate ,'YYYYMMDD') As BLDAT,
				dbo.FormatDate(OrdMstr.CreateDate ,'YYYYMMDD') As BUDAT,RecMstr.RecNo As LFSNR,Case when OrdDet.OrderQty >0 then '101' else '102' End As BWART_H ,
				OrdDet.LocTo As LGORT_H,Left(cast(abs(RecDet.RecQty) As varchar),13) As ERFMG_H,RecMstr.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) As ZComnum,
				Left(cast(RecDet.RecQty As varchar),13) As LMNGA_H,'' As ISM,Case when BFDet.BFQty <0 then  '261' else '262' End As BWART_I,BFDet.Item As MATNR_I,
				Left(cast(abs(BFDet.BFQty) As varchar),13) As ERFMG_I,BFDet.Uom As GMEIN_I,BFDet.LocFrom As LGORT_I,NewId() As ZMESGUID,@ExecutionTimeStr As ZCSRQSJ ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
				from ORD_RecDet_4 RecDet,ORD_RecMstr_4 RecMstr,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr,ORD_OrderBackflushDet BFDet
				Where RecDet.OrderDetId = OrdDet.Id 
				and RecDet.RecNo = RecMstr.RecNo 
				and OrdDet.OrderNo = OrdMstr.OrderNo 
				and RecDet.Id = BFDet.RecDetId
				and OrdMstr.ResourceGroup = 30
				and OrdMstr.SubType= 0
				and RecMstr.Status=0
				and BFDet.IsVoid=0
				and RecDet.CreateDate between @StartTime and @EndTime
				--and Not RecDet.LastModifyDate between @StartTime and @EndTime
	Insert into SAP_Interface_PPMES0002
		Select OrdMstr.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSFP01' As ZPTYPE,
			RecMstr.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) As ZComnum,
			NewId() As ZMESGUID,@ExecutionTimeStr As ZCSRQSJ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from ORD_RecDet_4 RecDet,ORD_RecMstr_4 RecMstr,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr,ORD_OrderBackflushDet BFDet
			Where RecDet.OrderDetId = OrdDet.Id 
			and RecDet.RecNo = RecMstr.RecNo 
			and OrdDet.OrderNo = OrdMstr.OrderNo 
			and RecDet.Id = BFDet.RecDetId
			and OrdMstr.ResourceGroup = 30
			and OrdMstr.SubType= 0
			and RecMstr.Status=1
			and BFDet.IsVoid=1
			and RecDet.LastModifyDate between @StartTime and @EndTime
			
	--****************************************************非正常业务**********************************************************
	--废品报工 :SAP_Interface_PPMES0003
	Select top 1000 * from SAP_Interface_PPMES0003
	Insert into SAP_Interface_PPMES0003
	Select OrdDet.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSBG01' As ZPTYPE,MrpExScrap.ScrapQty As XMNGA,'' As GRUND,
			NewId() As ZMESGUID,'' As ZComnum,@ExecutionTimeStr As ZCSRQSJ ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from MRP_MrpExScrap MrpExScrap,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr
			where MrpExScrap.RefOrderNo=OrdMstr.OrderNo 
			and OrdDet.OrderNo=OrdMstr.OrderNo
			and MrpExScrap.ScrapType in (21,22,23)
			and MrpExScrap.IsVoid=0
			and MrpExScrap.CreateDate between @StartTime and @EndTime 
	Insert into SAP_Interface_PPMES0003
	Select OrdDet.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSBG01' As ZPTYPE,MrpExScrap.ScrapQty As XMNGA,'' As GRUND,
			NewId() As ZMESGUID,RecDet.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) As ZComnu
			,@ExecutionTimeStr As ZCSRQSJ ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from MRP_MrpExScrap MrpExScrap,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr,ORD_RecDet_4 RecDet
			where MrpExScrap.OrderNo=OrdMstr.OrderNo 
			and OrdDet.OrderNo=OrdMstr.OrderNo
			and RecDet.OrderNo=OrdMstr.OrderNo
			and MrpExScrap.IsVoid=0
			and OrdDet.ScheduleType in (24,25)
			and MrpExScrap.CreateDate between @StartTime and @EndTime 
	Insert into SAP_Interface_PPMES0003	
	Select MiscOrdMstr.MiscOrderNo As ZMESSC,MiscOrdDet.Seq As ZMESLN,'BUSBG01' As ZPTYPE,MiscOrdDet.Qty As XMNGA,'' As GRUND,
			NewId() As ZMESGUID,'' As ZComnu
			,@ExecutionTimeStr As ZCSRQSJ ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr 
			where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo 
			and MiscOrdMstr.SubType=26
			and MiscOrdMstr.Status in (0,1)
			and MiscOrdDet.CreateDate between @StartTime and @EndTime 	
			--select top 1000 * from ORD_MiscOrderDet order by createdate desc
			--select top 1000 * from MRP_MrpExScrap where  OrderNo like 'M%'
			--select top 1000 * from ORD_MiscOrderMstr  where miscorderno='MO00000808'
	--生产调整 :SAP_Interface_PPMES0005
	--Create table SAP_Interface_PPMES0005 (ZPTYPE varchar(8),	AUFART varchar(4),	WERKS varchar(4),	MATXT varchar(40),	GAMNG_H varchar(13),	GMEIN_H varchar(3),	GLTRP varchar(8),	GSTRP varchar(8),	BLDAT varchar(8),	BUDAT varchar(8),	BWART_I varchar(3),	MATNR_I varchar(18),	ERFMG_I varchar(13),	GMEIN_I varchar(3),	LGORT_I varchar(4),	ZMESGUID varchar(16))
	Insert into SAP_Interface_PPMES0005
	Select MiscOrdMstr.MiscOrderNo As ZMESSC,MiscOrdDet.Seq As ZMESLN,'BUSFP01' As ZPTYPE,'SY05' As AUFART,@WERKS As WERKS, 
			MiscOrdDet.ItemDesc As MATXT, MiscOrdDet.Qty As GAMNG_H, MiscOrdDet.Uom As GMEIN_H,MiscOrdMstr.CreateDate As GLTRP,MiscOrdMstr.CreateDate As GSTRP,
			MiscOrdMstr.EffDate As BLDAT, MiscOrdMstr.EffDate As BUDAT, Case when MiscOrdDet.Qty <0 then  '261' else '262' End As BWART_I,
			MiscOrdDet.Item As MATNR_I, MiscOrdDet.Qty As ERFMG_I, MiscOrdDet.Uom As GMEIN_I,MiscOrdMstr.Location As LGORT_I, NEWID() As ZMESGUID,
			@ExecutionTimeStr As ZCSRQSJ ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
			from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr 
			where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo 
			and MiscOrdMstr.SubType=50
			and MiscOrdMstr.Status in (0,1)
			and MiscOrdDet.CreateDate between @StartTime and @EndTime 	
	--返工:SAP_Interface_PPMES0001
		Insert into SAP_Interface_PPMES0001
			Select MiscOrdMstr.MiscOrderNo As ZMESSC,MiscOrdDet.Seq As ZMESLN,Case when MiscOrdMstr.MoveType='101' then 'BUSCO01' else 'BUSCO02' End As ZPTYPE,
				'SY04' As AUFART,@WERKS As WERKS,MiscOrdDet.Item As MATNR_H,
				Left(cast(MiscOrdDet.Qty As varchar),13) As GAMNG_H,MiscOrdDet.Uom As GMEIN_H,dbo.FormatDate(MiscOrdMstr.CreateDate,'YYYYMMDD')As GLTRP,
				dbo.FormatDate(MiscOrdMstr.CreateDate,'YYYYMMDD') As GSTRP,dbo.FormatDate(MiscOrdMstr.EffDate ,'YYYYMMDD') As BLDAT,
				dbo.FormatDate(MiscOrdMstr.EffDate ,'YYYYMMDD') As BUDAT,'' As LFSNR,MiscOrdMstr.MoveType As BWART_H ,
				MiscOrdMstr.Location As LGORT_H,Left(cast(abs(MiscOrdDet.Qty ) As varchar),13) As ERFMG_H,MiscOrdMstr.MiscOrderNo+right('00'+CAST(MiscOrdDet.Seq As varchar(10)),2) As ZComnum,
				Left(cast(MiscOrdDet.Qty As varchar),13) As LMNGA_H,'' As ISM,MiscOrdMstr.MoveType As BWART_I,'' As MATNR_I,
				'' As ERFMG_I,'' As GMEIN_I,'' As LGORT_I,NewId() As ZMESGUID,@ExecutionTimeStr As ZCSRQSJ ,'1' As BatchNo , NULL As UniqueCode,'0' As Status
				from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr
				Where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo
				and MiscOrdMstr.SubType=40
				and MiscOrdMstr.MoveType in ('101','261')
				and MiscOrdDet.CreateDate between @StartTime and @EndTime 	
	--试制：SAP_Interface_PPMES0006
	Insert into SAP_Interface_PPMES0006
		Select MiscOrdMstr.MiscOrderNo As ZMESSC, MiscOrdDet.Seq as ZMESLN, 'BUSFP01' as ZPTYPE, '' as AUFNR, 
				MiscOrdMstr.MiscOrderNo+right('00'+CAST(MiscOrdDet.Seq As varchar(10)),2) As ZComnum,
				MiscOrdDet.Qty as LMNGA_H, '' as ISM, MiscOrdMstr.MoveType as BWART,
				left(MiscOrdMstr.WBS,abs(CHARINDEX('/',ISNULL(MiscOrdMstr.WBS,''),1)-1)) as NPLNR, 
				right(MiscOrdMstr.WBS,len(MiscOrdMstr.WBS)-CHARINDEX('/',ISNULL(MiscOrdMstr.WBS,''),1)) as VORNR, MiscOrdDet.ReserveNo as RSNUM,
				MiscOrdDet.ReserveLine as RSPOS, MiscOrdDet.Item as MATNR1, MiscOrdDet.Qty as EPFMG,
				MiscOrdDet.Uom as ERFME, NEWID() as ZMESGUID, @ExecutionTimeStr as ZCSRQSJ, '1' as BatchNo , NULL As UniqueCode,  '0' as Status
				from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr
				Where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo
				and MiscOrdMstr.SubType=30
				and MiscOrdMstr.MoveType in ('281','282','581','582')
				and Status in (0,1)
				and MiscOrdDet.CreateDate between @StartTime and @EndTime 	
	
	--************************************************************************************************************************
			
	Update a
		Set a.LGORT_H=b.SAPLocation from SAP_Interface_PPMES0001 a, MD_Location b where a.LGORT_H=b.Code and a.ZCSRQSJ=@ExecutionTimeStr
	Update a
		Set a.LGORT_I=b.SAPLocation from SAP_Interface_PPMES0001 a, MD_Location b where a.LGORT_I=b.Code and a.ZCSRQSJ=@ExecutionTimeStr
	Update a
		Set a.LGORT_H=b.SAPLocation from SAP_Interface_PPMES0004 a, MD_Location b where a.LGORT_H=b.Code and a.ZCSRQSJ=@ExecutionTimeStr
		
		
		

	--更新批次号信息
	--Update a
	--Select * from SAP_Interface_PPMES0001 a ,SAP_EX001 b --......
	--Update location to SAPLocation...
	
	--Write log into table SAP_TransferLog...
	
	--Update table SAP_TimeControl...
	
	
	
	----存储写好后下面的这些要清除
	--Select top 1000* from ORD_OrderBackflushDet where RecNo='R400102798' order by Id desc  
	--Select top 1000* from ORD_RecDet_4 where RecNo ='R400102798' order by Id desc  
	--Select top 1000* from ORD_OrderMstr_4 where OrderNo ='O4EX0200001762' 
	--Select top 1000* from ORD_OrderDet_4 where OrderNo ='O4EX0200001762' 
	--Select top 1000* from sys.objects where name like '%flush%' 
	--炼胶生产执行
	--MES订单号		MES行号			业务类别	订单类型		工厂		产品物料号	订单数量	单位		基本开始日期	基本结束日期	凭证日期	过帐日期
	--ZMESSC		ZMESLN			ZPTYPE		AUFART			WERKS		MATNR_H		GAMNG_H		GMEIN_H		GSTRP			GSTRP			BLDAT		BUDAT
	--OrderMstr		OrderDet		XXXXX		OrderDet		XXXXX		OrderDet	OrderDet	OrderDet	OrderMstr		OrderMstr		OrderMstr	RecMstr
	--生产单号		生产单明细序号	BUSCO01		订单类型SY01	企业选项	成品产出	订单数量	订单单位	开始时间		窗口时间		生效时间	创建时间

	--产品移动类型	产品库位	收货数量	报工单号		确认数量	工时数量	组件移动类型	组件物料号		组件数量		组件单位		组建库位		GUID				接口传输日期时间
	--BWART_H		LGORT_H		ERFMG_H		ZComnum			LMNGA_H	 	ISM			BWART_I			MATNR_I			ERFMG_I			GMEIN_I			LGORT_I			ZMESGUID			ZCSRQSJ
	--XXXXX			OrderDet	RecDet		RecMstr			RecDet		XXXXX		XXXXX			BackflushDet	BackflushDet	BackflushDet	BackflushDet	XXXXX				XXXXX
	--101			入库库位	RecQty		RecOrdNo+Seq	RecQty		空由SAP自取	261				回冲的物料号	回冲的数量		回冲物料号单位	回冲物料号库位	接口中间表中的主键	此数据的录入中间表的时间
	--Select top 1000 * from SAP_Interface_PPMES0001 
	--Select top 1000 * from MD_Location
	----SP_help'SAP_Interface_PPMES0001'
	----Select top 1000 * from  ORD_OrderBackflushDet where 
	--Select top 1000 Item  from ORD_OrderDet_4 where OrderNo like '%EX%'
	--Select top 1000 *  from ORD_OrderMstr_4 where OrderNo like '%EX%'
	--ORD_OrderBackflushDet
END