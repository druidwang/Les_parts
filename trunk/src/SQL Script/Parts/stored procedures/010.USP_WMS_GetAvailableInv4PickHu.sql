SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_GetAvailableInv4PickHu')
BEGIN
	DROP PROCEDURE USP_WMS_GetAvailableInv4PickHu
END
GO

CREATE PROCEDURE dbo.USP_WMS_GetAvailableInv4PickHu
	@PickTargetTable PickTargetTableType readonly
AS
BEGIN
	set nocount on
	declare @ErrorMsg nvarchar(MAX)

	create table #tempPickTarget_010
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Item varchar(50)
	)

	create table #tempLocation_010
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Suffix varchar(50)
	)

	begin try
		if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempAvailableInv_010%') 
		begin
			set @ErrorMsg = '没有定义返回数据的参数表。'
			RAISERROR(@ErrorMsg, 16, 1) 

			--代码不会执行到这里
			create table #tempAvailableInv_010
			(
				RowId int identity(1, 1),
				Location varchar(50),
				Item varchar(50),
				HuId varchar(50),
				Uom varchar(5),
				UC decimal(18, 8),
				Area varchar(50),
				Bin varchar(50),
				LotNo varchar(50),
				Qty decimal(18, 8),
				OccupyQty decimal(18, 8),
				IsOdd bit
			)
		end
		else
		begin
			truncate table #tempAvailableInv_010
		end

		insert into #tempPickTarget_010(Location, Item) select distinct Location, Item from @PickTargetTable

		insert into #tempLocation_010(Location, Suffix) 
		select distinct l.Code, l.PartSuffix
		from #tempPickTarget_010 as tmp inner join MD_Location as l on tmp.Location = l.Code

		declare @LocationRowId int
		declare @MaxLocationRowId int
		declare @Location varchar(50)
		declare @LocSuffix varchar(50)
		declare @SelectInvStatement nvarchar(max)

		select @LocationRowId = MIN(RowId), @MaxLocationRowId = MAX(RowId) from #tempLocation_010

		while (@LocationRowId <= @MaxLocationRowId)
		begin
			select @Location = Location, @LocSuffix = Suffix
			from #tempLocation_010 where RowId = @LocationRowId

			set @SelectInvStatement = 'insert into #tempAvailableInv_010(Location, Item, HuId, Uom, UC, Area, Bin, LotNo, Qty, OccupyQty, IsOdd) '
			set @SelectInvStatement = @SelectInvStatement + 'select sp.Location, sp.Item, hu.HuId, hu.Uom, hu.UC, bin.Area, llt.Bin, hu.LotNo, hu.Qty, 0 as OccupyQty, CASE WHEN hu.UC = hu.Qty THEN 0 ELSE 1 END as IsOdd '
			set @SelectInvStatement = @SelectInvStatement + 'from #tempPickTarget_010 as sp '
			set @SelectInvStatement = @SelectInvStatement + 'inner join INV_LocationLotDet_' + @LocSuffix + ' as llt on sp.Location = llt.Location and sp.Item = llt.Item ' 
			set @SelectInvStatement = @SelectInvStatement + 'inner join INV_Hu as hu on llt.HuId = hu.HuId '
			set @SelectInvStatement = @SelectInvStatement + 'inner join MD_LocationBin as bin on llt.Bin = bin.Code '
			set @SelectInvStatement = @SelectInvStatement + 'left join WMS_PickTask as pt on llt.HuId = pt.HuId and pt.IsActive = 1 '  --过滤掉被拣货单占用的条码
			set @SelectInvStatement = @SelectInvStatement + 'where sp.Location = ''' + @Location + ''' and llt.OccupyRefNo is null and llt.Qty > 0 and llt.QualityType = 0 and pt.Id is null '

			exec sp_executesql @SelectInvStatement

			set @LocationRowId = @LocationRowId + 1
		end
	end try
	begin catch
		set @ErrorMsg = N'获取拣货可用库存发生异常：' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	drop table #tempLocation_010
	drop table #tempPickTarget_010
END
GO