USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_PP_UpdateEXScraptInterim]    Script Date: 12/08/2014 10:34:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
--[USP_SAP_PP_UpdatePPMES001Interim]  
--[USP_SAP_PP_UpdatePPMES001Interim]  
-- =============================================
ALTER PROCEDURE [dbo].[USP_SAP_PP_UpdateEXScraptInterim]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
--declare 
 --@LocationFrom varchar(50),
 --@LocationTo varchar(50),
 --@ItemFrom varchar(50),
 --@ItemTo varchar(50)
 
 
BEGIN
  SET NOCOUNT ON;
 --2014/04/25	废品投料也走废品报废ZWS_PPMES0003 ----0001
 --2014/04/27	MES端对生产调整单所产生的261和262类型的计划外出入库，按照订单实际耗量分摊 ----0002
 --2014/05/13	废品数以千克为单位传给SAP ----0003
 --2014/06/11	找不到投料MES单号的先过滤掉,For Test阶段,上线前的切换准备工作会解决这个问题 ----0004
 --2014/06/14	投料消耗从回冲Bom事务里面去找并分摊	----0005
 --2014/06/26	找不到MES订单号就新建一个	----0006
 --2014/06/27	塞芯的Bom	----0007
 --2014/08/21	如果是报断面找投得最多的3开头半成品	----0008
 --2014/10/10	有些冲销是当天做当天取消的，所以PP0002表作为排除条件不准,要找RecMstr ----0009
 --2014/10/11	基本单位为M的也要做单位转化 ----0010(--todo没有PC单位转换的就传'KG')
 --2014/10/20	临时创建的OE单的优先级在匹配报废品的OE单时往后排 ----0011
 --dbo.Zunused_USP_SAP_PP_UpdateEXScraptInterim_BackUpOn20140821 这个是8月21号保存的旧版本
 Declare @CurrentTime datetime=Getdate()
 Declare @ZMESGUID varchar(50)=dbo.FormatDate(GETDATE(),'YYYYMMDDHHNNSS0000')
 Declare @WERKS varchar(50)
	Select @WERKS=Value from SYS_EntityPreference where Id = 90107
 Insert into SAP_Interface_ExscraptMstr(MiscOrderNo,MiscOrder,Reason,BatchNO,CreateDate)
	Select Id,'OF'+Right('000000000000'+CAST(Id As varchar),8) As OrderNo,'MES'+Cast(ScrapType As varchar(20)) As Reason,@BatchNO,GETDATE() As CreateDate 
		from MRP_MrpExScrap
		where ScrapType in (21,22,23,24,25)
		and IsVoid=0
		and CreateDate > @StartTime and CreateDate<=@EndTime
		and CreateUser<>3910
		
--delete SAP_Interface_ExscraptMstr
Select 'OF'+Right('000000000000'+CAST(Id As varchar),8) As OrderNo,Flow As ProdLine,EffectDate ,Shift,Item,ScrapQty,ScrapQty As OriginalScrapQty,
	Cast(0 As Decimal(18,8)) As SAPOrderNOQty,Cast(0 As Decimal(18,8)) As SAPOrderNOQtySumByMiscOrderNO,'MES'+Cast(ScrapType As varchar(20))As Reason into #Scrap_01 from 
		MRP_MrpExScrap a 
		where a.ScrapType in (21,22,23,24,25)
		and a.IsVoid=0
		and a.CreateDate > @StartTime and a.CreateDate<=@EndTime
		and CreateUser<>3910
--Select top 1000 * from SAP_Interface_ExscraptMstr 
 --Drop table #ParentSubItems
Select b.Bom,b.Item,CAST(b.RateQty/m.Qty As decimal(18,8)) as UnitQty 
		into #ParentSubItems
		from PRD_BomDet b,PRD_BomMstr m where b.Bom =m.Code
		and  (b.StartDate<=Getdate() or b.StartDate is null)
		and (b.EndDate> Getdate() or b.EndDate is null)
		and b.Item like '29%'
		and m.IsActive=1
 
