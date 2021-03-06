USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_AngingSearch]    Script Date: 12/08/2014 15:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_Report_AngingSearch]
(
	@Location varchar(80),
	@Item varchar(80),
	@LotNo varchar(80),
	@HuOption int ,
	@IsIncludeEmptyStock bit,
	@IsIncludeNoNeedAging bit
	--@PageSize int,
	--@Page intdbo.

)
AS
BEGIN
    SELECT @Location=LTRIM(RTRIM(@Location)),@Item=LTRIM(RTRIM(@Item)),@LotNo=LTRIM(RTRIM(@LotNo))
/*
exec [USP_Report_AngingSearch_1114] '9204','','','4','false','false'
500368184
*/
	SET NOCOUNT ON
	----00001  When the location bin contains "$" ,it means Hu is under status of aging.
	----00002  2013/12/23  Optimize the performance
	----00003  2013/12/23  老化查询新需求：需要区分冻结库存和非冻结库存、待验和合格库存等不同状态。考虑新增复选框还是新增列？
	----00001
	Declare @OriginalHuOption varchar(2)=@HuOption
	If @HuOption in (3)
		Begin
			Set @OriginalHuOption=''
		End	
	----00001
	If @HuOption=4
	Begin
		--/// 未老化
        --/// </summary>
        --UnAging = 1,
        --/// <summary>
        --/// 已老化
        --/// </summary>
        --Aged = 2,
        select distinct b.Item into #EXItems from SCM_FlowMstr a with(nolock),SCM_FlowDet b with(nolock) where a.Code=b.flow
			and a.ResourceGroup='20'
		select a.Item as Item,SPACE(100)/*b.itemdesc may be null*/ as ItemDesc ,SUM(a.Qty) as TotalQty,
			SUM(case when b.HuOption=0 and a.QualityType=0 and a.IsFreeze=0 and not(AgingStartTime is not null and AgingEndTime is null) then 1 else 0 end *a.Qty) as NoNeedAgingQty,
			SUM(case when b.HuOption=1 and a.QualityType=0 and a.IsFreeze=0 and not(AgingStartTime is not null and AgingEndTime is null) then 1 else 0 end *a.Qty) as UnAgingQty,
			SUM(case when b.HuOption=2 and a.QualityType=0 and a.IsFreeze=0 and not(AgingStartTime is not null and AgingEndTime is null) then 1 else 0 end *a.Qty) as AgedQty,
			SUM(case when (AgingStartTime is not null and AgingEndTime is null) and a.QualityType=0 and a.IsFreeze=0 then 1 else 0 end *a.Qty) as AgingQty,
			SUM(case when b.HuId is null and a.QualityType=0 and a.IsFreeze=0 then 1 else 0 end *a.Qty) as Qty,
			SUM((case when b.HuId is null then 0 else 1 end)*(case when a.IsFreeze=1 then 1 else 0 end) *a.Qty) as FreezedQty,
			SUM((case when b.HuId is null then 0 else 1 end)*(case when a.IsFreeze=0 then 1 else 0 end) *a.Qty) as NonFreezeQty,
			SUM((case when b.HuId is null then 0 else 1 end)*(case when a.QualityType=0 then 1 else 0 end) *a.Qty) as QulifiedQty,
			SUM((case when b.HuId is null then 0 else 1 end)*(case when a.QualityType=2 then 1 else 0 end) *a.Qty) as InspectQty,
			SUM((case when b.HuId is null then 0 else 1 end)*(case when a.QualityType=1 then 1 else 0 end) *a.Qty) as InQulifiedQty,
			null AgingStartTime,null AgingEndTime
			into #SumByLocation
			from VIEW_LocationLotDet a with(nolock) left join INV_Hu b with(nolock) 
			on a.HuId =b.HuId where a.Location =@Location and a.Item in (select * from #EXItems) and a.Item like isnull(@Item,'')+'%'
			group by a.Item
			select Code into #NeedAgingItem from MD_Item with(nolock) where ItemOption=1
			If @IsIncludeNoNeedAging='False'
			Begin
				Delete #SumByLocation where Item not in (select Code from #NeedAgingItem) and UnAgingQty=0 and AgedQty=0 and AgingQty=0--UnAgingQty!=0 and AgedQty!=0 and AgingQty!=0 and Qty!=0
			End
			Else
			Begin
				Delete #SumByLocation where TotalQty=0
			End
			----零库存
			If @IsIncludeEmptyStock='True' and isnull(@Location,'')!='' 
			Begin
				Insert into #SumByLocation
					select a.Code as Item,SPACE(100)/*b.itemdesc may be null*/ as ItemDesc,CAST(0 as decimal(18,2)) as TotalQty,CAST(0 as decimal(18,2)) as NoNeedAgingQty, 
						CAST(0 as decimal(18,2)) as UnAgingQty,CAST(0 as decimal(18,2)) as AgedQty,CAST(0 as decimal(18,2)) as AgingQty,
						CAST(0 as decimal(18,2)) as Qty,CAST(0 as decimal(18,2)) as FreezedQty,CAST(0 as decimal(18,2)) as NonFreezeQty,CAST(0 as decimal(18,2)) as QulifiedQty,
						CAST(0 as decimal(18,2)) as InspectQty,CAST(0 as decimal(18,2)) as InQulifiedQty, null AgingStartTime,null AgingEndTime from #NeedAgingItem a 
						where a.Code not in (select Item from #SumByLocation)
			End
			----
			update b
				set b.ItemDesc=a.Desc1 from MD_Item a with(nolock) , #SumByLocation b where a.Code =b.Item 
			Select COUNT(*) from #SumByLocation
			select Item, ItemDesc ,'' RefItemCode,'' Uom ,'' HuId,'' LotNo, 
				'' LocTo,CAST(0 as decimal(18,2)) As UC,GETDATE() as RemindExpireDate,GETDATE() as ExpireDate,'' as Location,
				CAST(0 As int) As RowID,''Bin,0 as IsFreeze,0 as QualityType,TotalQty,UnAgingQty,AgedQty,AgingQty,Qty,FreezedQty,NonFreezeQty,QulifiedQty,
				InspectQty,InQulifiedQty,NoNeedAgingQty,null AgingStartTime,null AgingEndTime,
				CAST(0 as decimal(18,2)) Qty0,CAST(0 as decimal(18,2)) Qty1,CAST(0 as decimal(18,2)) Qty2 from #SumByLocation
			Return
	End
	DECLARE @PagePara varchar(1000)=''
	select top 0 a.Item,a.ItemDesc ,a.RefItemCode,a.Uom ,a.HuId,a.LotNo,cast(a.Qty as decimal(18,2)) Qty,CAST(0 As int) As RowID,space(50)Bin,0 as IsFreeze,0 as QualityType,AgingStartTime,AgingEndTime into #TempResult from INV_Hu a where 1=2
	If isnull(@LotNo,'') =''
		Begin
			Insert into #TempResult 
			Select a.Item,a.ItemDesc ,a.RefItemCode,a.Uom ,a.HuId,a.LotNo,a.Qty ,
				ROW_NUMBER()over(order by a.item) As RowID,Bin ,IsFreeze,QualityType,AgingStartTime,AgingEndTime from INV_Hu a with(nolock),VIEW_LocationLotDet b with(nolock) where a.HuId =b.HuId 
				----00002
				And a.HuOption =case when  @OriginalHuOption='' then a.HuOption else @OriginalHuOption end  ---a.HuOption like cast(@OriginalHuOption as varchar)+'%'
				And b.Location =@Location and b.Item like isnull(@Item,'')+'%'
		print dbo.FormatDate(getdate(),'YYYYMMDDHHNNSS')
		End
	else
		Begin
			--Declare @ProddateNext datetime =dateadd (DAY,1,@Manufacturedate)
			Insert into #TempResult 
			Select a.Item,a.ItemDesc ,a.RefItemCode,a.Uom ,a.HuId,a.LotNo,a.Qty,
				ROW_NUMBER()over(order by a.item) As RowID,Bin ,IsFreeze,QualityType,AgingStartTime,AgingEndTime  from INV_Hu a with(nolock),VIEW_LocationLotDet b with(nolock) where a.HuId =b.HuId 
				----00002
				And a.HuOption =case when  @OriginalHuOption='' then a.HuOption else @OriginalHuOption end  ---a.HuOption like cast(@OriginalHuOption as varchar)+'%'
				And b.Location =@Location and b.Item like isnull(@Item,'')+'%' and  a.LotNo = @LotNo
		End
	--If @Page>0
	--	Begin
	--		SET @PagePara='WHERE rowid BETWEEN '+cast(@PageSize*(@Page-1) as varchar(50))+' AND '++cast(@PageSize*(@Page) as varchar(50))
	--	End
	----0001
	If @HuOption in (1,2)
		Begin
			Delete #TempResult where AgingStartTime is not null and AgingEndTime is null
		End
		Else
		Begin
			Delete #TempResult where not (AgingStartTime is not null and AgingEndTime is null)
		End
	----0001
	Select COUNT(*) from #TempResult
	Select *,'' LocTo,CAST(0 as decimal(18,2)) As UC,GETDATE() as RemindExpireDate,CAST(0 as decimal(18,2)) TotalQty,
		CAST(0 as decimal(18,2)) UnAgingQty,CAST(0 as decimal(18,2)) AgedQty,CAST(0 as decimal(18,2)) AgingQty,CAST(0 as decimal(18,2)) FreezedQty,
		CAST(0 as decimal(18,2)) NonFreezeQty,CAST(0 as decimal(18,2)) QulifiedQty,CAST(0 as decimal(18,2)) InspectQty,
		CAST(0 as decimal(18,2)) InQulifiedQty,CAST(0 as decimal(18,2)) NoNeedAgingQty,
		GETDATE() as ExpireDate,'' as Location,CAST(0 as decimal(18,2)) Qty0,CAST(0 as decimal(18,2)) Qty1,CAST(0 as decimal(18,2)) Qty2 from #TempResult
		--print 'start'
		--print dbo.FormatDate(getdate(),'YYYYMMDDHHNNSS')
	--SP_help 'inv_hu'
	--print 'select top('+cast(@PageSize as varchar(20))+') a.Item,a.ItemDesc ,a.RefItemCode,a.Uom ,a.HuId,a.LotNo,a.Qty  from #TempResult a '+@PagePara
	--exec('select top('+ @PageSize +') a.Item,a.ItemDesc ,a.RefItemCode,a.Uom ,a.HuId,a.LotNo,a.Qty  from #TempResult a '+@PagePara) 
 
END