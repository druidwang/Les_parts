SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_CreatePickTask4PickQty')
BEGIN
	DROP PROCEDURE USP_WMS_CreatePickTask4PickQty
END
GO

CREATE PROCEDURE dbo.USP_WMS_CreatePickTask4PickQty
(
	@CreatePickTaskTable CreatePickTaskTableType readonly,
	@CreateUserId int,
	@CreateUserNm varchar(100)
)
AS
BEGIN
	set nocount on
	declare @DateTimeNow datetime
	declare @ErrorMsg nvarchar(MAX)
	declare @Trancount int

	set @DateTimeNow = GetDate()
	set @Trancount = @@trancount

	create table #tempMsg_002 
	(
		Id int identity(1, 1) primary key,
		Lvl tinyint,
		Msg varchar(2000)
	)

	create table #tempShipPlan_002
	(
		ShipPlanId int primary key,
		OrderNo varchar(50),
		OrderSeq int,
		OrderDetId int,
		StartTime datetime,
		WindowTime datetime,
		Item varchar(50),
		ItemDesc varchar(100),
		RefItemCode varchar(50),
		Uom varchar(5),
		BaseUom varchar(5),
		UnitQty decimal(18, 8),
		UC decimal(18, 8),
		UCDesc varchar(50),
		OrderQty decimal(18, 8),
		PickQty decimal(18, 8),
		PickedQty decimal(18, 8),
		ThisPickQty decimal(18, 8),
		ThisPickFullQty decimal(18, 8),  --本次要创建的拣货数（整包装）
		ThisPickOddQty decimal(18, 8),  --本次要创建的拣货数（零头数）
		ThisPickedQty decimal(18, 8),
		[Priority] tinyint,
		LocFrom varchar(50),
		Dock varchar(50),
		IsShipScanHu bit,
		IsActive bit,
	)

	CREATE TABLE #tempPickTask_002
	(
		RowId int IDENTITY(1,1),
		[Priority] tinyint,
		Item varchar(50),
		ItemDesc varchar(100),
		RefItemCode varchar(50),
		Uom varchar(5),
		BaseUom varchar(5),
		UnitQty decimal(18, 8),
		UC decimal(18, 8),
		UCDesc varchar(50),
		OrderQty decimal(18, 8),
		Loc varchar(50),
		Area varchar(50),
		Bin varchar(50),
		LotNo varchar(50),
		HuId varchar(50),
		StartTime datetime,
		WinTime datetime,
		IsPickHu bit,
		NeedRepack bit,
		OrderNo varchar(50),
		OrderSeq int,
		ShipPlanId int,
		TargetDock varchar(50),
	)

	if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempAvailableInv_002%') 
	begin
		create table #tempAvailableInv_002
		(
			RowId int identity(1, 1),
			Location varchar(50),
			PickBy tinyint,
			Item varchar(50),
			Uom varchar(5),
			UC decimal(18, 8),
			Area varchar(50),
			Bin varchar(50),
			BinSeq int,
			HuId varchar(50),
			LotNo varchar(50),
			Qty decimal(18, 8),
			IsOdd bit
		)
	end

	if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempOccupyBuffInv_003%') 
	begin
		create table #tempOccupyBuffInv_003
		(
			Id int primary key,
			PickedQty decimal(18, 8),
		)
	end

	begin try
		begin try
			--获取发运计划
			insert into #tempShipPlan_002(ShipPlanId, OrderNo, OrderSeq, OrderDetId, StartTime, WindowTime, 
									Item, ItemDesc, RefItemCode, Uom, BaseUom, UnitQty, UC, UCDesc,
									OrderQty, PickQty, PickedQty, ThisPickQty, ThisPickedQty, 
									[Priority], LocFrom, Dock, IsShipScanHu, IsActive)
			select sp.Id, sp.OrderNo, sp.OrderSeq, sp.OrderDetId, sp.StartTime, sp.WindowTime, 
			sp.Item, sp.ItemDesc, sp.RefItemCode, sp.Uom, sp.BaseUom, sp.UnitQty, sp.UC, sp.UCDesc,
			sp.OrderQty, sp.PickQty, sp.PickedQty, tmp.PickQty, 0,
			sp.[Priority], sp.LocFrom, sp.Dock, sp.IsShipScanHu, sp.IsActive
			from @CreatePickTaskTable as tmp 
			inner join WMS_ShipPlan as sp on tmp.Id = sp.Id
			
			--占用发货缓冲区的库存
			--exec USP_WMS_OcuppyBuffInv4PickQty @CreatePickTaskTable, @CreateUserId, @CreateUserNm
			--update sp set ThisPickQty = ThisPickQty - bi.PickedQty from #tempShipPlan_002 as sp inner join #tempOccupyBuffInv_003 as bi on sp.Id = bi.Id

			--获取可用库存
			declare @PickTargetTable PickTargetTableType
			insert into @PickTargetTable(Location, Item) select distinct LocFrom, Item from #tempShipPlan_002
			exec USP_WMS_GetAvailableInv4Pick @PickTargetTable

			declare @RowId int
			declare @MaxRowId int
			declare @Location varchar(50)
			declare @Item varchar(50)
			declare @Qty decimal(18, 8)
			declare @LastQty decimal(18, 8)
			select @RowId = MIN(RowId), @MaxRowId = MAX(RowId) from #tempAvailableInv_002
			while @RowId <= @MaxRowId
			begin
				set @LastQty = 0
				select @Location = Location, @Item = Item, @Qty = Qty 
				from #tempAvailableInv_002 where RowId = @RowId

				update sp set ThisPickedQty = @LastQty / sp.UnitQty,
				@Qty = @Qty - @LastQty, @LastQty = CASE WHEN @Qty >= sp.ThisPickQty * sp.UnitQty THEN sp.ThisPickQty * sp.UnitQty ELSE @Qty END
				from #tempShipPlan_002 as sp
				where sp.Item = @Item and sp.LocFrom = @Location
				set @Qty = @Qty - @LastQty

				insert into #tempPickTask_002(OrderNo, OrderSeq, ShipPlanId, TargetDock,
											[Priority], Item, ItemDesc, RefItemCode , Uom , BaseUom, UnitQty, UC, UCDesc, OrderQty, 
											Loc, StartTime, WinTime, IsPickHu, NeedRepack)
				select OrderNo, OrderSeq, ShipPlanId, Dock,
				[Priority], Item, ItemDesc, RefItemCode, Uom, BaseUom, UnitQty, UC, UCDesc, ThisPickedQty 
				Loc, @DateTimeNow, case when StartTime >= @DateTimeNow then StartTime else @DateTimeNow end, 0, 0
				from #tempShipPlan_002 where ThisPickedQty > 0

				update #tempShipPlan_002 set ThisPickQty = ThisPickQty - ThisPickedQty, ThisPickedQty = 0 where ThisPickedQty > 0

				set @RowId = @RowId + 1 
			end
		end try
		begin catch
			set @ErrorMsg = N'数据准备出现异常：' + Error_Message()
			RAISERROR(@ErrorMsg, 16, 1) 
		end catch

		begin try
			if @Trancount = 0
			begin
				begin tran
			end

			if exists(select top 1 1 from #tempPickTask_002)
			begin
				INSERT INTO WMS_PickTask( Priority, Item, ItemDesc, RefItemCode, Uom, BaseUom, UnitQty, UC, UCDesc, OrderQty, PickQty, Loc, Area, Bin, LotNo, HuId, PickBy, PickGroup, PickUserId, PickUserNm, StartTime, WinTime, IsActive, CreateUser, CreateUserNm, CreateDate, LastModifyUser, LastModifyUserNm, LastModifyDate, CloseUser, CloseUserNm, CloseDate, Version, IsPickHu, NeedRepack)
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
		set @ErrorMsg = N'创建拣货任务发生异常：' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	select Lvl, Msg from #tempMsg_002 order by Id

	drop table #tempMsg_002
END
GO