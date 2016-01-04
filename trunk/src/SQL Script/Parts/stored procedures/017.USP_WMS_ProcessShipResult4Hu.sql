SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_ProcessShipResult4Hu')
BEGIN
	DROP PROCEDURE USP_WMS_ProcessShipResult4Hu
END
GO

CREATE PROCEDURE dbo.USP_WMS_ProcessShipResult4Hu
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

	create table #tempBuffInv_018
	(
		UUID varchar(50) primary key,
		HuId varchar(50),
		LotNo varchar(50),
		Item varchar(50),
		Uom varchar(5),
		UnitQty decimal(18, 8),
		UC decimal(18, 8),
		Qty  decimal(18, 8),
		Location varchar(50),
		IsLock bit,
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
		OrderNo varchar(50),
		OrderDetId int,
		OrderType tinyint,
		Item varchar(50),
		Uom varchar(5),
		UnitQty decimal(18, 8),
		UC decimal(18, 8),
		LockQty decimal(18, 8),
		ShipQty decimal(18, 8),
		ThisShipQty decimal(18, 8),
		IsActive bit,
		[Version] int,
	)

	create table #tempOrderDet_017
	(
		OrderNo varchar(50),
		OrderDetId int Primary Key,
		OrderSeq int,
		OrderType tinyint,
		IsShipExceed bit,
		[Status] tinyint,
		Item varchar(50),
		OrderQty decimal(18, 8),
		ShipQty decimal(18, 8),
		ThisShipQty decimal(18, 8),
		MVersion int,
		DVersion int,
	)

	create table #tempTransportOrder_017
	(
		TransportOrderNo varchar(50),
		[Status] tinyint
	)

	create table #tempTransportRoute_017
	(
		TransportOrderNo varchar(50),
		Seq int,
		ShipAddr varchar(50),
	)

	create table #tempIpMstr_017
	(
		IpNo varchar(50),
		Type tinyint,
		OrderType tinyint,
		OrderSubType tinyint,
		QualityType tinyint,
		Status tinyint,
		DepartTime datetime,
		ArriveTime datetime,
		PartyFrom varchar(50),
		PartyFromNm varchar(100),
		PartyTo varchar(50),
		PartyToNm varchar(100),
		ShipFrom varchar(50),
		ShipFromAddr varchar(256),
		ShipFromTel varchar(50),
		ShipFromCell varchar(50),
		ShipFromFax varchar(50),
		ShipFromContact varchar(50),
		ShipTo varchar(50),
		ShipToAddr varchar(256),
		ShipToTel varchar(50),
		ShipToCell varchar(50),
		ShipToFax varchar(50),
		ShipToContact varchar(50),
		Dock varchar(100),
		IsAutoReceive bit,
		IsShipScanHu bit,
		IsPrintAsn bit,
		IsAsnPrinted bit,
		IsPrintRec bit,
		IsRecExceed bit,
		IsRecFulfillUC bit,
		IsRecFifo bit,
		IsAsnUniqueRec bit,
		IsCheckPartyFromAuth bit,
		IsCheckPartyToAuth bit,
		RecGapTo tinyint,
		AsnTemplate varchar(100),
		RecTemplate varchar(100),
		HuTemplate varchar(100),
		EffDate datetime,
		CreateUser int,
		CreateUserNm varchar(100),
		CreateDate datetime,
		LastModifyUser int,
		LastModifyUserNm varchar(100),
		LastModifyDate datetime,
		CloseDate datetime,
		CloseUser int,
		CloseUserNm varchar(100),
		CloseReason varchar(256),
		Version int,
		WMSNo varchar(50),
		CreateHuOpt tinyint,
		IsRecScanHu bit,
		Flow varchar(50),
	)

	create table #tempIpDet_017
	(
		
	)

	create table #tempIpLocationDet_017
	(
		
	)


	begin try
		begin try
			if not exists(select top 1 1 from @ShipResultTable)
			begin
				insert into #tempMsg_017(Lvl, Msg) values(2, N'发运条码不能为空。')
			end

			if not exists(select top 1 1 from #tempMsg_017)
			begin
				exec USP_WMS_GetHuInventory4Ship @ShipResultTable

				insert into #tempMsg_017(Lvl, Msg)
				select 2, N'发运条码['+ HuId + N']大于1条。' 
				from @ShipResultTable group by HuId having COUNT(1) > 1

				insert into #tempMsg_017(Lvl, Msg)
				select 2, N'发运条码['+ HuId + N']不存在。' from #tempBuffInv_018 where Item is null
				
				insert into #tempMsg_017(Lvl, Msg)
				select distinct 2, N'条码['+ HuId + N']不在发货缓冲区。'
				from #tempBuffInv_018 where Item is not null and Location is null

				insert into #tempMsg_017(Lvl, Msg)
				select 2, N'条码['+ HuId + N']在库位['+ Location + N']中不存在。'
				from #tempLocationLotDet_018 where Location is not null and Id is null

				insert into #tempMsg_017(Lvl, Msg)
				select 2, N'条码['+ HuId + N']已经被占用。'
				from #tempLocationLotDet_018
				where OccupyType <> 0

				insert into #tempMsg_017(Lvl, Msg)
				select 2, N'条码['+ HuId + N']的质量状态不是合格。'
				from #tempLocationLotDet_018
				where QualityType <> 0

				insert into #tempMsg_017(Lvl, Msg)
				select 2, N'条码['+ HuId + N']已经被冻结'
				from #tempLocationLotDet_018
				where IsFreeze = 1

				insert into #tempMsg_017(Lvl, Msg)
				select distinct 2, N'条码['+ HuId + N']没有和发运计划关联。'
				from #tempBuffInv_018 where ShipPlanId is null

				select distinct 2, N'条码['+ HuId + N']和多个发运计划关联。'
				from #tempBuffInv_018 where ShipPlanId is not null
				group by HuId having count(1) > 1
					
				if not exists(select top 1 1 from #tempMsg_017)
				begin
					insert into #tempShipPlan_017(ShipPlanId, OrderNo, OrderDetId, OrderType, Item, Uom, UnitQty, UC, LockQty, ShipQty, ThisShipQty, IsActive, [Version])
					select distinct bi.ShipPlanId, sp.OrderNo, sp.OrderDetId, sp.OrderType, sp.Item, sp.Uom, sp.UnitQty, sp.UC, sp.LockQty, sp.ShipQty, 0, sp.IsActive, sp.[Version]  
					from WMS_ShipPlan as sp 
					right join #tempBuffInv_018 as bi on sp.Id = bi.ShipPlanId
						
					update sp set ThisShipQty = bi.Qty
					from #tempShipPlan_017 as sp 
					inner join (select ShipPlanId, SUM(Qty) as Qty from #tempBuffInv_018 group by ShipPlanId) as bi on sp.ShipPlanId = bi.ShipPlanId
						
					select 2, N'发运计划['+ ShipPlanId + N']不存在。'
					from #tempShipPlan_017 where OrderNo is null

					select 2, N'发运计划['+ ShipPlanId + N']已经关闭。'
					from #tempShipPlan_017 where IsActive = 0

					select 2, N'发运计划['+ ShipPlanId + N']的发货数超过了锁定的库存数。'
					from #tempShipPlan_017 where LockQty < ShipQty + ThisShipQty

					if not exists(select top 1 1 from #tempMsg_017)
					begin
						if exists (select top 1 1 from #tempShipPlan_017 where OrderType = 2)
						begin
							insert into #tempOrderDet_017(OrderNo, OrderDetId, OrderSeq, OrderType, IsShipExceed, [Status], Item, OrderQty, ShipQty, MVersion, DVersion)
							select sp.OrderNo, sp.OrderDetId, det.Seq, 2, mstr.IsShipExceed, mstr.[Status], det.Item, det.OrderQty, det.ShipQty, mstr.[Version], det.[Version]
							from #tempShipPlan_017 as sp
							left join ORD_OrderDet_2 as det on sp.OrderDetId = det.Id
							left join ORD_OrderMstr_2 as mstr on sp.OrderNo = mstr.OrderNo
						end

						if exists (select top 1 1 from #tempShipPlan_017 where OrderType = 3)
						begin
							insert into #tempOrderDet_017(OrderNo, OrderDetId, OrderSeq, OrderType, IsShipExceed, [Status], Item, OrderQty, ShipQty, ThisShipQty, MVersion, DVersion)
							select sp.OrderNo, sp.OrderDetId, det.Seq, 3, mstr.IsShipExceed, mstr.[Status], det.Item, det.OrderQty, det.ShipQty, 0, mstr.[Version], det.[Version]
							from #tempShipPlan_017 as sp
							left join ORD_OrderDet_3 as det on sp.OrderDetId = det.Id
							left join ORD_OrderMstr_3 as mstr on sp.OrderNo = mstr.OrderNo
						end

						update #tempOrderDet_017 set ThisShipQty = sp.ThisShipQty
						from #tempOrderDet_017 as det 
						inner join (select OrderDetId, SUM(ThisShipQty) as ThisShipQty from #tempShipPlan_017 group by OrderDetId) as sp on det.OrderDetId = sp.OrderDetId
							 
						select 2, N'发运计划对应发货单号['+ OrderNo + N']不存在。'
						from #tempOrderDet_017 where OrderQty is null

						select 2, N'发运计划对应发货单号['+ OrderNo + N']为创建状态，不能发货。'
						from #tempOrderDet_017 where OrderQty is not null and [Status] = 0

						select 2, N'发运计划对应发货单号['+ OrderNo + N']已经完成，不能发货。'
						from #tempOrderDet_017 where OrderQty is not null and [Status] = 3

						select 2, N'发运计划对应发货单号['+ OrderNo + N']已经关闭，不能发货。'
						from #tempOrderDet_017 where OrderQty is not null and [Status] = 4

						select 2, N'发运计划对应发货单号['+ OrderNo + N']已经取消，不能发货。'
						from #tempOrderDet_017 where OrderQty is not null and [Status] = 5

						select 2, N'发货单号['+ OrderNo + N']行号['+ CONVERT(varchar, OrderSeq) + N']物料代码['+ Item + N']的发货数已经大于等于订单数。'
						from #tempOrderDet_017 where OrderQty is not null and [Status] in (1, 2) and OrderQty <= ShipQty
							
						select 2, N'发货单号['+ OrderNo + N']行号['+ CONVERT(varchar, OrderSeq) + N']物料代码['+ Item + N']的发货数大于等于订单数。'
						from #tempOrderDet_017 where OrderQty is not null and [Status] in (1, 2) and OrderQty > ShipQty and IsShipExceed = 0 and OrderQty < ShipQty + ThisShipQty
					end
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

			



	create table #tempBuffInv_018
	(
		UUID varchar(50) primary key,
		HuId varchar(50),
		LotNo varchar(50),
		Item varchar(50),
		Uom varchar(5),
		UnitQty decimal(18, 8),
		UC decimal(18, 8),
		Qty  decimal(18, 8),
		Location varchar(50),
		IsLock bit,
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
		OrderNo varchar(50),
		OrderDetId int,
		OrderType tinyint,
		Item varchar(50),
		Uom varchar(5),
		UnitQty decimal(18, 8),
		UC decimal(18, 8),
		LockQty decimal(18, 8),
		ShipQty decimal(18, 8),
		ThisShipQty decimal(18, 8),
		IsActive bit,
		[Version] int,
	)

	create table #tempOrderDet_017
	(
		OrderNo varchar(50),
		OrderDetId int Primary Key,
		OrderSeq int,
		OrderType tinyint,
		IsShipExceed bit,
		[Status] tinyint,
		Item varchar(50),
		OrderQty decimal(18, 8),
		ShipQty decimal(18, 8),
		ThisShipQty decimal(18, 8),
		MVersion int,
		DVersion int,
	)





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