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
	@CreateUserId int,
	@CreateUserNm varchar(100)
)
AS
BEGIN
	set nocount on
	declare @DateTimeNow datetime
	declare @ErrorMsg nvarchar(MAX)
	
	create table #tempMsg_001 
	(
		Id int identity(1, 1) primary key,
		Lvl tinyint,
		Msg varchar(2000)
	)

	create table #tempShipPlan_001
	(
		ShipPlanId int primary key,
		OrderQty decimal(18, 8),
		PickQty decimal(18, 8),
		ThisPickQty decimal(18, 8),
		IsShipScanHu bit,
		PickBy tinyint,
		IsActive bit,
	)

	begin try

		insert into #tempShipPlan_001(ShipPlanId, OrderQty, PickQty, ThisPickQty, IsShipScanHu, PickBy, IsActive)
		select sp.Id, sp.OrderQty, sp.PickQty, tmp.PickQty, sp.IsShipScanHu, l.PickBy, sp.IsActive
		from @CreatePickTaskTable as tmp 
		inner join WMS_ShipPlan as sp on tmp.Id = sp.Id
		inner join MD_Location as l on sp.LocFrom = l.Code

		--��鷢�˼ƻ��Ƿ�ر�
		insert into #tempMsg_001(Lvl, Msg)
		select 2, N'��������'+ convert(varchar, ShipPlanId) + N'�Ѿ��رա�'
		from #tempShipPlan_001 where IsActive = 0

		--��鴴���ļ���������Ƿ񳬹��˼ƻ���
		insert into #tempMsg_001(Lvl, Msg)
		select 2, N'��������'+ convert(varchar, ShipPlanId) + N'�ļ�����Ѿ������˶�������'
		from #tempShipPlan_001 where IsActive = 1
		and PickQty + ThisPickQty > OrderQty

		if exists(select top 1 1 from #tempMsg_001)
		begin
			declare @CreatePickTask4PickQtyTable CreatePickTaskTableType
			declare @CreatePickTask4PickLotNoTable CreatePickTaskTableType
			declare @CreatePickTask4PickHuTable CreatePickTaskTableType

			insert into @CreatePickTask4PickQtyTable(Id, PickQty) select ShipPlanId, ThisPickQty from #tempShipPlan_001 where IsShipScanHu = 0
			insert into @CreatePickTask4PickLotNoTable(Id, PickQty) select ShipPlanId, ThisPickQty from #tempShipPlan_001 where IsShipScanHu = 1 and PickBy = 0
			insert into @CreatePickTask4PickHuTable(Id, PickQty) select ShipPlanId, ThisPickQty from #tempShipPlan_001 where IsShipScanHu = 1 and PickBy = 1

			if exists(select top 1 1 from @CreatePickTask4PickQtyTable)
			begin
				exec USP_WMS_CreatePickTask4PickQty @CreatePickTask4PickQtyTable, @CreateUserId,@CreateUserNm 
			end

			if exists(select top 1 1 from @CreatePickTask4PickLotNoTable)
			begin
				exec USP_WMS_CreatePickTask4PickLotNo @CreatePickTask4PickLotNoTable, @CreateUserId,@CreateUserNm 
			end

			if exists(select top 1 1 from @CreatePickTask4PickHuTable)
			begin
				exec USP_WMS_CreatePickTask4PickHu @CreatePickTask4PickHuTable, @CreateUserId,@CreateUserNm 
			end
		end
	end try
	begin catch
		set @ErrorMsg = N'��������������쳣��' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	select Lvl, Msg from #tempMsg_001 order by Id

	drop table #tempMsg_001
END
GO