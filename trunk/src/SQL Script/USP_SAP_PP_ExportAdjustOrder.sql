USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_PP_ExportAdjustOrder]    Script Date: 12/08/2014 10:31:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_SAP_PP_ExportAdjustOrder]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
BEGIN
	--2014/04/27	MES端对生产调整单所产生的261和262类型的计划外出入库，按照#*订单实际耗量*#分摊	2014/04/27	--0001
	--过账日期设在当天???????
	--2014/09/13	10月初先不分摊	----0002
	--2014/10/17    取Note  ----0003
	--2014/10/27	 
	--接口传给SAP的调整原因描述
	--调整原因描述长度
	--翻箱后过滤--[物料号]翻箱后过滤差异--20
	--盘点调整[MES生产调整原因]--人工输入
	--尾差调整261--[SAP库位]尾差调整出库16
	--尾差调整262--[SAP库位]尾差调整入库16
	--2014/11/13	委外成本中心发料 --0006
	SET NOCOUNT ON
	DECLARE @CurrDate datetime=GETDATE()
	DECLARE @CurrDate1 datetime=Dateadd(minute,1,GETDATE())
	Declare @ExecutionTimeStr datetime = @CurrDate--varchar(20)=dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS')
	Declare @WERKS varchar(50)
	Declare @MonthStart DateTime 
	Declare @MonthEnd DateTime
	Declare @ZMESGUID varchar(50)=dbo.FormatDate(@CurrDate,'YYYYMMDDHHNNSS0000')
	Declare @ZMESGUID1 varchar(50)=dbo.FormatDate(Dateadd(minute,1,@CurrDate),'YYYYMMDDHHNNSS0000')
	Select @WERKS=Value from SYS_EntityPreference where Id = 90107
	Select  @MonthStart=dbo.FormatDate(@CurrDate,'YYYY-MM-01 00:00:00'),
		@MonthEnd= dbo.FormatDate(Dateadd(month,1,@CurrDate),'YYYY-MM-01 00:00:00')
		--select Code ,GETDATE (),@CurrDate from MD_Location as l where Code in(select distinct(LocFrom) from SCM_FlowMstr where type=4) 
	Print @MonthStart
	Print @MonthEnd
	----被冲销过得记录不分摊
	---- EXEC [USP_SAP_PP_ExportAdjustOrder] '9FDG6B087100436689B98292AFC467WE','2014-04-01','2014-04-01'
	--select top 1000 * from ORD_MiscOrderMstr
	--MiscOrdMstr.Type  
	--Drop table #MiscOrdDet
	Select MiscOrdMstr.Location LocationM ,
		Case when MiscOrdMstr.MoveType = '261' and MiscOrdDet.Qty<0 
		then '262' when MiscOrdMstr.MoveType = '262' 
		and MiscOrdDet.Qty<0 then '261' else MiscOrdMstr.MoveType End As MoveType
		,MiscOrdMstr.Type,MiscOrdDet.*,MiscOrdMstr.EffDate As BLDAT,MiscOrdMstr.EffDate As BUDAT,
		'0' As IsDistribution
		into #MiscOrdDet
		from ORD_MiscOrderDet MiscOrdDet,ORD_MiscOrderMstr MiscOrdMstr 
		where MiscOrdDet.MiscOrderNo=MiscOrdMstr.MiscOrderNo 
		and MiscOrdMstr.SubType=50
		and MiscOrdMstr.CloseDate between @StartTime and @EndTime
		and MiscOrdMstr.CloseUser<>3910
	----当月内冲销的不要分摊
	Select MiscOrderNo into #CancelMiscOrderNo from ORD_MiscOrderMstr 
		where CancelDate between @StartTime and @EndTime
		and SubType=50 and CancelUser<>3910
	Select a.MiscOrderNo into #DELMiscOrder from #MiscOrdDet a,#CancelMiscOrderNo b where a.MiscOrderNo=b.MiscOrderNo
	Delete a from #MiscOrdDet a,#DELMiscOrder b where a.MiscOrderNo =b.MiscOrderNo 
	Delete a from #CancelMiscOrderNo a,#DELMiscOrder b where a.MiscOrderNo =b.MiscOrderNo 
	
	Update a
		Set a.LocationM=b.SAPLocation from #MiscOrdDet a,MD_Location b where a.LocationM =b.Code  
	--Delete N/A库位
	Delete #MiscOrdDet where LocationM='N/A'
	--
	--Select *  from #MiscOrdDet where  MATNR_I like '3%'
	--Drop table #SAP_Interface_PPMES0001Need  Drop table #SumOrderQtyByLocItem
	Select Distinct a.*,CAST(0 As decimal(28,18)) As SAPOrderQtyRate,CAST(0 As decimal(28,18)) As SumOrderQtyByLocItem,CAST(0 As decimal(28,18)) As SumERFMG_I  into #SAP_Interface_PPMES0001Need
		from SAP_Interface_PPMES0001 a,#MiscOrdDet b
		where a.lgort_I=b.LocationM
		and a.MATNR_I =b.Item 
		and a.ZPTYPE ='BUSCO01'
		and OrderType in ('EXOrder','MIOrder','FIOrder')
		and a.ZCSRQSJ between @MonthStart and @MonthEnd
		and a.ZComnum not in (select ZComnum from SAP_Interface_PPMES0002)
		--0002
		and 1=2
	--001Begin	
	Update a
		Set a.SumERFMG_I=b.SumERFMG_I from #SAP_Interface_PPMES0001Need a,
		(Select ZMESSC,LGORT_I,MATNR_I,SUM(cast(ERFMG_I As decimal(28,18))) As SumERFMG_I 
		from #SAP_Interface_PPMES0001Need group by ZMESSC,LGORT_I,MATNR_I)b
		where a.ZMESSC=b.ZMESSC and a.LGORT_I=b.LGORT_I and a.MATNR_I=b.MATNR_I

	Delete #SAP_Interface_PPMES0001Need where CAST(SumERFMG_I As decimal(28,18))=0
	Delete a from (Select *,ROW_NUMBER()Over(partition by ZMESSC,MATNR_I Order by MATNR_I) As NONO from #SAP_Interface_PPMES0001Need)a
		Where a.NONO !=1
	Select LGORT_I,MATNR_I,SUM(cast(SumERFMG_I As decimal(28,18))) As SumOrderQtyByLocItem into #SumOrderQtyByLocItem
		from #SAP_Interface_PPMES0001Need a
		Group by LGORT_I,MATNR_I
	--Select LGORT_I,MATNR_I,SUM(cast(GAMNG_H As decimal(28,18))) As SumOrderQtyByLocItem into #SumOrderQtyByLocItem
	--	from #SAP_Interface_PPMES0001Need a
	--	Group by LGORT_I,MATNR_I
	--0001
	Update a
		Set a.SumOrderQtyByLocItem=b.SumOrderQtyByLocItem,SAPOrderQtyRate=Cast(SumERFMG_I As decimal(28,18))/Cast(b.SumOrderQtyByLocItem  As decimal(28,18))
		from #SAP_Interface_PPMES0001Need a,#SumOrderQtyByLocItem b 
		where a.LGORT_I=b.LGORT_I and a.MATNR_I=b.MATNR_I
		
	--Select Cast(GAMNG_H As decimal(28,18)),Cast(b.SumOrderQtyByLocItem  As decimal(28,18)),Cast(GAMNG_H As decimal(28,18))/Cast(b.SumOrderQtyByLocItem  As decimal(28,18))
	--	from #SAP_Interface_PPMES0001Need a,#SumOrderQtyByLocItem b 
	--	where a.LGORT_I=b.LGORT_I and a.MATNR_I=b.MATNR_I
	
	--Calculate Rate ,每个MiscOrderDet 直接乘就可以实现平均摊
	--Select top 1000 * from #SAP_Interface_PPMES0001Need where LGORT_I ='3018' and MATNR_I ='300948'
	--Select top 1000 * from #MiscOrdDet where LocationM  ='3018' and Item ='300948'
	Update b
		Set b.IsDistribution ='1' from #SAP_Interface_PPMES0001Need a,#MiscOrdDet b where a.MATNR_I=b.Item 
		and a.LGORT_I =b.LocationM  
		
	Select Distinct a.*,b.MiscOrderNo ,b.Qty As DistributionQty,ROW_NUMBER()Over(Partition by b.MiscOrderNo Order by ZMESSC)As NONO ,b.MoveType ,
		b.BLDAT As BLDATAJU,b.BUDAT As BUDATAJU,b.MiscOrderNo+CAST(b.Id As varchar) As MISCDET
	    into #SAP_Interface_PPMES0001Temp 
		from #SAP_Interface_PPMES0001Need a,#MiscOrdDet b where a.MATNR_I=b.Item 
		and a.LGORT_I =b.LocationM  
	Update #SAP_Interface_PPMES0001Temp
	Set BWART_I=MoveType,ERFMG_I= Left(cast(Floor(SAPOrderQtyRate*DistributionQty*1000)/1000 As varchar),13),
		/*ERFMG_H=Left(cast(ERFMG_H*SAPOrderQtyRate*DistributionQty/ERFMG_I As varchar),13),
		LMNGA_H=Left(cast(LMNGA_H*SAPOrderQtyRate*DistributionQty/ERFMG_I As varchar),13),*/
		ERFMG_H=0,LMNGA_H=0,ZPTYPE='BUSTZ02',BLDAT = BLDATAJU,BUDAT = BUDATAJU,
		LFSNR=MiscOrderNo,MTSNR=MiscOrderNo,OrderType='AdjustOrder',
		BatchNo=@BatchNo,ZComnum=replace(replace(MiscOrderNo,'MI0','I'),'MO0','O')+ RIGHT('0000'+ cast(NONO As varchar),4),
		Status=0, ZMESGUID=@ZMESGUID,ZCSRQSJ =@CurrDate,UniqueCode=null,TailQty='0'
		from #SAP_Interface_PPMES0001Temp
	----将误差加到任一生产单
	 Select MISCDET,DistributionQty,Sum(Cast(ERFMG_I As decimal(18,8)))As QtyDis into #QtyDis from #SAP_Interface_PPMES0001Temp
		Group by MISCDET,DistributionQty
	--MI0000043810238
	Update b
		Set b.ERFMG_I=Left(Cast(CAST(ERFMG_I as decimal(18,8))+round(a.DistributionQty,3)-QtyDis as varchar),13)
		,TailQty = Cast((a.DistributionQty-round(a.DistributionQty,3)) As decimal(18,8))
		 from #QtyDis a ,(Select *,ROW_NUMBER()over(PARTITION By MISCDET Order by ERFMG_I) As NONOROW  from #SAP_Interface_PPMES0001Temp) b
		Where a.MISCDET =b.MISCDET and b.NONOROW =1
	--保存调整的报工单号和订单号 Select * from #SAP_Interface_PPMES0001Temp Select top 100 * from SAP_Interface_PPMES0001
	Insert into SAP_Interface_AdjustMstr
		Select distinct MiscOrderNo,@BatchNo,@CurrDate from #SAP_Interface_PPMES0001Temp 
	Insert into SAP_Interface_AdjustDet(MiscOrder, MiscOrderDet, AdjustSAPOrder, ZMESLN, BatchNo, CreateDate) 
		Select distinct MiscOrderNo,ZComnum,ZMESSC,ZMESLN,@BatchNo,@CurrDate from #SAP_Interface_PPMES0001Temp 
	
	--插入接口数据
	Insert into SAP_Interface_PPMES0001(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, 
		BWART_H, LGORT_H, ERFMG_H, ZComnum, MTSNR, LMNGA_H, ISM, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, 
		ZCSRQSJ, BatchNo, UniqueCode, Status, OrderType,TailQty)
	Select ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, 
		BWART_H, LGORT_H, ERFMG_H, ZComnum, MTSNR, LMNGA_H, ISM, BWART_I, MATNR_I,Left( abs(round(Cast(ERFMG_I as decimal(18,8)),3)) ,13) As ERFMG_I, 
		GMEIN_I, LGORT_I, ZMESGUID,ZCSRQSJ, BatchNo, UniqueCode, Status, OrderType,
		TailQty
		from #SAP_Interface_PPMES0001Temp
	
	--Select * from #MiscOrdDet where IsDistribution =0
	
	--Truncate table SAP_Interface_PPMES0001
	----没有投料的要通过PPMES0005接口传送

	--含义	接口字段	长度	MES取数说明
	--MES订单号	ZMESSC	20	
	--MES行号	ZMESLN	4	
	--调整单号	AdjustOrderNo	20	
	--调整单行号	AdjustSeq	4	
	--调整时间	AdjustDate	20	

	Insert into SAP_Interface_PPMES0005(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, 
		ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,TailQty)
		Select  MiscMstr.MiscOrderNo As ZMESSC, '1'/*MiscDet.Seq*/ As ZMESLN,'BUSTZ01' As ZPTYPE,'SY05' As AUFART, @WERKS As WERKS,/*--0003 '40'*/ isnull(MiscMstr.Note,'') As MATXT,'1' AS GAMNG_H, 
			MiscDet.BaseUom As GMEIN_H, MiscMstr.CreateDate As GLTRP,MiscMstr.CreateDate As GSTRP,MiscMstr.EffDate As BLDAT,MiscMstr.EffDate As BUDAT,MiscMstr.MoveType As BWART_I,
			MiscDet.Item As MATNR_I,Left(cast(abs(round(MiscDet.Qty*MiscDet.UnitQty,3)) As varchar),13) As ERFMG_I,MiscDet.BaseUom As GMEIN_I,MiscMstr.Location As LGORT_I,
			@ZMESGUID As ZMESGUID,@ExecutionTimeStr ZCSRQSJ,@BatchNo BatchNo,null as UniqueCode, '0' As status,
			Left(cast(MiscDet.Qty*MiscDet.UnitQty-round(MiscDet.Qty*MiscDet.UnitQty,3) As varchar),50) As TailQty
			from ORD_MiscOrderMstr MiscMstr ,ORD_MiscOrderDet MiscDet 
			where MiscMstr.MiscOrderNo =MiscDet.MiscOrderNo
			and MiscMstr.SubType=50
			and Id not in (select Id from #MiscOrdDet where IsDistribution='1')
			and MiscMstr.MiscOrderNo in (select MiscOrderNo from #MiscOrdDet)
			and MiscMstr.CloseDate between @StartTime and @EndTime  
			and MiscMstr.CreateUser<>3910
			
	Update a
		Set a.LGORT_I=b.SAPLocation from SAP_Interface_PPMES0005 a, MD_Location b where a.LGORT_I=b.Code and a.BatchNo=@BatchNo
	Delete SAP_Interface_PPMES0005 where BatchNo=@BatchNo and LGORT_I='N/A'
	/*----***********
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
	Select dbo.FormatDate(@CurrDate,'YYYYMMDDHH') As ZMESSC, ROW_NUMBER()Over(Order by MATNR_I) As ZMESLN, 'BUSTZ01' As ZPTYPE,'SY05'As AUFART,@WERKS As WERKS, 'MATXT'AS MATXT,'1'AS GAMNG_H, 
		GMEIN_I As GMEIN_H,GetDate()AS GLTRP,GetDate()AS GSTRP, GetDate()AS BLDAT, GetDate()AS BUDAT, 
		Case when sum(Case when OrderType='AdjustOrder' and BWART_I = '261' then -1 else 1 End*cast(TailQty As decimal(28,18))) <0 then  '261' else '262' End As BWART_I, MATNR_I, 
		left(Cast(ABS(sum(Case when OrderType='AdjustOrder' and BWART_I = '261' then -1 else 1 End *cast(TailQty As decimal(28,18)))) as varchar),13) As ERFMG_I, GMEIN_I, LGORT_I,
		@ZMESGUID As ZMESGUID,@ExecutionTimeStr ZCSRQSJ,@BatchNo BatchNo,null as UniqueCode, '0' As status,0 As tailQty,'2'
		from SAP_Interface_PPMES0001 a
		where cast(TailQty As decimal(28,18)) !=0
		and OrderType in ('EXOrder','MIOrder','FIOrder'/*,'AdjustOrder'*/)
		and ZCSRQSJ between @MonthStart and @MonthEnd
		and not exists(select 0 from SAP_Interface_PPMES0002 b where a.ZComnum=b.ZComnum)
		Group by WERKS,MATNR_I,GMEIN_I,LGORT_I
		having ABS(sum(cast(TailQty As decimal(28,18))))>0.001
		
	--废品报工尾差
 	Insert into #SAP_Interface_PPMES0005(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, 
		ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,TailQty,Type)
	Select dbo.FormatDate(@CurrDate,'YYYYMMDDHH') As ZMESSC, ROW_NUMBER()Over(Order by MATNR_I) As ZMESLN, 'BUSTZ01' As ZPTYPE,'SY05'As AUFART,@WERKS As WERKS, 'MATXT'AS MATXT,'1'AS GAMNG_H, 
		GMEIN_I As GMEIN_H,GetDate()AS GLTRP,GetDate()AS GSTRP, GetDate()AS BLDAT, GetDate()AS BUDAT, 
		Case when sum(cast(TailQty As decimal(28,18))) <0 then  '261' else '262' End As BWART_I, MATNR_I, 
		left(Cast(ABS(sum(cast(TailQty As decimal(28,18)))) as varchar),13) As ERFMG_I, GMEIN_I, LGORT_I,
		@ZMESGUID As ZMESGUID,@ExecutionTimeStr ZCSRQSJ,@BatchNo BatchNo,null as UniqueCode, '0' As status,0 As tailQty,'3'
		from SAP_Interface_PPMES0003 a
		where cast(TailQty As decimal(28,18)) !=0
		and ZCSRQSJ between @MonthStart and @MonthEnd
		and not exists(select 0 from SAP_Interface_PPMES0003 b where a.ZComnum=b.ZComnum and b.ZPTYPE= 'BUSCX02')
		Group by WERKS,MATNR_I,GMEIN_I,LGORT_I
		having ABS(sum(cast(TailQty As decimal(28,18))))>0.001
	----按照库位合并调整单
	Select top 0 * into #SAP_Interface_PPMES0005_Tem from SAP_Interface_PPMES0005 where 1=2
		Insert into #SAP_Interface_PPMES0005_Tem
			Select ZMESSC, 1 As ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GETDATE() GLTRP,GETDATE() GSTRP, GETDATE()BLDAT, GETDATE()BUDAT, 
			Case when sum(cast(ERFMG_I As decimal(28,18))*case when BWART_I='261' then -1 else 1 end) <0 then  '261' else '262' End As BWART_I, MATNR_I,
			left(Cast(ABS(sum(cast(ERFMG_I As decimal(28,18))*case when BWART_I='261' then -1 else 1 end)) as varchar),13) As ERFMG_I,
			  GMEIN_I, LGORT_I, 
			@ZMESGUID As ZMESGUID,@ExecutionTimeStr ZCSRQSJ,@BatchNo BatchNo,null as UniqueCode, '0' As status,0 As tailQty,'4' 
			from #SAP_Interface_PPMES0005
			Group by ZMESSC,ZPTYPE,AUFART,WERKS,MATXT,GAMNG_H,GMEIN_H,MATNR_I,   GMEIN_I, LGORT_I
		
		Select *,Dense_rank()Over(Partition by ZMESSC Order by LGORT_I) As ZMESLNSEQ into #SAP_Interface_PPMES0005_Insert from #SAP_Interface_PPMES0005_Tem
		Update #SAP_Interface_PPMES0005_Insert
		Set MATXT =b.saplocdesc, ZMESLN=ZMESLNSEQ from #SAP_Interface_PPMES0005_Tem a,MD_SAPlocdesc b where a.LGORT_I=b.saploc
		
		--Select * from #SAP_Interface_PPMES0005_Insert
		Insert into SAP_Interface_PPMES0005(
			ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, ERFMG_I, 
			GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status, TailQty, Type)
			Select ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATXT, GAMNG_H, GMEIN_H, GLTRP, GSTRP, BLDAT, BUDAT, BWART_I, MATNR_I, ERFMG_I, 
				GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status, TailQty, Type from #SAP_Interface_PPMES0005_Insert
	----更新3个必输字段
	----传送尾差End*/
	
		
	---调整单冲销
	----冲销报工号为空，就按订单号和订单行号去冲销
	Insert into SAP_Interface_PPMES0002(ZMESSC, ZMESLN, ZPTYPE, ZComnum, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType)
		Select Distinct ZMESSC,ZMESLN,'BUSCX01' As ZPTYPE,'' As ZComnum,@ZMESGUID,@CurrDate,@BatchNo,null As UniqueCode,
		'0' AS Status, 'AdjustOrder' As OrderType from SAP_Interface_PPMES0005
		where ZMESSC in (Select MiscOrderNo from #CancelMiscOrderNo)
	
	Insert into SAP_Interface_PPMES0002(ZMESSC, ZMESLN, ZPTYPE, ZComnum, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType)
		Select Distinct AdjustSAPOrder,ZMESLN,'BUSCX01' As ZPTYPE,MiscOrderDet As ZComnum,@ZMESGUID,@CurrDate,@BatchNo,null As UniqueCode,
		'0' AS Status, 'AdjustOrder' As OrderType from SAP_Interface_AdjustDet
		where MiscOrder in (Select MiscOrderNo from #CancelMiscOrderNo)
	--全部走了生产报工的调整单统计
	Select distinct MiscOrder into #SCO from SAP_Interface_AdjustDet where MiscOrderDet in
		(Select ZComnum from SAP_Interface_PPMES0002 where BatchNo =@BatchNo and OrderType='AdjustOrder' and ZMESSC like 'O%')
	-----如果是上线之前的冲销，在这里全部通过SY05冲销
	If exists(Select * from #CancelMiscOrderNo where MiscOrderNo not in(select ZMESSC from SAP_Interface_PPMES0002) and MiscOrderNo not in (select * from #SCO))
		Begin
			Select MiscOrderNo into #MiscOrderNo from #CancelMiscOrderNo where MiscOrderNo not in(select ZMESSC from SAP_Interface_PPMES0002)
			Insert into SAP_Interface_PPMES0002(ZMESSC, ZMESLN, ZPTYPE, ZComnum, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status,OrderType)
				Select distinct MiscMstr.MiscOrderNo As ZMESSC, '1' As ZMESLN,'BUSCX01' As ZPTYPE,
				'' As ZComnum,@ZMESGUID,@CurrDate,@BatchNo,null As UniqueCode,
				'0' AS Status, 'AdjustOrder' As OrderType  
				from ORD_MiscOrderMstr MiscMstr ,ORD_MiscOrderDet MiscDet 
				where MiscMstr.MiscOrderNo =MiscDet.MiscOrderNo
				and MiscMstr.SubType=50
				and MiscMstr.MiscOrderNo in (Select MiscOrderNo from #MiscOrderNo)
				and MiscMstr.CreateUser<>3910
		End
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
	--调整数0不传
	Update SAP_Interface_PPMES0005
		Set Status ='1' from SAP_Interface_PPMES0005 where CAST(ERFMG_I As decimal(18,8)) =0 and BatchNo=@BatchNo
		SELECT Status=1,BatchNo=@BatchNo,'生成调整数据成功。'
	--CancelDate
	Update a
	Set a.Canceldate=b.LastModifyDate from SAP_Interface_PPMES0002 a,ORD_MiscOrderMstr b
	 where BatchNo= @BatchNo
	 and a.ZMESSC=b.MiscOrderNo
	 and b.SubType =50
	---Update UniqueCode	
	----************************
		--插入成本中心发料接口
		Select Code into #NONSAP from MD_Location where SAPLocation ='N/A' ----and Region not like 'S%'
		SELECT *,SPACE(50) As LIFNR1 INTO #Temp1_STMES0001 FROM SAP_Interface_STMES0001 WHERE 1<>1
		SELECT *,SPACE(50) As LIFNR1 INTO #Temp2_STMES0001 FROM SAP_Interface_STMES0001 WHERE 1<>1
		INSERT INTO #Temp1_STMES0001(ZMESKO, ZMESKOSEQ, BWARTWA, WERKS, BLDAT, BUDAT, LGORT, KOSTL, LIFNR, MATNR1, EPFMG, 
			ERFME, MATNR_TH, UMLGO, ZMESGUID, ZCSRQSJ, Status, BatchNo, DataType,LIFNR1)
		SELECT mm.MiscOrderNo+mm.MoveType,md.Seq,MoveType,@WERKS AS WERKS,mm.EffDate,mm.EffDate AS BUDAT,
			Case when l.Region like 'S%' and l.SAPLocation ='N/A' then l.Code else l.SAPLocation End AS LGORT,mm.CostCenter,mm.MiscOrderNo AS LIFNR,md.Item,CAST(md.Qty*md.UnitQty AS decimal(10,3)) AS Qty,
			md.BaseUom,'' AS MATNR_TH,'' AS UMLGO,mm.MiscOrderNo+'0' As ZMESGUID,@CurrDate,0,@BatchNo, 3,mm.MiscOrderNo
		FROM ORD_MiscOrderMstr mm INNER JOIN ORD_MiscOrderDet md ON mm.MiscOrderNo=md.MiscOrderNo
		INNER JOIN MD_Location l ON l.Code=mm.Location
		WHERE mm.SubType in(0,26) AND mm.CloseDate>@StartTime AND mm.CloseDate<=@EndTime AND mm.IsCs=0
		--0004--0005
		AND mm.Location not in (Select Code from #NONSAP) AND mm.CreateUser<>3910
		
		INSERT INTO #Temp2_STMES0001(ZMESKO, ZMESKOSEQ, BWARTWA, WERKS, BLDAT, BUDAT, LGORT, KOSTL, LIFNR, MATNR1, EPFMG, 
			ERFME, MATNR_TH, UMLGO, ZMESGUID, ZCSRQSJ, Status, BatchNo, DataType,LIFNR1)
		SELECT mm.MiscOrderNo+mm.CancelMoveType,md.Seq,CancelMoveType,@WERKS AS WERKS,mm.CancelDate,mm.CancelDate AS BUDAT,
			Case when l.Region like 'S%' and l.SAPLocation ='N/A' then l.Code else l.SAPLocation End AS LGORT,mm.CostCenter,mm.MiscOrderNo AS LIFNR,md.Item,CAST(md.Qty*md.UnitQty AS decimal(10,3)) AS Qty,
			md.BaseUom,'' AS MATNR_TH,'' AS UMLGO,mm.MiscOrderNo+'1' As ZMESGUID,@CurrDate,0,@BatchNo, 3,mm.MiscOrderNo
		FROM ORD_MiscOrderMstr mm INNER JOIN ORD_MiscOrderDet md ON mm.MiscOrderNo=md.MiscOrderNo
		INNER JOIN MD_Location l ON l.Code=mm.Location
		WHERE mm.SubType in(0,26) AND mm.Status=2 AND mm.CancelDate>@StartTime AND mm.CancelDate<=@EndTime AND mm.IsCs=0
		--0004--0005
		AND mm.Location not in (Select Code from #NONSAP) AND mm.LastModifyUser<>3910
		--插入委外成本中心发货,先移库到虚拟库,再从虚拟库成本中心发货--0006
		--正向
		--1.采购到虚拟库,为了使GUID不重复，一个末尾为0，一个末尾为1
		Select Code into #SubconctractingLoc from MD_Location where SAPLocation ='N/A' and Region  like 'S%'
		Declare @SubconctractingSwitchSAPLoction varchar(4)
		Select @SubconctractingSwitchSAPLoction=Value from SYS_EntityPreference where Id =90113
		INSERT INTO #Temp1_STMES0001(ZMESKO, ZMESKOSEQ, BWARTWA, WERKS, BLDAT, BUDAT, LGORT, KOSTL, LIFNR, MATNR1, EPFMG, 
			ERFME, MATNR_TH, UMLGO, ZMESGUID, ZCSRQSJ, Status, BatchNo, DataType,LIFNR1)
		SELECT mm.MiscOrderNo+mm.MoveType+'0',md.Seq,CASE WHEN mm.MoveType='201' THEN '542' ELSE '541' END AS BWARTWA,@WERKS AS WERKS,mm.EffDate,mm.EffDate AS BUDAT,
			@SubconctractingSwitchSAPLoction  AS LGORT,mm.CostCenter,mm.Location AS LIFNR,md.Item,CAST(md.Qty*md.UnitQty AS decimal(10,3)) AS Qty,
			md.BaseUom,'' AS MATNR_TH,'' AS UMLGO,mm.MiscOrderNo+'0' As ZMESGUID,@CurrDate,0,@BatchNo, 3,mm.MiscOrderNo
		FROM ORD_MiscOrderMstr mm INNER JOIN ORD_MiscOrderDet md ON mm.MiscOrderNo=md.MiscOrderNo
		INNER JOIN MD_Location l ON l.Code=mm.Location
		WHERE mm.SubType in(0) AND mm.CloseDate>@StartTime AND mm.CloseDate<=@EndTime AND mm.IsCs=0
		AND mm.Location in (Select Code from #SubconctractingLoc) AND mm.CreateUser<>3910
		--2.从虚拟库成本中心发料
		INSERT INTO #Temp1_STMES0001(ZMESKO, ZMESKOSEQ, BWARTWA, WERKS, BLDAT, BUDAT, LGORT, KOSTL, LIFNR, MATNR1, EPFMG, 
			ERFME, MATNR_TH, UMLGO, ZMESGUID, ZCSRQSJ, Status, BatchNo, DataType,LIFNR1)
		SELECT mm.MiscOrderNo+mm.MoveType+'1',md.Seq,MoveType,@WERKS AS WERKS,mm.EffDate,mm.EffDate AS BUDAT,
			@SubconctractingSwitchSAPLoction AS LGORT,mm.CostCenter,mm.MiscOrderNo AS LIFNR,md.Item,CAST(md.Qty*md.UnitQty AS decimal(10,3)) AS Qty,
			md.BaseUom,'' AS MATNR_TH,'' AS UMLGO,mm.MiscOrderNo+'0' As ZMESGUID,@CurrDate,0,@BatchNo, 3,mm.MiscOrderNo
		FROM ORD_MiscOrderMstr mm INNER JOIN ORD_MiscOrderDet md ON mm.MiscOrderNo=md.MiscOrderNo
		INNER JOIN MD_Location l ON l.Code=mm.Location
		WHERE mm.SubType in(0) AND mm.CloseDate>@StartTime AND mm.CloseDate<=@EndTime AND mm.IsCs=0
		AND mm.Location in (Select Code from #SubconctractingLoc) AND mm.CreateUser<>3910
		
		--反向(冲销)
		--1.移库到虚拟库
		INSERT INTO #Temp2_STMES0001(ZMESKO, ZMESKOSEQ, BWARTWA, WERKS, BLDAT, BUDAT, LGORT, KOSTL, LIFNR, MATNR1, EPFMG, 
			ERFME, MATNR_TH, UMLGO, ZMESGUID, ZCSRQSJ, Status, BatchNo, DataType,LIFNR1)
		SELECT mm.MiscOrderNo+mm.CancelMoveType+'0',md.Seq,CASE WHEN mm.CancelMoveType='202' THEN '541' ELSE '542' END AS BWARTWA,@WERKS AS WERKS,mm.CancelDate,mm.CancelDate AS BUDAT,
			@SubconctractingSwitchSAPLoction  AS LGORT,mm.CostCenter,mm.Location AS LIFNR,md.Item,CAST(md.Qty*md.UnitQty AS decimal(10,3)) AS Qty,
			md.BaseUom,'' AS MATNR_TH,'' AS UMLGO,mm.MiscOrderNo+'1' As ZMESGUID,@CurrDate,0,@BatchNo, 3,mm.MiscOrderNo
		FROM ORD_MiscOrderMstr mm INNER JOIN ORD_MiscOrderDet md ON mm.MiscOrderNo=md.MiscOrderNo
		INNER JOIN MD_Location l ON l.Code=mm.Location
		WHERE mm.SubType in(0) AND mm.CancelDate>@StartTime AND mm.Status=2 AND mm.CancelDate<=@EndTime AND mm.IsCs=0
		AND mm.Location in (Select Code from #SubconctractingLoc) AND mm.CreateUser<>3910
		--2.从虚拟库成本中心发料
		INSERT INTO #Temp2_STMES0001(ZMESKO, ZMESKOSEQ, BWARTWA, WERKS, BLDAT, BUDAT, LGORT, KOSTL, LIFNR, MATNR1, EPFMG, 
			ERFME, MATNR_TH, UMLGO, ZMESGUID, ZCSRQSJ, Status, BatchNo, DataType,LIFNR1)
		SELECT mm.MiscOrderNo+mm.CancelMoveType+'1',md.Seq,CancelMoveType,@WERKS AS WERKS,mm.CancelDate,mm.CancelDate AS BUDAT,
			@SubconctractingSwitchSAPLoction AS LGORT,mm.CostCenter,mm.MiscOrderNo AS LIFNR,md.Item,CAST(md.Qty*md.UnitQty AS decimal(10,3)) AS Qty,
			md.BaseUom,'' AS MATNR_TH,'' AS UMLGO,mm.MiscOrderNo+'1' As ZMESGUID,@CurrDate,0,@BatchNo, 3,mm.MiscOrderNo
		FROM ORD_MiscOrderMstr mm INNER JOIN ORD_MiscOrderDet md ON mm.MiscOrderNo=md.MiscOrderNo
		INNER JOIN MD_Location l ON l.Code=mm.Location
		WHERE mm.SubType in(0) AND mm.CancelDate>@StartTime AND mm.Status=2 AND  mm.CancelDate<=@EndTime AND mm.IsCs=0
		AND mm.Location in (Select Code from #SubconctractingLoc) AND mm.CreateUser<>3910
		
		--插入委外成本中心发货,走转手流程
		--处理计划外出入库同一个批次发生冲销的问题	
		SELECT s1.LIFNR1 INTO #TEMP2 FROM #Temp1_STMES0001 s1 INNER JOIN #Temp2_STMES0001 s2 ON s1.LIFNR1=s2.LIFNR1
		WHERE s1.BatchNo=@BatchNo AND s2.BatchNo=@BatchNo
		IF @@ROWCOUNT>0
		BEGIN
			DELETE a FROM #Temp1_STMES0001 a INNER JOIN #TEMP2 b ON a.LIFNR1=b.LIFNR1
			DELETE a FROM #Temp2_STMES0001 a INNER JOIN #TEMP2 b ON a.LIFNR1=b.LIFNR1
		END
		
		DROP TABLE #TEMP2
		INSERT INTO SAP_Interface_STMES0001(ZMESKO, ZMESKOSEQ, BWARTWA, WERKS, BLDAT, BUDAT, LGORT, KOSTL, LIFNR, MATNR1, EPFMG, ERFME, MATNR_TH, UMLGO, ZMESGUID, ZCSRQSJ, Status, BatchNo, UniqueCode)
		SELECT ZMESKO, ZMESKOSEQ, BWARTWA, WERKS, BLDAT, BUDAT, LGORT, KOSTL, LIFNR, MATNR1, EPFMG, ERFME, MATNR_TH, UMLGO, ZMESGUID, ZCSRQSJ, Status, BatchNo, UniqueCode FROM #Temp1_STMES0001
		UNION ALL
		SELECT ZMESKO, ZMESKOSEQ, BWARTWA, WERKS, BLDAT, BUDAT, LGORT, KOSTL, LIFNR, MATNR1, EPFMG, ERFME, MATNR_TH, UMLGO, ZMESGUID, ZCSRQSJ, Status, BatchNo, UniqueCode FROM #Temp2_STMES0001
		
		DECLARE @UniqueCode2 varchar(50)
		WHILE EXISTS(SELECT * FROM SAP_Interface_STMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL)
		BEGIN
			DECLARE @LastOrderNo2 varchar(50)
			SET @UniqueCode2=REPLACE(NEWID(),'-','')
			UPDATE TOP(5000) SAP_Interface_STMES0001 SET UniqueCode=@UniqueCode2 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			SELECT TOP 1 @LastOrderNo2=ZMESKO FROM SAP_Interface_STMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			PRINT @LastOrderNo2
			IF EXISTS(SELECT 1 FROM SAP_Interface_STMES0001 WHERE BatchNo=@BatchNo AND UniqueCode=@UniqueCode2 AND ZMESKO=@LastOrderNo2 )
			BEGIN
				UPDATE SAP_Interface_STMES0001 SET UniqueCode=@UniqueCode2 WHERE BatchNo=@BatchNo AND ZMESKO=@LastOrderNo2
			END
		END
		----0003--移库的产品组信息已经不重要，可以为空
		Update a
			Set a.SPART =isnull(b.Division,'') from SAP_Interface_STMES0001 a,MD_Item b 
				Where a.BatchNo=@BatchNo and a.MATNR1 =b.Code
		----0003
		SELECT Status=1,BatchNo=@BatchNo,'生成库存转储接口数据成功。'
END