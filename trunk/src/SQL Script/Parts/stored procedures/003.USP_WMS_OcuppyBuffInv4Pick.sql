SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_OcuppyBuffInv4Pick')
BEGIN
	DROP PROCEDURE USP_WMS_OcuppyBuffInv4Pick
END
GO

CREATE PROCEDURE dbo.USP_WMS_OcuppyBuffInv4Pick
	@CreatePickTaskTable CreatePickTaskTableType readonly,
	@IsPickHu bit,
	@CreateUserId int,
	@CreateUserNm varchar(100)
AS
BEGIN
	set nocount on
	declare @DateTimeNow datetime
	declare @ErrorMsg nvarchar(MAX)

	set @DateTimeNow = GetDate()

	create table #tempPickTarget_003
	(
		Id int identity(1, 1),
		Loc varchar(50),
		Item varchar(50)
	)

	create table #tempShipPlan_003
	(
		RowId int identity(1, 1) primary key,
		Id int,
		[Priority] tinyint,
		StartTime DateTime,
		LocFrom varchar(50),
		Item varchar(50),
		Uom varchar(5),
		UC decimal(18, 8),
		UnitQty decimal(18, 8),
		LockQty decimal(18, 8),		--可发货的数量
		PickQty decimal(18, 8),		--创建的拣货数
		PickedQty decimal(18, 8),	--已拣货数
		ThisLockQty decimal(18, 8),  --本次冻结的可发货数量
		ThisPickQty decimal(18, 8),  --本次要创建的拣货数
		ThisPickOddQty decimal(18, 8),  --本次要创建的拣货数除以整包装的零头
		ThisPickedQty decimal(18, 8),  --本次占用缓冲区的数量（本次拣货数）
		[Version] int
	)

	create table #tempBuffInv_003
	(
		RowId int identity(1, 1) primary key,
		Loc varchar(50),
		Item varchar(50),
		HuId varchar(50),
		Uom varchar(5),
		UC decimal(18, 8),
		Qty decimal(18, 8),
		UnitQty decimal(18, 8),
		OccupyShipPlanId int
	)

	begin try
		begin try
			--获取拣货库位和零件
			insert into #tempPickTarget_003(Loc, Item) 
			select distinct sp.LocFrom, sp.Item from @CreatePickTaskTable as t 
			inner join WMS_ShipPlan as sp on t.Id = sp.Id

			--获取发货计划
			insert into #tempShipPlan_003(Id, [Priority], StartTime, LocFrom, Item, UOM, UC, UnitQty, 
			LockQty, PickQty, PickedQty, ThisLockQty, ThisPickQty, ThisPickOddQty, ThisPickedQty, [Version])
			select sp.Id, sp.[Priority], sp.StartTime, sp.LocFrom, sp.Item, sp.Uom, sp.UC, sp.UnitQty, 
			sp.LockQty, sp.PickQty, sp.PickedQty, 0, t.PickQty, t.PickQty % sp.UC, 0, sp.[Version] 
			from @CreatePickTaskTable as t
			inner join WMS_ShipPlan as sp on t.Id = sp.Id
			order by sp.LocFrom, sp.Item, sp.[Priority], sp.StartTime, sp.Id

			if (@IsPickHu = 0)
			begin  --按数量拣货扣减缓冲区库存
				--按数量拣货：拣货完成后即增加shipPlan的PickedQty（已拣货数）和LockQty（已锁定数）
				--PickedQty（已拣货数）和LockQty（已锁定数）应该是一致的，这里只计算PickedQty

				--获取可用的Buff（库存单位）
				--不能过滤已经移动至道口的物料
				insert into #tempBuffInv_003(Loc, Item, Qty)
				select bi.Loc, bi.Item, bi.Qty
				from #tempPickTarget_003 as pt
				inner join WMS_BuffInv as bi on pt.Item = bi.Item and pt.Loc = bi.Loc
				where bi.HuId is null and bi.Qty > 0 and bi.IOType = 1  --目前只考虑发货缓存区，不考虑收货缓冲区（越库操作）
				group by bi.Loc, bi.Item

				--扣减掉发运计划占用的数量（库存单位）
				--不用单独扣减直接用发运计划占用的量(表WMS_PickOccupy)
				update bi set Qty = bi.Qty - sp.PickedQty
				from #tempBuffInv_003 as bi
				inner join (select sp.LocFrom, sp.Item, SUM((sp.PickedQty - sp.ShipQty) * sp.UnitQty) as PickedQty --转换为库存单位
							from WMS_ShipPlan as sp 
							inner join #tempPickTarget_003 as pt on sp.LocFrom = pt.Loc and sp.Item = pt.Item
							where sp.IsActive = 1 and sp.IsShipScanHu = 0 and sp.PickedQty > sp.ShipQty
							group by sp.LocFrom, sp.Item) as sp on bi.Loc = sp.LocFrom and bi.Item = sp.Item

				--发运计划占用缓冲区库存，按照发运优先级、发货时间顺序占用
				declare @RowId int
				declare @MaxRowId int
				declare @Loc varchar(50)
				declare @Item varchar(50)
				declare @OrgQty decimal(18, 8)
				declare @Qty decimal(18, 8)
				declare @LastQty decimal(18, 8)
				select @RowId = MIN(RowId), @MaxRowId = MAX(RowId) from #tempBuffInv_003
				while (@RowId <= @MaxRowId)
				begin
					select @Loc = Loc, @Item = Item, @OrgQty = Qty, @Qty = Qty, @LastQty = 0 from #tempBuffInv_003 where RowId = @RowId

					if (@Qty > 0)
					begin
						update sp set ThisPickedQty = CASE WHEN @Qty >= sp.ThisPickQty * sp.UnitQty THEN sp.ThisPickQty ELSE @Qty / sp.UnitQty END,
						@Qty = @Qty - @LastQty, @LastQty = ThisPickedQty * sp.UnitQty
						from #tempShipPlan_003 as sp
						where sp.Item = @Item and sp.LocFrom = @Loc
					end
				
					set @RowId = @RowId + 1
				end
			end
			else
			begin  --按条码拣货扣减缓冲区库存
				--按条码拣货：拣货完成后就增加PickedQty
				--要等缓冲区的库存和ShipPlan的UOM和UC完全匹配或者通过配送条码手工关联ShipPlan，才会增加shipPlan的LockQty（已锁定数）

				--获取可用的Buff（库存单位）
				--不能过滤已经移动至道口的物料
				insert into #tempBuffInv_003(Loc, Item, HuId, Uom, UC, Qty, UnitQty)
				select bi.Loc, bi.Item, bi.HuId, hu.Uom, hu.UC, bi.Qty, hu.UnitQty
				from #tempPickTarget_003 as pt
				inner join WMS_BuffInv as bi on pt.Item = bi.Item and pt.Loc = bi.Loc
				inner join INV_Hu as hu on bi.HuId = hu.HuId
				left join WMS_BuffOccupy as bo on bi.Id = bo.BuffInvId
				where bi.Qty > 0 and bi.IOType = 1  --目前只考虑发货缓存区，不考虑收货缓冲区（越库操作）
				and bo.Id is null

				select sp.LocFrom, sp.Item, sp.Uom, sp.UC, SUM((sp.LockQty - sp.ShipQty) * sp.UnitQty - ISNULL(occ.Qty, 0)) as RemainLockQty, SUM((sp.PickedQty - sp.ShipQty) * sp.UnitQty - ISNULL(occ.Qty, 0)) as RemainPickedQty --转换为库存单位
				from WMS_ShipPlan as sp
				inner join #tempPickTarget_003 as pt on sp.LocFrom = pt.Loc and sp.Item = pt.Item
				left join (select bo.ShipPlanId, SUM(bi.Qty) as Qty from #tempPickTarget_003 as pt
							inner join WMS_BuffInv as bi on pt.Item = bi.Item and pt.Loc = bi.Loc
							inner join WMS_BuffOccupy as bo on bi.Id = bo.BuffInvId
							where bi.Qty > 0 and bi.IOType = 1) as occ on sp.Id = occ.ShipPlanId
				where sp.IsActive = 1 and sp.IsShipScanHu = 1 and sp.PickedQty > sp.ShipQty



			end
		end try
		begin catch
			set @ErrorMsg = N'数据准备出现异常：' + Error_Message()
			RAISERROR(@ErrorMsg, 16, 1) 
		end catch

		begin try
			declare @trancount int
			set @trancount = @@trancount

			if @Trancount = 0
			begin
				begin tran
			end
			
			if (@IsPickHu = 0)
			begin  --按数量拣货扣减缓冲区库存
				--获取需要更新的行数
				declare @UpdateRowCount int
				select @UpdateRowCount = count(1) from #tempShipPlan_003 where ThisPickedQty > 0
			
				--更新创建拣货单的数量和已经拣货的数量
				update sp set LockQty = sp.LockQty + tmp.ThisPickedQty, PickedQty = sp.PickedQty + tmp.ThisPickedQty, PickQty = sp.PickQty + tmp.ThisPickedQty, 
				LastModifyDate = @DateTimeNow, LastModifyUser = @CreateUserId, LastModifyUserNm = @CreateUserNm, [Version] = sp.[Version] + 1
				from  #tempShipPlan_003 as tmp
				inner join WMS_ShipPlan as sp on tmp.Id = sp.Id and tmp.[Version] = sp.[Version]
				where tmp.ThisPickedQty > 0

				if (@@ROWCOUNT <> @UpdateRowCount)
				begin
					RAISERROR(N'数据已经被更新，请重试。', 16, 1)
				end
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
	end try
	begin catch
		set @ErrorMsg = N'占用缓冲区库存发生异常：' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	select Id, ThisPickedQty from #tempShipPlan_003 where ThisPickedQty > 0

	drop table #tempPickTarget_003
	drop table #tempShipPlan_003
	drop table #tempBuffInv_003
END
GO