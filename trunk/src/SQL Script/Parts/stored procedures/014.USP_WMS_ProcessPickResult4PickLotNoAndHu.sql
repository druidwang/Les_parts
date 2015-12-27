SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_ProcessPickResult4PickLotNoAndHu')
BEGIN
	DROP PROCEDURE USP_WMS_ProcessPickResult4PickLotNoAndHu
END
GO

CREATE PROCEDURE dbo.USP_WMS_ProcessPickResult4PickLotNoAndHu
	@PickResultTable PickResultTableType readonly,
	@PickBy tinyint,
	@CreateUserId int,
	@CreateUserNm varchar(100)
AS
BEGIN
	set nocount on
	declare @DateTimeNow datetime
	declare @ErrorMsg nvarchar(MAX)
	
	set @DateTimeNow = GetDate()

	create table #tempLocation_014
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Suffix varchar(50)
	)

	create table #tempPickResult_014
	(
		RowId int identity(1, 1),
		HuId varchar(50) primary key,
		LotNo varchar(50),
		PickTaskId int,
		PickTaskUUID varchar(50),
		Item varchar(50),
		ItemDesc varchar(50),
		RefItemCode varchar(100),
		Uom varchar(5),
		BaseUom varchar(5),
		UC decimal(18, 8),
		UCDesc varchar(50),
		UnitQty decimal(18, 8),
		Loc varchar(50),
		Area varchar(50),
		Bin varchar(50),
		Qty decimal(18, 8)
	)

	create table #tempPickTask_014
	(
		PickTaskID int,
		PickTaskUUID varchar(50) Primary Key,
		OrderQty decimal(18, 8),
		PickQty decimal(18, 8),
		ThisPickQty decimal(18, 8),
		UC decimal(18, 8),
		[Version] int
	)

	create table #tempPickOccupy_014
	(
		Id int Primary Key,
		PickTaskUUID varchar(50),
		ShipPlanId int,
		OccupyQty decimal(18, 8),
		ReleaseQty decimal(18, 8),
		ThisReleaseQty decimal(18, 8),
		ThisLockQty decimal(18, 8),
		[Version] int
	)

	create table #tempShipPlan_014
	(
		ShipPlanId int Primary Key,
		PickQty decimal(18, 8),
		PickedQty decimal(18, 8),
		ThisPickedQty decimal(18, 8),
		ThisLockQty decimal(18, 8),
		[Version] int,
	)

	create table #tempHuInventory_015
	(
		LocationLotDetId int primary key,
		HuId varchar(50),
		LotNo varchar(50),
		Item varchar(50),
		ItemDesc varchar(50),
		RefItemCode varchar(100),
		Uom varchar(5),
		BaseUom varchar(5),
		UC decimal(18, 8),
		UCDesc varchar(50),
		UnitQty decimal(18, 8),
		Location varchar(50),
		Area varchar(50),
		Bin varchar(50),
		Qty decimal(18, 8),
		[Version] int
	)

	begin try
		if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempMsg_014%') 
		begin
			set @ErrorMsg = '没有定义返回数据的参数表。'
			RAISERROR(@ErrorMsg, 16, 1) 

			--代码不会执行到这里
			create table #tempMsg_014 
			(
				Id int identity(1, 1) primary key,
				Lvl tinyint,
				Msg varchar(2000)
			)
		end
		else
		begin
			truncate table #tempMsg_014
		end

		begin try
			exec USP_WMS_GetHuInventory4Pick @PickResultTable
			
			insert into #tempLocation_014(Location, Suffix)
			select distinct l.Code, l.PartSuffix 
			from #tempHuInventory_015 as inv inner join MD_Location as l on inv.Location = l.Code

			insert into #tempMsg_014(Lvl, Msg)
			select 2, N'条码['+ pr.HuId + N']在库位['+ pt.Loc + N']中不存在。'
			from @PickResultTable as pr left join #tempHuInventory_015 as inv on pr.HuId = inv.HuId
			inner join WMS_PickTask as pt on pr.PickTaskId = pt.Id
			where inv.HuId is null

			insert into #tempMsg_014(Lvl, Msg)
			select 2, N'条码['+ pr.HuId + N']不在库格上。'
			from @PickResultTable as pr left join #tempHuInventory_015 as inv on pr.HuId = inv.HuId
			inner join WMS_PickTask as pt on pr.PickTaskId = pt.Id
			where inv.Bin is null

			insert into #tempMsg_014(Lvl, Msg)
			select 2, N'拣货任务['+ convert(varchar, pt.Id) + N']的物料代码['+ pt.Item + N']和条码['+ inv.HuId + N']的物料代码['+ inv.Item + N']不匹配。'
			from @PickResultTable as pr inner join #tempHuInventory_015 as inv on pr.HuId = inv.HuId
			inner join WMS_PickTask as pt on pr.PickTaskId = pt.Id
			where inv.Item <> pt.Item

			insert into #tempMsg_014(Lvl, Msg)
			select 2, N'拣货任务['+ convert(varchar, pt.Id) + N']物料代码['+ pt.Item + N']的单位['+ pt.Uom + N']和条码['+ inv.HuId + N']物料代码['+ inv.Item + N']的单位['+ pt.Uom + N']不匹配。'
			from @PickResultTable as pr inner join #tempHuInventory_015 as inv on pr.HuId = inv.HuId
			inner join WMS_PickTask as pt on pr.PickTaskId = pt.Id
			where inv.Uom <> pt.Uom

			if not exists(select top 1 1 from #tempMsg_014)
			begin
				insert into #tempPickResult_014(PickTaskId, PickTaskUUID, HuId, LotNo, Item, ItemDesc, RefItemCode, 
												Uom, BaseUom, UC, UCDesc, UnitQty, Loc, Area, Bin, Qty)
				select pt.Id, pt.UUID, inv.HuId, inv.LotNo, inv.Item, inv.ItemDesc, inv.RefItemCode, 
				inv.Uom, inv.BaseUom, inv.UC, inv.UCDesc, inv.UnitQty, inv.Location, inv.Area, inv.Bin, inv.Qty
				from @PickResultTable as pr inner join #tempHuInventory_015 as inv on pr.HuId = inv.HuId
				inner join WMS_PickTask as pt on pr.PickTaskId = pt.Id

				insert into #tempPickTask_014(PickTaskID, PickTaskUUID, OrderQty, PickQty, ThisPickQty, UC, [Version])
				select distinct pt.Id, pt.UUID, pt.OrderQty, pt.PickQty, 0, pt.UC, pt.[Version]
				from @PickResultTable as tmp 
				inner join WMS_PickTask as pt on tmp.PickTaskId = pt.Id

				update pt set ThisPickQty = tmp.Qty
				from #tempPickTask_014 as pt 
				inner join (select PickTaskId, SUM(Qty) as Qty 
							from @PickResultTable 
							group by PickTaskId) as tmp on pt.PickTaskId = tmp.PickTaskId

				insert into #tempPickOccupy_014(Id, PickTaskUUID, ShipPlanId, OccupyQty, ReleaseQty, ThisReleaseQty, ThisLockQty, [Version])
				select po.Id, po.UUID, po.ShipPlanId, po.OccupyQty, po.ReleaseQty, 0, 0, po.[Version]
				from #tempPickTask_014 as pt 
				inner join WMS_PickOccupy as po on pt.PickTaskUUID = po.UUID

				insert into #tempShipPlan_014(ShipPlanId, PickQty, PickedQty, ThisPickedQty, [Version])
				select distinct sp.Id, sp.PickQty, sp.PickedQty, 0, sp.[Version]
				from WMS_ShipPlan as sp 
				inner join #tempPickOccupy_014 as po on po.ShipPlanId = sp.Id

				declare @RowId int
				declare @MaxRowId int
				declare @PickTaskId int
				declare @PickTaskUUID varchar(50)
				declare @Qty decimal(18, 8)
				declare @IsOdd bit
				declare @LastQty decimal(18, 8)
				select @RowId = MIN(RowId), @MaxRowId = MAX(RowId) from #tempPickResult_014
				while @RowId <= @MaxRowId
				begin
					set @LastQty = 0
					select @PickTaskId = pr.PickTaskId, @PickTaskUUID = pr.PickTaskUUID, @Qty = pr.Qty, @IsOdd = CASE WHEN pt.UC = pr.UC THEN 0 ELSE 1 END
					from #tempPickResult_014 as pr inner join #tempPickTask_014 as pt on pr.PickTaskUUID = pt.PickTaskUUID 
					where pr.RowId = @RowId

					update #tempPickOccupy_014 set ThisReleaseQty = ThisReleaseQty + @LastQty, ThisLockQty = ThisLockQty + CASE WHEN @IsOdd = 0 THEN @LastQty ELSE 0 END,
					@Qty = @Qty - @LastQty, @LastQty = CASE WHEN @Qty >= OccupyQty - ReleaseQty - ThisReleaseQty THEN OccupyQty - ReleaseQty - ThisReleaseQty ELSE @Qty END
					where PickTaskUUID = @PickTaskUUID
					set @Qty = @Qty - @LastQty

					--if (@Qty > 0)
					--begin
					--	insert into #tempMsg_014(Lvl, Msg)
					--	values (2, N'拣货任务['+ convert(varchar, @PickTaskId) + N']的已拣数已经超过了对应发运单的拣货数。')
					--end

					set @RowId = @RowId + 1
				end

				update sp set ThisPickedQty = po.ThisReleaseQty, ThisLockQty = po.ThisLockQty
				from #tempShipPlan_014 as sp 
				inner join (select ShipPlanId, SUM(ThisReleaseQty) as ThisReleaseQty, SUM(ThisLockQty) as ThisLockQty 
							from #tempPickOccupy_014 group by ShipPlanId) as po on po.ShipPlanId = sp.ShipPlanId

				insert into #tempMsg_014(Lvl, Msg)
				select 2, N'拣货任务关联的发运任务['+ convert(varchar, ShipPlanId) + N']的已拣数已经超过了待拣数。'
				from #tempShipPlan_014 where PickQty < PickedQty + ThisPickedQty
			end
		end try
		begin catch
			set @ErrorMsg = N'数据准备出现异常：' + Error_Message()
			RAISERROR(@ErrorMsg, 16, 1) 
		end catch

		if not exists(select top 1 1 from #tempMsg_014)
		begin
			begin try
				declare @Trancount int
				set @Trancount = @@trancount

				if @Trancount = 0
				begin
					begin tran
				end
				
				declare @UpdateCount int

				select @UpdateCount = COUNT(1) from #tempPickTask_014
				update pt set PickQty = pt.PickQty + tmp.ThisPickQty, IsActive = CASE WHEN pt.PickQty + tmp.ThisPickQty >= pt.OrderQty THEN 1 ELSE 0 END,
								LastModifyDate = @DateTimeNow, LastModifyUser = @CreateUserId, LastModifyUserNm = @CreateUserNm, [Version] = pt.[Version] + 1
				from WMS_PickTask as pt inner join #tempPickTask_014 as tmp on pt.UUID = tmp.PickTaskUUID and pt.[Version] = tmp.[Version]

				if (@@ROWCOUNT <> @UpdateCount)
				begin
					RAISERROR(N'数据已经被更新，请重试。', 16, 1)
				end

				select @UpdateCount = COUNT(1) from  #tempPickOccupy_014 where ThisReleaseQty > 0
				update po set ReleaseQty = po.ReleaseQty + tmp.ThisReleaseQty, [Version] = po.[Version] + 1
				from WMS_PickOccupy as po inner join #tempPickOccupy_014 as tmp on po.Id = tmp.Id and po.[Version] = tmp.[Version]
				where tmp.ThisReleaseQty > 0

				if (@@ROWCOUNT <> @UpdateCount)
				begin
					RAISERROR(N'数据已经被更新，请重试。', 16, 1)
				end

				select @UpdateCount = COUNT(1) from  #tempShipPlan_014 where ThisPickedQty > 0
				update sp set LockQty = sp.LockQty + tmp.ThisLockQty, PickedQty = sp.PickedQty + tmp.ThisPickedQty, 
				LastModifyDate = @DateTimeNow, LastModifyUser = @CreateUserId, LastModifyUserNm = @CreateUserNm, [Version] = sp.[Version] + 1
				from WMS_ShipPlan as sp inner join #tempShipPlan_014 as tmp on sp.Id = tmp.ShipPlanId and sp.[Version] = tmp.[Version]
				where tmp.ThisPickedQty > 0

				if (@@ROWCOUNT <> @UpdateCount)
				begin
					RAISERROR(N'数据已经被更新，请重试。', 16, 1)
				end

				insert into WMS_PickResult(PickTaskId, PickTaskUUID, Item, ItemDesc, RefItemCode, Uom, BaseUom, UC, UCDesc, PickQty, Loc, 
				Area, Bin, LotNo, HuId, PickUserId, PickUserNm, CreateUser, CreateUserNm, CreateDate, IsCancel)
				select PickTaskId, PickTaskUUID, Item, ItemDesc, RefItemCode, Uom, BaseUom, UC, UCDesc, Qty, Loc,  
				Area, Bin, LotNo, HuId, @CreateUserId, @CreateUserNm, @CreateUserId, @CreateUserNm, @DateTimeNow, 0 
				from #tempPickResult_014

				insert into WMS_BuffInv(UUID, Loc, IOType, Item, Uom, UC, Qty, LotNo, HuId, CreateUser, CreateUserNm, CreateDate, LastModifyUser, LastModifyUserNm, LastModifyDate, [Version])
				select NEWID(), Location, 1, Item, Uom, UC, Qty * UnitQty, LotNo, HuId, @CreateUserId, @CreateUserNm, @DateTimeNow, @CreateUserId, @CreateUserNm, @DateTimeNow, 1 
				from #tempHuInventory_015

				declare @Location varchar(50)
				declare @Suffix varchar(50)
				declare @UpdateInvStatement nvarchar(max)
				declare @Parameter nvarchar(max)

				select @RowId = MIN(RowId), @MaxRowId = MAX(RowId) from #tempLocation_014
				while (@RowId <= @MaxRowId)
				begin
					select @Location = Location, @Suffix = Suffix from #tempLocation_014 where RowId = @RowId

					set @UpdateInvStatement = 'declare @UpdateCount int '
					set @UpdateInvStatement = @UpdateInvStatement + 'select @UpdateCount = COUNT(1) from #tempHuInventory_015 where Location = @Location_1 '
					set @UpdateInvStatement = @UpdateInvStatement + 'update lld set Bin = null, LastModifyUser = @CreateUserId_1, LastModifyUserNm = @CreateUserNm_1, LastModifyDate = @DateTimeNow_1, [Version] = lld.[Version] + 1 '
					set @UpdateInvStatement = @UpdateInvStatement + 'from INV_LocationLotDet_' + @Suffix + ' as lld '
					set @UpdateInvStatement = @UpdateInvStatement + 'inner join #tempHuInventory_015 as inv on lld.Id = inv.LocationLotDetId and lld.[Version] = inv.[Version] '
					set @UpdateInvStatement = @UpdateInvStatement + 'if (@@ROWCOUNT <> @UpdateCount) '
					set @UpdateInvStatement = @UpdateInvStatement + 'begin '
					set @UpdateInvStatement = @UpdateInvStatement + 'RAISERROR(N''数据已经被更新，请重试。'', 16, 1) '
					set @UpdateInvStatement = @UpdateInvStatement + 'end'
					set @Parameter = N'@Location_1 varchar(50), @CreateUserId_1 int, @CreateUserNm_1 varchar(100), @DateTimeNow_1 datetime'

					exec sp_executesql @UpdateInvStatement, @Parameter, @Location_1=@Location, @CreateUserId_1=@CreateUserId, @CreateUserNm_1=@CreateUserNm, @DateTimeNow_1=@DateTimeNow

					set @RowId = @RowId + 1
				end

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

	drop table #tempLocation_014
	drop table #tempPickResult_014
	drop table #tempPickTask_014
	drop table #tempPickOccupy_014
	drop table #tempShipPlan_014
	drop table #tempHuInventory_015
END
GO