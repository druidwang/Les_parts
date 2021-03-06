USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_GetLotNoInventory]    Script Date: 12/08/2014 15:16:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
--[USP_Report_GetLotNoInventory] '',''
-- =============================================
ALTER PROCEDURE [dbo].[USP_Report_GetLotNoInventory]
(
 @Location varchar(50),
 @ItemFrom varchar(50),
 @ItemTo varchar(50),
 @SortType int
)
As
BEGIN
 SET NOCOUNT ON;
 --@SortType=1 Sort by item lotno bin 
 --@SortType=2 Sort by bin item lotno
 If isnull(@ItemFrom,'')='' and isnull(@ItemTo,'')=''
	 Begin
		Select  l.Location As 库位,loc.Name As 库位描述,isnull(l.Bin,'') As 库格,l.Item As 物料,i.Desc1+case when Isnull(RefCode,'')='' then '' else '['+RefCode+']' end As 物料描述,l.LotNo As 制造日期,
			Cast(l.HuQty As float) As 单包装,l.HuUom As 单位,
			Cast(Sum(l.HuQty * Case when l.QualityType=1 then 1 else 0 end) As float) As 待验数,
			Cast(Sum(l.HuQty * Case when l.QualityType=2 then 1 else 0 end) As float) As 不合格数,
			Cast(Sum(l.HuQty * Case when l.QualityType=0 then 1 else 0 end) As float) As 合格数,
			Cast(Sum(l.HuQty * Case when l.IsFreeze=1 then 1 else 0 end) As float) As 冻结数,
			Cast(Sum(l.HuQty * Case when l.OccupyType>0 then 1 else 0 end) As float) As 占用数,
			Cast(Sum(l.HuQty * Case when l.IsFreeze=0 and l.QualityType=0 and l.OccupyType=0 then 1 else 0 end) As float) As 可用数,
			Cast(Sum(l.HuQty * Case when l.IsFreeze=0 and l.QualityType=0 and l.OccupyType=0 then 1 else 0 end)/l.HuQty As float) As 可用箱数,
			Cast(Sum(l.HuQty)/l.HuQty As float) As 总箱数
			--,ISNULL(l.BinSeq,99999999) As BinSeq
			From VIEW_LocationLotDet l with(nolock)
			Join MD_Item i with(nolock) on l.Item = i.Code
			Join MD_Location loc with(nolock) on loc.Code = l.Location
			Where l.huid is not null and l.Location like ISNULL(@Location,'')+'%' ----and l.Item like ISNULL(@Item,'')+'%'
			Group by l.Location,loc.Name, l.Bin,l.Item,i.Desc1+case when Isnull(RefCode,'')='' then '' else '['+RefCode+']' end ,l.LotNo,l.HuQty,l.HuUom,l.BinSeq
			Order by Case when @SortType = 1 then l.Item else ISNULL(l.Bin,'ZZZZZZZZ') End,
			Case when @SortType = 1 then l.LotNo else l.Item End,
			Case when @SortType = 1 then ISNULL(l.Bin,'ZZZZZZZZ') else l.LotNo End
			--Order by CASE WHEN l.BinSeq IS NULL THEN 1 ELSE 0 END,l.BinSeq,case when @SortType = 1 then l.Bin else l.Item End,case when @SortType = 1 then l.Item else l.Bin End,LotNo
	 End
	 Else
	 Begin
		If ISNULL(@ItemFrom,'')='' Begin Set @ItemFrom=@ItemTo End
		If ISNULL(@ItemTo,'')='' Begin Set @ItemTo=@ItemFrom End
		Select  l.Location As 库位,loc.Name As 库位描述,isnull(l.Bin,'') As 库格,l.Item As 物料,i.Desc1+case when Isnull(i.RefCode,'')='' then '' else '['+i.RefCode+']' end As 物料描述 ,l.LotNo As 制造日期,
			Cast(l.HuQty As float) As 单包装,l.HuUom As 单位,
			Cast(Sum(l.HuQty * Case when l.QualityType=1 then 1 else 0 end) As float) As 待验数,
			Cast(Sum(l.HuQty * Case when l.QualityType=2 then 1 else 0 end) As float) As 不合格数,
			Cast(Sum(l.HuQty * Case when l.QualityType=0 then 1 else 0 end) As float) As 合格数,
			Cast(Sum(l.HuQty * Case when l.IsFreeze=1 then 1 else 0 end) As float) As 冻结数,
			Cast(Sum(l.HuQty * Case when l.OccupyType>0 then 1 else 0 end) As float) As 占用数,
			Cast(Sum(l.HuQty * Case when l.IsFreeze=0 and l.QualityType=0 and l.OccupyType=0 then 1 else 0 end) As float) As 可用数,
			Cast(Sum(l.HuQty * Case when l.IsFreeze=0 and l.QualityType=0 and l.OccupyType=0 then 1 else 0 end)/l.HuQty As float) As 可用箱数,
			Cast(Sum(l.HuQty)/l.HuQty As float) As 总箱数
			--,ISNULL(l.BinSeq,99999999) As BinSeq
			From VIEW_LocationLotDet l with(nolock)
			Join MD_Item i with(nolock) on l.Item = i.Code
			Join MD_Location loc with(nolock) on loc.Code = l.Location
			Where l.huid is not null and l.Location like ISNULL(@Location,'')+'%' and l.Item  between @ItemFrom and @ItemTo
			Group by l.Location,loc.Name,l.Bin,l.Item,i.Desc1+case when Isnull(RefCode,'')='' then '' else '['+RefCode+']' end ,l.LotNo,l.HuQty,l.HuUom,l.BinSeq
			Order by Case when @SortType = 1 then l.Item else ISNULL(l.Bin,'ZZZZZZZZ') End,
			Case when @SortType = 1 then l.LotNo else l.Item End,
			Case when @SortType = 1 then ISNULL(l.Bin,'ZZZZZZZZ') else l.LotNo End
			--Order by CASE WHEN l.BinSeq IS NULL THEN 1 ELSE 0 END,l.BinSeq,case when @SortType = 1 then l.Bin else l.Item End,case when @SortType = 1 then l.Item else l.Bin End,LotNo
	 End
END


