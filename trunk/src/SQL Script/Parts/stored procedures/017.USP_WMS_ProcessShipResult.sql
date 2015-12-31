SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_ProcessShipResult')
BEGIN
	DROP PROCEDURE USP_WMS_ProcessShipResult
END
GO

CREATE PROCEDURE dbo.USP_WMS_ProcessShipResult
	@TransportOrderNo varchar(50),
	@ShipResultTable ShipResultTableType readonly,
	@CreateUserId int,
	@CreateUserNm varchar(100),
	@EffDate datetime
AS
BEGIN
	set nocount on
	declare @DateTimeNow datetime
	declare @ErrorMsg nvarchar(MAX)
	
	set @DateTimeNow = GetDate()

	if @EffDate is null
	begin
		set @EffDate = @DateTimeNow
	end

	create table #tempMsg_017 
	(
		Id int identity(1, 1) primary key,
		Lvl tinyint,
		Msg varchar(2000)
	)

	create table #tempShipResult_017
	(
		HuId varchar(50) primary key,
		LotNo varchar(50),
		Item varchar(50),
		Uom varchar(5),
		UnitQty decimal(18, 8),
		UC decimal(18, 8),
		Qty  decimal(18, 8),
	)

	create table #tempBuffInv_018
	(
		UUID varchar(50) primary key,
		HuId varchar(50),
		Location varchar(50),
		ShipPlanId int,
		[Version] int
	)

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

	create table #tempShipPlan_017
	(
		ShipPlanId int Primary Key,
		OrderQty decimal(18, 8),
		ShipQty decimal(18, 8),
		ThisShipQty decimal(18, 8),
		[Version] int,
	)

	begin try
		begin try
			if not exists(select top 1 1 from @ShipResultTable)
			begin
				insert into #tempMsg_017(Lvl, Msg) values(2, N'发运条码不能为空。')
			end

			if not exists(select top 1 1 from #tempMsg_017)
			begin
				insert into #tempShipResult_017(HuId, LotNo, Item, Uom, UnitQty, UC, Qty)
				select srt.HuId, hu.LotNo, hu.Item, hu.Uom, hu.UnitQty, hu.UC, hu.Qty
				from INV_Hu as hu right join @ShipResultTable as srt on hu.HuId = srt.HuId

				insert into #tempMsg_017(Lvl, Msg)
				select 2, N'发运条码['+ HuId + N']不存在。' from #tempShipResult_017 where Item is null

				if not exists(select top 1 1 from #tempMsg_017)
				begin
					insert into #tempMsg_017(Lvl, Msg)
					select 2, N'发运条码['+ HuId + N']大于1条。' 
					from @ShipResultTable group by HuId having COUNT(1) > 1

					exec USP_WMS_GetHuInventory4Ship @ShipResultTable




				end
			end
		end try
		begin catch
			set @ErrorMsg = N'数据准备出现异常：' + Error_Message()
			RAISERROR(@ErrorMsg, 16, 1) 
		end catch

		if not exists(select top 1 1 from #tempMsg_017)
		begin
			begin try
				declare @Trancount int
				set @Trancount = @@trancount

				if @Trancount = 0
				begin
					begin tran
				end

				declare @UpdateCount int

			

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
		set @ErrorMsg = N'处理翻包结果发生异常：' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	select Lvl, Msg from #tempMsg_017

	drop table #tempMsg_017
END
GO