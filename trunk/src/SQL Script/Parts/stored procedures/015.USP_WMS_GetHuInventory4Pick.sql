SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_GetHuInventory4Pick')
BEGIN
	DROP PROCEDURE USP_WMS_GetHuInventory4Pick
END
GO

CREATE PROCEDURE dbo.USP_WMS_GetHuInventory4Pick
	@PickResultTable PickResultTableType readonly
AS
BEGIN
	set nocount on
	declare @ErrorMsg nvarchar(MAX)

	create table #tempPickResult_015
	(
		HuId varchar(50) primary key,
		Location varchar(50)
	)

	create table #tempLocation_015
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Suffix varchar(50)
	)

	begin try
		if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempHuInventory_015%') 
		begin
			set @ErrorMsg = '没有定义返回数据的参数表。'
			RAISERROR(@ErrorMsg, 16, 1) 

			--代码不会执行到这里
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
		end
		else
		begin
			truncate table #tempHuInventory_015
		end

		insert into #tempPickResult_015(HuId, Location)
		select tmp.HuId, pt.Loc from @PickResultTable as tmp 
		inner join WMS_PickTask as pt on tmp.PickTaskUUID = pt.Id

		insert into #tempLocation_015(Location, Suffix) 
		select distinct pr.Location, l.PartSuffix
		from #tempPickResult_015 as pr inner join MD_Location as l on pr.Location = l.Code

		declare @RowId int
		declare @MaxRowId int
		declare @Location varchar(50)
		declare @Suffix varchar(50)
		declare @SelectInvStatement nvarchar(max)

		select @RowId = MIN(RowId), @MaxRowId = MAX(RowId) from #tempLocation_015
		while (@RowId <= @MaxRowId)
		begin
			select @Location = Location, @Suffix = Suffix from #tempLocation_015 where RowId = @RowId

			set @SelectInvStatement = 'insert into #tempHuInventory_015(LocationLotDetId, HuId, LotNo, Item, ItemDesc, RefItemCode, Uom, BaseUom, UC, UCDesc, UnitQty, Location, Area, Bin, Qty, [Version]) '
			set @SelectInvStatement = @SelectInvStatement + 'select lld.Id, hu.HuId, hu.LotNo, hu.Item, hu.ItemDesc, hu.RefItemCode, hu.Uom, hu.BaseUom, hu.UC, hu.UCDesc, hu.UnitQty, lld.Location, bin.Area, lld.Bin, lld.Qty, lld.[Version] '
			set @SelectInvStatement = @SelectInvStatement + 'from #tempPickResult_015 as pr '
			set @SelectInvStatement = @SelectInvStatement + 'inner join INV_Hu as hu on pr.HuId = hu.HuId '
			set @SelectInvStatement = @SelectInvStatement + 'inner join INV_LocationLotDet_' + @Suffix + ' as lld on lld.HuId = hu.HuId '
			set @SelectInvStatement = @SelectInvStatement + 'left join MD_LocationBin as bin on lld.Bin = bin.Code '
			set @SelectInvStatement = @SelectInvStatement + 'where pr.Location = ''' + @Location + ''' and lld.Location = ''' + @Location + ''' and lld.Qty > 0 '
	
			exec sp_executesql @SelectInvStatement

			set @RowId = @RowId + 1
		end
	end try
	begin catch
		set @ErrorMsg = N'获取条码库存发生异常：' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	drop table #tempPickResult_015
	drop table #tempLocation_015
END
GO