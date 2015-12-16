SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_WMS_GetAvailableInv4Pick')
BEGIN
	DROP PROCEDURE USP_WMS_GetAvailableInv4Pick
END
GO

CREATE PROCEDURE dbo.USP_WMS_GetAvailableInv4Pick
	@PickTargetTable PickTargetTableType readonly,
	@IsPickHu bit
AS
BEGIN
	set nocount on
	declare @ErrorMsg nvarchar(MAX)

	create table #tempPickTarget_002
	(
		RowId int identity(1, 1),
		Location varchar(50),
		Item varchar(50)
	)

	create table #tempLocation_002
	(
		RowId int identity(1, 1),
		Location varchar(50),
		IsSpread bit,
		PickBy tinyint,
		Suffix varchar(50)
	)

	begin try
		if not exists(select top 1 1 FROM tempdb.sys.objects WHERE type = 'U' AND name like '#tempAvailableInv_002%') 
		begin
			set @ErrorMsg = 'û�ж��巵�����ݵĲ�����'
			RAISERROR(@ErrorMsg, 16, 1) 

			--���벻��ִ�е�����
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
		else
		begin
			truncate table #tempAvailableInv_002
		end

		insert into #tempPickTarget_002(Location, Item) select distinct Location, Item from @PickTargetTable
		insert into #tempLocation_002(Location, IsSpread, PickBy, Suffix) 
		select distinct l.Code, l.IsSpread, l.PickBy, l.PartSuffix
		from #tempPickTarget_002 as tmp inner join MD_Location as l on tmp.Location = l.Code

		declare @LocationRowId int
		declare @MaxLocationRowId int
		declare @Location varchar(50)
		declare @IsSpread bit
		declare @PickBy tinyint
		declare @LocSuffix varchar(50)
		declare @SelectInvStatement varchar(max)

		select @LocationRowId = MIN(RowId), @MaxLocationRowId = MAX(RowId) from #tempLocation_002

		while (@LocationRowId <= @MaxLocationRowId)
		begin
			select @Location = Location, @IsSpread = IsSpread, @LocSuffix = Suffix, @PickBy = PickBy
			from #tempLocation_002 where RowId = @LocationRowId
			set @SelectInvStatement = ''

			if (@IsPickHu = 0)
			begin --���������
				set @SelectInvStatement = 'select sp.Location, sp.Item, SUM(ISNULL(llt.Qty, 0)) as InvQty '
				set @SelectInvStatement = @SelectInvStatement + 'from #tempPickTarget_002 as sp '
				set @SelectInvStatement = @SelectInvStatement + 'inner join INV_LocationLotDet_' + @LocSuffix + ' as llt on sp.Location = llt.Location and sp.Item = llt.Item '
				set @SelectInvStatement = @SelectInvStatement + 'where sp.Location = ' + @Location + ' and llt.OccupyRefNo is null and llt.Qty <> 0 and llt.HuId is null and llt.QualityType = 0'
				set @SelectInvStatement = @SelectInvStatement + 'group by sp.Location, sp.Item '
				set @SelectInvStatement = @SelectInvStatement + 'having SUM(llt.Qty, 0) > 0'

				insert into #tempAvailableInv_002(Location, Item, Qty) exec sp_executesql @SelectInvStatement
			end
			else
			begin --��������
				if (@PickBy = 0)
				begin  --�����ż��
					set @SelectInvStatement = 'select sp.Location, 0 as PickBy, sp.Item, hu.Uom, hu.UC, hu.LotNo, bin.Area, llt.Bin, bin.Seq, SUM(llt.Qty) as InvQty, 0 as IsOdd '
					set @SelectInvStatement = @SelectInvStatement + 'from #tempPickTarget_002 as sp '
					set @SelectInvStatement = @SelectInvStatement + 'inner join INV_LocationLotDet_' + @LocSuffix + ' as llt on sp.Location = llt.Location and sp.Item = llt.Item '
					set @SelectInvStatement = @SelectInvStatement + 'inner join INV_Hu as hu on llt.HuId = hu.HuId '
					set @SelectInvStatement = @SelectInvStatement + 'inner join MD_LocationBin as bin on llt.Bin = bin.Code '
					set @SelectInvStatement = @SelectInvStatement + 'where sp.Location = ' + @Location + ' and llt.OccupyRefNo is null and llt.Qty > 0 and llt.QualityType = 0 and llt.Bin is not null and hu.Qty = hu.UC '
					set @SelectInvStatement = @SelectInvStatement + 'group by sp.Location, sp.Item, hu.Uom, hu.UC, hu.LotNo, bin.Area, llt.Bin, bin.Seq'
				
					insert into #tempAvailableInv_002(Location, PickBy, Item, Uom, UC, LotNo, Area, Bin, BinSeq, Qty, IsOdd) exec sp_executesql @SelectInvStatement

					set @SelectInvStatement =  'select sp.Location, 0 as PickBy, hu.UC, sp.Item, hu.HuId, hu.LotNo, bin.Area, llt.Bin, bin.Seq, llt.Qty, 1 as IsOdd '
					set @SelectInvStatement = @SelectInvStatement + 'from #tempPickTarget_002 as sp '
					set @SelectInvStatement = @SelectInvStatement + 'inner join INV_LocationLotDet_' + @LocSuffix + ' as llt on sp.Location = llt.Location and sp.Item = llt.Item ' 
					set @SelectInvStatement = @SelectInvStatement + 'inner join INV_Hu as hu on llt.HuId = hu.HuId '
					set @SelectInvStatement = @SelectInvStatement + 'inner join MD_LocationBin as bin on llt.Bin = bin.Code '
					set @SelectInvStatement = @SelectInvStatement + 'left join WMS_PickTask as pt on llt.HuId = pt.HuId and pt.IsActive = 1 '  --���˵��������ռ�õ�����
					set @SelectInvStatement = @SelectInvStatement + 'where sp.Location = ' + @Location + ' and llt.OccupyRefNo is null and llt.Qty > 0 and llt.QualityType = 0 and llt.Bin is not null and pt.Id is null and hu.Qty <> hu.UC'

					insert into #tempAvailableInv_002(Location, PickBy, Item, UC, HuId, LotNo, Area, Bin, BinSeq, Qty, IsOdd) exec sp_executesql @SelectInvStatement
				end
				else
				begin  --��������
					set @SelectInvStatement =  'select sp.Location, 1 as PickBy, hu.UC, sp.Item, hu.HuId, hu.LotNo, bin.Area, llt.Bin, bin.Seq, llt.Qty, CASE WHEN hu.UC = hu.Qty THEN 0 ELSE 1 END as IsOdd '
					set @SelectInvStatement = @SelectInvStatement + 'from #tempPickTarget_002 as sp '
					set @SelectInvStatement = @SelectInvStatement + 'inner join INV_LocationLotDet_' + @LocSuffix + ' as llt on sp.Location = llt.Location and sp.Item = llt.Item ' 
					set @SelectInvStatement = @SelectInvStatement + 'inner join INV_Hu as hu on llt.HuId = hu.HuId '
					set @SelectInvStatement = @SelectInvStatement + 'inner join MD_LocationBin as bin on llt.Bin = bin.Code '
					set @SelectInvStatement = @SelectInvStatement + 'left join WMS_PickTask as pt on llt.HuId = pt.HuId and pt.IsActive = 1 '  --���˵��������ռ�õ�����
					set @SelectInvStatement = @SelectInvStatement + 'where sp.Location = ' + @Location + ' and llt.OccupyRefNo is null and llt.Qty > 0 and llt.QualityType = 0 and llt.Bin is not null and pt.Id is null '

					insert into #tempAvailableInv_002(Location, PickBy, Item, UC, HuId, LotNo, Area, Bin, BinSeq, Qty, IsOdd) exec sp_executesql @SelectInvStatement
				end
			end

			set @LocationRowId = @LocationRowId + 1
		end

		--�ۼ���ռ�õĿ��
		if (@IsPickHu = 0)
		begin --���������
			update inv set Qty = inv.Qty - oc.OccupyQty
			from #tempAvailableInv_002 as inv inner join
			(select ai.Location, ai.Item, SUM(OccupyQty) as OccupyQty
			from (select sp.Location, sp.Item, SUM(bi.Qty) as OccupyQty 
					from #tempPickTarget_002 as sp
					inner join WMS_BuffInv as bi on bi.Loc = sp.Location and bi.Item = sp.Item
					where bi.Qty > 0 and bi.HuId is null and bi.IOType = 1
					group by sp.Location, sp.Item
					union all 
					select pt.Loc, pt.Item, SUM((pt.OrderQty - pt.PickQty) * pt.UnitQty) as OccupyQty
					from #tempPickTarget_002 as sp 
					inner join WMS_PickTask as pt on sp.Location = pt.Loc and sp.Item = pt.Item
					where pt.IsPickHu = 0 and pt.IsActive = 1 and pt.OrderQty > pt.PickQty
					group by pt.Loc, pt.Item) as ai
			group by ai.Location, ai.Item) as oc on inv.Location = oc.Location and inv.Item = oc.Item

			--ɾ������С�ڵ���0�Ŀ��
			delete from #tempAvailableInv_002 where Qty <= 0
		end
		else
		begin --��������
			if (@PickBy = 0)
			begin  --�����ż��
				--����ջ�����Ŀ��
				--insert into #tempAvailableInv_002(Location, Item, UC, LotNo, BinSeq, Qty)
				--select bi.Loc, bi.Item, hu.UC, hu.LotNo, -100, SUM(bi.Qty)
				--from #tempPickTarget_002 as sp
				--inner join WMS_BuffInv as bi on bi.Loc = sp.Location and bi.Item = sp.Item
				--inner join INV_Hu as hu on bi.HuId = hu.HuId
				--where bi.Qty > 0 and bi.IOType = 0 --���ջ�������
				--group by bi.Loc, bi.Item, hu.UC, hu.LotNo

				--�ۼ������ռ�õĿ�棨�ȿۼ�ռ�û���Ŀ�棩          ������Ǽ�Ŀ���е����ϣ��ݲ�֧��ֱ�Ӽ�ذ��ϵ����ϣ���Ϊ�ذ��ϵ�����Ӧ�ö��ڻ��������棩
				--update inv set Qty = inv.Qty - oc.OccupyQty
				--from #tempAvailableInv_002 as inv inner join
				--(select pt.Loc, pt.Item, pt.UC, pt.LotNo, SUM((pt.OrderQty - pt.PickQty) * pt.UnitQty) as OccupyQty
				--from #tempPickTarget_002 as sp 
				--inner join WMS_PickTask as pt on sp.Location = pt.Loc and sp.Item = pt.Item
				--where pt.IsPickHu = 1 and pt.PickBy = 0 and pt.IsActive = 1 and pt.OrderQty > pt.PickQty and pt.Bin is null
				--group by pt.Loc, pt.Item, pt.UC, pt.LotNo) as oc on inv.Location = oc.Loc and inv.Item = oc.Item and inv.UC = oc.UC and inv.LotNo = oc.LotNo
				--where inv.Bin is null

				--�ۼ������ռ�õĿ�棨�ۼ�����ϵĿ�棩
				update inv set Qty = inv.Qty - oc.OccupyQty
				from #tempAvailableInv_002 as inv inner join
				(select pt.Loc, pt.Item, pt.Uom, pt.UC, pt.LotNo, pt.Bin, SUM((pt.OrderQty - pt.PickQty) * pt.UnitQty) as OccupyQty
				from @PickTargetTable as sp 
				inner join WMS_PickTask as pt on sp.Location = pt.Loc and sp.Item = pt.Item and sp.Uom = pt.Uom and sp.UC = pt.UC
				where pt.IsPickHu = 1 and pt.PickBy = 0 and pt.IsActive = 1 and pt.OrderQty > pt.PickQty and pt.IsOdd = 0
				group by pt.Loc, pt.Item, pt.Uom, pt.UC, pt.LotNo, pt.Bin) as oc on inv.Location = oc.Loc and inv.Item = oc.Item and inv.Uom = oc.Uom and inv.UC = oc.UC and inv.LotNo = oc.LotNo and inv.Bin = oc.Bin
				where inv.IsOdd = 0

				--ɾ������С�ڵ���0�Ŀ��
				delete from #tempAvailableInv_002 where Qty <= 0
			end
			--else
			--begin  --��������
			--	--����ջ�����Ŀ��
			--	insert into #tempAvailableInv_002(Location, Item, UC, HuId, LotNo, BinSeq, Qty)
			--	select bi.Loc, bi.Item, bi.UC, bi.HuId, bi.LotNo, -100, bi.Qty
			--	from #tempPickTarget_002 as sp
			--	inner join WMS_BuffInv as bi on bi.Loc = sp.Location and bi.Item = sp.Item
			--	left join WMS_PickTask as pt on bi.HuId = pt.HuId and pt.IsActive = 1  --���˵��������ռ�õ�����
			--	where bi.Qty > 0 and bi.IOType = 0 --���ջ�������
			--	and pt.Id is null
			--end
		end 

	end try
	begin catch
		set @ErrorMsg = N'��ȡ������ÿ�淢���쳣��' + Error_Message() 
		RAISERROR(@ErrorMsg, 16, 1) 
	end catch

	drop table #tempLocation_002
	drop table #tempPickTarget_002
END
GO