Select ROW_NUMBER()Over(Partition By OrderNO Order by isnull(b.Bom,'')) As Seq,a.*,
	isnull(b.Bom,a.Item) As ExItem,cast(1 as decimal(18,8)) As UnitQty,SPACE(50) As ZMESSC,SPACE(50) As SumRecQtyBySAPOrdNo
	,a.EffectDate As SettledEffectDate,CAST(0 as decimal(18,8)) As TimeGap into #Scrap_02 
	from #Scrap_01 a Left join #ParentSubItems b on a.Item =b.Item  
	
 
--3开头物料直接由KG转化为件
Update b
	Set b.UnitQty=case when BaseUom='PC' and AltUom ='KG' then cast(BaseQty/AltQty as decimal(18,8))
		when BaseUom='KG' and AltUom ='PC' then cast(AltQty/BaseQty as decimal(18,8))else 1 end  
		from MD_UomConv a with(nolock), #Scrap_02 b
		where a.Item =b.ExItem and ((a.BaseUom='PC' and 
		a.AltUom ='KG') or (BaseUom='KG' and AltUom ='PC'))
		and exists(select * from MD_Item c where b.ExItem=c.Code and c.Uom='PC')
----0010Begin
Update b
	Set b.UnitQty=case when BaseUom='M' and AltUom ='KG' then cast(BaseQty/AltQty as decimal(18,8))
		when BaseUom='KG' and AltUom ='M' then cast(AltQty/BaseQty as decimal(18,8))else 1 end  
		from MD_UomConv a with(nolock), #Scrap_02 b
		where a.Item =b.ExItem and ((a.BaseUom='M' and 
		a.AltUom ='KG') or (BaseUom='KG' and AltUom ='M'))
		and exists(select * from MD_Item c where b.ExItem=c.Code and c.Uom='M')
----0010End
Update #Scrap_02 Set ScrapQty=ScrapQty*UnitQty

----冲销的ExRecNo
Select RecNo into #RecNo from ORD_RecMstr_4 where Status =1 and OrderSubType =0  
	and Flow in(Select Code from SCM_FlowMstr where ResourceGroup =20) and CreateDate >'2014-09-01'
