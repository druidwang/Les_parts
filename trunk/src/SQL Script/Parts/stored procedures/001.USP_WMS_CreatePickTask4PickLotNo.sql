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
		PickQty decimal(18, 8),
		PickedQty decimal(18, 8),
		ThisPickQty decimal(18, 8),
		ThisPickFullQty decimal(18, 8),  --����Ҫ�����ļ����������װ��
		ThisPickOddQty decimal(18, 8),  --����Ҫ�����ļ��������ͷ����
		ThisPickedQty decimal(18, 8),
		[Priority] tinyint,
		LocFrom varchar(50),
		Dock varchar(50),
		IsShipScanHu bit,
		IsActive bit,
	)

	create table #tempGroupedShipPlan_001
	(
		RowId int identity(1, 1),
		LocFrom varchar(50),
		Item varchar(50),
		Uom varchar(5),
		UC decimal(18, 8),
		UnitQty decimal(18, 8),
		[Priority] tinyint,
		TargetPickQty decimal(18, 8),
		ThisPickQty decimal(18, 8),
	)

	create table #tempAvailableFullInv_002
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
		Qty decimal(18, 8)
	)

	create table #tempAvailableOddInv_002
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
		Qty decimal(18, 8)
	)

	CREATE TABLE WMS_PickTask_001
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
		NeedRepack bit
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

	if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempOccupyBuffInv_004%') 
	begin
		create table #tempOccupyBuffInv_004
		(
			Id int primary key,
			PickedQty decimal(18, 8),
		)
	end

	if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempOccupyBuffInv_005%') 
	begin
		create table #tempOccupyBuffInv_005
		(
			Id int primary key,
			PickedQty decimal(18, 8),
		)
	end

	begin try
		begin try
			--��ȡ���˼ƻ�
			insert into #tempShipPlan_001(Id, OrderNo, OrderSeq, OrderDetId, StartTime, WindowTime, 
									Item, ItemDesc, RefItemCode, Uom, BaseUom, UnitQty, UC, UCDesc,
									OrderQty, PickQty, PickedQty, ThisPickQty, ThisPickedQty, 
									[Priority], LocFrom, Dock, IsShipScanHu, IsActive)
			select sp.Id, sp.OrderNo, sp.OrderSeq, sp.OrderDetId, sp.StartTime, sp.WindowTime, 
			sp.Item, sp.ItemDesc, sp.RefItemCode, sp.Uom, sp.BaseUom, sp.UnitQty, sp.UC, sp.UCDesc,
			sp.OrderQty, sp.PickQty, sp.PickedQty, tmp.PickQty, 0,
			sp.[Priority], sp.LocFrom, sp.Dock, sp.IsShipScanHu, sp.IsActive
			from @CreatePickTaskTable as tmp 
			inner join WMS_ShipPlan as sp on tmp.Id = sp.Id

			--��鷢�˼ƻ��Ƿ�ر�
			insert into #tempMsg_001(Lvl, Msg)
			select 2, N'��������'+ convert(varchar, Id) + N'�Ѿ��رա�'
			from #tempShipPlan_001 where IsActive = 0

			--��鴴���ļ���������Ƿ񳬹��˼ƻ���
			insert into #tempMsg_001(Lvl, Msg)
			select 2, N'��������'+ convert(varchar, Id) + N'�ļ�����Ѿ������˶�������'
			from #tempShipPlan_001 where IsActive = 1
			and PickQty + ThisPickQty > OrderQty

			--��ȡ�Ƿ������뷢��/���
			select @IsPickHu = IsShipScanHu
			from #tempShipPlan_001 group by IsShipScanHu

			if (@@ROWCOUNT > 1) 
			begin
				insert into #tempMsg_001(Lvl, Msg) values(2, N'����������Ͱ����������ܺϲ������������')
			end

			if not exists(select top 1 1 from #tempMsg_001)
			begin
				--ռ�÷����������Ŀ��
				if (@IsPickHu = 0)
				begin  --�����������
					exec USP_WMS_OcuppyBuffInv4PickQty @CreatePickTaskTable, @CreateUserId, @CreateUserNm
					update sp set ThisPickQty = ThisPickQty - bi.PickedQty from #tempShipPlan_001 as sp inner join #tempOccupyBuffInv_003 as bi on sp.Id = bi.Id
				end
				else
				begin
					declare @CreatePickTaskTable4PickLotNo CreatePickTaskTableType
					declare @CreatePickTaskTable4PickHu CreatePickTaskTableType

					insert into @CreatePickTaskTable4PickLotNo(Id, PickQty) 
					select * from #tempShipPlan_001 as sp inner join MD_Location as l on sp.LocFrom = l.Code
					where l.PickBy = 0

					insert into @CreatePickTaskTable4PickHu(Id, PickQty) 
					select * from #tempShipPlan_001 as sp inner join MD_Location as l on sp.LocFrom = l.Code
					where l.PickBy = 1

					if exists(select top 1 1 from @CreatePickTaskTable4PickLotNo)
					begin
						exec USP_WMS_OcuppyBuffInv4PickLotNo @CreatePickTaskTable4PickLotNo, @CreateUserId, @CreateUserNm
						update sp set ThisPickQty = ThisPickQty - bi.PickedQty from #tempShipPlan_001 as sp inner join #tempOccupyBuffInv_004 as bi on sp.Id = bi.Id
					end

					if exists(select top 1 1 from @CreatePickTaskTable4PickHu)
					begin
						exec USP_WMS_OcuppyBuffInv4PicHu @CreatePickTaskTable4PickHu, @CreateUserId, @CreateUserNm
						update sp set ThisPickQty = ThisPickQty - bi.PickedQty from #tempShipPlan_001 as sp inner join #tempOccupyBuffInv_005 as bi on sp.Id = bi.Id
					end
				end

				--���㰴���ż���������ͷ�����Ҫ����
				if (@IsPickHu = 1)
				begin
					update #tempShipPlan_001 set ThisPickFullQty = ROUND(ThisPickQty / UC, 0, 1) * UC, ThisPickFullQty = ThisPickQty % UC where ThisPickQty > 0
				end

				--��ȡ���ÿ��
				declare @PickTargetTable PickTargetTableType
				if (@IsPickHu = 0)
				begin
					insert into @PickTargetTable(Location, Item) select distinct LocFrom, Item from #tempShipPlan_001
				end
				else
				begin
					insert into @PickTargetTable(Location, Item, Uom, UC) select distinct LocFrom, Item, Uom, UC from #tempShipPlan_001
				end
				exec USP_WMS_GetAvailableInv4Pick @PickTargetTable, @IsPickHu


				select * from #tempAvailableInv_002 where IsOdd = 1

				declare @RowId int
				declare @MaxRowId int
				declare @Location varchar(50)
				declare @PickBy tinyint
				declare @Item varchar(50)
				declare @Uom varchar(5)
				declare @UC decimal(18, 8)
				declare @Bin varchar(50)
				declare @HuId varchar(50)
				declare @LotNo varchar(50)
				declare @IsOdd bit
				declare @Qty decimal(18, 8)
				declare @LastQty decimal(18, 8)
				select @RowId = MIN(RowId), @MaxRowId = MAX(RowId) from #tempAvailableInv_002
				while @RowId <= @MaxRowId
					set @LastQty = 0
					select @Location = Location, @PickBy = PickBy, @Item = Item, @Uom = Uom, @UC = UC, @Bin = Bin, @HuId = HuId, @LotNo = LotNo, @Qty = Qty, @IsOdd = IsOdd 
					from #tempAvailableInv_002 where RowId = @RowId

					if (@IsPickHu = 0)
					begin --���������
						update sp set ThisPickedQty = @LastQty / sp.UnitQty,
						@Qty = @Qty - @LastQty, @LastQty = CASE WHEN @Qty >= sp.ThisPickQty * sp.UnitQty THEN sp.ThisPickQty * sp.UnitQty ELSE @Qty END
						from #tempShipPlan_001 as sp
						where sp.Item = @Item and sp.LocFrom = @Location
						set @Qty = @Qty - @LastQty

						insert into WMS_PickTask_001([Priority], Item, ItemDesc, RefItemCode , Uom , BaseUom, UnitQty, UC, UCDesc, OrderQty, 
													Loc, StartTime, WinTime, IsPickHu, NeedRepack)
						select [Priority], Item, ItemDesc, RefItemCode , Uom , BaseUom, UnitQty, UC, UCDesc, ThisPickedQty 
						Loc, @DateTimeNow, case when StartTime >= @DateTimeNow then StartTime else @DateTimeNow end, 0, 0
						from #tempShipPlan_001 where ThisPickedQty > 0
						update #tempShipPlan_001 set ThisPickQty = ThisPickQty - ThisPickedQty, ThisPickedQty = 0 where ThisPickedQty > 0
					end
					else
					begin 
						if (@PickBy = 0)
						begin  --�����ż��
							if (@IsOdd = 0)
							begin
								update sp set ThisPickedQty = @LastQty / sp.UnitQty,
								@Qty = @Qty - @LastQty, @LastQty = CASE WHEN @Qty >= sp.ThisPickFullQty * sp.UnitQty THEN sp.ThisPickFullQty * sp.UnitQty ELSE @Qty END
								from #tempShipPlan_001 as sp
								where sp.Item = @Item and sp.LocFrom = @Location and sp.Uom = @Uom and sp.UC = @UC
								and sp.ThisPickFullQty > 0
								set @Qty = @Qty - @LastQty

								insert into WMS_PickTask_001([Priority], Item, ItemDesc, RefItemCode , Uom , BaseUom, UnitQty, UC, UCDesc, OrderQty, 
															Loc, Bin, LotNo, StartTime, WinTime, IsPickHu, NeedRepack)
								select [Priority], Item, ItemDesc, RefItemCode , Uom , BaseUom, UnitQty, UC, UCDesc, ThisPickedQty 
								Loc, @Bin, @LotNo, @DateTimeNow, case when StartTime >= @DateTimeNow then StartTime else @DateTimeNow end, 0, 0
								from #tempShipPlan_001 where ThisPickedQty > 0
								update #tempShipPlan_001 set ThisPickQty = ThisPickQty - ThisPickedQty, ThisPickFullQty = ThisPickFullQty - ThisPickedQty, ThisPickedQty = 0 where ThisPickedQty > 0

								if @Qty > 0
								begin
									update sp set ThisPickedQty = @LastQty / sp.UnitQty,
									@Qty = @Qty - @LastQty, @LastQty = CASE WHEN @Qty >= sp.ThisPickOddQty * sp.UnitQty THEN sp.ThisPickOddQty * sp.UnitQty ELSE @Qty END
									from #tempShipPlan_001 as sp
									where sp.Item = @Item and sp.LocFrom = @Location and sp.Uom = @Uom and sp.UC = @UC
									set @Qty = @Qty - @LastQty

									insert into WMS_PickTask_001([Priority], Item, ItemDesc, RefItemCode , Uom , BaseUom, UnitQty, UC, UCDesc, OrderQty, 
																Loc, Bin, LotNo, StartTime, WinTime, IsPickHu, NeedRepack)
									select [Priority], Item, ItemDesc, RefItemCode , Uom , BaseUom, UnitQty, UC, UCDesc, ThisPickedQty 
									Loc, @Bin, @LotNo, @DateTimeNow, case when StartTime >= @DateTimeNow then StartTime else @DateTimeNow end, 0, 0
									from #tempShipPlan_001 where ThisPickedQty > 0
									update #tempShipPlan_001 set ThisPickQty = ThisPickQty - ThisPickedQty, ThisPickFullQty = ThisPickFullQty - ThisPickedQty, ThisPickedQty = 0 where ThisPickedQty > 0
								end
							end
						end
						else
						begin
						end
						insert into WMS_PickTask_001([Priority], Item, ItemDesc, RefItemCode , Uom , BaseUom, UnitQty, UC, UCDesc, OrderQty, 
													Loc, Area, Bin, LotNo, HuId, StartTime, WinTime, IsPickHu)
						select * from #tempShipPlan_001
					end

					set @RowId = @RowId + 1 
				end
			end
		end try
		begin catch
			set @ErrorMsg = N'����׼�������쳣��' + Error_Message()
			RAISERROR(@ErrorMsg, 16, 1) 
		end catch

		begin try
			declare @trancount int
			set @trancount = @@trancount

			if @Trancount = 0
			begin
				begin tran
			end
		end try
		begin catch
			if @Trancount = 0
			begin
				rollback
			end 

			set @ErrorMsg = N'���ݸ��³����쳣��' + Error_Message()
			RAISERROR(@ErrorMsg, 16, 1) 
		end catch
	end try
	begin catch
		set @ErrorMsg = N'��������������쳣��' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	select Lvl, Msg from #tempMsg_001 order by Id

	drop table #tempMsg_001
END
GO