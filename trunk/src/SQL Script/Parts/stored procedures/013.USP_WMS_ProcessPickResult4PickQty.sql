SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_ProcessPickResult4PickQty')
BEGIN
	DROP PROCEDURE USP_WMS_ProcessPickResult4PickQty
END
GO

CREATE PROCEDURE dbo.USP_WMS_ProcessPickResult4PickQty
	@PickResultTable PickResultTableType readonly,
	@CreateUserId int,
	@CreateUserNm varchar(100)
AS
BEGIN
	set nocount on
	declare @DateTimeNow datetime
	declare @ErrorMsg nvarchar(MAX)
	
	set @DateTimeNow = GetDate()

	create table #tempPickTask_013
	(
		RowId int identity(1, 1),
		PickTaskID int,
		PickTaskUUID varchar(50) Primary Key,
		Loc varchar(50),
		Item varchar(50),
		ItemDesc varchar(50),
		RefItemCode varchar(100),
		Uom varchar(5),
		BaseUom varchar(5),
		UC decimal(18, 8),
		UCDesc varchar(50),
		UnitQty decimal(18, 8),
		OrderQty decimal(18, 8),
		PickQty decimal(18, 8),
		ThisPickQty decimal(18, 8),
		[Version] int
	)

	create table #tempPickOccupy_013
	(
		Id int Primary Key,
		PickTaskUUID varchar(50),
		ShipPlanId int,
		OccupyQty decimal(18, 8),
		ReleaseQty decimal(18, 8),
		ThisReleaseQty decimal(18, 8),
		[Version] int
	)

	create table #tempShipPlan_013
	(
		ShipPlanId int Primary Key,
		PickQty decimal(18, 8),
		PickedQty decimal(18, 8),
		ThisPickedQty decimal(18, 8),
		[Version] int,
	)

	begin try
		if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempMsg_013%') 
		begin
			set @ErrorMsg = '没有定义返回数据的参数表。'
			RAISERROR(@ErrorMsg, 16, 1) 

			--代码不会执行到这里
			create table #tempMsg_013 
			(
				Id int identity(1, 1) primary key,
				Lvl tinyint,
				Msg varchar(2000)
			)
		end
		else
		begin
			truncate table #tempMsg_013
		end

		begin try
			insert into #tempPickTask_013(PickTaskId, PickTaskUUID, Loc, Item, ItemDesc, RefItemCode, Uom, BaseUom, UC, UCDesc, UnitQty, OrderQty, PickQty, ThisPickQty, [Version])
			select distinct tp.Id, tp.UUID, tp.Loc, tp.Item, tp.ItemDesc, tp.RefItemCode, tp.Uom, tp.BaseUom, tp.UC, tp.UCDesc, tp.UnitQty, tp.OrderQty, tp.PickQty, tmp.Qty, tp.[Version]
			from @PickResultTable as tmp 
			inner join WMS_PickTask as tp on tmp.PickTaskId = tp.Id

			insert into #tempPickOccupy_013(Id, PickTaskUUID, ShipPlanId, OccupyQty, ReleaseQty, ThisReleaseQty, [Version])
			select po.Id, po.UUID, po.ShipPlanId, po.OccupyQty, po.ReleaseQty, 0, po.[Version]
			from #tempPickTask_013 as pt 
			inner join WMS_PickOccupy as po on pt.PickTaskUUID = po.UUID

			insert into #tempShipPlan_013(ShipPlanId, PickQty, PickedQty, ThisPickedQty, [Version])
			select distinct sp.Id, sp.PickQty, sp.PickedQty, 0, sp.[Version]
			from WMS_ShipPlan as sp 
			inner join #tempPickOccupy_013 as po on po.ShipPlanId = sp.Id
			
			declare @RowId int
			declare @MaxRowId int
			declare @PickTaskId int
			declare @PickTaskUUID varchar(50)
			declare @Qty decimal(18, 8)
			declare @LastQty decimal(18, 8)
			select @RowId = MIN(RowId), @MaxRowId = MAX(RowId) from #tempPickTask_013
			while @RowId <= @MaxRowId
			begin
				set @LastQty = 0
				select @PickTaskId = PickTaskId, @PickTaskUUID = PickTaskUUID, @Qty = ThisPickQty
				from #tempPickTask_013 where RowId = @RowId

				update #tempPickOccupy_013 set ThisReleaseQty = @LastQty,
				@Qty = @Qty - @LastQty, @LastQty = CASE WHEN @Qty >= OccupyQty - ReleaseQty THEN OccupyQty - ReleaseQty ELSE @Qty END
				where PickTaskUUID = @PickTaskUUID
				set @Qty = @Qty - @LastQty

				if (@Qty > 0)
				begin
					insert into #tempMsg_013(Lvl, Msg)
					values (2, N'拣货任务['+ convert(varchar, @PickTaskId) + N']的已拣数已经超过了对应发运单的拣货数。')
				end

				set @RowId = @RowId + 1
			end

			update sp set ThisPickedQty = po.ThisReleaseQty
			from #tempShipPlan_013 as sp 
			inner join (select ShipPlanId, SUM(ThisReleaseQty) as ThisReleaseQty 
						from #tempPickOccupy_013 group by ShipPlanId) as po on po.ShipPlanId = sp.ShipPlanId
		
			insert into #tempMsg_013(Lvl, Msg)
			select 2, N'和拣货任务关联的发运任务['+ convert(varchar, ShipPlanId) + N']的已拣数已经超过了待拣数。'
			from #tempShipPlan_013 where PickQty < PickedQty + ThisPickedQty
		end try
		begin catch
			set @ErrorMsg = N'数据准备出现异常：' + Error_Message()
			RAISERROR(@ErrorMsg, 16, 1) 
		end catch

		if not exists(select top 1 1 from #tempMsg_013)
		begin
			begin try
				declare @Trancount int
				set @Trancount = @@trancount

				if @Trancount = 0
				begin
					begin tran
				end
				
				declare @UpdateCount int

				select @UpdateCount = COUNT(1) from #tempPickTask_013
				update pt set PickQty = pt.PickQty + tmp.ThisPickQty, IsActive = CASE WHEN pt.PickQty + tmp.ThisPickQty >= pt.OrderQty THEN 1 ELSE 0 END,
								LastModifyDate = @DateTimeNow, LastModifyUser = @CreateUserId, LastModifyUserNm = @CreateUserNm, [Version] = pt.[Version] + 1
				from WMS_PickTask as pt inner join #tempPickTask_013 as tmp on pt.UUID = tmp.PickTaskUUID and pt.[Version] = tmp.[Version]

				if (@@ROWCOUNT <> @UpdateCount)
				begin
					RAISERROR(N'数据已经被更新，请重试。', 16, 1)
				end

				select @UpdateCount = COUNT(1) from  #tempPickOccupy_013 where ThisReleaseQty > 0
				update po set ReleaseQty = po.ReleaseQty + tmp.ThisReleaseQty, [Version] = po.[Version] + 1
				from WMS_PickOccupy as po inner join #tempPickOccupy_013 as tmp on po.Id = tmp.Id and po.[Version] = tmp.[Version]
				where tmp.ThisReleaseQty > 0

				if (@@ROWCOUNT <> @UpdateCount)
				begin
					RAISERROR(N'数据已经被更新，请重试。', 16, 1)
				end

				select @UpdateCount = COUNT(1) from  #tempShipPlan_013 where ThisPickedQty > 0
				update sp set LockQty = sp.LockQty + tmp.ThisPickedQty, PickedQty = sp.PickedQty + tmp.ThisPickedQty, 
				LastModifyDate = @DateTimeNow, LastModifyUser = @CreateUserId, LastModifyUserNm = @CreateUserNm, [Version] = sp.[Version] + 1
				from WMS_ShipPlan as sp inner join #tempShipPlan_013 as tmp on sp.Id = tmp.ShipPlanId and sp.[Version] = tmp.[Version]
				where tmp.ThisPickedQty > 0

				if (@@ROWCOUNT <> @UpdateCount)
				begin
					RAISERROR(N'数据已经被更新，请重试。', 16, 1)
				end

				insert into WMS_PickResult(PickTaskId, PickTaskUUID, Item, ItemDesc, RefItemCode, Uom, BaseUom, UC, UCDesc, PickQty, Loc, 
				PickUserId, PickUserNm, CreateUser, CreateUserNm, CreateDate, IsCancel)
				select PickTaskId, PickTaskUUID, Item, ItemDesc, RefItemCode, Uom, BaseUom, UC, UCDesc, PickQty, Loc,  
				@CreateUserId, @CreateUserNm, @CreateUserId, @CreateUserNm, @DateTimeNow, 0 
				from #tempPickTask_013

				insert into WMS_BuffInv(UUID, Loc, IOType, Item, Uom, UC, Qty, CreateUser, CreateUserNm, CreateDate, LastModifyUser, LastModifyUserNm, LastModifyDate, [Version])
				select NEWID(), Loc, 1, Item, Uom, UC, ThisPickQty * UnitQty, @CreateUserId, @CreateUserNm, @DateTimeNow, @CreateUserId, @CreateUserNm, @DateTimeNow, 1 
				from #tempPickTask_013

				if @Trancount = 0 
				begin  
					commit
				end
			end try
			begin catch
				if @Trancount = 0
				begin
					rollback
				end 

				set @ErrorMsg = N'数据更新出现异常：' + Error_Message()
				RAISERROR(@ErrorMsg, 16, 1) 
			end catch
		end
	end try
	begin catch
		set @ErrorMsg = N'处理拣货结果发生异常：' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	drop table #tempPickTask_013
	drop table #tempPickOccupy_013
	drop table #tempShipPlan_013
END
GO