SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_OcuppyBuffInv4Pick')
BEGIN
	DROP PROCEDURE USP_WMS_OcuppyBuffInv4Pick
END
GO

CREATE PROCEDURE dbo.USP_WMS_OcuppyBuffInv4Pick
	@CreatePickTaskTable CreatePickTaskTableType readonly,
	@IsPickHu bit,
	@CreateUserId int,
	@CreateUserNm varchar(100)
AS
BEGIN
	set nocount on
	declare @DateTimeNow datetime
	declare @ErrorMsg nvarchar(MAX)

	set @DateTimeNow = GetDate()

	create table #tempPickTarget_003
	(
		Id int identity(1, 1),
		Loc varchar(50),
		Item varchar(50)
	)

	create table #tempShipPlan_003
	(
		RowId int identity(1, 1) primary key,
		Id int,
		[Priority] tinyint,
		StartTime DateTime,
		LocFrom varchar(50),
		Item varchar(50),
		Uom varchar(5),
		UC decimal(18, 8),
		UnitQty decimal(18, 8),
		LockQty decimal(18, 8),		--�ɷ���������
		PickQty decimal(18, 8),		--�����ļ����
		PickedQty decimal(18, 8),	--�Ѽ����
		ThisLockQty decimal(18, 8),  --���ζ���Ŀɷ�������
		ThisPickQty decimal(18, 8),  --����Ҫ�����ļ����
		ThisPickOddQty decimal(18, 8),  --����Ҫ�����ļ������������װ����ͷ
		ThisPickedQty decimal(18, 8),  --����ռ�û����������������μ������
		[Version] int
	)

	create table #tempBuffInv_003
	(
		RowId int identity(1, 1) primary key,
		Loc varchar(50),
		Item varchar(50),
		HuId varchar(50),
		Uom varchar(5),
		UC decimal(18, 8),
		Qty decimal(18, 8),
		UnitQty decimal(18, 8),
		OccupyShipPlanId int
	)

	begin try
		begin try
			--��ȡ�����λ�����
			insert into #tempPickTarget_003(Loc, Item) 
			select distinct sp.LocFrom, sp.Item from @CreatePickTaskTable as t 
			inner join WMS_ShipPlan as sp on t.Id = sp.Id

			--��ȡ�����ƻ�
			insert into #tempShipPlan_003(Id, [Priority], StartTime, LocFrom, Item, UOM, UC, UnitQty, 
			LockQty, PickQty, PickedQty, ThisLockQty, ThisPickQty, ThisPickOddQty, ThisPickedQty, [Version])
			select sp.Id, sp.[Priority], sp.StartTime, sp.LocFrom, sp.Item, sp.Uom, sp.UC, sp.UnitQty, 
			sp.LockQty, sp.PickQty, sp.PickedQty, 0, t.PickQty, t.PickQty % sp.UC, 0, sp.[Version] 
			from @CreatePickTaskTable as t
			inner join WMS_ShipPlan as sp on t.Id = sp.Id
			order by sp.LocFrom, sp.Item, sp.[Priority], sp.StartTime, sp.Id

			if (@IsPickHu = 0)
			begin  --����������ۼ����������
				--����������������ɺ�����shipPlan��PickedQty���Ѽ��������LockQty������������
				--PickedQty���Ѽ��������LockQty������������Ӧ����һ�µģ�����ֻ����PickedQty

				--��ȡ���õ�Buff����浥λ��
				--���ܹ����Ѿ��ƶ������ڵ�����
				insert into #tempBuffInv_003(Loc, Item, Qty)
				select bi.Loc, bi.Item, bi.Qty
				from #tempPickTarget_003 as pt
				inner join WMS_BuffInv as bi on pt.Item = bi.Item and pt.Loc = bi.Loc
				where bi.HuId is null and bi.Qty > 0 and bi.IOType = 1  --Ŀǰֻ���Ƿ������������������ջ���������Խ�������
				group by bi.Loc, bi.Item

				--�ۼ������˼ƻ�ռ�õ���������浥λ��
				--���õ����ۼ�ֱ���÷��˼ƻ�ռ�õ���(��WMS_PickOccupy)
				update bi set Qty = bi.Qty - sp.PickedQty
				from #tempBuffInv_003 as bi
				inner join (select sp.LocFrom, sp.Item, SUM((sp.PickedQty - sp.ShipQty) * sp.UnitQty) as PickedQty --ת��Ϊ��浥λ
							from WMS_ShipPlan as sp 
							inner join #tempPickTarget_003 as pt on sp.LocFrom = pt.Loc and sp.Item = pt.Item
							where sp.IsActive = 1 and sp.IsShipScanHu = 0 and sp.PickedQty > sp.ShipQty
							group by sp.LocFrom, sp.Item) as sp on bi.Loc = sp.LocFrom and bi.Item = sp.Item

				--���˼ƻ�ռ�û�������棬���շ������ȼ�������ʱ��˳��ռ��
				declare @RowId int
				declare @MaxRowId int
				declare @Loc varchar(50)
				declare @Item varchar(50)
				declare @OrgQty decimal(18, 8)
				declare @Qty decimal(18, 8)
				declare @LastQty decimal(18, 8)
				select @RowId = MIN(RowId), @MaxRowId = MAX(RowId) from #tempBuffInv_003
				while (@RowId <= @MaxRowId)
				begin
					select @Loc = Loc, @Item = Item, @OrgQty = Qty, @Qty = Qty, @LastQty = 0 from #tempBuffInv_003 where RowId = @RowId

					if (@Qty > 0)
					begin
						update sp set ThisPickedQty = CASE WHEN @Qty >= sp.ThisPickQty * sp.UnitQty THEN sp.ThisPickQty ELSE @Qty / sp.UnitQty END,
						@Qty = @Qty - @LastQty, @LastQty = ThisPickedQty * sp.UnitQty
						from #tempShipPlan_003 as sp
						where sp.Item = @Item and sp.LocFrom = @Loc
					end
				
					set @RowId = @RowId + 1
				end
			end
			else
			begin  --���������ۼ����������
				--���������������ɺ������PickedQty
				--Ҫ�Ȼ������Ŀ���ShipPlan��UOM��UC��ȫƥ�����ͨ�����������ֹ�����ShipPlan���Ż�����shipPlan��LockQty������������

				--��ȡ���õ�Buff����浥λ��
				--���ܹ����Ѿ��ƶ������ڵ�����
				insert into #tempBuffInv_003(Loc, Item, HuId, Uom, UC, Qty, UnitQty)
				select bi.Loc, bi.Item, bi.HuId, hu.Uom, hu.UC, bi.Qty, hu.UnitQty
				from #tempPickTarget_003 as pt
				inner join WMS_BuffInv as bi on pt.Item = bi.Item and pt.Loc = bi.Loc
				inner join INV_Hu as hu on bi.HuId = hu.HuId
				left join WMS_BuffOccupy as bo on bi.Id = bo.BuffInvId
				where bi.Qty > 0 and bi.IOType = 1  --Ŀǰֻ���Ƿ������������������ջ���������Խ�������
				and bo.Id is null

				select sp.LocFrom, sp.Item, sp.Uom, sp.UC, SUM((sp.LockQty - sp.ShipQty) * sp.UnitQty - ISNULL(occ.Qty, 0)) as RemainLockQty, SUM((sp.PickedQty - sp.ShipQty) * sp.UnitQty - ISNULL(occ.Qty, 0)) as RemainPickedQty --ת��Ϊ��浥λ
				from WMS_ShipPlan as sp
				inner join #tempPickTarget_003 as pt on sp.LocFrom = pt.Loc and sp.Item = pt.Item
				left join (select bo.ShipPlanId, SUM(bi.Qty) as Qty from #tempPickTarget_003 as pt
							inner join WMS_BuffInv as bi on pt.Item = bi.Item and pt.Loc = bi.Loc
							inner join WMS_BuffOccupy as bo on bi.Id = bo.BuffInvId
							where bi.Qty > 0 and bi.IOType = 1) as occ on sp.Id = occ.ShipPlanId
				where sp.IsActive = 1 and sp.IsShipScanHu = 1 and sp.PickedQty > sp.ShipQty



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
			
			if (@IsPickHu = 0)
			begin  --����������ۼ����������
				--��ȡ��Ҫ���µ�����
				declare @UpdateRowCount int
				select @UpdateRowCount = count(1) from #tempShipPlan_003 where ThisPickedQty > 0
			
				--���´�����������������Ѿ����������
				update sp set LockQty = sp.LockQty + tmp.ThisPickedQty, PickedQty = sp.PickedQty + tmp.ThisPickedQty, PickQty = sp.PickQty + tmp.ThisPickedQty, 
				LastModifyDate = @DateTimeNow, LastModifyUser = @CreateUserId, LastModifyUserNm = @CreateUserNm, [Version] = sp.[Version] + 1
				from  #tempShipPlan_003 as tmp
				inner join WMS_ShipPlan as sp on tmp.Id = sp.Id and tmp.[Version] = sp.[Version]
				where tmp.ThisPickedQty > 0

				if (@@ROWCOUNT <> @UpdateRowCount)
				begin
					RAISERROR(N'�����Ѿ������£������ԡ�', 16, 1)
				end
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

			set @ErrorMsg = N'���ݸ��³����쳣��' + Error_Message()
			RAISERROR(@ErrorMsg, 16, 1) 
		end catch
	end try
	begin catch
		set @ErrorMsg = N'ռ�û�������淢���쳣��' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	select Id, ThisPickedQty from #tempShipPlan_003 where ThisPickedQty > 0

	drop table #tempPickTarget_003
	drop table #tempShipPlan_003
	drop table #tempBuffInv_003
END
GO