USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_ScheduleMi]    Script Date: 12/08/2014 15:13:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		liqiuyun
-- Create date: 20130727
-- Description:	修正挤出天计划释放算法:天计划转班产计划
-- =============================================
ALTER PROCEDURE [dbo].[USP_Busi_MRP_ScheduleMi]
(@SnapTime datetime,
@PlanVersion datetime
)
AS
Begin
 
 
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-----
	return
	Declare @ClearTime decimal(18,8),@MaxDailyWorkHour decimal(18,8),@TotalWorkingHour float,@ActiveFlag varchar(5)
	select  @ClearTime=Value from SYS_EntityPreference where id =20002
	Set @MaxDailyWorkHour =24-@ClearTime*3/60
	Print @MaxDailyWorkHour
	--select distinct ProductLine into #flow from MRP_MrpMiPlan where PlanVersion='2013-08-13 09:15:31.000'
	
	Select *,(Qty + AdjustQty)/UnitCount/60*WorkHour as WorkingHour,CAST(0 as decimal(18,8)) as TotalWorkingHour,CAST(0 as decimal(18,8)) as AdjustHours,
		'Y' as ActiveFlag,row_number()over(partition  by plandate order by Mrppriority ,huto) as NOID into #MRP_MrpMiPlan from MRP_MrpMiPlan where PlanVersion ='2013-08-13 09:15:31.000' and ProductLine='MI01'
	select PlanDate,SUM(WorkingHour)-@MaxDailyWorkHour As OverFlow 
		into #DailyOverFlow from #MRP_MrpMiPlan
		Group by PlanDate having SUM(WorkingHour)-@MaxDailyWorkHour>0 
	Update a  Set a.TotalWorkingHour=b.TotalWorkingHour from #MRP_MrpMiPlan a ,
		(select PlanDate,SUM(WorkingHour)As TotalWorkingHour from #MRP_MrpMiPlan Group by PlanDate)b
		where a.PlanDate =b.PlanDate 
	select* from #DailyOverFlow
	Update a
		Set a.AdjustHours=-b.OverFlow*a.WorkingHour/a.TotalWorkingHour from #MRP_MrpMiPlan a,#DailyOverFlow b where a.PlanDate =b.PlanDate 
	
	--select Item,-SUM(AdjustHours) As AdjustHours into #ItemAdjustHours from #MRP_MrpMiPlan group by Item
	--select * from #ItemAdjustHours
	 select Item ,SUM(WorkingHour) WorkingHour into #TrackItemSummary from #MRP_MrpMiPlan group by Item
	 --select Item ,SUM(WorkingHour) WorkingHour into #TrackItemSummary_new from #MRP_MrpMiPlan group by Item
		--select * from #TrackItemSummary a,#TrackItemSummary_new b where a.Item=b.item
	select * from #MRP_MrpMiPlan 
	--Drop table #distribution;Drop table #MRP_MrpMiPlan;Drop table #DailyOverFlow;Drop table #MRP_MrpMiPlan;Drop table #NeedAddPlanDate
	select distinct PlanDate into #NeedAddPlanDate from #MRP_MrpMiPlan 
		where  PlanDate not in (select PlanDate from #DailyOverFlow)
	Declare @MaxOverFlowPlanDate varchar(20)='',@MaxIdlePlanDate varchar(20)='',@NeedInsertHours decimal (18,8),@AllowInsertHOurs decimal(18,8)
	Declare @DistributeOverFlowOKFlag varchar(5)='N' ,@DistributIdlePlanDate varchar(5)='N' ,@ItemHours decimal (18,8),@NoID int,@Item varchar(20)
	Declare @Huto varchar(30)
	--select * from #MRP_MrpMiPlan where  PlanDate ='2013-08-13'
	select top 0 * into #MRP_MrpMiPlan_temp from #MRP_MrpMiPlan
	while exists(select top 1 * from #NeedAddPlanDate)
		Begin
			set @NoID=1
			select @MaxOverFlowPlanDate=MAX(PlanDate) from #MRP_MrpMiPlan where ActiveFlag ='Y' and TotalWorkingHour >21.90000000
			select @MaxIdlePlanDate=MAX(PlanDate) from #MRP_MrpMiPlan where ActiveFlag ='Y' and TotalWorkingHour <21.90000000
				and PlanDate<@MaxOverFlowPlanDate
			If @@ROWCOUNT =0
				Begin
					print 'Update N:'+@MaxOverFlowPlanDate
					Update #MRP_MrpMiPlan set ActiveFlag ='N' where PlanDate=@MaxOverFlowPlanDate
					continue
				End
			-----将生产相同物料的优先级往前提
			--select * from 
			-----
			if @MaxOverFlowPlanDate>@MaxIdlePlanDate
				Begin
					
					select @AllowInsertHOurs=TotalWorkingHour-21.90000000 from #MRP_MrpMiPlan where PlanDate =@MaxOverFlowPlanDate
					select @NeedInsertHours=21.90000000-TotalWorkingHour from #MRP_MrpMiPlan where PlanDate =@MaxIdlePlanDate
					--select * from #MRP_MrpMiPlan where PlanDate ='2013-09-08'
					--select * from #MRP_MrpMiPlan where PlanDate ='2013-08-24'
					select 'AAA',@MaxOverFlowPlanDate MaxOverFlowPlanDate, @MaxIdlePlanDate MaxIdlePlanDate,@AllowInsertHOurs AllowInsertHOurs,@NeedInsertHours needInsertHours
					----差额和溢出不可能完全相等，所以给它们一个浮动范围
					if abs(@AllowInsertHOurs-@NeedInsertHours)<0.1
					Begin
						Update #MRP_MrpMiPlan Set ActiveFlag ='N' where PlanDate =@MaxIdlePlanDate 
						Update #MRP_MrpMiPlan Set ActiveFlag ='N' where PlanDate =@MaxOverFlowPlanDate 
					End
					else if @AllowInsertHOurs<@NeedInsertHours 
					Begin 
						Set @NeedInsertHours=@AllowInsertHOurs
						Update #MRP_MrpMiPlan Set ActiveFlag ='N' where PlanDate =@MaxOverFlowPlanDate 
					End
					else if @AllowInsertHOurs>@NeedInsertHours
					Begin
						Update #MRP_MrpMiPlan Set ActiveFlag ='N' where PlanDate =@MaxIdlePlanDate 
					End

					while exists(select top 1 * from #MRP_MrpMiPlan where PlanDate =@MaxOverFlowPlanDate and NOID=@NoID)
					Begin
					print 'BBB'
						select top 1 @ItemHours=WorkingHour,@Item=Item,@Huto =HuTo from #MRP_MrpMiPlan where PlanDate =@MaxOverFlowPlanDate and NOID=@NoID order by NOID
						print cast(@ItemHours as varchar)+':'+cast(@NeedInsertHours as varchar)
						If @ItemHours>@NeedInsertHours
						Begin
							Update #MRP_MrpMiPlan set TotalWorkingHour= TotalWorkingHour-@NeedInsertHours from #MRP_MrpMiPlan where PlanDate =@MaxOverFlowPlanDate
							Update #MRP_MrpMiPlan set WorkingHour= WorkingHour-@NeedInsertHours from #MRP_MrpMiPlan where NOID=@NoID and PlanDate =@MaxOverFlowPlanDate
							if exists(select top 1 * from #MRP_MrpMiPlan where PlanDate =@MaxIdlePlanDate and Huto=@HuTo and Item=@Item )
							Begin
							print 'CCC'
								Update #MRP_MrpMiPlan Set WorkingHour=WorkingHour+@NeedInsertHours from #MRP_MrpMiPlan 
									where PlanDate =@MaxIdlePlanDate and Huto=@HuTo and Item=@Item
								Update #MRP_MrpMiPlan set TotalWorkingHour=TotalWorkingHour+@NeedInsertHours from #MRP_MrpMiPlan where PlanDate =@MaxIdlePlanDate 
							End
							Else
							Begin
							print 'DDD'
								select @TotalWorkingHour=TotalWorkingHour,@ActiveFlag=ActiveFlag from #MRP_MrpMiPlan where PlanDate=@MaxIdlePlanDate
								Delete #MRP_MrpMiPlan_temp
								Insert into #MRP_MrpMiPlan_temp
									select * from #MRP_MrpMiPlan where PlanDate =@MaxOverFlowPlanDate and NOID =@NoID 
								Update #MRP_MrpMiPlan_temp set WorkingHour =@NeedInsertHours ,PlanDate =@MaxIdlePlanDate,ActiveFlag=@ActiveFlag
								Insert into #MRP_MrpMiPlan select * from #MRP_MrpMiPlan_temp
								Update #MRP_MrpMiPlan set TotalWorkingHour=@TotalWorkingHour+@NeedInsertHours 
									where PlanDate =@MaxIdlePlanDate
							End
							Set @NeedInsertHours=0

						End
						Else
						Begin
						print 'EEE'
							Update #MRP_MrpMiPlan set TotalWorkingHour= TotalWorkingHour-@ItemHours from #MRP_MrpMiPlan where PlanDate =@MaxOverFlowPlanDate
							Update #MRP_MrpMiPlan set WorkingHour= WorkingHour-@ItemHours from #MRP_MrpMiPlan where NOID=@NoID and  PlanDate =@MaxOverFlowPlanDate
							if exists(select top 1 * from #MRP_MrpMiPlan where PlanDate =@MaxIdlePlanDate and Huto=@HuTo and Item=@Item )
							Begin
							print 'FFF'
								Update #MRP_MrpMiPlan Set WorkingHour=WorkingHour+@ItemHours from #MRP_MrpMiPlan 
									where PlanDate =@MaxIdlePlanDate and Huto=@HuTo and Item=@Item
								Update #MRP_MrpMiPlan set TotalWorkingHour=TotalWorkingHour+@ItemHours from #MRP_MrpMiPlan where PlanDate =@MaxIdlePlanDate 
							End
							Else
							Begin
							print 'GGG'
								select @TotalWorkingHour=TotalWorkingHour,@ActiveFlag=ActiveFlag from #MRP_MrpMiPlan where PlanDate=@MaxIdlePlanDate
								Delete #MRP_MrpMiPlan_temp
								Insert into #MRP_MrpMiPlan_temp
									select * from #MRP_MrpMiPlan where PlanDate =@MaxOverFlowPlanDate and NOID =@NoID 
								Update #MRP_MrpMiPlan_temp set WorkingHour =@ItemHours ,PlanDate =@MaxIdlePlanDate,ActiveFlag=@ActiveFlag
								Insert into #MRP_MrpMiPlan select * from #MRP_MrpMiPlan_temp
								Update #MRP_MrpMiPlan set TotalWorkingHour=@TotalWorkingHour+@NeedInsertHours 
									where PlanDate =@MaxIdlePlanDate
							End
							Set @NeedInsertHours=@NeedInsertHours-@ItemHours
						End
						If @NeedInsertHours>0
						Begin
							print'@NoID:'+cast(@NoID as varchar)
							Set @NoID=@NoID+1
						End
						Else
						Begin
							Print 'GGG0'
							Break
						End

					End
				End
				else
				Begin
					print 'break'
					break
				End
			print 'HHH'
			select @MaxOverFlowPlanDate='',@MaxIdlePlanDate=''
		End
	Update a
		Set a.AdjustQty =(b.WorkingHour/60/a.UnitCount /a.WorkHour -a.Qty) from MRP_MrpMiPlan a,#MRP_MrpMiPlan b 
			where a.PlanVersion='2013-08-13 09:15:31.000'  and a.ProductLine ='MI01' 
			and a.PlanDate=b.PlanDate and a.Item=b.Item and a.HuTo=b.HuTo 
	Update b
		Set  b.Activeflag='A' from MRP_MrpMiPlan a,#MRP_MrpMiPlan b 
			where a.PlanVersion='2013-08-13 09:15:31.000'  and a.ProductLine ='MI01' 
			and a.PlanDate=b.PlanDate and a.Item=b.Item and a.HuTo=b.HuTo 
	Insert into MRP_MrpMiPlan(ProductLine, Item, PlanDate, LocationFrom, LocationTo, PlanVersion, Sequence, WorkHour, UnitCount, Qty, AdjustQty, MrpPriority, MaxStock, SafeStock, InvQty, HuTo, Bom, Uom, BatchSize, Logs)
		select ProductLine, Item, PlanDate, LocationFrom, LocationTo, PlanVersion, Sequence, WorkHour, UnitCount,
			0, AdjustQty, MrpPriority, MaxStock, SafeStock, InvQty, HuTo, Bom, Uom, BatchSize, Logs from #MRP_MrpMiPlan
			where ActiveFlag !='A'
	return 
----Insert Into active orders
	Declare @id int
	select top 3000 Item ,Flow,sum(Qty/UC/60*WorkHour) as WorkingHour into #MRP_MrpShipPlan_1 from MRP_MrpShipPlan a with(nolock),MD_Item b with(nolock) 
		where a.Item =b.Code and Flow='MI01' and PlanVersion='2013-08-13 09:15:31.000' and SourceType='1' group by Item ,Flow
	select * from #MRP_MrpShipPlan_1
	Select *,(Qty + AdjustQty)/UnitCount/60*WorkHour as WorkingHour,CAST(0 as decimal(18,8)) as TotalWorkingHour,CAST(0 as decimal(18,8)) as AdjustHours,
		'Y' as ActiveFlag,row_number()over(partition  by plandate order by Mrppriority ,huto) as NOID into #MRP_MrpMiPlan_1 from MRP_MrpMiPlan 
		 where PlanVersion ='2013-08-13 09:15:31.000' and ProductLine='MI01'
	select PlanDate,SUM(WorkingHour)-21.90000000 As OverFlow 
		into #DailyOverFlow_1 from #MRP_MrpMiPlan_1
		Group by PlanDate having SUM(WorkingHour)-21.90000000<0 
	delete #MRP_MrpMiPlan_1 where PlanDate not in (select PlanDate from #DailyOverFlow_1)
	Update a  Set a.TotalWorkingHour=b.TotalWorkingHour from #MRP_MrpMiPlan_1 a ,
		(select PlanDate,SUM(WorkingHour)As TotalWorkingHour from #MRP_MrpMiPlan_1 Group by PlanDate)b
		where a.PlanDate =b.PlanDate 
	select* from #DailyOverFlow_1
	Update a
		Set a.AdjustHours=-b.OverFlow*a.WorkingHour/a.TotalWorkingHour from #MRP_MrpMiPlan_1 a,#DailyOverFlow_1 b where a.PlanDate =b.PlanDate 
	Declare @ShipItem varchar(20)
	while exists(select top 1 * from #MRP_MrpShipPlan_1)
	begin
		select top 1 @ShipItem=item,@AllowInsertHOurs=WorkingHour from #MRP_MrpShipPlan_1
		set @NoID=1;set @MaxIdlePlanDate =''
		select @MaxIdlePlanDate=MAX(PlanDate) from #MRP_MrpMiPlan_1 where ActiveFlag ='Y' and TotalWorkingHour <21.90000000 and Item =@Item 
		if @@ROWCOUNT =0
			Begin
				select @MaxIdlePlanDate=MAX(PlanDate) from #MRP_MrpMiPlan_1 where ActiveFlag ='Y' and TotalWorkingHour <21.90000000 ---and Item =@Item
				If @@ROWCOUNT =0
					Begin
						Break
					End 
			End
		select @NeedInsertHours=21.90000000-TotalWorkingHour from #MRP_MrpMiPlan_1 where PlanDate =@MaxIdlePlanDate
		if abs(@AllowInsertHOurs-@NeedInsertHours)<0.1
		Begin
			delete #MRP_MrpShipPlan_1 where Item =@Item 
			Update #MRP_MrpMiPlan_1 Set ActiveFlag ='N' where PlanDate =@MaxIdlePlanDate 
		End
		else if @AllowInsertHOurs<@NeedInsertHours 
		Begin 
			Set @NeedInsertHours=@AllowInsertHOurs
			delete #MRP_MrpShipPlan_1 where Item =@Item 
		End
		else if @AllowInsertHOurs>@NeedInsertHours
		Begin
			Update #MRP_MrpMiPlan_1 Set ActiveFlag ='N' where PlanDate =@MaxIdlePlanDate
			update #MRP_MrpShipPlan_1 set WorkingHour =WorkingHour - @NeedInsertHours where Item =@Item 
		End
		if exists(select top 1 * from #MRP_MrpMiPlan_1 where PlanDate =@MaxIdlePlanDate and Huto=@HuTo and Item=@Item )
		Begin
			select top 1 @Huto =HuTo from #MRP_MrpMiPlan_1 
					where PlanDate =@MaxIdlePlanDate and Item=@Item
			Update #MRP_MrpMiPlan_1 Set WorkingHour=WorkingHour+@NeedInsertHours from #MRP_MrpMiPlan_1 
				where PlanDate =@MaxIdlePlanDate and Huto=@HuTo and Item=@Item
			Update #MRP_MrpMiPlan_1 set TotalWorkingHour=TotalWorkingHour+@NeedInsertHours from #MRP_MrpMiPlan_1 where PlanDate =@MaxIdlePlanDate 
		End
		Else
		Begin
		select @id=MAX(id)+1 from MRP_MrpMiPlan with(nolock)
		Insert into MRP_MrpMiPlan(id,ProductLine, Item, PlanDate, LocationFrom, LocationTo, PlanVersion, Sequence, WorkHour, UnitCount, Qty,
			AdjustQty, MrpPriority, MaxStock, SafeStock, InvQty, HuTo, Bom, Uom, BatchSize)
			select top 1 @id, Flow, Item, @MaxIdlePlanDate, isnull(LocFrom,''), isnull(LocTo,''), '2013-08-13 09:15:31.000', Seq, WorkHour, b.UC,0 As Qty,(@NeedInsertHours/60/a.UC /b.WorkHour -0) As AjQTY,
				MrpPriority, MaxStock, a.SafeStock, 0 As InvQty, @Huto, a.Bom, b.Uom, BatchSize
				from  SCM_FlowDet a with(nolock),MD_Item b with(nolock) where Flow='MI01' and Item =@Item and a.Item=b.Code
		End
	End
	
 
End






































			--select top 1 @PlanDate=PlanDate from #NeedAddPlanDate order by PlanDate desc
			--select @NeedInsertHours=@MaxDailyWorkHour-TotalWorkingHour from #MRP_MrpMiPlan where PlanDate=@PlanDate
			--if @NeedInsertHours>@MaxDailyWorkHour
			--	Begin
			--		print 1
			--	End
			--select a.Item,SUM(distinct b.AdjustHours) as CurrentHours into #TempItem from #MRP_MrpMiPlan a,#ItemAdjustHours b 
			--	where  PlanDate ='2013-08-13' and a.Item>=b.Item 
			--	group by a.Item having SUM(distinct b.AdjustHours)>=1.0 
			--select  @MaxITem=MAX(item),@MinITem=MIN(Item) from #TempItem
			--If @MaxITem=@MinITem 
			--	Begin
			--		s
			--	End
			--Update a
			--	Set a.AdjustHours =b.AdjustHours  from #MRP_MrpMiPlan a,#ItemAdjustHours b where a.Item =b.Item and a.Item between @MinITem and @MaxITem
			
			--select distinct a.Item from #MRP_MrpMiPlan a,#ItemAdjustHours b where  PlanDate ='2013-08-13' and a.Item=b.Item 
			--	 order by a.Item 
			--select *  from #MRP_MrpMiPlan where PlanDate ='2013-08-13' and item='270018' 
			
			--delete #NeedAddPlanDate where PlanDate=@PlanDate 
