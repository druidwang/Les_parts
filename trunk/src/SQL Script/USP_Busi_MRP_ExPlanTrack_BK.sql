USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_ExPlanTrack_BK]    Script Date: 12/08/2014 15:08:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[USP_Busi_MRP_ExPlanTrack_BK] 
(
	@PlanVersion datetime,
	@Flow varchar(20)=''
	
)
AS
BEGIN
--[USP_Busi_MRP_ExPlanTrack_BK] '2014-03-21 13:37:45'
--收的部分BOM拆分是否有问题???
set nocount on
		--Select * from #FiPlanQty
	---XXXXXX
	Declare @WeekIndex varchar(50)
	Declare @PlanVersionEndDate datetime
	Declare @NextWeekIndex varchar(50)--下一周
	Declare @AfterNextWeekIndex varchar(50)--下下周
	Declare @PlanVersionWeekIndex varchar(50)
	select @WeekIndex=WeekIndex from MRP_WeekIndex where StartDate<=dbo.FormatDate(getdate(),'YYYY-MM-DD') and EndDate>=dbo.FormatDate(getdate(),'YYYY-MM-DD')

	select @NextWeekIndex=WeekIndex from MRP_WeekIndex where StartDate<= dateadd(day,7,GETDATE()) and EndDate>=dateadd(day,7,GETDATE())
	select @AfterNextWeekIndex=WeekIndex from MRP_WeekIndex where StartDate<= dateadd(day,14,GETDATE()) and EndDate>=dateadd(day,14,GETDATE())
	select @PlanVersionWeekIndex=DateIndex from MRP_MrpPlanMaster where PlanVersion =@PlanVersion
	--0001   
    Select @PlanVersionEndDate=EndDate from MRP_WeekIndex where WeekIndex =@PlanversionWeekIndex
    --0001 


	declare @StartDate datetime = dbo.FormatDate(GETDATE(),'YYYY/MM/DD');
	declare @EndDate datetime;
	declare @SnapTime datetime = dbo.GetStartInvSnapTimeByDate(getdate());

	select p.Item as Section,AVG(p.MrpSpeed) as Speed,
	stuff((SELECT ' ' + ProductLine from MRP_ProdLineEx as t where t.Item = p.Item FOR xml path('')), 1, 1, '') as Flow
	into #SectionFlow
	from MRP_ProdLineEx p where 1=1 and p.StartDate<=GETDATE() and  p.EndDate>GETDATE()
	group by Item

	Create Table #Plandates (Plandate varchar(20))
	Declare @i As int=0
	while @i <14
		Begin
			Insert into #Plandates
				Select dbo.FormatDate(dateadd(day,@i,GETDATE()),'YYYY/MM/DD')
			Set @i =@i + 1
		End
	select b.Item as 断面,i1.Desc1 as 断面描述,s.Flow as 生产线,isnull(ScrapPct,0)ScrapPct ,
	i2.Code as 半制品,i2.Desc1 as 半制品描述,Plandate,
	CAST(b.RateQty/m.Qty as decimal(18,2)) as 单位长度,
	CAST(0 as decimal) as 当前库存,CAST(0 as decimal) as 待收,CAST(0 as decimal) as 待发,'N' as 报警
	into #Plan
	from PRD_BomDet b,#SectionFlow s,PRD_BomMstr m,MD_Item i1,MD_Item i2,#Plandates 
	where b.Item = s.Section and m.Code = b.Bom and i1.Code = b.Item and i2.Code = b.Bom
	and b.Item like '29%' and b.StartDate<=GETDATE() and b.EndDate>GETDATE() and b.BomMrpOption in (0,2) and m.IsActive=1
	
	--Select * from #Plandates
	select top 1 @EndDate = EndDate from MRP_WeekIndex w
	join MRP_MrpPlanMaster p on w.WeekIndex = p.DateIndex
	 where PlanVersion=@PlanVersion
	--Add on 2014/03/01
    Select @EndDate = dbo.FormatDate(Dateadd(day,14,GETDATE()),'YYYY/MM/DD');
	--待发--取得后加工的收并拆分BOM
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
	Declare @FiMrpPlanversion DateTime
	Select @FiMrpPlanversion = max(PlanVersion) from MRP_MrpPlanMaster 
		where ResourceGroup =30 and IsRelease =1 
	Insert into  #PlanInQty
		Exec USP_Busi_MRP_GetPlanIn @FiMrpPlanversion,''--''返回所有的线别
	--Select * from #PlanInQty
	Create Table  #FiPlanQty(Item varchar(50),PlanDate varchar(50),Qty float)
	INsert into #FiPlanQty
		Select Item ,dbo.FormatDate(starttime,'YYYY/MM/DD'),SUM(Qty) As Qty from #PlanInQty
			Group by Item ,dbo.FormatDate(starttime,'YYYY/MM/DD')
	if (@Flow ='ExMachineTrack')
	Begin
		print 'deletefidate'+dbo.FormatDate(@PlanVersionEndDate,'YYYY/MM/DD')
		Delete #FiPlanQty  where PlanDate >dbo.FormatDate(@PlanVersionEndDate,'YYYY/MM/DD')
	End
	/*
	select PlanVersion,DateIndex 
	into #PlanVersion
	from MRP_MrpPlanMaster
	where DateIndex>=@WeekIndex and
	PlanVersion in (select max(PlanVersion) from MRP_MrpPlanMaster where ResourceGroup = 30 and IsRelease=1 group by DateIndex,ResourceGroup)

	select sp.Item,dbo.FormatDate(PlanDate,'YYYY/MM/DD') PlanDate,SUM(sp.Qty) as Qty 
	into #FiPlanQty
	from MRP_MrpFiShiftPlan sp,#PlanVersion pv,MRP_WeekIndex wi where 
	sp.PlanVersion=pv.PlanVersion and pv.DateIndex = wi.WeekIndex
	and sp.PlanDate between wi.StartDate and wi.EndDate 
	and sp.PlanDate between @StartDate and @EndDate
	group by sp.Item,dbo.FormatDate(PlanDate,'YYYY/MM/DD')*/
	
	select b.Item,dbo.FormatDate(PlanDate,'YYYY/MM/DD') PlanDate,SUM(p.Qty*b.RateQty/m.Qty) As Qty
	into #PlanOut 
	from #FiPlanQty p,PRD_BomDet b,PRD_BomMstr m
	where p.Item = b.Bom and b.Bom = m.Code  
	and b.StartDate<=GETDATE() and b.EndDate>GETDATE() and b.BomMrpOption in (0,2) and m.IsActive=1
	group by b.Item,dbo.FormatDate(PlanDate,'YYYY/MM/DD')

	update p set p.待发 =o.Qty*(1+p.ScrapPct) from #Plan p, #PlanOut o where p.半制品 = o.Item and p.Plandate=o.PlanDate

	--库存
	select * into #Inv from dbo.GetInvBySnapTime(@SnapTime)
	update p set p.当前库存 =i.Qty from #Plan p, #Inv i where p.半制品 = i.Item

	--待收 和其它的报表一样，从USP_Busi_MRP_GetPlanIn里面去数据，实现方法重用和统一
	delete #PlanInQty
	Insert into  #PlanInQty
		Exec USP_Busi_MRP_GetPlanIn @PlanVersion,@flow--''返回所有的线别
	--Select * from #PlanInQty
	Create Table  #ShiftPlanIn1(Item varchar(50),PlanDate varchar(50),Qty float)
	INsert into #ShiftPlanIn1
		Select Item ,dbo.FormatDate(starttime,'YYYY/MM/DD'),SUM(Qty) As Qty from #PlanInQty
			Group by Item ,dbo.FormatDate(starttime,'YYYY/MM/DD')
	---XXXXXX
	/*select p.Item,p.ProductLine,dbo.FormatDate(p.PlanDate,'YYYY/MM/DD')PlanDate,p.Shift,SUM(Qty) as Qty 
	into #ShiftPlanIn 
	from  MRP_MrpExShiftPlan p
	join MRP_MrpExPlanMaster m on m.ReleaseVersion = p.ReleaseVersion and m.ProductLine=p.ProductLine and m.PlanDate=p.PlanDate and m.Shift=p.Shift 
	where m.IsActive=1 and p.Item <>299999 and p.Qty>0 and m.PlanDate between @StartDate and @EndDate
	group by p.Item,p.ProductLine,p.PlanDate,p.Shift
    ----订单覆盖计划Begin 完成或关闭取OrderQty
	Select b.Flow ,a.Item ,dbo.FormatDate(b.EffDate,'YYYY/MM/DD') as PlanDate,b.Shift as shift ,
		SUM(case when b.Status IN(3,4)then RecQty else OrderQty  End) As Qty into #OrderQty
		from ord_Orderdet_4 a ,ORD_OrderMstr_4 b 
		where a.OrderNo =b.OrderNo and dbo.FormatDate(b.EffDate,'YYYY/MM/DD') in (select PlanDate from #ShiftPlanIn)
		and b.Status in (1,2,3,4) 
		and b.IsIndepentDemand != 1 and SubType = 0 and b.ResourceGroup =20
		group by b.Flow ,a.Item ,dbo.FormatDate(b.EffDate,'YYYY/MM/DD') ,b.Shift
	select top 0 * into #delete from #ShiftPlanIn
	Delete b output deleted.* into #delete from  #OrderQty a ,#ShiftPlanIn b 
		where a.Flow=b.ProductLine and a.Item=b.Item and a.PlanDate=b.PlanDate and a.shift =b.Shift 
	Insert into #ShiftPlanIn
		Select a.Item,a.Flow,a.PlanDate,'' As Shift,a.Qty from #OrderQty a,#delete b where a.Flow=b.ProductLine and a.Item=b.Item 
			and a.PlanDate=b.PlanDate and a.shift=b.Shift
	Select p.Item,p.PlanDate,p.ProductLine,SUM(Qty) as Qty into #ShiftPlanIn_S from #ShiftPlanIn p
		Group by p.Item,p.PlanDate,p.ProductLine
    ----订单覆盖计划End
    ----加上前一周的DailyPlan 默认只给查前一周和这一周和下一周和下下周
    Declare @CurrentWeekVersion datetime 
    Declare @NextWeekVersion datetime 
    Declare @AfterNextWeekVersion datetime 
    Select @CurrentWeekVersion =MAX(PlanVersion) from MRP_MrpPlanMaster
		Where ResourceGroup =20 and IsRelease =1 and DateIndex =@WeekIndex and @WeekIndex!=@PlanVersionWeekIndex
    Select @NextWeekVersion =MAX(PlanVersion) from MRP_MrpPlanMaster
		Where ResourceGroup =20 and IsRelease =1 and DateIndex =@NextWeekIndex and @NextWeekIndex!=@PlanVersionWeekIndex
    Select @AfterNextWeekVersion =MAX(PlanVersion) from MRP_MrpPlanMaster
		Where ResourceGroup =20 and IsRelease =1 and DateIndex =@AfterNextWeekIndex  

	select p.Item,p.PlanDate,SUM(Qty) as Qty 
	into #DailyPlanIn
	from MRP_MrpExItemPlan p
	where p.PlanVersion in (@PlanVersion,@CurrentWeekVersion,@NextWeekVersion,@AfterNextWeekVersion) and Qty>0
	and p.PlanDate between @StartDate and @EndDate
	and not exists(select 1 from #ShiftPlanIn_S s where s.PlanDate= p.PlanDate and s.ProductLine = p.ProductLine)
	group by p.Item,p.PlanDate
	update p set p.待收 =d.Qty/**(1+p.ScrapPct)*/ from #Plan p, #DailyPlanIn d where p.半制品 = d.Item and p.Plandate=d.PlanDate

	select Item, PlanDate,SUM(Qty) as Qty 
	into #ShiftPlanIn1
	from #ShiftPlanIn_S
	group by Item,PlanDate*/
	update p set p.待收 =round(p.待收+d.Qty/(1+p.ScrapPct),0) from #Plan p, #ShiftPlanIn1 d where p.半制品 = d.Item and p.Plandate=d.PlanDate
	--小于0的作0处理
	IF OBJECT_ID('tempdb..##EXTRACK') IS NOT NULL
	Begin
		Drop table ##EXTRACK
    End
    Select 生产线,断面,断面描述,半制品,半制品描述,Plandate,MAX(当前库存)当前库存,sum(case when 待收 < 0 then 0 else 待收 End)待收,
		sum(case when 待发 < 0 then 0 else 待发 End)待发 into  ##EXTRACK from #Plan
		Group by 生产线,断面,断面描述,半制品,半制品描述,Plandate  
		
	drop table #SectionFlow
	drop table #Plan
	drop table #PlanOut
	drop table #Inv
	drop table #ShiftPlanIn1

END
