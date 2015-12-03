SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_CreatePickTask')
BEGIN
	DROP PROCEDURE USP_WMS_CreatePickTask
END
GO

CREATE PROCEDURE dbo.USP_WMS_CreatePickTask
(
	@CreatePickTaskTable CreatePickTaskTableType readonly,
	@IsOccupyInv bit,
	@CreateUserId int,
	@CreateUserNm varchar(100)
)
AS
BEGIN
	set nocount on
	declare @DateTimeNow datetime
	declare @ErrorMsg nvarchar(MAX)
	declare @IsPickHu bit

	set @DateTimeNow = GetDate()

	create table #tempMsg_001 
	(
		Id int identity(1, 1) primary key,
		Lvl tinyint,
		Msg varchar(2000)
	)

	create table #tempShipPlan_001
	(
		Id int primary key,
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
		ShipQty decimal(18, 8),
		PickQty decimal(18, 8),
		ThisPickQty decimal(18, 8),
		[Priority] tinyint,
		LocFrom varchar(50),
		Dock varchar(50),
		IsShipScanHu bit,
		IsOccupyInv bit,
		IsActive bit,
	)

	create table #tempLocation_001
	(
		RowId int identity(1, 1),
		Location varchar(50),
		IsSpread bit,
		PickBy tinyint,
		Suffix varchar(50)
	)

	create table #tempPickTarget_001
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Item varchar(50)
	)

	create table #tempAvailableInv_001
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Item varchar(50),
		Area varchar(50),
		Bin varchar(50),
		BinSeq int,
		HuId varchar(50),
		LotNo varchar(50),
		Qty decimal(18, 8)
	)

	create table #tempPickTask_001
	(
		RowId int identity(1, 1) primary key,
		OrderNo varchar(50),
		OrderSeq int,
		OrderDetId int,
		ShipPlanId int,
		TargetDock varchar(50),
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
		PickQty decimal(18, 8),
		LocFrom varchar(50),
		Area varchar(50),
		Bin varchar(50),
		LotNo varchar(50),
		HuId varchar(50),
		PickBy tinyint,
		StartTime datetime,
		WindowTime datetime,
	)

	begin try
		insert into #tempShipPlan_001(Id, OrderNo, OrderSeq, OrderDetId, StartTime, WindowTime, 
								Item, ItemDesc, RefItemCode, Uom, BaseUom, UnitQty, UC, UCDesc,
								OrderQty, ShipQty, PickQty, ThisPickQty, [Priority], LocFrom, Dock, IsShipScanHu, IsOccupyInv, IsActive)
		select sp.Id, sp.OrderNo, sp.OrderSeq, sp.OrderDetId, sp.StartTime, sp.WindowTime, 
		sp.Item, sp.ItemDesc, sp.RefItemCode, sp.Uom, sp.BaseUom, sp.UnitQty, sp.UC, sp.UCDesc,
		sp.OrderQty, sp.ShipQty, sp.PickQty, tmp.PickQty, sp.[Priority], sp.LocFrom, sp.Dock, sp.IsShipScanHu, CASE WHEN @IsOccupyInv = 1 or sp.IsOccupyInv = 1 THEN 1 ELSE 0 END, sp.IsActive
		from @CreatePickTaskTable as tmp 
		inner join WMS_ShipPlan as sp on tmp.Id = sp.Id

		insert into #tempMsg_001(Lvl, Msg)
		select 2, N'发货任务'+ convert(varchar, Id) + N'已经关闭。'
		from #tempShipPlan_001 where IsActive = 0

		insert into #tempMsg_001(Lvl, Msg)
		select 2, N'发货任务'+ convert(varchar, Id) + N'的拣货数已经超过了订单数。'
		from #tempShipPlan_001 where IsActive = 1
		and (PickQty + ThisPickQty > OrderQty or ShipQty + ThisPickQty > OrderQty)

		select @IsPickHu = IsShipScanHu
		from #tempShipPlan_001 group by IsShipScanHu

		if (@@ROWCOUNT > 1) 
		begin
			insert into #tempMsg_001(Lvl, Msg) values(2, N'按数量拣货和按条码拣货不能合并创建拣货任务。')
		end

		if not exists(select top 1 1 from #tempMsg_001)
		begin
			--获取可用库存
			declare @PickTargetTable PickTargetTableType
			insert into @PickTargetTable(Location, Item) select distinct LocFrom, Item from #tempShipPlan_001
			insert into #tempAvailableInv_001(Location, Item, Area, Bin, BinSeq, HuId, LotNo, Qty) exec USP_WMS_GetAvailableInv4Pick @PickTargetTable, @IsPickHu



		end

	end try
	begin catch
		set @ErrorMsg = N'创建拣货任务发生异常：' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	select Lvl, Msg from #tempMsg_001 order by Id

	drop table #tempMsg_001
END
GO