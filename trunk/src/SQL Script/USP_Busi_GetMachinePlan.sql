USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_GetMachinePlan]    Script Date: 12/08/2014 15:08:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_Busi_GetMachinePlan]
(
	@PlanDate DateTime
)
AS
BEGIN
	SET NOCOUNT ON

declare @EndDate  DateTime = dateadd(day,20,@PlanDate);


-- exec [dbo].[USP_Busi_GetMachinePlan] '2014-01-20'

select space(50) as Flow,w.WeekIndex,p.Item,space(50) as IslandDescription,space(50) as MachineDescription,
space(50) as Machine,0 as MachineType,cast(0 as decimal) as ShiftQuota, cast(SUM(p.Qty) as decimal) as Qty,
cast(0 as decimal) as MachineQty,cast(0 as decimal) as StartQty,cast(0 as decimal) as SafeStock,cast(0 as decimal) as OutQty,cast(0 as decimal) as InQty,cast(0 as decimal) as EndQty,cast(0 as decimal) as NetQty
into #MrpPlan
from MRP_MrpPlan p,MRP_WeekIndex w
where p.PlanDate between w.StartDate and w.EndDate
and p.PlanDate between @PlanDate and  @EndDate
group by p.Item,w.WeekIndex
order by w.WeekIndex,p.Item

select Flow,Machine,Item 
into #MachineItem
from SCM_FlowDet d
join SCM_FlowMstr m on m.Code = d.Flow
where m.ResourceGroup = 30 and m.IsMRP = 1 and Machine is not null
order by Machine

update p set p.Machine = m.Machine,p.Flow =m.Flow from  #MrpPlan p,#MachineItem m where p.Item = m.Item
update p set p.IslandDescription = i.Desc1,p.MachineDescription =m.Desc1 from #MrpPlan p,MRP_Island i,MRP_Machine m
where i.Code = m.Island and m.Code = p.Machine

update p set p.MachineType = m.MachineType,p.ShiftQuota = m.ShiftQuota,p.MachineQty = m.Qty
from  #MrpPlan p ,MRP_Machine m 
where p.Machine = m.Code and m.StartDate<=@PlanDate and m.EndDate>@PlanDate

Declare @NineOclock DateTime= dbo.Format_To_Date(dbo.FormatDate(GetDate(),'YYYYMMDD')+'090000')
Declare @SnapTime1 DateTime
Declare @SnapTime2 DateTime
Declare @SnapTimeUsed DateTime
Select @SnapTime2 =MIN(SnapTime) from MRP_SnapMaster 
	Where SnapTime>=@NineOclock and Type =1 and IsRelease=1
Select @SnapTime1 =max(SnapTime) from MRP_SnapMaster 
	Where SnapTime<=@NineOclock and Type =1 and IsRelease=1
If ABS(ISNULL(datediff(MINUTE,@NineOclock,@SnapTime2),100000))>ABS(datediff(MINUTE,@NineOclock,@SnapTime1))
	Begin
		Set @SnapTimeUsed=@SnapTime1
	End
	Else
	Begin
		Set @SnapTimeUsed=@SnapTime2
	End
print @SnapTimeUsed

Declare @WeekIndex varchar(50)
select @WeekIndex=MIN(WeekIndex) from #MrpPlan
print @WeekIndex

select Item,SUM(Qty) as Qty
into #InventoryBalance 
from MRP_InventoryBalance where SnapTime = @SnapTimeUsed and Qty>0
group by Item
update p set p.StartQty =i.Qty from  #MrpPlan p,#InventoryBalance i 
where p.Item = i.Item and p.WeekIndex = @WeekIndex

select Item,SUM(ShipQty-RecQty) as Qty
into #TransitOrder 
from MRP_TransitOrder where SnapTime = @SnapTimeUsed and ShipQty>RecQty
group by Item
update p set p.StartQty =t.Qty+p.StartQty from  #MrpPlan p,#TransitOrder t
where p.Item = t.Item and p.WeekIndex = @WeekIndex

--收
select PlanVersion,DateIndex 
into #PlanVersion
from MRP_MrpPlanMaster
where DateIndex>=(select weekindex from MRP_WeekIndex where StartDate<=dbo.FormatDate(getdate(),'YYYY-MM-DD') and EndDate>=dbo.FormatDate(getdate(),'YYYY-MM-DD')) 
and PlanVersion in (select max(PlanVersion) from MRP_MrpPlanMaster where ResourceGroup = 30 and IsRelease=1 group by DateIndex,ResourceGroup)

select sp.Item,SUM(sp.Qty) as Qty 
into #InQty
from MRP_MrpFiShiftPlan sp,#PlanVersion pv,MRP_WeekIndex wi where 
sp.PlanVersion=pv.PlanVersion and pv.DateIndex = wi.WeekIndex
and PlanDate between wi.StartDate and wi.EndDate 
and sp.PlanDate >= dbo.FormatDate(GetDate(),'YYYYMMDD') and sp.PlanDate< @PlanDate
group by Item

update p set p.InQty =i.Qty from  #MrpPlan p,#InQty i
where p.Item = i.Item and p.WeekIndex = @WeekIndex

--发
select Item,SUM(Qty) as Qty 
into #OutQty
from MRP_MrpPlan  
where PlanDate >= dbo.FormatDate(GetDate(),'YYYYMMDD') and PlanDate< @PlanDate
group by Item
update p set p.OutQty =o.Qty from  #MrpPlan p,#OutQty o 
where p.Item = o.Item and p.WeekIndex = @WeekIndex

--安全库存
select Item,SUM(SafeStock) as SafeStock  
into #SafeStock
from SCM_FlowDet d
join SCM_FlowMstr m on d.Flow = m.Code
where m.IsActive = 1 and m.IsMRP =1 and d.MrpWeight >0 
and(StartDate is null or StartDate<=GETDATE()) and (EndDate is null or EndDate>GETDATE())
Group by Item
update p set p.SafeStock =s.SafeStock from  #MrpPlan p,#SafeStock s 
where p.Item = s.Item --and p.WeekIndex = @WeekIndex

update p set p.EndQty =p.StartQty-p.OutQty+p.InQty from  #MrpPlan p 
where p.WeekIndex = @WeekIndex
update p set p.NetQty =p.Qty-p.EndQty+p.SafeStock from  #MrpPlan p 
where p.WeekIndex = @WeekIndex

--返回
--WeekIndex	Item	Machine	MachineType	ShiftQuota	Qty(毛)	StartQty SafeStock OutQty InQty EndQty NetQty
--update #MrpPlan   Set NetQty =20
--where   Machine <>'' and  Qty>=0 and  ShiftQuota > 0
--and Machine ='600137'  and Item =501820 and WeekIndex ='2014-15'
select * from #MrpPlan p 
where  p.Machine <>'' and p.Qty>=0 and p.ShiftQuota > 0
order by p.WeekIndex,p.IslandDescription,p.Machine
Insert into sconit_log
	Select 'USP_Busi_GetMachinePlan',dbo.formatdate( @plandate,'YYYYMMDD'),getdate()
END
