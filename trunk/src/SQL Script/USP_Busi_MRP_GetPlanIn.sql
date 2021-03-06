USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_GetPlanIn]    Script Date: 12/08/2014 15:10:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		liqiuyun
-- Create date: 20130809
-- Description:	GetPlanIn 生产待收
-- =============================================
ALTER PROCEDURE [dbo].[USP_Busi_MRP_GetPlanIn]
(
	@PlanVersion datetime,
	@Flow varchar(50)
)
AS

BEGIN
    SELECT @Flow=LTRIM(RTRIM(@Flow))
    ---2014/03/28	如果是Excel模具计划的挤出条子模拟则要看下时间是不是在00:00 to 09:00，如果是的话要把模拟的开始日期设置为取快照的日期，即前一天的日期 0001
	---2014/04/21   备模的量不考虑	0002
	--  exec [USP_Busi_MRP_GetPlanIn] '2014-03-21 13:37:45',''
	SET NOCOUNT ON;
	
	declare @ResourceGroup  varchar(50), @StartDate  varchar(50), @WeekIndex varchar(20),@PlanversionWeekIndex varchar(20),@PlanVersionEndDate Datetime
    select @ResourceGroup = ResourceGroup,@PlanversionWeekIndex=DateIndex from MRP_MrpPlanMaster where PlanVersion = @PlanVersion
	select @WeekIndex=WeekIndex from MRP_WeekIndex where StartDate<=dbo.FormatDate(getdate(),'YYYY-MM-DD') and EndDate>=dbo.FormatDate(getdate(),'YYYY-MM-DD')

	--0001   
    Select @PlanVersionEndDate=EndDate from MRP_WeekIndex where WeekIndex =@PlanversionWeekIndex
    --0001 
    select @StartDate = CONVERT(varchar(10) , @PlanVersion, 111 ) 
    --2014/03/10 如果是USP_Busi_MRP_PurchaseDailyPlan来调用则把开始时间设置为当前天
	If @Flow ='PurchaseInvoke'
		Begin
			Set @StartDate =CONVERT(varchar(10) , GETDATE(), 111 ) 
			Set @Flow=''
		End
	--0001
	If @Flow ='ExMachineTrack'
		Begin
			If dbo.FormatDate(getdate(),'HHNNSS') between '000000' and '090000'
				Begin
					Set @StartDate =CONVERT(varchar(10) ,DATEADD(day,-1, GETDATE()), 111 ) 
				End
			Set @Flow=''
		End
	--构建空表
	CREATE TABLE #PlanIn(
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
	
	--独立需求生产单 
	insert into #PlanIn
		select m.Flow as Flow,4 as OrderType,d.Item, m.StartTime as StartTime,m.WindowTime as WindowTime,
			m.LocFrom as LocationFrom,m.LocTo as  LocationTo,
			sum(case when d.OrderQty-d.RecQty<0 then 0 else d.OrderQty-d.RecQty end)* d.UnitQty as Qty,
			d.Bom as Bom,2 as SourceType,m.PartyFrom as SourceParty
				from ORD_OrderDet_4 as d 
				join ORD_OrderMstr_4 as m on d.OrderNo = m.OrderNo 
				join Scm_flowmstr as f on f.Code = m.Flow
				where f.resourceGroup = @ResourceGroup and m.Status in (1,2) and m.IsIndepentDemand = 1 and SubType = 0
				group by m.Flow,d.Item,m.StartTime,m.WindowTime,m.LocFrom,m.LocTo,m.PartyFrom,d.UnitQty,d.Bom
	select top 0 *,SPACE(50) as Category,SPACE(50) as Shift into #PlanIn_Iterim from #PlanIn
	If @ResourceGroup=10
	Begin
	--班产计划
		insert into #PlanIn_Iterim
		--declare @StartDate datetime=getdate()
			select s.ProductLine as Flow,4 as OrderType,s.Item as Item,s.StartTime as StartTime,
				s.WindowTime as WindowTime,s.LocationFrom as LocationFrom,s.LocationTo as LocationTo,
				SUM(s.Qty) as Qty,s.Bom as Bom,0 as SourceType,l.Region as SourceParty,'PlanPart' as Category,s.Shift as shift
					from MRP_MrpMiShiftPlan s 
					join MRP_MrpMiDateIndex m on s.CreateDate = m.CreateDate and s.ProductLine = m.ProductLine
					join MD_Location l on l.Code = s.LocationFrom
					where  m.IsActive =1 and m.PlanDate>=@StartDate
					group by s.StartTime,s.WindowTime,s.Item,s.ProductLine,s.LocationFrom,s.LocationTo,s.Bom,l.Region,s.Shift

	--加shipplan
	--天计划
		insert into #PlanIn
			Select s.Flow as Flow,4 as OrderType,s.Item as Item, dbo.FormatDate(s.StartTime,'YYYY-MM-DD 07:45:00') as StartTime,
				DATEADD(day,1, dbo.FormatDate(s.StartTime,'YYYY-MM-DD 07:45:00')) as WindowTime,s.LocationFrom as LocationFrom,s.LocationTo as LocationTo,
				round(SUM(s.Qty/*/i.UC*/),1) as Qty,s.Bom as Bom,1 as SourceType,l.Region as SourceParty
				from MRP_MrpShipPlan s 
				join MD_Location l on l.Code = s.LocationFrom
				--join MD_Item i on s.Item=i.Code
				where s.PlanVersion=@PlanVersion and s.Flow = @Flow--and s.StartTime>=@StartDate
				Group by  dbo.FormatDate(s.StartTime,'YYYY-MM-DD 07:45:00'),
				DATEADD(day,1, dbo.FormatDate(s.StartTime,'YYYY-MM-DD 07:45:00')),
				s.Item,s.Flow,s.LocationFrom,s.LocationTo,s.Bom,l.Region
		--select distinct PlanDate,ProductLine into #temp1 from MRP_MrpMiDateIndex m where m.IsActive =1 and m.PlanDate>=@StartDate
		--insert into #PlanIn
		----declare @StartDate datetime=getdate() declare @PlanVersion datetime='2013-08-09 13:56:09.000'		
		--select s.ProductLine as Flow,4 as OrderType,s.Item as Item,s.PlanDate as StartTime,
		--	DATEADD(day,1, s.PlanDate) as WindowTime,s.LocationFrom as LocationFrom,s.LocationTo as LocationTo,
		--	SUM(s.Qty + s.AdjustQty) as Qty,s.Bom as Bom,1 as SourceType,l.Region as SourceParty
		--		from MRP_MrpMiPlan s 
		--		join MD_Location l on l.Code = s.LocationFrom
		--		where s.PlanVersion=@PlanVersion  and s.PlanDate>=@StartDate
		--		and not exists
		--		(select 1 from #temp1 t where t.PlanDate=s.PlanDate and t.ProductLine = s.ProductLine)
		--		group by s.PlanDate,s.Item,s.ProductLine,s.LocationFrom,s.LocationTo,s.Bom,l.Region
		--		drop table #temp1
 
	End		
	else if  @ResourceGroup=20
	Begin
	--全部取天计划
	--班产计划
		insert into #PlanIn_Iterim
			select s.ProductLine as Flow,4 as OrderType,s.Item as Item,s.PlanDate as StartTime,
				DATEADD(day,1, s.PlanDate) as WindowTime,s.LocationFrom as LocationFrom,s.LocationTo as LocationTo,
				----0002*Case when s.ProductType = 'D' then 0 else 1 End)
				SUM( s.Qty*Case when s.ProductType = 'D' then 0 else 1 End) as Qty,s.Bom as Bom,0 as SourceType,l.Region as SourceParty,'PlanPart' as Category,s.Shift as Shift 
				from MRP_MrpExShiftPlan s 
				join MRP_MrpExPlanMaster m on s.ReleaseVersion = m.ReleaseVersion and s.Shift = m.Shift 
				and s.ProductLine = m.ProductLine and s.PlanDate = m.PlanDate
				join MD_Location l on l.Code = s.LocationFrom	
				where  m.IsActive =1 and m.PlanDate>=@StartDate and s.Item!='299999'
				group by s.PlanDate,s.Item,s.ProductLine,s.LocationFrom,s.LocationTo,s.Bom,l.Region,s.Shift
		
		 
	--天计划	
	    --已经转成了班产计划
		select distinct PlanDate,ProductLine into #temp2 from MRP_MrpExPlanMaster m where m.IsActive =1 and m.PlanDate>=@StartDate	
		insert into #PlanIn
			select s.ProductLine as Flow,4 as OrderType,s.Item as Item,s.PlanDate as StartTime,
				DATEADD(day,1, s.PlanDate) as WindowTime,f.LocFrom as LocationFrom,f.LocTo as LocationTo,
				SUM(s.Qty + s.AdjustQty+ s.CorrectionQty) as Qty,s.Item as Bom,1 as SourceType,f.PartyFrom as SourceParty
					from MRP_MrpExItemPlan s 
					join SCM_FlowMstr f on f.Code = s.ProductLine
					where PlanVersion=@PlanVersion and s.Item!='299999' and PlanDate>=@StartDate and s.Qty + s.AdjustQty+ s.CorrectionQty>0 
					and not exists (select 1 from #temp2 t where t.PlanDate=s.PlanDate and t.ProductLine = s.ProductLine)
					----0001Begin
					and s.DateIndex = case when  @Flow ='ExMachineTrack' then  @PlanversionWeekIndex else s.DateIndex End
					----0001End
					
					group by s.PlanDate,s.Item,s.ProductLine,f.LocFrom,f.LocTo,f.PartyFrom
	
		Declare @CurrentWeekIndex varchar(20)
	    select @CurrentWeekIndex = WeekIndex from MRP_WeekIndex where StartDate<=dbo.FormatDate(getdate(),'YYYY-MM-DD') and EndDate>=dbo.FormatDate(getdate(),'YYYY-MM-DD')

	    --加上PlanVersion没有覆盖到的计划
	    print @WeekIndex+@CurrentWeekIndex+@PlanversionWeekIndex
	    ---这里应该是所选版本对应的周别
	    --if @WeekIndex>@CurrentWeekIndex
	    if @PlanversionWeekIndex>@CurrentWeekIndex
	    Begin
			--todo 封装
			--天计划	 	
			Declare @WeekEnd datetime
			Declare @OldPlanVersion datetime
			select top 1 @OldPlanVersion = PlanVersion from MRP_MrpPlanMaster where IsRelease = 1 and ResourceGroup = @ResourceGroup
			and DateIndex<=@CurrentWeekIndex order by PlanVersion desc
			Select @WeekEnd=StartDate from MRP_WeekIndex where WeekIndex = @WeekIndex				
			
			insert into #PlanIn
				select s.ProductLine as Flow,4 as OrderType,s.Item as Item,s.PlanDate as StartTime,
					DATEADD(day,1, s.PlanDate) as WindowTime,f.LocFrom as LocationFrom,f.LocTo as LocationTo,
					SUM(s.Qty+ s.AdjustQty+ s.CorrectionQty) as Qty,s.Item as Bom,1 as SourceType,f.PartyFrom as SourceParty
						from MRP_MrpExItemPlan s 
						join SCM_FlowMstr f on f.Code = s.ProductLine
						where PlanVersion=@OldPlanVersion and s.Item!='299999' and s.Qty + s.AdjustQty+ s.CorrectionQty>0
						and PlanDate<@WeekEnd  and PlanDate>=@StartDate 
						and not exists (select 1 from #temp2 t where t.PlanDate=s.PlanDate and t.ProductLine = s.ProductLine)
						group by s.PlanDate,s.Item,s.ProductLine,f.LocFrom,f.LocTo,f.PartyFrom
		End
		--drop table #temp2
	End	
	else if  @ResourceGroup=30	
	Begin
	
		select PlanVersion,DateIndex 
		into #PlanVersion
		from MRP_MrpPlanMaster
		where DateIndex>=@WeekIndex and
		PlanVersion in (select max(PlanVersion) from MRP_MrpPlanMaster where ResourceGroup = 30 and IsRelease=1 
		group by DateIndex,ResourceGroup)
		
		insert into #PlanIn_Iterim
			select s.ProductLine as Flow,4 as OrderType,s.Item as Item,s.StartTime as StartTime,
				s.WindowTime as WindowTime,s.LocationFrom as LocationFrom,s.LocationTo as LocationTo,
				SUM(s.Qty) as Qty,s.Bom as Bom,0 as SourceType,l.Region as SourceParty,'PlanPart',s.Shift as Shift
				from MRP_MrpFiShiftPlan s,#PlanVersion pv,MRP_WeekIndex wi,MD_Location l
				where l.Code = s.LocationFrom and s.PlanVersion=pv.PlanVersion and pv.DateIndex = wi.WeekIndex
				and s.PlanDate between wi.StartDate and wi.EndDate
				and s.PlanDate>=@StartDate
				group by s.StartTime,s.WindowTime,s.Item,s.ProductLine,s.LocationFrom,s.LocationTo,s.Bom,l.Region,s.Shift
				
		insert into #PlanIn_Iterim
			select s.ProductLine as Flow,4 as OrderType,s.Item as Item,s.StartTime as StartTime,
				s.WindowTime as WindowTime,s.LocationFrom as LocationFrom,s.LocationTo as LocationTo,
				SUM(s.Qty) as Qty,s.Bom as Bom,0 as SourceType,l.Region as SourceParty,'PlanPart',s.Shift as Shift
				from MRP_MrpFiShiftPlan s,#PlanVersion pv,MRP_WeekIndex wi,MD_Location l
				where l.Code = s.LocationFrom and s.PlanVersion=pv.PlanVersion and pv.DateIndex = wi.WeekIndex
				and s.PlanVersion=(select top 1 PlanVersion from #PlanVersion order by DateIndex desc)
				and s.PlanDate > wi.EndDate
				and s.PlanDate>=@StartDate
				group by s.StartTime,s.WindowTime,s.Item,s.ProductLine,s.LocationFrom,s.LocationTo,s.Bom,l.Region,s.Shift
 
 
	End	
	----订单
	--	Insert into #PlanIn_Iterim
	--		select b.Flow ,4 as OrderType,a.Item ,dbo.FormatDate(b.EffDate,'YYYY-MM-DD') as StartTime,b.WindowTime ,a.LocFrom as LocationFrom,
	--			a.LocTo as LocationTo,SUM(a.OrderQty) as Qty,a.Bom as Bom,0 as SourceType,c.Region as SourceParty,'OrderPart' as Category,b.Shift as shift 
	--			from ord_Orderdet_4 a ,ORD_OrderMstr_4 b, MD_Location c where a.OrderNo =b.OrderNo and b.EffDate >@StartDateTime and b.Status in (1,2) 
	--			and b.IsIndepentDemand != 1 and SubType = 0 and b.ResourceGroup =@ResourceGroup and a.LocFrom=c.Code
	--			 group by b.Flow ,a.Item ,dbo.FormatDate(b.EffDate,'YYYY-MM-DD'),b.WindowTime ,b.StartTime,a.LocFrom,a.LocTo,a.Bom ,c.Region,b.Shift
				
	--	--select*from #PlanIn_Iterim a,#PlanIn_Iterim b where a.Shift =b.Shift 
	--	--	and a.StartTime =b.StartTime and a.Category='ShiftPlanPart'and b.Category='OrderPart'
	----生产单覆盖计划----同一天同一个班优先取Order 
	--	Delete a from #PlanIn_Iterim a,#PlanIn_Iterim b where a.Shift =b.Shift 
	--		and a.StartTime =b.StartTime and a.Category='PlanPart'and b.Category='OrderPart'

		Insert into #PlanIn
			select Flow,OrderType,Item,StartTime,WindowTime,LocationFrom,LocationTo,SUM(Qty) as Qty,Bom,SourceType,SourceParty from #PlanIn_Iterim
				group by Flow,OrderType,Item,StartTime,WindowTime,LocationFrom,LocationTo,Bom,SourceType,SourceParty
	If(ISNULL(@Flow,'') = '')
	Begin
		select Flow,OrderType,Item,StartTime,WindowTime,LocationFrom,LocationTo,SUM(Qty) as Qty,Bom,SourceType,SourceParty from #PlanIn
			group by Flow,OrderType,Item,StartTime,WindowTime,LocationFrom,LocationTo,Bom,SourceType,SourceParty
	End
	else
	Begin
	--优化 在前面过滤
		select Flow,OrderType,Item,StartTime,WindowTime,LocationFrom,LocationTo,SUM(Qty) as Qty,Bom,SourceType,SourceParty from #PlanIn
		where Flow = @Flow
		group by Flow,OrderType,Item,StartTime,WindowTime,LocationFrom,LocationTo,Bom,SourceType,SourceParty
	End
	drop table  #PlanIn
END


