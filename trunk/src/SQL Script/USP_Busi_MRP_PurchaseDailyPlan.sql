USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_PurchaseDailyPlan]    Script Date: 12/08/2014 15:12:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_Busi_MRP_PurchaseDailyPlan]
(
	@Flow varchar(50),
	@Item varchar(50),
	@ItemGroup varchar(50)
) 
AS
BEGIN
--[USP_Busi_MRP_PurchaseDailyPlan] '30070-9301','',''
set nocount on
--计算后加工的每天的收当天往后2周只需拆一层BOM
	Declare @CurrentTime datetime = getdate()
	CREATE TABLE #PlanInQty(
		[Flow] [varchar](50) NULL,
		[OrderType] [tinyint] NOT NULL,
		[Item] [varchar](50) NOT NULL,
		[StartTime] [datetime] NOT NULL,
		[WindowTime] [datetime] NOT NULL,
		[LocationFrom] [varchar](50) NULL,
		[LocationTo] [varchar](50) NULL,
		[Qty] [float] NOT NULL,
		[Bom] [varchar](50) NULL,
		[SourceType] [tinyint] NOT NULL,
		[SourceParty] [varchar](50) NULL,
	) 	
--找一个ResourceGroup=30的有效版本传入USP_Busi_MRP_GetPlanIn 取得后加工的收
	Declare @FiMrpPlanversion DateTime
	select @FiMrpPlanversion = max(PlanVersion) from MRP_MrpPlanMaster 
		where ResourceGroup =30 and IsRelease =1 
	Insert into  #PlanInQty
		Exec USP_Busi_MRP_GetPlanIn @FiMrpPlanversion,'PurchaseInvoke'--''返回所有的线别

--计算挤出的每天的收当天往后2周,BOM需要拆到最后一层
	Create Table #InsertFromSP ( 生产线 varchar(20),断面 varchar(20), 断面描述 varchar(50),	半制品	varchar(20),半制品描述 varchar(50),	Plandate varchar(20), 当前库存 varchar(20),待收 varchar(20),待发 varchar(20) )
		Exec [USP_Busi_MRP_ExPlanTrack_BK] @FiMrpPlanversion
	Insert into #InsertFromSP
		--不能嵌套调用存储，所以这里用全局表过度一下  2014/03/16
		Select * from ##EXTRACK
	--Insert into #InsertFromSP --传一个时间类型的参数就可以了
	--	Exec [USP_Busi_MRP_ExPlanTrack_BK]  @FiMrpPlanversion
--汇总Item
	Select 'FIItem' AS AreaType,Item ,dbo.FormatDate(starttime,'YYYY/MM/DD') As Plandate,Sum(Qty) As Qty 
		into #ItemSummary 
		from #PlanInQty where Qty  !=0
		Group by Item ,dbo.FormatDate(starttime,'YYYY/MM/DD')
	Insert into #ItemSummary
		select 'EXItem' AS AreaType,半制品 As Item,Plandate,Sum(cast(待收 As float)) As Qty
			from #InsertFromSP where 待收 !=0
			Group by 半制品,Plandate
--拆BOM
select b.Bom,b.Item,CAST(b.RateQty/m.Qty as float) as UnitQty 
	into #ParentSubItems
	from PRD_BomDet b,PRD_BomMstr m where b.Bom =m.Code
	and  b.StartDate<=@CurrentTime 
	and b.EndDate>@CurrentTime 
	and m.IsActive=1
