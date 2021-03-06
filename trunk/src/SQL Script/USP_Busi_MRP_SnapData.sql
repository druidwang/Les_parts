USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_SnapData]    Script Date: 12/08/2014 15:13:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		liqiuyun
-- Create date: 20130801
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[USP_Busi_MRP_SnapData] 
(
@snapTime datetime,
@snapType int
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	--exec  USP_Busi_MRP_SnapData  getdate()
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--@snapType 0:预测 1：作业
	--MRP_SnapMrpPlan
	
	--Save MRP_SnapMrpPlan
	if @snapType =1
	Begin
		Insert into MRP_SnapMrpPlan(SnapTime, PlanDate, Item, Flow, Location, Qty, OrderType, PlanVersion, OrderQty, ShippedQty, ReceivedQty, Party, WindowTime)
		select @snapTime as SnapTime, PlanDate, Item, Flow, Location, Qty, OrderType, PlanVersion, OrderQty, ShippedQty, ReceivedQty, Party, WindowTime
			from dbo.MRP_MrpPlan with(nolock) where PlanDate > @snapTime
	End
	
	--Save Mrp_SnapMachine
	if @snapType =0
	Begin
		--Cancel insert daily data into Mrp_SnapMachine and MRP_SnapProdLineEx
		--Declare @CurrentDateIndex varchar(20)= dbo.FormatDate(@snapTime,'YYYY-MM-DD')
		Declare @CurrentWeekDateIndex varchar(20)= cast(DATEPART(year,DATEADD(day,-1, @snapTime)) as varchar)+'-'+right('0'+cast(datepart(week,DATEADD(day,-1, @snapTime)) as varchar),2)
		Declare @CurrentMothDateIndex varchar(20)= cast(DATEPART(year,@snapTime) as varchar)+'-'+right('0'+cast(datepart(MONTH,@snapTime) as varchar),2)
		--select @CurrentDateIndex,@CurrentWeekDateIndex,@CurrentMothDateIndex
		insert into Mrp_SnapMachine (SnapTime, Code, DateIndex, DateType, Region, Desc1, ShiftQuota, Qty, Island, MachineType, ShiftType, NormalWorkDayPerWeek,
			MaxWorkDayPerWeek, ShiftPerDay, IslandQty, IslandDesc1, TrailTime, HaltTime, Holiday, Flow)
		select @snapTime,Code, DateIndex, DateType, Region, Desc1, ShiftQuota, Qty, Island, MachineType, ShiftType, NormalWorkDayPerWeek, MaxWorkDayPerWeek, ShiftPerDay, 
			IslandQty, IslandDesc1, TrailTime, HaltTime, Holiday, Flow from MRP_MachineInstance  with(nolock) 
			where DateIndex >= case when DateType =5 then @CurrentWeekDateIndex 
			when DateType =6 then @CurrentMothDateIndex else @CurrentWeekDateIndex end  and DateType !=4
			
		--Save MRP_SnapProdLineEx
		Insert into MRP_SnapProdLineEx(SnapTime, ProductLine, Item, DateIndex, DateType, Region, ApsPriority, Quota, SwitchTime, SpeedTimes, MinLotSize,
			EconomicLotSize, MaxLotSize, TurnQty, Correction, ShiftType, RccpSpeed, MrpSpeed, ProductType)
		select @snapTime,ProductLine, Item, DateIndex, DateType, Region, ApsPriority, Quota, SwitchTime, SpeedTimes, MinLotSize,
			EconomicLotSize, MaxLotSize, TurnQty, Correction, ShiftType, RccpSpeed, MrpSpeed, ProductType from MRP_ProdLineExInstance with(nolock)
			where DateIndex >= case when DateType =5 then @CurrentWeekDateIndex 
			when DateType =6 then @CurrentMothDateIndex else @CurrentWeekDateIndex end and DateType !=4
	End
	--
END
