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
	@CreatePickTaskTable CreatePickTaskTableType,
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

	create table #tempMsg_01 
	(
		Id int identity(1, 1) primary key,
		Lvl tinyint,
		Msg varchar(2000)
	)

	create table #tempShipPlan_01
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

	create table #tempLocation_01
	(
		RowId int identity(1, 1),
		Location varchar(50),
		IsSpread bit,
		PickBy tinyint,
		Suffix varchar(50)
	)

	create table #tempPickTarget_01
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Item varchar(50)
	)

	create table #tempAvailableInv_01
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Item varchar(50),
		HuId varchar(50),
		LotNo varchar(50),
		Qty decimal(18, 8)
	)

	create table #tempPickTask_01
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
		insert into #tempShipPlan_01(Id, OrderNo, OrderSeq, OrderDetId, StartTime, WindowTime, 
								Item, ItemDesc, RefItemCode, Uom, BaseUom, UnitQty, UC, UCDesc,
								OrderQty, ShipQty, PickQty, ThisPickQty, [Priority], LocFrom, Dock, IsShipScanHu, IsOccupyInv, IsActive)
		select sp.Id, sp.OrderNo, sp.OrderSeq, sp.OrderDetId, sp.StartTime, sp.WindowTime, 
		sp.Item, sp.ItemDesc, sp.RefItemCode, sp.Uom, sp.BaseUom, sp.UnitQty, sp.UC, sp.UCDesc,
		sp.OrderQty, sp.ShipQty, sp.PickQty, tmp.PickQty, sp.[Priority], sp.LocFrom, sp.Dock, sp.IsShipScanHu, CASE WHEN @IsOccupyInv = 1 or sp.IsOccupyInv = 1 THEN 1 ELSE 0 END, sp.IsActive
		from @CreatePickTaskTable as tmp 
		inner join WMS_ShipPlan as sp on tmp.Id = sp.Id

		insert into #tempMsg_01(Lvl, Msg)
		select 2, N'发货任务'+ convert(varchar, Id) + N'已经关闭。'
		from #tempShipPlan_01 where IsActive = 0

		insert into #tempMsg_01(Lvl, Msg)
		select 2, N'发货任务'+ convert(varchar, Id) + N'的拣货数已经超过了订单数。'
		from #tempShipPlan_01 where IsActive = 1
		and (PickQty + ThisPickQty > OrderQty or ShipQty + ThisPickQty > OrderQty)

		select @IsPickHu = IsShipScanHu
		from #tempShipPlan_01 group by IsShipScanHu

		if (@@ROWCOUNT > 1) 
		begin
			insert into #tempMsg_01(Lvl, Msg) values(2, N'按数量拣货和按条码拣货不能合并创建拣货任务。')
		end

		if not exists(select top 1 1 from #tempMsg_01)
		begin
			insert into #tempPickTarget_01(Location, Item) select distinct LocFrom, Item from #tempShipPlan_01

			insert into #tempLocation_01(Location, IsSpread, PickBy, Suffix) 
			select distinct sp.LocFrom, l.IsSpread, l.PickBy, l.PartSuffix 
			from #tempShipPlan_01 as sp inner join MD_Location as l on sp.LocFrom = l.Code

			declare @LocationRowId int
			declare @MaxLocationRowId int
			declare @Location varchar(50)
			declare @IsSpread bit
			declare @LocSuffix varchar(50)
			select @LocationRowId = MIN(RowId), @MaxLocationRowId = MAX(RowId) from #tempLocation_01

			while (@LocationRowId <= @MaxLocationRowId)
			begin
				select @Location = Location, @IsSpread = IsSpread, @LocSuffix = Suffix 
				from #tempLocation_01 where RowId = @LocationRowId

				if (@IsPickHu = 0)
				begin --按数量拣货
					
					insert into #tempAvailableInv_01(Location, Item, Qty)
					select ai.Location, ai.Item, SUM(InvQty) - SUM(OccupyQty)
					from (select sp.Location, sp.Item, SUM(ISNULL(llt.Qty, 0)) as InvQty, 0 as OccupyQty
							from #tempPickTarget_01 as sp
							left join INV_LocationLotDet as llt on sp.Location = llt.Location and sp.Item = llt.Item 
							where sp.Location = @Location and (llt.Id is null or (llt.OccupyRefNo is null and llt.Qty > 0 and llt.HuId is null and llt.QualityType = 0))
							group by sp.Location, sp.Item
							union all 
							select sp.Location, sp.Item, 0 as InvQty, SUM(ISNULL(bi.Qty, 0)) as OccupyQty 
							from #tempPickTarget_01 as sp
							left join WMS_BuffInv as bi on bi.Loc = sp.Location and bi.Item = sp.Item
							where sp.Location = @Location and (bi.Id is null or (bi.Qty > 0 and bi.HuId is null))
							group by sp.Location, sp.Item
							union all 
							select sp.Location, sp.Item, 0 as InvQty, SUM(ISNULL(pt.PickQty, 0)) as OccupyQty 
							from #tempPickTarget_01 as sp
							left join (select pt.Loc, pt.Item, SUM((pt.OrderQty - pt.PickQty) * pt.UnitQty) as PickQty
										from #tempPickTarget_01 as sp inner join WMS_PickTask as pt on sp.Location = pt.Loc and sp.Item = pt.Item
										where sp.Location = @Location and (pt.LotNo is null and pt.HuId is null and pt.IsActive = 1 and pt.OrderQty > pt.PickQty) 
										group by pt.Loc, pt.Item) as pt on pt.Loc = sp.Location and pt.Item = sp.Item
							group by sp.Location, sp.Item) as ai
					group by ai.Location, ai.Item
					having  SUM(InvQty) > SUM(OccupyQty)
				end
				else 
				begin --按条码拣货
					select *
					from #tempShipPlan_01 as sp
					inner join VIEW_LocationLotDet as llt on sp.LocFrom = llt.Location and sp.Item = llt.Item
				end

				set @LocationRowId = @LocationRowId + 1
			end
		end

	end try
	begin catch
		set @ErrorMsg = N'更新库存出现异常：' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	select Lvl, Msg from #tempMsg_01 order by Id

	drop table #tempMsg_01
END
GO