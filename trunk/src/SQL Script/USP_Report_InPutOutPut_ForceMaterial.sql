USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_InPutOutPut_ForceMaterial]    Script Date: 12/08/2014 15:16:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
--[USP_Report_InPutOutPut_ForceMaterial] 'O4EX0100000011','2013/9/16 0:00:00','2013/9/24 0:00:00'
-- =============================================
ALTER PROCEDURE [dbo].[USP_Report_InPutOutPut_ForceMaterial]
(
 @OrderNo varchar(50),
 @DateFrom datetime ,
 @DateTo datetime 
)
AS

--declare 
 --@OrderNo varchar(50),
 --@DateFrom varchar(50)='2010-04-27 21:44:27.000',
 --@DateTo varchar(50)='2018-04-27 21:44:27.000'
 
BEGIN
 SET NOCOUNT ON;
 --select OrderNo ,count(distinct FGItem ) from ord_orderbackflushdet where FGItem !=Bom 
 --group by OrderNo having count(distinct FGItem )>1
--select  prodlinefact,* from  ord_orderbackflushdet where prodlinefact is not null
--select  prodlinefact,* from  ord_orderbackflushdet where prodlinefact is not null
if isnull(@DateFrom,'')=''
	Begin
		select @DateFrom=dbo.MinimumDateValue(1) 
	End
if isnull(@DateTo,'')=''
	Begin
		 select @DateTo=dbo.MaximumDateValue(0) 
	End
Select a.OrderNo as 订单号,a.FGItem as 成品,b.Desc1 as 成品描述,b.Uom as 成品单位,Cast(0 as int) as 产出数量,
	a.Item as 原材料,a.Itemdesc as 描述,a.Uom as 零件单位, sum(BFQty)as 投入数量
	into #INOUT from ord_orderbackflushdet a with(nolock) ,MD_Item b with(nolock) where a.FGItem=b.code
	and (a.Createdate between @DateFrom and @DateTo  /*or a.Createdate like isnull(@OrderNo,'')+'%'*/) 
	and a.isvoid='0'  and  a.OrderNo like isnull(@OrderNo,'')+'%'
	and a.ProdLineFact='EXV'
	/*b.Desc1 like '%塞芯%' and*/ 
	Group by a.OrderNo ,a.FGItem,b.Desc1,b.Uom,a.Item,a.Itemdesc,a.Uom
If @@rowcount =0
	Begin
		Select 0 as tablecolumncount
		select 0 as rowcounts,0 as mergerows
		Select '所选择的查询条件，系统无数据，请重新选择!' As NG
		Return 
	End 
--select * from MD_Item where Desc1 like '%塞芯%'
 ------产出数量,可能有一个成品号对应几个产出的记录
 --Drop table #OUTPUT

Select a.OrderNo as 订单号,Item as 成品,sum( RecQty) as  产出数量 into #OUTPUT from ord_recdet_4 a with(nolock),ORD_OrderMstr_4 b with(nolock)
	where Item in (select 成品 from  #INOUT)  and b.ProdLineFact='EXV' and a.OrderNo=b.OrderNo group by a.OrderNo,Item
--select * from ord_recdet_4
 --Select * from #OUTPUT
 -------Update 产出数量,理论用量
Update a set a.产出数量=b.产出数量 from #INOUT a,#OUTPUT b where a.成品=b.成品  and a.订单号=b.订单号 
--Set up every column's min width
Select 8 as tablecolumncount
Select MergrRows,a.订单号,a.成品,成品描述,产出数量,原材料,描述 原材料描述,abs(cast(投入数量 as decimal(18,2))) 投入数量 from #INOUT a,
	(Select 订单号,成品,COUNT(*) MergrRows from #INOUT group by 订单号,成品) b 
	where a.订单号=b.订单号 and a.成品=b.成品
 --------Set up min width in SP 
Select 50,50,50,80,50,50,80,50

End