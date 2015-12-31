SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_GetHuInventory4Ship')
BEGIN
	DROP PROCEDURE USP_WMS_GetHuInventory4Ship
END
GO

CREATE PROCEDURE dbo.USP_WMS_GetHuInventory4Ship
	@ShipResultTable ShipResultTableType readonly
AS
BEGIN
	set nocount on
	declare @ErrorMsg nvarchar(MAX)

	create table #tempLocation_018
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Suffix varchar(50)
	)

	begin try
		if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempBuffInv_018%') 
		begin
			set @ErrorMsg = '没有定义返回数据的参数表。'
			RAISERROR(@ErrorMsg, 16, 1) 

			--代码不会执行到这里
			create table #tempBuffInv_018
			(
				UUID varchar(50) primary key,
				HuId varchar(50),
				Location varchar(50),
				ShipPlanId int,
				[Version] int
			)
		end
		else
		begin
			truncate table #tempBuffInv_018
		end

		if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempLocationLotDet_018%') 
		begin
			set @ErrorMsg = '没有定义返回数据的参数表。'
			RAISERROR(@ErrorMsg, 16, 1) 

			--代码不会执行到这里
			create table #tempLocationLotDet_018
			(
				Id int primary key,
				Location varchar(50),
				HuId varchar(50),
				IsCS bit,
				PlanBill int,
				QualityType tinyint,
				IsFreeze bit,
				OccupyType tinyint,
				[Version] int,
			)
		end
		else
		begin
			truncate table #tempLocationLotDet_018
		end

		insert into #tempBuffInv_018(UUID, HuId, Location, [Version])
		select bi.UUID, sr.HuId, bi.Loc, bi.[Version] 
		from @ShipResultTable as sr 
		left join WMS_BuffInv as bi on sr.HuId = bi.HuId 
		where bi.UUID is null or bi.Qty > 0

		insert into #tempLocation_018(Location, Suffix) 
		select distinct l.Code, l.PartSuffix from #tempBuffInv_018 as bi inner join MD_Location as l on bi.Location = l.Code

		declare @RowId int
		declare @MaxRowId int
		declare @Location varchar(50)
		declare @Suffix varchar(50)
		declare @SelectInvStatement nvarchar(max)
		declare @Parameter nvarchar(max)

		select @RowId = MIN(RowId), @MaxRowId = MAX(RowId) from #tempLocation_018
		while (@RowId <= @MaxRowId)
		begin
			select @Location = Location, @Suffix = Suffix from #tempLocation_018 where RowId = @RowId

			set @SelectInvStatement = 'insert into #tempLocationLotDet_018(LocationLotDetId, Location, HuId, IsCS, PlanBill, QualityType, IsFreeze, OccupyType, [Version]) '
			set @SelectInvStatement = @SelectInvStatement + 'select lld.Id, lld.Location, bi.HuId, lld.IsCS, lld.PlanBill, lld.QualityType, lld.IsFreeze, lld.OccupyType, lld.[Version] '
			set @SelectInvStatement = @SelectInvStatement + 'from #tempBuffInv_018 as bi '
			set @SelectInvStatement = @SelectInvStatement + 'left join INV_LocationLotDet_' + @Suffix + ' as lld on lld.HuId = bi.HuId '
			set @SelectInvStatement = @SelectInvStatement + 'where bi.Location = @Location_1 and ((lld.Location = @Location_1 and lld.Qty > 0) or lld.Id is null)'
			set @Parameter = N'@Location_1 varchar(50) '
	
			exec sp_executesql @SelectInvStatement, @Parameter, @Location_1=@Location

			set @RowId = @RowId + 1
		end
	end try
	begin catch
		set @ErrorMsg = N'获取条码库存发生异常：' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	drop table #tempLocation_018
END
GO