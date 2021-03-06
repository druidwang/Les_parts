USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_GetFinishedPlanInOut]    Script Date: 12/08/2014 15:10:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		
-- Create date: 
-- Description:	已完成的收发
--========
ALTER PROCEDURE [dbo].[USP_Busi_MRP_GetFinishedPlanInOut]
(
	@PlanVersion datetime,
	@Flow varchar(50)
)
AS

BEGIN
	--2014/4/16 开始时间@StartDate取@PlanVersion date&补足PlanVersion里面没有的日期 --0001
	Set @Flow = LEFT(@Flow,4)
    Declare @SnapTime datetime 
    select top 1 @SnapTime=SnapTime from MRP_MrpPlanMaster With(nolock) where PlanVersion = @PlanVersion
    print @SnapTime
    select distinct Item into #Items from MRP_FlowDetail with(nolock) where SnapTime =@SnapTime and Flow =@Flow and StartDate <=@PlanVersion and EndDate >@PlanVersion
	--EXEC [USP_Busi_MRP_GetFinishedPlanInOut]  '2014-01-17 09:48:57','FI21'
    Declare @CurrentTime datetime =getdate()
    --这个变量很重要，算出当前的工作日，Example如果是18号，那么18号之前的算作已发已收的范畴
    Declare @CurrentPlandate date = dbo.FormatDate(@CurrentTime,'YYYY/MM/DD')
    Declare @VersionPlandate date = dbo.FormatDate(@PlanVersion,'YYYY/MM/DD')
    If  dbo.FormatDate(@CurrentTime,'HHNNSS') between '000000' and '074500' 
		Begin
			Set @CurrentPlandate=dbo.FormatDate(dateadd(day,-1,@CurrentTime),'YYYY/MM/DD')
		End
	--版本的开始和结束时间
	Declare @StartDate datetime
	Declare @EndDate datetime
	Declare @StartShipDate datetime
	Declare @EndShipDate datetime
	Declare @IsMrp bit
	Declare @ResourceGroup int
	--0001@VersionPlandate
	--select @StartDate =MIN(PlanDate) from MRP_MrpFiShiftPlan where PlanVersion=@Planversion
	Select @StartDate=dbo.FormatDate(@PlanVersion,'YYYY-MM-DD 00:00:00')
	--0001
	select @EndDate = dbo.Format_To_Date(dbo.FormatDate(GETDATE(),'YYYYMMDD ')+'000000')
	Select @StartShipDate=DATEADD(MINUTE,465,@StartDate),@EndShipDate = DATEADD(MINUTE,465,@EndDate)
	--select @StartDate,@EndDate,@IsMrp,@StartShipDate,@EndShipDate
	Select @IsMrp =IsMRP,@ResourceGroup=ResourceGroup  from SCM_FlowMstr with(nolock) where code =@Flow
	Create Table #ReceivedQty (PlanDate varchar(50),Item varchar(50),ReceivedQty float)
	Create Table #ShippedQty (PlanDate varchar(50),Item varchar(50),ShippedQty float)
	--天生产实收
	--1.后加工 注意IsMrp
	Insert into  #ReceivedQty
		Select dbo.FormatDate(m.EffDate,'YYYY/MM/DD') as PlanDate,Item,sum(RecQty) As ReceiveddQty 
			from ORD_OrderDet_4 d join ORD_OrderMstr_4 m on d.OrderNo = m.OrderNo
			where Flow= @Flow and @IsMrp=1 and RecQty!=0
			and m.EffDate between @StartDate and @CurrentPlandate
			Group by dbo.FormatDate(m.EffDate,'YYYY/MM/DD'),Item
		  
		  
	----2.挤出,炼胶的实收
	----时间段选择7:45到次日7:45
	--select top 100 * from ORD_RecDet_4 d
	--join ORD_RecMstr_4 m on d.RecNo = m.RecNo
	--where m.Status=0


	--天销售实发,时间段选择7:45到次日7:45
	--1.销售出去
	Insert into  #ShippedQty
		select Case when dbo.FormatDate(d.CreateDate,'HHNNSS') between '000000' and '074500' 
			then dbo.FormatDate(DATEADD(day,-1,d.CreateDate),'YYYY/MM/DD') 
			else  dbo.FormatDate( d.CreateDate,'YYYY/MM/DD') End as PlanDate,Item,SUM(d.ShipQty) As ShippedQty 
			from ORD_OrderDet_3 d join ORD_OrderMstr_3 m on d.OrderNo = m.OrderNo
			where /*m.Status=0 
			and*/ d.CreateDate Between @StartShipDate and @EndShipDate
			and d.ShipQty!=0
			Group by Case when dbo.FormatDate(d.CreateDate,'HHNNSS') between '000000' and '074500' 
			then dbo.FormatDate(DATEADD(day,-1,d.CreateDate),'YYYY/MM/DD') 
			else  dbo.FormatDate( d.CreateDate,'YYYY/MM/DD')End,Item
	--2.发往异地库/线边(!IsMRP)
	Insert into  #ShippedQty
		Select Case when dbo.FormatDate(d.CreateDate,'HHNNSS') between '000000' and '074500' 
			then dbo.FormatDate(DATEADD(day,-1,d.CreateDate),'YYYY/MM/DD') 
			else  dbo.FormatDate( d.CreateDate,'YYYY/MM/DD') End as PlanDate,Item,sum(ShipQty)  
			from ORD_OrderDet_2 d join ORD_OrderMstr_2 m on d.OrderNo = m.OrderNo
			join MD_Location l on l.Code = d.LocTo
			where l.IsMRP = 0
			and d.CreateDate Between @StartShipDate and @EndShipDate
			and d.ShipQty!=0
			Group by Case when dbo.FormatDate(d.CreateDate,'HHNNSS') between '000000' and '074500' 
			then dbo.FormatDate(DATEADD(day,-1,d.CreateDate),'YYYY/MM/DD') 
			else  dbo.FormatDate( d.CreateDate,'YYYY/MM/DD')End,Item

	--PlanRecQty
	--后加工
	select dbo.FormatDate(PlanDate,'YYYY/MM/DD') As PlanDate,Item,sum(Qty) As PlanRecQty into #PlanRecQty from MRP_MrpFiShiftPlan with(nolock) 
		where PlanVersion=@Planversion /*and Qty!=0*/ and ProductLine=@Flow 
		Group by dbo.FormatDate(PlanDate,'YYYY/MM/DD'),Item
	--0001Begin
	--补足PlanVersion里面没有的日期
	Insert into #PlanRecQty
		Select distinct PlanDate ,Item ,0 As Qty  from #ReceivedQty a where not exists(
			Select 0 from #PlanRecQty b where a.PlanDate =b.PlanDate and a.Item =b.Item )
	Insert into #PlanRecQty
		Select distinct PlanDate ,Item ,0 As Qty  from #ShippedQty a where not exists(
			Select 0 from #PlanRecQty b where a.PlanDate =b.PlanDate and a.Item =b.Item )
	--0001End
	--PlanShipQty
	--后加工
	select dbo.FormatDate(StartTime,'YYYY/MM/DD') As PlanDate,Item,sum(Qty) As PlanShipQty into #PlanShipQty from MRP_MrpShipPlan 
		where PlanVersion =@Planversion and Flow = @Flow /*and Qty!=0*/
		Group by dbo.FormatDate(StartTime,'YYYY/MM/DD'),Item
	
	Select a.PlanDate,a.Item,isnull(a.PlanRecQty,0),isnull(b.PlanShipQty,0),isnull(c.ReceivedQty,0),isnull(d.ShippedQty,0) 
		from #PlanRecQty a 
		Left join #PlanShipQty b on a.PlanDate =b.plandate and a.Item=b.Item 
		Left join #ReceivedQty c on a.PlanDate =c.plandate and a.Item=c.Item 
		Left join #ShippedQty d on a.PlanDate =d.plandate and a.Item=d.Item 
		where a.Item in (select * from #Items) and a.PlanDate < @CurrentPlandate 
	--在存储里计算已经过去的每一天的期末库存直接返回到前台，总当前年日期往前推算
	--存
	/*select Item,SUM(ATPQty) As 期初库存 into #PrimaryInv 
		from VIEW_LocationDet as l inner join MD_Location as loc on l.Location = loc.Code 
        where loc.IsMrp = 1 and l.ATPQty>0 and Item in (
		select Item from #Items) 
        Group by Item*/
    --Select top					
	--select top 1000 * from MRP_MrpShipPlan
	
END