Delete a from (Select *,ROW_NUMBER()over(partition by Bom,Item Order by UnitQty)As NONO from #ParentSubItems) a where a.NONO!=1
Create nonclustered index IX_BOM on #ParentSubItems(Bom)
Create nonclustered index IX_Item on #ParentSubItems(Item)
Select a.Bom ,a.Item,a.UnitQty,
	b.Bom BomLevel1,b.Item ItemLevel1,b.UnitQty UnitQtyLevel1,
	c.Bom BomLevel2,c.Item ItemLevel2,c.UnitQty UnitQtyLevel2,
	d.Bom BomLevel3,d.Item ItemLevel3,d.UnitQty UnitQtyLevel3,
	e.Bom BomLevel4,e.Item ItemLevel4,e.UnitQty UnitQtyLevel4,
	f.Bom BomLevel5,f.Item ItemLevel5,f.UnitQty UnitQtyLevel5
	into #BOMFlat from #ParentSubItems a 
	left join #ParentSubItems b on a.Item =b.Bom  
	left join #ParentSubItems c on b.Item =c.Bom 
	left join  #ParentSubItems d  on c.Item =d.Bom
	left join  #ParentSubItems e  on d.Item =e.Bom
	left join  #ParentSubItems f  on e.Item =f.Bom
	where  a.Bom in (Select Item from #ItemSummary where AreaType='EXItem')
Update #BOMFlat Set BomLevel1 = Bom,ItemLevel1=Item,UnitQtyLevel1=1 where BomLevel1 is null
Update #BOMFlat Set BomLevel2 = BomLevel1,ItemLevel2=ItemLevel1,UnitQtyLevel2=1 where BomLevel2 is null
Update #BOMFlat Set BomLevel3 = BomLevel2,ItemLevel3=ItemLevel2,UnitQtyLevel3=1 where BomLevel3 is null
Update #BOMFlat Set BomLevel4 = BomLevel3,ItemLevel4=ItemLevel3,UnitQtyLevel4=1 where BomLevel4 is null
Update #BOMFlat Set BomLevel5 = BomLevel4,ItemLevel5=ItemLevel4,UnitQtyLevel5=1 where BomLevel5 is null
Update #BOMFlat Set UnitQtyLevel5=UnitQtyLevel1*UnitQtyLevel2*UnitQtyLevel3*UnitQtyLevel4*UnitQtyLevel5
--Select * from #ParentSubItems
--Select * from #ItemSummary
--根据拆分的BOM直接算出最终的材料需求
--EX Part
--select * from #BOMFlat return
Select a.*,b.ItemLevel5 As LastItemLevel,a.Qty * b.UnitQtyLevel5 As LastItemLevelQty
	into #ItemUltiMateRequest
	from #ItemSummary a ,(Select distinct * from #BOMFlat)b
	Where a.Item =b.Bom and a.AreaType ='EXItem'
Insert into #ItemUltiMateRequest
	Select a.*,b.Item As LastItemLevel,a.Qty * b.UnitQty As LastItemLevelQty
		from #ItemSummary a ,#ParentSubItems b
		Where a.Item =b.Bom and a.AreaType ='FiItem'
--路线物料明细匹配需求 Select * from SCM_FlowMstr where Type =1   Select * from MD_ItemCategory  
Select a.Flow As 路线,Plandate ,a.Item As 材料 ,d.Desc1 As 材料描述,a.Uom As 材料单位,
	c.Qty  材料需求,a.SafeStock As 安全库存
	into #PurchaseRequest
	from SCM_FlowDet a,SCM_FlowMstr b ,#ItemUltiMateRequest c,MD_Item d---,MD_ItemCategory e
	where a.Flow = b.Code and a.Item =c.LastItemLevel
	and a.Item =d.Code /*and d.ItemCategory =e.Code and e.SubCategory =0*/ and b.IsActive=1
	and a.Item = case when isnull(@Item,'') ='' then a.Item else @Item End
	and d.ItemCategory = case when isnull(@ItemGroup,'') ='' then d.ItemCategory else @ItemGroup End
	and (a.StartDate<=@CurrentTime or a.StartDate is null) 
	and (a.EndDate>@CurrentTime or a.EndDate is null)
	and b.Type =1 and b.Code = case when isnull(@Flow,'') ='' then b.Code  else @Flow end
--实时库存
	Select Item,SUM(ATPQty) As 当前库存 into #CurrentInv 
		from VIEW_LocationDet as l inner join MD_Location as loc on l.Location = loc.Code 
        where loc.IsMrp = 1 and l.ATPQty>0 and Item in (
		select 材料 from #PurchaseRequest) 
        Group by Item
--Select * from #PurchaseRequest
Select a.*,isnull(b.当前库存,0)当前库存 into #Records  
	from #PurchaseRequest a left join #CurrentInv b on a.材料=b.Item
 --Select * from #Records
--return
--透视
	Create Table #tmp1 (Plandate varchar(20))
	Declare @i As int=0
	while @i <14
		Begin
			Insert into #tmp1
				Select dbo.FormatDate(dateadd(day,@i,GETDATE()),'YYYY/MM/DD')
			Set @i =@i + 1
		End
	Declare @SQL varchar(max)=''
	Declare @SQL1 varchar(max)=''
	SELECT @SQL=@SQL+'Isnull(['+dbo.FormatDate(plandate,'MM/DD')+'],0)'+' as ['+dbo.FormatDate(plandate,'MM/DD') +'],'
		,@SQL1=@SQL1+'['+dbo.FormatDate(plandate,'MM/DD') +'],'
	FROM #tmp1 ORDER BY PlanDate
	IF @SQL!=''
	BEGIN
		SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
		SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
	END
	--路线	采购日期	材料	材料描述	材料单位	材料需求	当前库存
	--30033-9101	2014/03/03	200029	碳黑 N990	KG	7344	16771.33100000
	Declare @SQLInterim varchar(max)=@SQL
	Set @SQL='SELECT 路线,材料,材料描述,安全库存,当前库存,'+@SQLInterim+' FROM (select * from #Records) as D  pivot(max(材料需求) for plandate in ('+@SQL1+')) as PVT order by 材料;'
	Print @SQL
	EXEC (@SQL)
--Select * from #Records
Drop table #PurchaseRequest
Drop table #ItemSummary
Drop table #ItemUltiMateRequest
Drop table #ParentSubItems
Drop table #BOMFlat

End