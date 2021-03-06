USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_GetMiDailyPlan]    Script Date: 12/08/2014 15:23:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USP_Busi_GetMiShiftPlan '2013/6/21 13:55:41','MI01[炼胶主线]','Get'
 
ALTER PROCEDURE [dbo].[USP_Busi_MRP_GetMiDailyPlan]
 
AS
BEGIN
	SET NOCOUNT ON
	----2014/07/17		单包装取BOMMSTR的基本数量	--0001
	----2014/07/17		Done 导出日期到最新挤出版本周的截止日期	--0002
	----2014/07/17		Done  库存取8点的快照(新增快照Or推算?????)--0003
	----2014/12/08		腔口数--0004
	Declare @PlanVersion datetime
	Declare @CurrentDate datetime
	Declare @CurrentTime datetime=Getdate()
	Declare @SnapTime datetime
	Declare @EndDate datetime
	select @CurrentDate=  dbo.FormatDate ( GETDATE(),'YYYY-MM-DD ')+'00:00:00'
	select @EndDate =DATEADD(SECOND,-1,DATEADD (day,12,@CurrentDate))
	print @CurrentDate
	print @EndDate
	Declare @TimeDiff int 
	select @TimeDiff=substring(shifttime,1,2)*60+substring(shifttime,4,2)*1 from PRD_ShiftDet where Shift like 'EX3-1%'
	--取7:45点到次日7:45点的计划数据
	--set @CurrentDate =DATEADD(MINUTE,@TimeDiff,@CurrentDate) 
	--set @EndDate =DATEADD(MINUTE,@TimeDiff,@EndDate) 
	

	Select @PlanVersion=max(planversion) from mrp_mrpplanmaster with(nolock) where ResourceGroup = 10 and IsRelease = 1
	--
	--Select @SnapTime =[dbo].[GetStartInvSnapTimeByDate](GETDATE())
	--Select @SnapTime=SnapTime  from MRP_MrpPlanMaster with(nolock) where PlanVersion =@PlanVersion and ResourceGroup = 10
	--
	Select top 1 @SnapTime=SnapTime from MRP_InventoryBalance_MIPlan
	select Item,b.UC,a.Location, round(SUM(Qty+Ipqty)/b.UC,1) as Qty into #LocationDet from MRP_InventoryBalance_MIPlan a with(nolock) ,MD_Item b with(nolock)  
		where a.Location in('9201','9202','9203','9204') and a.Item =b.Code and a.SnapTime=@SnapTime group by a.Item,b.UC,a.Location

	----select top 1000* from MRP_InventoryBalance  
	---2014/03/23 取挤出的生产待收拆分BOM Begin
	CREATE TABLE #PlanInQty(
		[Flow] [varchar](50) NULL,
		[OrderType] [tinyint] NOT NULL,
		[Item] [varchar](50) NOT NULL,
		[StartTime] [datetime] NOT NULL,
		[WindowTime] [datetime] NOT NULL,
		[LocationFrom] [varchar](50) NULL,
		[LocationTo] [varchar](50) NULL,
		[Qty] [float] NOT NULL,
		[Bom] [varchar](50) NULL,
		[SourceType] [tinyint] NOT NULL,
		[SourceParty] [varchar](50) NULL,
		)
	CREATE TABLE #PlanInQty1(
		[Flow] [varchar](50) NULL,
		[OrderType] [tinyint] NOT NULL,
		[Item] [varchar](50) NOT NULL,
		[StartTime] [datetime] NOT NULL,
		[WindowTime] [datetime] NOT NULL,
		[LocationFrom] [varchar](50) NULL,
		[LocationTo] [varchar](50) NULL,
		[Qty] [float] NOT NULL,
		[Bom] [varchar](50) NULL,
		[SourceType] [tinyint] NOT NULL,
		[SourceParty] [varchar](50) NULL,
		)
	Declare @EXMrpPlanversion DateTime,@EXMrpPlanversion1 DateTime
	Declare @WeekIndex varchar(20),@WeekIndex1 varchar(20),@NeedDateFrom datetime,@NeedDateTo datetime,@NeedDateFrom1 datetime,@NeedDateTo1 datetime
	select @WeekIndex=WeekIndex,@NeedDateFrom=StartDate,@NeedDateTo=EndDate from MRP_WeekIndex where StartDate<=dbo.FormatDate(getdate(),'YYYY-MM-DD') and EndDate>=dbo.FormatDate(getdate(),'YYYY-MM-DD')
	select @WeekIndex1=WeekIndex,@NeedDateFrom1=StartDate,@NeedDateTo1=EndDate from MRP_WeekIndex where StartDate<=dbo.FormatDate(dateadd(day,7,getdate()),'YYYY-MM-DD') and EndDate>=dbo.FormatDate(dateadd(day,7,getdate()),'YYYY-MM-DD')


	Select @EXMrpPlanversion = max(PlanVersion) from MRP_MrpPlanMaster 
		where ResourceGroup =20 and IsRelease =1  and DateIndex =@WeekIndex
	Select @EXMrpPlanversion1 = max(PlanVersion) from MRP_MrpPlanMaster 
		where ResourceGroup =20 and IsRelease =1  and DateIndex =@WeekIndex1	
	Select @EndDate=EndDate from MRP_WeekIndex where WeekIndex =( Select max(DateIndex) from MRP_MrpPlanMaster where ResourceGroup =20 and IsRelease =1)
	
	print dbo.formatdate(@EXMrpPlanversion,'YYYYMMDDHHNNSS')+'sss'
	print dbo.formatdate(@EXMrpPlanversion1,'YYYYMMDDHHNNSS')+'sss'
	--Select @EXMrpPlanversion,@EXMrpPlanversion
	--当周
	If @EXMrpPlanversion is not null
	Begin
		print 'AA'
		Insert into  #PlanInQty
			Exec USP_Busi_MRP_GetPlanIn @EXMrpPlanversion,'PurchaseInvoke'--''返回所有的线别
	End	
	--下一周
	If @EXMrpPlanversion1 is not null
	Begin
		print 'QQ'
		Insert into  #PlanInQty
			Exec USP_Busi_MRP_GetPlanIn @EXMrpPlanversion1,'PurchaseInvoke'--''返回所有的线别
	End
	--Select @NeedDateFrom1,@NeedDateTo1
	Delete #PlanInQty where dbo.FormatDate(StartTime,'YYYY/MM/DD') not between dbo.FormatDate(@NeedDateFrom,'YYYY/MM/DD') and dbo.FormatDate(@NeedDateTo,'YYYY/MM/DD')
	Delete #PlanInQty1 where dbo.FormatDate(StartTime,'YYYY/MM/DD') not between dbo.FormatDate(@NeedDateFrom1,'YYYY/MM/DD') and dbo.FormatDate(@NeedDateTo1,'YYYY/MM/DD')
	Insert into #PlanInQty
		Select * from #PlanInQty1
	select b.Bom,b.Item,CAST(b.RateQty/m.Qty as float) as UnitQty ,CAST(0 As decimal(18,8)) As UomConvQTy
		into #ParentSubItems
		from PRD_BomDet b,PRD_BomMstr m where b.Bom =m.Code
		and  (b.StartDate<=@CurrentTime or b.StartDate is null)
		and (b.EndDate>@CurrentTime or b.EndDate is null)
		and m.IsActive=1
	Delete a from (Select *,ROW_NUMBER()over(partition by Bom,Item Order by UnitQty)As NONO from #ParentSubItems) a where a.NONO!=1
	Create nonclustered index IX_BOM on #ParentSubItems(Bom)
	Create nonclustered index IX_Item on #ParentSubItems(Item)
	----单位转换Begin
	Select Distinct b.Bom,b.Item,b.Uom As ZUom ,m.Uom As FUom ,CAST(0 As decimal(18,8)) As UomConvQTy,'N' As IsUPdated
		into #UomConvQTy
		from PRD_BomDet b,PRD_BomMstr m where b.Bom =m.Code
		and  b.StartDate<=GETDATE() 
		and b.EndDate>GETDATE()  
		and b.Uom !=m.Uom
		and m.IsActive=1
	Update b
		Set b.UomConvQTy=a.BaseQty/a.AltQty,b.IsUPdated='Y' from MD_UomConv a,#UomConvQTy b 
		where a.Item=b.Bom and a.BaseUom=b.FUom 
		and a.AltUom=b.ZUom 
		
	Update b
		Set b.UomConvQTy=a.AltQty/a.BaseQty,b.IsUPdated='Y' from MD_UomConv a,#UomConvQTy b 
		where a.Item=b.Bom and a.AltUom=b.FUom 
		and a.BaseUom=b.ZUom and b.IsUPdated='N'
		
	Update b
		Set b.UomConvQTy=a.AltQty/a.BaseQty,b.IsUPdated='Y' from MD_UomConv a,#UomConvQTy b 
		where a.Item=b.Item and a.BaseUom=b.ZUom 
		and a.AltUom=b.FUom and b.IsUPdated='N'
		
	Update b
		Set b.UomConvQTy=a.BaseQty/a.AltQty,b.IsUPdated='Y' from MD_UomConv a,#UomConvQTy b 
		where a.Item=b.Item and a.AltUom=b.ZUom 
		and a.BaseUom=b.FUom and b.IsUPdated='N'
	Update a	
		Set a.UnitQty=a.UnitQty * Case when b.IsUPdated ='N' then 1 else  b.UomConvQTy End 
			from #ParentSubItems a ,#UomConvQTy  b where a.Bom=b.Bom and a.Item=b.Item
			
	----单位转换End	
	--Select * from #ParentSubItems
	Select b.Item,dbo.FormatDate(a.StartTime,'YYYY/MM/DD') as Plandate ,a.Qty*b.UnitQty As Qty into #calculate1 
		from #PlanInQty a ,#ParentSubItems b 
		where StartTime >=@CurrentDate
		and a.Item=b.Bom
		and b.Item not like '29%'
		--Group by  b.Item,dbo.FormatDate(a.StartTime,'YYYY/MM/DD')
	Select c.Item,dbo.FormatDate(a.StartTime,'YYYY/MM/DD') as Plandate ,a.Qty*b.UnitQty*c.UnitQty As Qty into #calculate2 
		from #PlanInQty a ,#ParentSubItems b ,#ParentSubItems c
		where StartTime >=@CurrentDate
		and a.Item=b.Bom
		and b.Item =C.Bom
		and b.Item like '29%'
		and c.Item Not like '29%'

		--Group by  b.Item,dbo.FormatDate(a.StartTime,'YYYY/MM/DD')
	Insert into #calculate1
		Select * from #calculate2
	Select Item ,Plandate,SUM(Qty) As QTy into #MrpShipPlan from #calculate1
		Group by Item ,Plandate
	---2014/03/23 取挤出的生产待收拆分BOM End
		--Select * from #ParentSubItems
	Select a.Flow,a.Item As ExItem,b.Item,dbo.FormatDate(a.StartTime,'YYYY/MM/DD') as Plandate ,a.Qty As ExQty,a.Qty*b.UnitQty As Qty 
		into #calculateExItem1
		from #PlanInQty a ,#ParentSubItems b 
		where StartTime >=@CurrentDate
		and a.Item=b.Bom
		and b.Item not like '29%'
		--Group by  b.Item,dbo.FormatDate(a.StartTime,'YYYY/MM/DD')
	Select a.Flow,a.Item As ExItem,c.Item,dbo.FormatDate(a.StartTime,'YYYY/MM/DD') as Plandate,a.Qty As ExQty ,a.Qty*b.UnitQty*c.UnitQty As Qty 
		into #calculateExItem2 
		from #PlanInQty a ,#ParentSubItems b ,#ParentSubItems c
		where StartTime >=@CurrentDate
		and a.Item=b.Bom
		and b.Item =C.Bom
		and b.Item like '29%'
		and c.Item Not like '29%'
	Insert into #calculateExItem1
		Select * from #calculateExItem2
		
Select a.Flow As 生产线,a.Plandate  As 日期,b.Item As 挤出断面,SPACE(50) As 挤出名称,a.Item As 胶料编码, 
	SPACE(50) As 胶料名称 ,max(a.ExQty*b.UnitQty) As 挤出班次,sum(a.Qty) As 数量,  CAST(0 as float) As 折合车数,SPACE(50) As 描述
	into #rectemp
	from #calculateExItem1 a, #ParentSubItems b 
	where a.ExItem =b.Bom and b.Item like '29%'
	and a.Item like '27%'
	Group by a.Flow,b.Item,a.Item,a.Plandate
	
	
Update a
	Set a.折合车数=round(a.数量/isnull (c.MinUC, b.UC),1),a.胶料名称=b.Desc1  from #rectemp a 
	inner join MD_Item b on a.胶料编码=b.Code
	left join (Select UC,MinUC ,Item  from SCM_FlowDet a,SCM_FlowMstr b
	where a.Flow =b.Code and b.ResourceGroup =10 and MinUC!=0) c on a.胶料编码=c.Item
Update a
	Set a.挤出名称=b.Desc1  from #rectemp a,MD_Item b where a.挤出断面=b.Code
	
---移线的挤出资源Begin
Select b.ProductLine,b.Item,MAX(ShiftType)ShiftType ,MAX(MrpSpeed*SpeedTimes/*--0004*/) MrpSpeed
 into #MRP_ProdLineEx from MRP_ProdLineEx b Group by b.ProductLine,b.Item
	--where  (b.StartDate <GETDATE() or b.StartDate is null)
	--and (b.EndDate >GETDATE() or b.EndDate is null)
Insert into #MRP_ProdLineEx
	Select 生产线 ,挤出断面,MAX(c.ShiftType) ,MAX(c.MrpSpeed) from #rectemp a,#MRP_ProdLineEx c
		where not exists(Select * from #MRP_ProdLineEx b 
		where a.生产线=b.ProductLine and a.挤出断面=b.Item )
		and a.挤出断面=c.Item group by 生产线 ,挤出断面
---移线的挤出资源End
	
Update a
	Set a.挤出班次=round(a.挤出班次/b.MrpSpeed/60/(24/b.ShiftType),2) from #rectemp a,#MRP_ProdLineEx b 
	where a.生产线 =b.ProductLine and a.挤出断面=b.Item 

Update #rectemp Set 描述=CAST (挤出班次 As varchar(20))+';'+CAST ( round(数量,2) As varchar(20))+';'+CAST (折合车数 As varchar(20))
	--select * into #MRP_MrpShipPlan from MRP_MrpShipPlan s with(nolock) 
	--	where s.PlanVersion =@PlanVersion
	--Create index IX_Item on  #MRP_MrpShipPlan (item)
	--select s.Item,b.UC ,dbo.FormatDate(s.StartTime,'YYYY/MM/DD') as PlanDate,round(SUM(s.Qty)/b.UC,1) as Qty into #MrpShipPlan from #MRP_MrpShipPlan s , MD_Item b with(nolock)
	--	 where s.StartTime between @CurrentDate and @EndDate  and s.item=b.Code group by  s.Item,b.UC ,dbo.FormatDate(s.StartTime,'YYYY/MM/DD')
	--select distinct dbo.FormatDate( StartTime,'YYYY/MM/DD') from  #MRP_MrpShipPlan
	select * from  #LocationDet
	----0001	Begin
	----2014/03/25返回数量换算到车，炼胶比较特殊，单包装取MD_ITEM(胶料在折算成车的时候请按单车重量来折算)
	--UPdate a
	--   Set a.QTy=round(a.QTy/ isnull (c.MinUC, b.UC),1)from #MrpShipPlan a 
	--   inner join MD_Item b on  a.Item=b.Code
	--   left join (Select UC,MinUC ,Item  from SCM_FlowDet a,SCM_FlowMstr b
	--   where a.Flow =b.Code and b.ResourceGroup =10 and MinUC!=0) c on a.Item=c.Item
	UPdate a
	   Set a.QTy=round(a.QTy/ isnull (c.Qty, b.UC),1)from #MrpShipPlan a 
	   inner join MD_Item b on  a.Item=b.Code
	   left join PRD_BomMstr c on a.Item=c.Code
	----0001	End
	--Select UC,MinUC ,Item  from SCM_FlowDet a,SCM_FlowMstr b where a.Flow =b.Code and b.ResourceGroup =10
	
	Declare @SQL varchar(max)=''
	Declare @SQL1 varchar(max)=''
	SELECT DISTINCT PlanDate INTO #tmp1 FROM #MrpShipPlan ORDER BY PlanDate
	--如果没有任何的发货计划就塞入当前日期，并返回0数量
		Declare @i int =0
		Declare @CheckDate varchar(20) 
		Declare @StartDate1 dateTime 
		Declare @EndDate1 dateTime 
		Select @StartDate1=dbo.FormatDate(GETDATE(),'YYYY/MM/DD')
		Select @EndDate1=dbo.FormatDate( dateadd(day,15,@StartDate1),'YYYY/MM/DD')
		
		While @i<15
		Begin
			Set @CheckDate = dbo.FormatDate( dateadd(day,@i,@StartDate1),'YYYY/MM/DD')
			If not exists(select 0 from #tmp1 where PlanDate = @CheckDate)
				Begin
					print @CheckDate
					Insert into #tmp1
						Select @CheckDate where @CheckDate<=@EndDate1
				End
			Set @i=@i+1
		End
		Delete #tmp1 where Plandate >@EndDate
	SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),PlanDate)+'],0)'+' as ['+PlanDate +'],'
		,@SQL1=@SQL1+'['+PlanDate +'],'
	FROM #tmp1 ORDER BY PlanDate
	IF @SQL!=''
	BEGIN
		SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
		SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
	END		 
	set @SQL='SELECT Item ,'+@SQL+' into #Record FROM (select * from #MrpShipPlan) as D  pivot(max(Qty)'+
	' for PlanDate in ('+@SQL1+')) as PVT order by Item desc; select * from #Record '
	Print @SQL
	EXEC (@SQL)
	----增加返回挤出生产需求明细
	--Select Flow As 生产线,Item As 物料,dbo.FormatDate(starttime,'YYYY-MM-DD') As 日期,Qty As 数量 from #PlanInQty
	Select @SQL='',@SQL1=''
	SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),PlanDate)+'],0)'+' as ['+PlanDate +'],'
		,@SQL1=@SQL1+'['+PlanDate +'],'
	FROM #tmp1 ORDER BY PlanDate
	IF @SQL!=''
	BEGIN
		SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
		SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
	END	
	set @SQL='SELECT 胶料编码,胶料名称,生产线,挤出断面,挤出名称 ,'+@SQL+'FROM (select * from #rectemp) as D  pivot(max(描述)'+
	' for 日期 in ('+@SQL1+')) as PVT order by 胶料编码 desc'
	Print @SQL
	EXEC (@SQL)
	--Select * from #rectemp


END
