SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_GetAvailableInv4PickQty')
BEGIN
	DROP PROCEDURE USP_WMS_GetAvailableInv4PickQty
END
GO

CREATE PROCEDURE dbo.USP_WMS_GetAvailableInv4PickQty
	@PickTargetTable PickTargetTableType readonly
AS
BEGIN
	set nocount on
	declare @ErrorMsg nvarchar(MAX)

	create table #tempPickTarget_008
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Item varchar(50)
	)

	create table #tempLocation_008
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Suffix varchar(50)
	)

	begin try
		if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempAvailableInv_008%') 
		begin
			set @ErrorMsg = 'û�ж��巵�����ݵĲ�����'
			RAISERROR(@ErrorMsg, 16, 1) 

			--���벻��ִ�е�����
			create table #tempAvailableInv_008
			(
				RowId int identity(1, 1),
				Location varchar(50),
				Item varchar(50),
				Qty decimal(18, 8)
			)
		end
		else
		begin
			truncate table #tempAvailableInv_008
		end

		insert into #tempPickTarget_008(Location, Item) select distinct Location, Item from @PickTargetTable
		insert into #tempLocation_008(Location, Suffix) 
		select distinct l.Code, l.PartSuffix
		from #tempPickTarget_008 as tmp inner join MD_Location as l on tmp.Location = l.Code

		declare @LocationRowId int
		declare @MaxLocationRowId int
		declare @Location varchar(50)
		declare @LocSuffix varchar(50)
		declare @SelectInvStatement nvarchar(max)

		select @LocationRowId = MIN(RowId), @MaxLocationRowId = MAX(RowId) from #tempLocation_008

		while (@LocationRowId <= @MaxLocationRowId)
		begin
			select @Location = Location, @LocSuffix = Suffix
			from #tempLocation_008 where RowId = @LocationRowId
			set @SelectInvStatement = ''

			set @SelectInvStatement = 'insert into #tempAvailableInv_008(Location, Item, Qty) '
			set @SelectInvStatement = @SelectInvStatement + 'select sp.Location, sp.Item, SUM(ISNULL(llt.Qty, 0)) as InvQty '
			set @SelectInvStatement = @SelectInvStatement + 'from #tempPickTarget_008 as sp '
			set @SelectInvStatement = @SelectInvStatement + 'inner join INV_LocationLotDet_' + @LocSuffix + ' as llt on sp.Location = llt.Location and sp.Item = llt.Item '
			set @SelectInvStatement = @SelectInvStatement + 'where sp.Location = ''' + @Location + ''' and llt.OccupyRefNo is null and llt.Qty <> 0 and llt.HuId is null and llt.QualityType = 0'
			set @SelectInvStatement = @SelectInvStatement + 'group by sp.Location, sp.Item '
			set @SelectInvStatement = @SelectInvStatement + 'having SUM(llt.Qty, 0) > 0'

			exec sp_executesql @SelectInvStatement

			set @LocationRowId = @LocationRowId + 1
		end

		--�ۼ���ռ�õĿ��
		update inv set Qty = inv.Qty - oc.OccupyQty
		from #tempAvailableInv_008 as inv inner join
		(select ai.Location, ai.Item, SUM(OccupyQty) as OccupyQty
		from (select sp.Location, sp.Item, SUM(bi.Qty) as OccupyQty 
				from #tempPickTarget_008 as sp
				inner join WMS_BuffInv as bi on bi.Loc = sp.Location and bi.Item = sp.Item
				where bi.Qty > 0 and bi.HuId is null and bi.IOType = 1
				group by sp.Location, sp.Item
				union all 
				select pt.Loc, pt.Item, SUM((pt.OrderQty - pt.PickQty) * pt.UnitQty) as OccupyQty
				from #tempPickTarget_008 as sp 
				inner join WMS_PickTask as pt on sp.Location = pt.Loc and sp.Item = pt.Item
				where pt.IsPickHu = 0 and pt.IsActive = 1
				group by pt.Loc, pt.Item) as ai
		group by ai.Location, ai.Item) as oc on inv.Location = oc.Location and inv.Item = oc.Item

		--ɾ������С�ڵ���0�Ŀ��
		delete from #tempAvailableInv_008 where Qty <= 0
	end try
	begin catch
		set @ErrorMsg = N'��ȡ������ÿ�淢���쳣��' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	drop table #tempLocation_008
	drop table #tempPickTarget_008
END
GO