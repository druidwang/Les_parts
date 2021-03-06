USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_IPInv]    Script Date: 12/08/2014 15:17:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
--[USP_Report_IPInv] '','','501199','','',2
--[USP_Report_IPInv] '','','200000','200019'
-- =============================================
ALTER PROCEDURE [dbo].[USP_Report_IPInv]
(
 @LocationFrom varchar(50),
 @LocationTo varchar(50),
 @ItemFrom varchar(50),
 @ItemTo varchar(50),
 @Flow varchar(50),
 @IpReportType int
 
)
AS
--declare 
 --@LocationFrom varchar(50),
 --@LocationTo varchar(50),
 --@ItemFrom varchar(50),
 --@ItemTo varchar(50)
 
 
BEGIN
 SET NOCOUNT ON;

--库存质量状态
--    Qualified = 0,   //正常
--    Inspect = 1,  //待验
--    Reject = 2,    //不合格品
-------Process search condition when the para is null or empty
SELECT @LocationFrom=LTRIM(RTRIM(@LocationFrom)),@LocationTo=LTRIM(RTRIM(@LocationTo)),@ItemFrom=LTRIM(RTRIM(@ItemFrom)),@ItemTo=LTRIM(RTRIM(@ItemTo))
Select top 0 * into #IpReportStatistic from ORD_IpDet_2 a with(nolock)
Declare @statement nvarchar(1000)='Select * from ORD_IpDet_'+cast(@IpReportType as varchar)+' a with(nolock) where a.IsClose =0 and ABS(Qty)>ABS(RecQty) '
--Declare @statement1 nvarchar(1000)='Union All Select * from ORD_IpDet_7 a with(nolock) where a.IsClose =0 and ABS(Qty)>ABS(RecQty) '
Declare @Parameter nvarchar(1000)=''
Declare @SearchCondition nvarchar(1000)=''
If isnull (@LocationTo,'')=''
	Begin
		Set @LocationFrom='%'+isnull (@LocationFrom,'')+'%'
		Set @SearchCondition= @SearchCondition+ 'And a.LocTo like @LocationFrom_1 '
	End
Else
	Begin
		Set @SearchCondition= @SearchCondition+ 'And a.LocTo Between @LocationFrom_1 and @LocationTo_1 '
	End
If isnull (@ItemTo,'')=''
	Begin
		Set @ItemFrom='%'+isnull (@ItemFrom,'')+'%'
		Set @SearchCondition= @SearchCondition+ 'And a.Item like @ItemFrom_1 '
	End
Else
	Begin
		Set @SearchCondition= @SearchCondition+ 'And a.Item Between @ItemFrom_1 and @ItemTo_1 '
	End

If isnull (@Flow,'')!=''
	Begin
		Set @Flow='%'+isnull (@Flow,'')+'%'
		Set @SearchCondition= @SearchCondition+ 'And a.Flow like @Flow_1 '
	End

Set @statement=@statement+@SearchCondition--+@statement1+@SearchCondition
	
Set @Parameter=N' @LocationFrom_1 varchar(50),@LocationTo_1 varchar(50),@ItemFrom_1 varchar(50),@ItemTo_1 varchar(50),@Flow_1 varchar(50)'
--Select @Statement ,@Parameter
Insert into #IpReportStatistic
	EXEC SP_EXECUTESQL @Statement,@Parameter,
	@LocationFrom_1=@LocationFrom,@LocationTo_1=@LocationTo,@ItemFrom_1=@ItemFrom,@ItemTo_1=@ItemTo,@Flow_1=@Flow
-------
select a.Code as 物料,b.Code 物料组,b.Desc1 物料组描述 into #ItemCategory from MD_Item a with(nolock) , 
	MD_ItemCategory b with(nolock) where a.MaterialsGroup =b.Code 
	and b.SubCategory=5 and a.Code in (select Item from #IpReportStatistic)
Select Item As 代码, ItemDesc + case when Isnull(RefItemCode,'')='' then '' else '['+RefItemCode+']' end As 描述,ISNULL(b.物料组,'') 物料组,ISNULL(b.物料组描述,'')物料组描述, 
	BaseUom As 单位,Flow as 路线,LocFrom As 来源库位,LocTo As 目的库位,
	--cast(sum((Qty - RecQty)*UnitQty*Case when QualityType=1 then 1 else 0 end)As float) As 待检,
	cast(sum((Qty - RecQty)*UnitQty*Case when QualityType=2 then 1 else 0 end)As float) As 不合格,
	cast(sum((Qty - RecQty)*UnitQty*Case when QualityType=0 then 1 else 0 end)As float) As 合格,
	cast(sum((Qty - RecQty)*UnitQty)As float) As 总数 from #IpReportStatistic a left join #ItemCategory b
	on a.Item=b.物料 Group by Item, ItemDesc + case when Isnull(RefItemCode,'')='' then '' else '['+RefItemCode+']' end, BaseUom ,LocFrom,LocTo,Flow,物料组,物料组描述
--Select QualityType,* from #IpReportStatistic where item='200015' and locto='9201'and locfrom='9101'

END




