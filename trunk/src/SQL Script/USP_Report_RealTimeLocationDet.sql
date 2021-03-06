USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_RealTimeLocationDet]    Script Date: 12/08/2014 15:18:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_Report_RealTimeLocationDet]
(
	@Locations varchar(8000),
	@Items varchar(8000),
	@SortDesc varchar(100),
	@PageSize int,
	@Page int,
	@IsSummaryBySAPLoc bit,
	@SummaryLevel int,
	@IsGroupByManufactureParty bit,
	@IsGroupByLotNo bit,
	@IsOnlyShowQtyInv bit
)
AS
BEGIN
/*
exec USP_Report_RealTimeLocationDet '1002','','',100,1,1,0,1,1,1
500368184
--2014/08/01  在途分销售在途和移库在途，全部算到来源库位	--0001
--2014/09/24  去掉实时库存为0的		--0002
*/
    SELECT @Locations=LTRIM(RTRIM(@Locations)),@Items=LTRIM(RTRIM(@Items))
	SET NOCOUNT ON
	DECLARE @Sql varchar(max)
	DECLARE @Where  varchar(8000)
	DECLARE @PartSuffix varchar(5)
	DECLARE @PagePara varchar(8000)
	DECLARE @TmpForLoop int
	SELECT @Sql='',@TmpForLoop=0,@Where=''
	DECLARE @LocationIds table(Id int identity(1,1),PartSuffix varchar(5))
	CREATE TABLE #TempResult
	(
		rowid int,
		Location varchar(50), 
		Item varchar(50), 
		LotNo varchar(50),
		ManufactureParty varchar(50), 
		Qty decimal(18,8), 
		CsQty decimal(18,8), 
		QualifyQty decimal(18,8), 
		InspectQty decimal(18,8), 
		RejectQty decimal(18,8),  
		ATPQty decimal(18,8), 
		FreezeQty decimal(18,8)		
	)
	CREATE TABLE #TempInternal
	(
		Location varchar(50), 
		Item varchar(50), 
		LotNo varchar(50),
		ManufactureParty varchar(50), 
		Qty decimal(18,8), 
		CsQty decimal(18,8), 
		QualifyQty decimal(18,8), 
		InspectQty decimal(18,8), 
		RejectQty decimal(18,8),  
		ATPQty decimal(18,8), 
		FreezeQty decimal(18,8)
	)
	CREATE TABLE #TempTransQty
	(
		Item varchar(50), 
		Location varchar(50), 
		Qty decimal(18,8), 
		QualifyQty decimal(18,8), 
		RejectQty decimal(18,8)
	)
	CREATE TABLE #SalesTempTransQty
	(
		Item varchar(50), 
		Location varchar(50), 
		Qty decimal(18,8), 
		QualifyQty decimal(18,8), 
		RejectQty decimal(18,8)
	)	
	--如果有输入的库位则只查询输入库位的表，否则全部表拼接查询
	IF ISNULL(@Locations,'')='' 
	BEGIN
		INSERT INTO @LocationIds(PartSuffix)
		SELECT DISTINCT(PartSuffix) FROM MD_Location WHERE PartSuffix IS NOT NULL OR PartSuffix<>''
	END
	ELSE
	BEGIN
		--0002
		Select @Locations=@Locations+','+Code from MD_location where SAPLocation in(Select * from dbo.Func_SplitStr(@Locations,','))
		--0002
		SET @Where=' WHERE det.Location in('''+replace(@Locations,',',''',''')+''')'
	    SET @sql='SELECT DISTINCT PartSuffix FROM MD_Location WHERE Code in ('''+replace(@Locations,',',''',''')+''') or SAPLocation in ('''+replace(@Locations,',',''',''')+''')'
		 PRINT @Locations
		INSERT INTO @LocationIds(PartSuffix)
		EXEC(@sql)
	END
	
	---查询出数据时需要的条件
	-----物料
	IF ISNULL(@Items,'')<>'' 
	BEGIN
		IF ISNULL(@Where,'')=''
		BEGIN
			SET @Where=' WHERE det.Item IN ('''+replace(@Items,',',''',''')+''')'
		END
		ELSE
		BEGIN
			SET @Where=@Where+' AND det.Item IN ('''+replace(@Items,',',''',''')+''')'
		END
	END
	
	IF @IsOnlyShowQtyInv=1 AND @IsGroupByLotNo=0
	BEGIN
		IF ISNULL(@Where,'')=''
		BEGIN
			SET @Where=' WHERE det.LotNo is null '
		END
		ELSE
		BEGIN
			SET @Where=@Where+' AND det.LotNo is null '
		END
	END
	
	ELSE IF @IsGroupByLotNo=1 AND @IsOnlyShowQtyInv=0
	BEGIN
		IF ISNULL(@Where,'')=''
		BEGIN
			SET @Where=' WHERE det.LotNo is not null '
		END
		ELSE
		BEGIN
			SET @Where=@Where+' AND det.LotNo is not null '
		END
	END
	
	IF @IsGroupByLotNo=0 
	BEGIN
		IF @IsSummaryBySAPLoc=0
		BEGIN
		--移库
			insert into #TempTransQty
			select a.Item as Item,/*a.LocTo*/a.LocFrom as Location,
			sum((Qty - RecQty)*UnitQty) As Qty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=0 then 1 else 0 end) As QualifyQty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=2 then 1 else 0 end) As RejectQty
			from ORD_IpDet_2 a  where a.IsClose =0 and ABS(Qty)>ABS(RecQty) 
			group by a.Item,/*a.LocTo*/a.LocFrom
		--委外移库
			insert into #TempTransQty
			select a.Item as Item,/*a.LocTo*/a.LocFrom as Location,
			sum((Qty - RecQty)*UnitQty) As Qty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=0 then 1 else 0 end) As QualifyQty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=2 then 1 else 0 end) As RejectQty
			from ORD_IpDet_7 a  where a.IsClose =0 and ABS(Qty)>ABS(RecQty) 
			group by a.Item,/*a.LocTo*/a.LocFrom
		--销售
			insert into #SalesTempTransQty
			select a.Item as Item,/*a.LocTo*/a.LocFrom as Location,
			sum((Qty - RecQty)*UnitQty) As Qty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=0 then 1 else 0 end) As QualifyQty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=2 then 1 else 0 end) As RejectQty
			from ORD_IpDet_3 a  where a.IsClose =0 and ABS(Qty)>ABS(RecQty) 
			group by a.Item,/*a.LocTo*/a.LocFrom
		END
		ELSE
		BEGIN
		--移库
			insert into #TempTransQty
			select a.Item as Item,l.SAPLocation as Location,
			sum((Qty - RecQty)*UnitQty) As Qty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=0 then 1 else 0 end) As QualifyQty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=2 then 1 else 0 end) As RejectQty
			from ORD_IpDet_2 a 
			join MD_Location l on /*a.LocTo*/a.LocFrom = l.Code
			where a.IsClose =0 and ABS(Qty)>ABS(RecQty) 
			group by a.Item,l.SAPLocation
		--委外移库
			insert into #TempTransQty
			select a.Item as Item,l.SAPLocation as Location,
			sum((Qty - RecQty)*UnitQty) As Qty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=0 then 1 else 0 end) As QualifyQty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=2 then 1 else 0 end) As RejectQty
			from ORD_IpDet_7 a 
			join MD_Location l on /*a.LocTo*/a.LocFrom = l.Code
			where a.IsClose =0 and ABS(Qty)>ABS(RecQty) 
			group by a.Item,l.SAPLocation
		--销售
			insert into #SalesTempTransQty
			select a.Item as Item,l.SAPLocation as Location,
			sum((Qty - RecQty)*UnitQty) As Qty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=0 then 1 else 0 end) As QualifyQty,
			sum((Qty - RecQty)*UnitQty*Case when QualityType=2 then 1 else 0 end) As RejectQty
			from ORD_IpDet_3 a 
			join MD_Location l on /*a.LocTo*/a.LocFrom = l.Code
			where a.IsClose =0 and ABS(Qty)>ABS(RecQty) 
			group by a.Item,l.SAPLocation
		END
	END
	
	--PRINT @Where
	--select * from @LocationIds
	---排序条件
	IF ISNULL(@SortDesc,'')=''
	BEGIN
		SET @SortDesc=' ORDER BY Item ASC'
	END
		
	---查询出结果时需要的条件
	IF @Page>0
	BEGIN
		SET @PagePara='WHERE rowid BETWEEN '+cast(@PageSize*(@Page-1)+1 as varchar(50))+' AND '++cast(@PageSize*(@Page) as varchar(50))
	END

	DECLARE @MaxId int
	SELECT @MaxId = MAX(Id),@Sql='' FROM @LocationIds
	WHILE @TmpForLoop<@MaxId
	BEGIN
		SET @TmpForLoop=@TmpForLoop+1
		SELECT @PartSuffix=PartSuffix FROM @LocationIds WHERE Id=@TmpForLoop
		PRINT @TmpForLoop
		IF 	@IsGroupByManufactureParty=0 AND @IsGroupByLotNo=0
		BEGIN
			SET @Sql='SELECT det.Location, det.Item,'''' as LotNo,'''' as ManufactureParty,
					SUM(det.Qty) AS Qty, 
					SUM(CASE WHEN det.IsCS = 1 THEN det.Qty ELSE 0 END) AS CSQty, 					
                    SUM(CASE WHEN det.QualityType = 0 THEN det.Qty ELSE 0 END) AS QualifyQty, 
                    SUM(CASE WHEN det.QualityType = 1 THEN det.Qty ELSE 0 END) AS InspectQty, 
                    SUM(CASE WHEN det.QualityType = 2 THEN det.Qty ELSE 0 END) AS RejectQty, 
                    SUM(CASE WHEN det.IsATP = 1 THEN det.Qty ELSE 0 END) AS ATPQty, 
                    SUM(CASE WHEN det.IsFreeze = 1 THEN det.Qty ELSE 0 END) AS FreezeQty
					FROM  inv_locationlotdet_'+@PartSuffix+' AS det '+@Where+' 
					GROUP BY det.Location, det.Item'
		END	
		ELSE IF @IsGroupByManufactureParty=1 AND @IsGroupByLotNo=0
		BEGIN
			SET @Sql='SELECT det.Location, det.Item,'''' AS LotNo, 
					CASE WHEN bill.Party IS NOT NULL THEN bill.Party ELSE hu.ManufactureParty END AS ManufactureParty,
					SUM(det.Qty) AS Qty,
					SUM(CASE WHEN det.IsCS = 1 THEN det.Qty ELSE 0 END) AS CSQty,
                    SUM(CASE WHEN det.QualityType = 0 THEN det.Qty ELSE 0 END) AS QualifyQty, 
                    SUM(CASE WHEN det.QualityType = 1 THEN det.Qty ELSE 0 END) AS InspectQty, 
                    SUM(CASE WHEN det.QualityType = 2 THEN det.Qty ELSE 0 END) AS RejectQty, 
                    SUM(CASE WHEN det.IsATP = 1 THEN det.Qty ELSE 0 END) AS ATPQty, 
                    SUM(CASE WHEN det.IsFreeze = 1 THEN det.Qty ELSE 0 END) AS FreezeQty
					FROM  inv_locationlotdet_'+@PartSuffix+' AS det 
					LEFT JOIN dbo.INV_Hu AS hu ON det.HuId = hu.HuId  
					LEFT  JOIN BIL_PlanBill AS bill ON det.PlanBill=bill.id AND bill.Type=0 '+@Where+' 
					GROUP BY det.Location, det.Item,CASE WHEN bill.Party IS NOT NULL THEN bill.Party ELSE hu.ManufactureParty END '			
		END	
		ELSE IF @IsGroupByManufactureParty=0 AND @IsGroupByLotNo=1
		BEGIN
			SET @Sql='SELECT det.Location, det.Item, det.LotNo,'''' as ManufactureParty, 
					SUM(det.Qty) AS Qty, 
					SUM(CASE WHEN det.IsCS = 1 THEN det.Qty ELSE 0 END) AS CSQty,
                    SUM(CASE WHEN det.QualityType = 0 THEN det.Qty ELSE 0 END) AS QualifyQty, sum(CASE WHEN det.QualityType = 1 THEN det.Qty ELSE 0 END) AS InspectQty, 
                    SUM(CASE WHEN det.QualityType = 2 THEN det.Qty ELSE 0 END) AS RejectQty, sum(CASE WHEN det.IsATP = 1 THEN det.Qty ELSE 0 END) AS ATPQty, 
                    SUM(CASE WHEN det.IsFreeze = 1 THEN det.Qty ELSE 0 END) AS FreezeQty
					FROM  inv_locationlotdet_'+@PartSuffix+' AS det LEFT JOIN
					dbo.INV_Hu AS hu ON det.HuId = hu.HuId '+@Where+' and det.Qty<>0
					GROUP BY det.Location, det.Item, det.LotNo'		
		END			
		ELSE IF @IsGroupByManufactureParty=1 AND @IsGroupByLotNo=1	
		BEGIN
			SET @Sql='SELECT det.Location, det.Item,det.LotNo, 
					CASE WHEN bill.Party IS NOT NULL THEN bill.Party ELSE hu.ManufactureParty END AS ManufactureParty,
					SUM(det.Qty) AS Qty, 
					SUM(CASE WHEN det.IsCS = 1 THEN det.Qty ELSE 0 END) AS CSQty,
                    SUM(CASE WHEN det.QualityType = 0 THEN det.Qty ELSE 0 END) AS QualifyQty, sum(CASE WHEN det.QualityType = 1 THEN det.Qty ELSE 0 END) AS InspectQty, 
                    SUM(CASE WHEN det.QualityType = 2 THEN det.Qty ELSE 0 END) AS RejectQty, sum(CASE WHEN det.IsATP = 1 THEN det.Qty ELSE 0 END) AS ATPQty, 
                    SUM(CASE WHEN det.IsFreeze = 1 THEN det.Qty ELSE 0 END) AS FreezeQty
					FROM  inv_locationlotdet_'+@PartSuffix+' AS det 
					LEFT JOIN dbo.INV_Hu AS hu ON det.HuId = hu.HuId  
					LEFT  JOIN BIL_PlanBill AS bill ON det.PlanBill=bill.id AND bill.Type=0 '+@Where+' and det.Qty<>0
					GROUP BY det.Location, det.Item,det.LotNo,CASE WHEN bill.Party IS NOT NULL THEN bill.Party ELSE hu.ManufactureParty END '
		END	
		
		--exec(@Sql)	
		--print 'y'
		INSERT INTO #TempInternal
		EXEC(@Sql)		
	END
	--SELECT * FROM #TempInternal
	
	---最后的查询结果,包含2个数据集,一个是总数一个是分页数据
	IF @IsSummaryBySAPLoc=1
	BEGIN
		--汇总到SAP库位
		SET @sql = 'select row_number() over('+@SortDesc+') as rowid,* FROM (SELECT l.SAPLocation as Location, t.Item, t.LotNo, t.ManufactureParty,
			SUM(t.CSQty) AS CSQty,SUM(t.Qty) as QTY, SUM(t.QualifyQty) as QualifyQty, SUM(t.InspectQty) as InspectQty, 
			SUM(t.RejectQty) as RejectQty, SUM(t.ATPQty) as ATPQty, SUM(t.FreezeQty) as FreezeQty FROM #TempInternal as t
			INNER JOIN MD_Location l ON t.Location=l.Code
			left join #TempTransQty ts on ts.Item = t.Item and ts.Location = t.Location 
			left join #SalesTempTransQty s on s.Item = t.Item and s.Location = t.Location
			GROUP BY l.SAPLocation, t.Item, t.LotNo, t.ManufactureParty having SUM(t.Qty+isnull(ts.Qty,0)+isnull(s.Qty,0))<>0) as LocTranDet'
		--print 't'
		print @sql
		insert into #TempResult 
		exec(@sql)	
		--0002
		select count(1) from #TempResult d left join #TempTransQty t on t.Item = d.Item and t.Location = d.Location 
		left join #SalesTempTransQty s on s.Item = d.Item and s.Location = d.Location
		where d.Qty+isnull(t.Qty,0)+isnull(s.Qty,0)<>0
		--0002
		exec('select top('+@PageSize+') d.Location,l.Name as LocationName,d.Item,i.Desc1+case when Isnull(RefCode,'''')='''' then '''' else ''[''+RefCode+'']'' end as ItemDescription,
		i.MaterialsGroup as MaterialsGroup,c.Desc1 as MaterialsGroupDesc,i.Uom as Uom,d.LotNo,d.ManufactureParty,d.Qty,d.CSQTY, 
		d.QualifyQty,d.InspectQty,d.RejectQty,d.ATPQty,d.FreezeQty,isnull(t.Qty,0) as TransQty,
		isnull(t.QualifyQty,0) as TransQualifyQty,isnull(t.RejectQty,0) as TransRejectQty,
		isnull(s.Qty,0) as SalesTransQty,
		isnull(s.QualifyQty,0) as SalesTransQualifyQty,isnull(s.RejectQty,0) as SalesTransRejectQty
		from #TempResult as d
		left join MD_Item i on i.Code = d.Item
		left join MD_Location l on l.Code = d.Location
		left join MD_ItemCategory c on c.Code = i.MaterialsGroup and c.SubCategory=5
		left join #TempTransQty t on t.Item = d.Item and t.Location = d.Location 
		left join #SalesTempTransQty s on s.Item = d.Item and s.Location = d.Location '
		+@PagePara + ' and d.Qty+isnull(t.Qty,0)+isnull(s.Qty,0)<>0 ')		
	END
	ELSE
	BEGIN
		IF @SummaryLevel=0
		BEGIN
			--不汇总
			SET @sql = 'select row_number() over('+@SortDesc+') as rowid,* FROM (Select det.Location, det.Item, det.LotNo, det.ManufactureParty,
			det.Qty, det.CSQTY, det.QualifyQty, det.InspectQty, det.RejectQty, det.ATPQty, det.FreezeQty from #TempInternal as det 
			left join #TempTransQty ts on ts.Item = det.Item and ts.Location = det.Location  
			left join #SalesTempTransQty s on s.Item = det.Item and s.Location = det.Location 
			where det.Qty+isnull(ts.Qty,0)+isnull(s.Qty,0)<>0  ) As Dt'
			--print 'r'
			insert into #TempResult 
			exec(@sql)	
			
			PRINT @sql	
			--0002
			select count(1) from #TempResult d left join #TempTransQty t on t.Item = d.Item and t.Location = d.Location 
			left join #SalesTempTransQty s on s.Item = d.Item and s.Location = d.Location
			where d.Qty+isnull(t.Qty,0)+isnull(s.Qty,0)<>0
			--0002
			exec('select top('+@PageSize+') d.Location,l.Name as LocationName,d.Item,i.Desc1+case when Isnull(RefCode,'''')='''' then '''' else ''[''+RefCode+'']'' end as ItemDescription,
			i.MaterialsGroup as MaterialsGroup,c.Desc1 as MaterialsGroupDesc,i.Uom as Uom,d.LotNo,d.ManufactureParty,d.Qty,d.CSQTY, 
			d.QualifyQty,d.InspectQty,d.RejectQty,d.ATPQty,d.FreezeQty,isnull(t.Qty,0) as TransQty,
			isnull(t.QualifyQty,0) as TransQualifyQty,isnull(t.RejectQty,0) as TransRejectQty,
			isnull(s.Qty,0) as SalesTransQty,
			isnull(s.QualifyQty,0) as SalesTransQualifyQty,isnull(s.RejectQty,0) as SalesTransRejectQty
			from #TempResult as d
			left join MD_Item i on i.Code = d.Item
			left join MD_Location l on l.Code = d.Location
			left join MD_ItemCategory c on c.Code = i.MaterialsGroup and c.SubCategory=5
			left join #TempTransQty t on t.Item = d.Item and t.Location = d.Location 
			left join #SalesTempTransQty s on s.Item = d.Item and s.Location = d.Location  '
			+@PagePara + ' and d.Qty+isnull(t.Qty,0)+isnull(s.Qty,0)<>0 ') 
		END
		ELSE IF @SummaryLevel=1
		BEGIN
			--汇总到区域
			SET @sql = 'select row_number() over('+@SortDesc+') as rowid,* FROM (SELECT r.Code as Location, t.Item, t.LotNo, t.ManufactureParty,
				SUM(t.CSQty) AS CSQty,SUM(t.Qty) as QTY, SUM(t.QualifyQty) as QualifyQty, SUM(t.InspectQty) as InspectQty, 
				SUM(t.RejectQty) as RejectQty, SUM(t.ATPQty) as ATPQty, SUM(t.FreezeQty) as FreezeQty FROM #TempInternal as t
				INNER JOIN MD_Location l ON t.Location=l.Code
				INNER JOIN MD_Region r ON r.Code=l.Region
				GROUP BY r.Code, t.Item, t.LotNo, t.ManufactureParty having SUM(t.Qty)<>0) as LocTranDet'
			--print 'e'
			insert into #TempResult 
			exec(@sql)	
				
			select count(1) from #TempResult
			exec('select top('+@PageSize+')  Location, Item, LotNo, ManufactureParty, Qty, CSQTY, QualifyQty, InspectQty, RejectQty, ATPQty, FreezeQty from #TempResult '+@PagePara) 
		END
		ELSE IF @SummaryLevel=2
		BEGIN
			--汇总到车间
			SET @sql = 'select row_number() over('+@SortDesc+') as rowid,* FROM (SELECT r.Workshop as Location, t.Item, t.LotNo, t.ManufactureParty, 
				SUM(t.Qty) as QTY, SUM(t.CSQty) AS CSQty, SUM(t.QualifyQty) as QualifyQty, SUM(t.InspectQty) as InspectQty, 
				SUM(t.RejectQty) as RejectQty, SUM(t.ATPQty) as ATPQty, SUM(t.FreezeQty) as FreezeQty FROM #TempInternal as t
				INNER JOIN MD_Location l ON t.Location=l.Code
				INNER JOIN MD_Region r ON r.Code=l.Region
				GROUP BY r.Workshop, t.Item, t.LotNo, t.ManufactureParty having SUM(t.Qty)<>0) as LocTranDet'
--print 'w'
			insert into #TempResult 
			exec(@sql)	
				
			select count(1) from #TempResult
			exec('select top('+@PageSize+') Location, Item, LotNo, ManufactureParty, Qty, CSQTY, QualifyQty, InspectQty, RejectQty, ATPQty, FreezeQty from #TempResult '+@PagePara) 
		END
		ELSE IF @SummaryLevel=3
		BEGIN
			--汇总到工厂
			SET @sql = 'select row_number() over('+@SortDesc+') as rowid,* FROM (SELECT r.Plant as Location, t.Item, t.LotNo, t.ManufactureParty, 
				SUM(t.Qty) as QTY, SUM(t.CSQty) AS CSQty, SUM(t.QualifyQty) as QualifyQty, SUM(t.InspectQty) as InspectQty, 
				SUM(t.RejectQty) as RejectQty, SUM(t.ATPQty) as ATPQty, SUM(t.FreezeQty) as FreezeQty FROM #TempInternal as t
				INNER JOIN MD_Location l ON t.Location=l.Code
				INNER JOIN MD_Region r ON r.Code=l.Region
				GROUP BY r.Plant, t.Item, t.LotNo, t.ManufactureParty having SUM(t.Qty)<>0) as LocTranDet'
			--print 'q'
			insert into #TempResult 
			exec(@sql)	
				
			select count(1) from #TempResult
			exec('select top('+@PageSize+') Location, Item, LotNo, ManufactureParty, Qty, CSQTY, QualifyQty, InspectQty, RejectQty, ATPQty, FreezeQty from #TempResult '+@PagePara) 
		END
	END	
END