----
Declare @OrderNO varchar(20),@Shift varchar(20),@ProdLine varchar(20),@CreateDate DateTime,@EffectDateTime DateTime
Declare @RecDateTimeLt DateTime,@RecDateTimeGt DateTime,@EXItem varchar(20),@PlanNO varchar(20),@OrderQty float,@I Int=1
Declare @NewPlanNo varchar(30),@WeekIndex varchar(30),@SerialNO varchar(30),@Section varchar(20),@ScrpQty float
Select @WeekIndex= WeekIndex from MRP_WeekIndex d
		where dbo.FormatDate(Getdate(),'YYYY-MM-DD') > =d.StartDate and dbo.FormatDate(Getdate(),'YYYY-MM-DD')<=d.EndDate 
  while exists(Select 0 from #Scrap_02 where isnull(ZMESSC,'')='')
	Begin
		Select @PlanNo=null,@OrderQty =null
		Select top 1 @OrderNO=OrderNO,@Shift=Shift,@ProdLine=ProdLine,@CreateDate=EffectDate,@EffectDateTime=EffectDate,@EXItem=ExItem 
			,@ScrpQty =ScrapQty from #Scrap_02 where isnull(ZMESSC,'')=''
		--Select @OrderNO,@Shift,@ProdLine,@CreateDate,@EffectDateTime,@EXItem
		Declare @TimeDiff int=0
		Select @TimeDiff =Case when @Shift ='EX3-1'  then 705 when @Shift ='EX3-2' then 1185 else 1665 End
		Select @EffectDateTime=DATEADD(minute,@TimeDiff,@EffectDateTime)
		Select @RecDateTimeLt=MAX(RecTime) from SAP_EX001 
			where Item =@EXItem and ProductLine=@ProdLine and RecTime <@EffectDateTime
			and RecNo not in (Select RecNo from #RecNo)
		Select @RecDateTimeGt=MIN(RecTime) from SAP_EX001 
			where Item =@EXItem and ProductLine=@ProdLine and RecTime >@EffectDateTime
			and RecNo not in (Select RecNo from #RecNo)
		if @RecDateTimeGt is null and @RecDateTimeLt is null
		Begin
			print 'no matched planno'
		End
		Else
		Begin
			Select @RecDateTimeLt=ISNULL(@RecDateTimeLt,'1753-01-01'),@RecDateTimeGt=ISNULL(@RecDateTimeGt,'1900-01-01')
			If ABS(DATEDIFF(minute,@RecDateTimeLt,@EffectDateTime))>ABS(DATEDIFF(minute,@EffectDateTime,@RecDateTimeGt))
			Begin
				Set @EffectDateTime= @RecDateTimeGt
			End
			Else
			Begin
				Set @EffectDateTime= @RecDateTimeLt
			End
			Select top 1 @PlanNO =PlanNo,@OrderQty=OrderQty from SAP_EX001 
				where Item =@EXItem and ProductLine=@ProdLine and RecTime=@EffectDateTime
				and RecNo not in (Select RecNo from #RecNo)
		End
				

		If @RecDateTimeLt is null and @RecDateTimeGt is null
			Begin
				Select @RecDateTimeLt=MAX(RecTime) from SAP_EX001 
				where Item =@EXItem and RecTime <@EffectDateTime
				and RecNo not in (Select RecNo from #RecNo)
				Select @RecDateTimeGt=MIN(RecTime) from SAP_EX001 
				where Item =@EXItem and RecTime >@EffectDateTime
				and RecNo not in (Select RecNo from #RecNo)
			if @RecDateTimeGt is null and @RecDateTimeLt is null
				Begin
					print 'no matched planno'
				End
				Else
				Begin
					Select @RecDateTimeLt=ISNULL(@RecDateTimeLt,'1753-01-01'),@RecDateTimeGt=ISNULL(@RecDateTimeGt,'1900-01-01')
					If ABS(DATEDIFF(minute,@RecDateTimeLt,@EffectDateTime))>ABS(DATEDIFF(minute,@EffectDateTime,@RecDateTimeGt))
					Begin
						Set @EffectDateTime= @RecDateTimeGt
					End
					Else
					Begin
						Set @EffectDateTime= @RecDateTimeLt
					End
					Select top 1 @PlanNO =PlanNo,@OrderQty=OrderQty from SAP_EX001 
					where Item =@EXItem and RecTime=@EffectDateTime
					and RecNo not in (Select RecNo from #RecNo)
				End
			End
			If Isnull(@PlanNo,'')='' 
				Begin 
				--0006
				--Create New PlanNO
				Set @NewPlanNo='OE'+SUBSTRING(@WeekIndex,3,2)+Right(@WeekIndex,2)+Isnull(@EXItem,'')
				Select @SerialNO=right('00'+Cast(Cast(right(MAX(PlanNo),2)As int)+1 as varchar(10)),2) from SAP_EX001 where PlanNo like @NewPlanNo+'%'
				Set @NewPlanNo =@NewPlanNo + ISNULL(@SerialNO,'00')
				Set @PlanNo=@NewPlanNo
				If Isnull(@PlanNo,'')='' Begin Set @PlanNo='NoneUpdate' End
				Update #Scrap_02 Set ZMESSC = @PlanNo,SAPOrderNOQty=1,SettledEffectDate=ISNULL(@RecDateTimeLt,dateadd(minute,@I,'2010-01-01')/*--0011*/) where orderNO =@orderNO and ExItem =@EXItem 
				--Select top 100 * from SAP_EX001
				Insert into SAP_EX001(PlanNo, OrderNo, RecNo, RecTime, Shift, ProductLine, Item, WeekIndex, Section, OrderQty, RecQty,ZCSRQSJ,BatchNo,ISM)
					Select @NewPlanNo,dbo.FormatDate(dateadd(second,@I,Getdate()),'YYYYMMDDHHNNSS') As OrderNO,@OrderNO As RecNo,dateadd(minute,@I,'2010-01-01') As RecTime,
						@Shift As Shift ,@ProdLine As ProductLine,@EXItem As Item,@WeekIndex As WeekIndex,'' As Section ,ceiling(@ScrpQty) As OrderQty,
						Case when @ScrpQty=0 then 1 else ceiling(@ScrpQty) End AS RecQty,Getdate() As ZCSRQSJ ,@BatchNO As BatchNo,0 As ISM
				End
				Else
				Begin
					--Select  'ssss',@PlanNO ,@OrderQty
					Update #Scrap_02 Set ZMESSC = @PlanNo,SAPOrderNOQty=isnull(@OrderQty,0),SettledEffectDate=@EffectDateTime where orderNO =@orderNO and ExItem =@EXItem 
					--Update SAP_Interface_PPMES0001_Interim Set ZMESSC = @PlanNo,GAMNG_H=@OrderQty  
					--	where orderNO =@orderNO and isnull(ZMESSC,'')='' and isnull(@PlanNo,'')!='' 
				End
			Set @I =@I +1
	End
	Update #Scrap_02 Set TimeGap=ABS(datediff(hour,EffectDate,SettledEffectDate))
	Delete a from(Select *,ROW_NUMBER()Over(partition by Orderno order by TimeGap) As NONO from #Scrap_02) a where a.NONO !=1
 
	----开始分摊投料
	Select *,SPACE(13) As XMNGA,SPACE(5) As GRUND,SPACE(50) As SumQtyBySAPOrdNo into #SAP_Interface_PPMES0001 from SAP_Interface_PPMES0001
		Where ZMESSC in (select ZMESSC from #Scrap_02 /*Where Reason in ('MES24','MES25')*/)
		and ZPTYPE ='BUSCO01'
		and ZComnum not in (select ZComnum from SAP_Interface_PPMES0002)
		and OrderType in ('EXOrder','MIOrder','FIOrder')
	
	----0002废品数量平摊到SAPOrderNo,根据SAPOrderNo的实际消耗比(即收货数总和之比)
	Select ZMESSC,Sum(Cast(ERFMG_H As decimal(18,8))) As SumQtyBySAPOrdNo into #SumRecQtyBySAPOrdNo from #SAP_Interface_PPMES0001 
		Group by ZMESSC Having Sum(Cast(ERFMG_H As decimal(18,8)))>0 --0007
	Update a
		Set a.SumRecQtyBySAPOrdNo=b.SumQtyBySAPOrdNo from #Scrap_02 a,#SumRecQtyBySAPOrdNo b where a.ZMESSC=b.ZMESSC
	----0002
	Delete a from (Select *,dense_rank()over(partition by ZMESSC order by ZComnum) As NONO from #SAP_Interface_PPMES0001) a
		where NONO !=1
	Select PlanNo As  ZMESSC,SUM(recqty) As SumQtyBySAPOrdNo into #SumRecQtyBySAPOrdNo1 from SAP_EX001 where PlanNo in(
		Select  ZMESSC from #Scrap_02 where SumRecQtyBySAPOrdNo='') group by PlanNo
	Update a
		Set a.SumRecQtyBySAPOrdNo=b.SumQtyBySAPOrdNo from #Scrap_02 a,#SumRecQtyBySAPOrdNo1 b where a.ZMESSC=b.ZMESSC	
	--Select * from #SAP_Interface_PPMES0001 a,#Scrap_02 b 
	--	where a.
	Update a
		Set a.SAPOrderNOQtySumByMiscOrderNO=b.SumRecQtyBySAPOrdNo from #Scrap_02 a,
			(Select OrderNO,SUM(Cast(SumRecQtyBySAPOrdNo As decimal(18,8))) As SumRecQtyBySAPOrdNo from #Scrap_02 Group by OrderNO) b
		where a.OrderNo =b.OrderNo
	--加权平均每个SAP单号的报废数量???没有直接通过单位转换,所以不同的SAP单号下面的ScrapQty不一致
	--OrderNo	ProdLine	EffectDate	Shift	Item	ScrapQty	SAPOrderNOQty	SAPOrderNOQtySumByMiscOrderNO	ExItem	UnitQty	ZMESSC
	--O4EX0100002484	EX01	2014-04-17 00:00:00.000	EX3-3	290009	46.2919221168537	6600	14200	300955	1.095	OE141630095502
	--O4EX0100002484	EX01	2014-04-17 00:00:00.000	EX3-3	290009	52.8017236645363	7600	14200	301048	0.96	OE141630104801
	Update #Scrap_02
		Set ScrapQty =ScrapQty *(Cast(SumRecQtyBySAPOrdNo As decimal(18,8))/Cast(SAPOrderNOQtySumByMiscOrderNO As decimal(18,8)))
			--OriginalScrapQty =OriginalScrapQty *(Cast(SumRecQtyBySAPOrdNo As decimal(18,8))/Cast(SAPOrderNOQtySumByMiscOrderNO As decimal)) 
			from #Scrap_02
	--Select * from #Scrap_02 where OrderNo ='O4EX1500000984' order by OrderNo 
	--Select * from #SAP_Interface_PPMES0001 where ZMESSC ='OE141630058300'
	--alter table #SAP_Interface_PPMES0001 alter column ZComnum varchar(16)
	--0005Begin
	Declare @UinqCode varchar(100)=Replace(Newid(),'-','')
	Select top 0 *,SPACE(50) As MiscOrder into #SAP_Interface_PPMES0001_Tmp from SAP_Interface_PPMES0001 where 1=2
	Insert into #SAP_Interface_PPMES0001_Tmp(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, BWART_H, 
		LGORT_H, ERFMG_H, ZComnum, LMNGA_H, ISM, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, 
		UniqueCode, Status,OrderType,TailQty,MiscOrder)
		Select OrdMstr.OrderNo As ZMESSC,OrdDet.Seq As ZMESLN,'BUSCO01' As ZPTYPE,'SY01' As AUFART,@WERKS As WERKS,OrdDet.Item As MATNR_H,
			Left(cast(OrdDet.OrderQty As varchar),13) As GAMNG_H,OrdDet.BaseUom As GMEIN_H,OrdMstr.WindowTime As GLTRP,
			OrdMstr.StartTime As GSTRP,OrdMstr.EffDate As BLDAT,
			ExScrap.CreateDate As BUDAT,RecMstr.RecNo As LFSNR,Case when RecDet.RecQty >0 then '101' else '102' End As BWART_H ,
			OrdDet.LocTo As LGORT_H,Left(cast(abs(RecDet.RecQty) As varchar),13) As ERFMG_H,RecMstr.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) As ZComnum,
			Left(cast(RecDet.RecQty As varchar),13) As LMNGA_H,'' As ISM,Case when sum(BFDet.BFQty*BFDet.UnitQty) <0 then  '261' else '262' End As BWART_I,BFDet.Item As MATNR_I,
			Left(cast(abs(round(sum(BFDet.BFQty*BFDet.UnitQty),3)) as varchar),13) As ERFMG_I,BFDet.BaseUom As GMEIN_I,BFDet.LocFrom As LGORT_I,
			@ZMESGUID As ZMESGUID,@CurrentTime As ZCSRQSJ ,@BatchNo As BatchNo , @UinqCode As UniqueCode,'0' As Status,'ScrapEXOrder',
			Left(cast(sum(BFDet.BFQty*BFDet.UnitQty)-round(sum(BFDet.BFQty*BFDet.UnitQty),3) As varchar),50) As TailQty,'OF'+Right('000000000000'+CAST(ExScrap.Id As varchar),8) As MiscOrder
			from ORD_RecDet_4 RecDet,ORD_RecMstr_4 RecMstr,ORD_OrderDet_4 OrdDet,ORD_OrderMstr_4 OrdMstr,ORD_OrderBackflushDet BFDet
			,MRP_MrpExScrap  ExScrap 
			Where RecDet.OrderDetId = OrdDet.Id 
			and RecDet.RecNo = RecMstr.RecNo 
			and OrdDet.OrderNo = OrdMstr.OrderNo 
			and RecDet.Id = BFDet.RecDetId
			and OrdMstr.ResourceGroup = 20
			and OrdMstr.SubType= 40
			and ExScrap.OrderNo =OrdMstr.OrderNo
			and ScrapType in (24,25)
			and ExScrap.IsVoid=0
			--and BFDet.IsVoid=0
			and RecMstr.CreateDate>@StartTime AND RecMstr.CreateDate<=@EndTime
			and ExScrap.CreateUser<>3910
			Group BY OrdMstr.OrderNo ,OrdDet.Seq , OrdDet.Item ,
			Left(cast(OrdDet.OrderQty As varchar),13) ,OrdDet.BaseUom ,OrdMstr.WindowTime ,
			OrdMstr.StartTime ,OrdMstr.EffDate ,
			ExScrap.CreateDate ,RecMstr.RecNo ,Case when RecDet.RecQty >0 then '101' else '102' End ,
			OrdDet.LocTo ,Left(cast(abs(RecDet.RecQty) As varchar),13) ,
			RecMstr.RecNo+right('00'+CAST(RecDet.Seq As varchar(10)),2) ,
			Left(cast(RecDet.RecQty As varchar),13) ,BFDet.Item ,
			BFDet.BaseUom ,BFDet.LocFrom,'OF'+Right('000000000000'+CAST(ExScrap.Id As varchar),8)
		Update a
			Set a.LGORT_H=b.SAPLocation from #SAP_Interface_PPMES0001_Tmp a, MD_Location b where a.LGORT_H=b.Code  
		Update a
			Set a.LGORT_I=b.SAPLocation from #SAP_Interface_PPMES0001_Tmp a, MD_Location b where a.LGORT_I=b.Code  
	--0005End
	Select b.ZMESSC, ZMESLN, 'BUSBG01' As ZPTYPE, 'SY03' As AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, 
		BLDAT, BUDAT, b.OrderNo As LFSNR, BWART_H, 
		LGORT_H,  0 As ERFMG_H, b.OrderNo+right('0'+Cast(b.Seq as varchar(5)),2) As ZComnum, LMNGA_H, ISM, BWART_I, MATNR_I, 
		Cast(ERFMG_I As decimal(18,8))*(Cast(SumRecQtyBySAPOrdNo As decimal(18,8))/Cast(SAPOrderNOQtySumByMiscOrderNO As decimal(18,8))) As ERFMG_I
		, GMEIN_I, LGORT_I, @ZMESGUID As ZMESGUID, ZCSRQSJ, BatchNo, 
		@UinqCode As UniqueCode, Status,OrderType,
		Cast(TailQty As decimal(18,8))*(Cast(SumRecQtyBySAPOrdNo As decimal(18,8))/Cast(SAPOrderNOQtySumByMiscOrderNO As decimal(18,8))) As TailQty ,
		CEILING(b.ScrapQty) As XMNGA,b.Reason As GRUND,SPACE(50) As SumQtyBySAPOrdNo 
		into #SAP_Interface_PPMES0001_Rec 
		from #SAP_Interface_PPMES0001_Tmp a,#Scrap_02 b
		Where  a.MiscOrder=b.OrderNo 
	--Select * from #Scrap_02 a,#SAP_Interface_PPMES0001 b where a.ZMESSC =b.ZMESSC and a.OrderNo ='O4EX1500000984'
	--0001?????平摊到多个SAP生产单号的时候XMNGA废品数也要折算吗?---Conclusion:yes
	Insert into SAP_Interface_PPMES0003(ZMESSC, ZMESLN, ZPTYPE, WERKS, XMNGA,GMEIN_H, GRUND, ZComnum, BLDAT, BUDAT, 
	MTSNR, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,TailQty)
		Select ZMESSC, ZMESLN, ZPTYPE, WERKS, Left(cast(XMNGA as varchar),13) As XMNGA,GMEIN_H, GRUND, ZComnum, BLDAT, BUDAT, 
			Space(50) As MTSNR, BWART_I, MATNR_I, Left( abs(round(Cast(ERFMG_I as decimal(18,8)),3)),13) As ERFMG_I, 
			GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status ,
			Cast(TailQty as decimal(18,8)) As TailQty
			from #SAP_Interface_PPMES0001_Rec
			where GRUND in ('MES24','MES25')
	--Select * from SAP_Interface_PPMES0003
	--Select * from SAP_Interface_PPMES0001
	--Select top 100 * from SAP_ex001
	Insert into SAP_Interface_ExscraptDet(MiscOrder, MiscOrderDet, AdjustSAPOrder, BatchNo,ScraptQty, CreateDate)
		Select OrderNo, OrderNo+right('0'+Cast(Seq as varchar(5)),2) As MiscOrderDet,
			ZMESSC As AdjustSAPOrder,@BatchNo As BatchNo,ScrapQty,GETDATE() from #Scrap_02

	--为了补传MES历史生产单,把非投料类型放在这里生成
	Insert into SAP_Interface_PPMES0003(ZMESSC, ZMESLN, ZPTYPE, WERKS, XMNGA,GMEIN_H, GRUND, ZComnum, BLDAT, BUDAT, 
			MTSNR, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status)
			Select b.AdjustSAPOrder As ZMESSC,1 As ZMESLN ,'BUSBG01' As ZPTYPE,@WERKS As WERKS,
				Left(cast(Case when ceiling(ScraptQty)=0 then 1 else ceiling(ScraptQty) End As  varchar),13) XMNGA,'PC' As GMEIN_H ,Reason As GRUND,
				MiscOrderDet As ZComnum,EffectDate As BLDAT,c.CreateDate As BUDAT,'' As MTSNR, '' As BWART_I, '' As MATNR_I,
				 '' As ERFMG_I, '' As GMEIN_I, '' As LGORT_I ,@ZMESGUID As ZMESGUID ,
				GETDATE() As ZCSRQSJ,@BatchNo As BatchNo,NUll As UniqueCode,'0' as Status
				from SAP_Interface_ExscraptMstr a,SAP_Interface_ExscraptDet b ,MRP_MrpExScrap c
				where a.MiscOrder=b.MiscOrder
				and a.MiscOrderNo=c.Id
				and a.BatchNo=@BatchNo
				and a.Reason not in ('MES24','MES25')
				and c.CreateUser<>3910
	Update a	
		Set a.GMEIN_H=c.Uom from SAP_Interface_PPMES0003 a with(nolock),SAP_EX001 b with(nolock), MD_Item c with(nolock)
		where a.ZMESSC=b.PlanNo and a.BatchNo=@BatchNo
		and b.Item=c.Code and c.Uom != a.GMEIN_H
	Update a	
		Set a.GMEIN_H='PC' from SAP_Interface_PPMES0003 a with(nolock),
		SAP_EX001 b with(nolock), MD_UomConv c with(nolock)
		where a.ZMESSC=b.PlanNo and a.BatchNo=@BatchNo
		and b.Item=c.Item and
		((c.BaseUom='PC' and 
		c.AltUom ='KG') or (c.BaseUom='KG' and c.AltUom ='PC'))
		----0010Begin
	Update a	
		Set a.GMEIN_H='M' from SAP_Interface_PPMES0003 a with(nolock),
		SAP_EX001 b with(nolock), MD_UomConv c with(nolock)
		where a.ZMESSC=b.PlanNo and a.BatchNo=@BatchNo
		and b.Item=c.Item and
		((c.BaseUom='M' and 
		c.AltUom ='KG') or (c.BaseUom='KG' and c.AltUom ='M'))
		----0010End
	--Select top 1000 * from SAP_Interface_PPMES0003
	Update SAP_Interface_PPMES0003 Set XMNGA='1' where CAST(XMNGA As float)=0 and XMNGA!='' and BatchNo =@BatchNo

	--补传MES历史生产单
	--0006

	Select Distinct a.ZMESSC, ZMESLN, 'BUSCO01' As ZPTYPE, 'SY01' As AUFART, @WERKS As WERKS, b.ExItem As MATNR_H,Cast('0' As varchar(13))  As GAMNG_H, GMEIN_H,
	@CurrentTime As GLTRP, @CurrentTime As GSTRP, BLDAT, BUDAT,MTSNR As LFSNR,'101' As  BWART_H, c.SAPLocation As LGORT_H, 
	Cast('0' As varchar(13)) As ERFMG_H, replace(ZComnum,'OF','SF')ZComnum, MTSNR, Cast('0' As varchar(13)) As LMNGA_H, Cast('0' As varchar(13)) As ISM, '261' As BWART_I, MATNR_I, 
	Cast('0' As varchar(13)) As ERFMG_I, GMEIN_I, c.SAPLocation LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, @UinqCode As UniqueCode, '0' As Status,'HistoryEXOrder' OrderType, '0' As TailQty
	 into #Interface_PPMES0001
	 from SAP_Interface_PPMES0003 a,#Scrap_02 b,MD_Location c,SCM_FlowMstr e
	 where a.ZMESSC =b.ZMESSC and a.BatchNo =@BatchNo
	 and b.ProdLine =e.Code
	 and c.Code =e.LocFrom
	 and not exists(Select 0 from  SAP_Interface_PPMES0001 d where a.ZMESSC=d.ZMESSC)
	 Delete a from (select *,ROW_NUMBER()Over(partition by ZMESSC order by MATNR_H) As NONO from #Interface_PPMES0001)
		a where a.nono!=1
		Select * into #PRD_BomDet from PRD_BomDet with(nolock) 
			where Bom in (select MATNR_H from #Interface_PPMES0001 /*where GMEIN_I=''*/)
			and (StartDate is null or  StartDate<@CurrentTime) 
			and (EndDate is null or  EndDate>@CurrentTime) 
		Update a
			Set a.MATNR_I=b.Item,a.GMEIN_I=b.Uom,LGORT_I=LGORT_H 
			from #Interface_PPMES0001 a , #PRD_BomDet b 
			where a.MATNR_H=b.Bom -- and isnull(MATNR_I,'')=''
		--29再往下拆一层
		Select * into #PRD_BomDet_I from PRD_BomDet with(nolock) 
			where Bom in (select MATNR_I from #Interface_PPMES0001 where MATNR_I like '29%')
			and (StartDate is null or  StartDate<@CurrentTime) 
			and (EndDate is null or  EndDate>@CurrentTime) 
		Update a
			Set a.MATNR_I=b.Item,a.GMEIN_I=b.Uom,LGORT_I=LGORT_H 
			from #Interface_PPMES0001 a , #PRD_BomDet_I b 
			where a.MATNR_I=b.Bom
			
		----
		Update a
			Set a.GMEIN_H=b.Uom from #Interface_PPMES0001 a,MD_Item b where a.MATNR_H=b.Code 
	Update a
		Set a.GAMNG_H=Left(Cast(b.OrderQty As varchar),13) from #Interface_PPMES0001 a,SAP_EX001 b where a.ZMESSC=b.PlanNo 
	 Insert into SAP_Interface_PPMES0001(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H,
		GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, BWART_H, LGORT_H, ERFMG_H, ZComnum, MTSNR, LMNGA_H, ISM, BWART_I, MATNR_I, 
		ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status, OrderType, TailQty)
		Select ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H,
		GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, BWART_H, LGORT_H, ERFMG_H, ZComnum, MTSNR, LMNGA_H, ISM, BWART_I, MATNR_I, 
		ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status, OrderType, TailQty from #Interface_PPMES0001
	--0006
		--Delete ,Update在测试阶段启用下面的代码，测试完后要把所有存储整合在一起，一起更新
		Update SAP_Interface_PPMES0003 Set MTSNR =LEFT(ZComnum ,10) where BatchNo =@BatchNo
		Update SAP_Interface_PPMES0001 Set MTSNR =LFSNR where BatchNo =@BatchNo 
		---投料数为0不传
		Update SAP_Interface_PPMES0003
			Set Status =1 from SAP_Interface_PPMES0003 where Status =0 and BatchNo =@BatchNo and cast(ERFMG_I As decimal(18,8))=0 and GRUND in ('MES24','MES25') and ERFMG_I!=''
END




