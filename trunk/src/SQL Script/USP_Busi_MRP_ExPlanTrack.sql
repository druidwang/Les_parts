USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_ExPlanTrack]    Script Date: 12/08/2014 15:08:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[USP_Busi_MRP_ExPlanTrack] 
(
	@PlanVersion datetime
)
AS
BEGIN
--[USP_Busi_MRP_ExPlanTrack] '2014-01-24 11:15:32'
set nocount on

	declare @StartDate datetime = dbo.FormatDate(GETDATE(),'YYYY-MM-DD');
	declare @EndDate datetime;
	declare @SnapTime datetime = dbo.GetStartInvSnapTimeByDate(getdate());

	select p.Item as Section,AVG(p.MrpSpeed) as Speed,
	stuff((SELECT ' ' + ProductLine from MRP_ProdLineEx as t where t.Item = p.Item FOR xml path('')), 1, 1, '') as Flow
	into #SectionFlow
	from MRP_ProdLineEx p where 1=1 and p.StartDate<=GETDATE() and  p.EndDate>GETDATE()
	group by Item

	select b.Item as 断面,i1.Desc1 as 断面描述,s.Flow as 生产线,
	i2.Code as 半制品,i2.Desc1 as 半制品描述,
	CAST(b.RateQty/m.Qty as decimal(18,2)) as 单位长度,
	CAST(0 as decimal) as 当前库存,CAST(0 as decimal) as 待收,CAST(0 as decimal) as 待发,'N' as 报警
	into #Plan
	from PRD_BomDet b,#SectionFlow s,PRD_BomMstr m,MD_Item i1,MD_Item i2
	where b.Item = s.Section and m.Code = b.Bom and i1.Code = b.Item and i2.Code = b.Bom
	and b.Item like '29%' and b.StartDate<=GETDATE() and b.EndDate>GETDATE() and b.BomMrpOption in (0,2) and m.IsActive=1

	select top 1 @EndDate = EndDate from MRP_WeekIndex w
	join MRP_MrpPlanMaster p on w.WeekIndex = p.DateIndex
	 where PlanVersion=@PlanVersion

	--待发
	Declare @WeekIndex varchar(50)
	select @WeekIndex=WeekIndex from MRP_WeekIndex where StartDate<=dbo.FormatDate(getdate(),'YYYY-MM-DD') and EndDate>=dbo.FormatDate(getdate(),'YYYY-MM-DD')

	
	select PlanVersion,DateIndex 
	into #PlanVersion
	from MRP_MrpPlanMaster
	where DateIndex>@WeekIndex and
	PlanVersion in (select max(PlanVersion) from MRP_MrpPlanMaster where ResourceGroup = 30 and IsRelease=1 group by DateIndex,ResourceGroup)

	select sp.Item,SUM(sp.Qty) as Qty 
	into #FiPlanQty
	from MRP_MrpFiShiftPlan sp,#PlanVersion pv,MRP_WeekIndex wi where 
	sp.PlanVersion=pv.PlanVersion and pv.DateIndex = wi.WeekIndex
	and sp.PlanDate between wi.StartDate and wi.EndDate 
	and sp.PlanDate between @StartDate and @EndDate
	group by sp.Item
	
	select b.Item,SUM(p.Qty*b.RateQty/m.Qty) As Qty
	into #PlanOut 
	from #FiPlanQty p,PRD_BomDet b,PRD_BomMstr m
	where p.Item = b.Bom and b.Bom = m.Code  
	and b.StartDate<=GETDATE() and b.EndDate>GETDATE() and b.BomMrpOption in (0,2) and m.IsActive=1
	group by b.Item

	update p set p.待发 =o.Qty from #Plan p, #PlanOut o where p.半制品 = o.Item

	--库存
	select * into #Inv from dbo.GetInvBySnapTime(@SnapTime)
	update p set p.当前库存 =i.Qty from #Plan p, #Inv i where p.半制品 = i.Item

	--待收
	select p.Item,p.ProductLine,p.PlanDate,SUM(Qty) as Qty 
	into #ShiftPlanIn 
	from  MRP_MrpExShiftPlan p
	join MRP_MrpExPlanMaster m on m.ReleaseVersion = p.ReleaseVersion and m.ProductLine=p.ProductLine and m.PlanDate=p.PlanDate and m.Shift=p.Shift 
	where m.IsActive=1 and p.Item <>299999 and p.Qty>0 and m.PlanDate between @StartDate and @EndDate
	group by p.Item,p.ProductLine,p.PlanDate

	select p.Item,SUM(Qty) as Qty 
	into #DailyPlanIn
	from MRP_MrpExItemPlan p
	where p.PlanVersion=@PlanVersion and Qty>0
	and p.PlanDate between @StartDate and @EndDate
	and not exists(select 1 from #ShiftPlanIn s where s.PlanDate= p.PlanDate and s.ProductLine = p.ProductLine)
	group by p.Item 
	update p set p.待收 =d.Qty from #Plan p, #DailyPlanIn d where p.半制品 = d.Item

	select Item,SUM(Qty) as Qty 
	into #ShiftPlanIn1
	from #ShiftPlanIn
	group by Item
	update p set p.待收 =p.待收+d.Qty from #Plan p, #ShiftPlanIn1 d where p.半制品 = d.Item

	--报警
	update #Plan set 报警= 'Y' where 当前库存+待收-待发<0
	select * from #Plan order by 报警 desc,断面,半制品

	drop table #SectionFlow
	drop table #Plan
	drop table #PlanOut
	drop table #Inv
	drop table #ShiftPlanIn
	drop table #DailyPlanIn
	drop table #ShiftPlanIn1

END
