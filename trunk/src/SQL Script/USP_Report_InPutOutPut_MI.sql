USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_InPutOutPut_MI]    Script Date: 12/08/2014 15:16:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
--[USP_Report_InPutOutPut_MI] '10','','2013-11-19 00:00','2013-11-27 00:00'
-- =============================================
ALTER PROCEDURE [dbo].[USP_Report_InPutOutPut_MI]
(
 @ResourceGroup varchar(50),
 @Flow varchar(50),
 @DateFrom varchar(50),
 @DateTo varchar(50),
 @SearchType varchar(50)
)
AS
--declare 
 --@ResourceGroup varchar(50)=10,
 --@Flow varchar(50)='MI01',
 --@DateFrom varchar(50)='2010-04-27 21:44:27.000',
 --@DateTo varchar(50)='2018-04-27 21:44:27.000'
Begin
 SET NOCOUNT ON;
SELECT @ResourceGroup=LTRIM(RTRIM(@ResourceGroup)),@Flow=LTRIM(RTRIM(@Flow)),@DateFrom=LTRIM(RTRIM(@DateFrom)),@DateTo=LTRIM(RTRIM(@DateTo))
--******炼胶生产将一直在同一条产线上进行.
--Declare @AllActualUsage decimal(18,8)
-- Create table #SourceGroupLine (GroupLine varchar(50))
--------将传进来的@ResourceGroup转换为线别条件(现在已经取消ResourceGroup的条件，所以注释掉下面的取Line的代码
-- If isnull(@ResourceGroup,'')!=''
--	Begin
--		Insert into #SourceGroupLine
--			Select Distinct Code from SCM_FlowMstr with(nolock) where resourcegroup =@ResourceGroup
--	End
 ------基本信息,成品号FGItem
If @Flow=''
	Begin
		Set @Flow=null
	End
Create Table #OrderNo(OrderNo varchar(50))
Insert into #OrderNo
	Select distinct a.OrderNo from ord_orderbackflushdet a,ord_ordermstr_4 c 
		where a.OrderNo=c.OrderNo and c.Createdate between @DateFrom and @DateTo
		and a.ProdLine like '%'+isnull(@Flow,'')+'%' and a.isvoid='0'
		----XXXX
		and c.ResourceGroup =@ResourceGroup 
Create index IX_OrderNo on #OrderNo(OrderNo)

Select a.FGItem as 成品,b.Desc1 as 成品描述,b.Uom as 成品单位,Cast(0 as int) as 产出数量 ,a.Item as 原材料,
	a.Itemdesc as 描述,a.Uom as 零件单位,Cast(0 as decimal(18,8)) as 理论用量, sum(BFQty)as 实际用量
	into #INOUT from ord_orderbackflushdet a with(nolock) ,MD_Item b with(nolock)--ord_ordermstr_4 c with(nolock)  
	where a.FGItem=b.code and OrderNo in (select OrderNo from #OrderNo)
	--and c.Createdate between @DateFrom and @DateTo and a.ProdLine like '%'+isnull(@Flow,'')+'%' and a.isvoid='0'
	------XXXX
	--and c.ResourceGroup =@ResourceGroup
	Group by a.FGItem,b.Desc1,b.Uom,a.Item,a.Itemdesc,a.Uom 

 ------产出数量,可能有一个成品号对应几个产出的记录
 --Drop table #OUTPUT
Select Item as 成品,sum( RecQty) as  产出数量 into #OUTPUT from ord_recdet_4 with(nolock)
	where OrderNo in (select OrderNo from #OrderNo) group by Item
 --Select * from #OUTPUT
 --select * from ord_recdet_4 where orderdetid  not in (select orderdetid from #IDBOMMap)
 -------理论用量 产品号取ord_orderdet_4里的Bom
 --Drop table #TheoryUsage
 --Drop table #TheoryUsage
 ----XXXX一个Order的OrderDet同一个成品可能有2个或多个记录，这里由原来的OrderNo Join变成 OderDetId Join
Select case when b.Bom is not null then b.Bom else a.Bom end as 成品,a.Item as 原材料,sum(a.OrderQty) as 理论用量 into #TheoryUsage 
	from ord_orderBomdet a with(nolock) left join ord_orderdet_4 b with(nolock)  on a.OrderDetId=b.Id-- and a.bom=b.bom --and a.item=b.item
	inner join  ORD_OrderMstr_4 c with(nolock) on b.OrderNo =c.OrderNo
	where a.Bom in (select distinct 成品 from  #INOUT)
	and a.OrderNo in (select * from #OrderNo)
	----XXXX
	and c.ResourceGroup =@ResourceGroup
	group by case when b.Bom is not null then b.Bom else a.Bom end ,a.Item
 --select * from #TheoryUsage
 -------Update 产出数量,理论用量
Update a set a.产出数量=b.产出数量 from #INOUT a,#OUTPUT b where a.成品=b.成品
Update a set a.理论用量=b.理论用量 from #INOUT a,#TheoryUsage b where a.成品=b.成品 and a.原材料=b.原材料
-----过滤部分的差量要从产出里面减掉(过滤过后数量增加了？？？)
select Itemfrom ,sum(qty-newqty) as diff into #filter from INV_ItemExchange 
	where itemexchangetype= 2 and Createdate between @DateFrom and @DateTo 
	and Itemfrom in (select 成品  from #INOUT)  group by ItemFrom
--select * from #filter
--select top 1000 qty,newqty,* from INV_ItemExchange
----XXXX暂时注释掉过滤的逻辑
--update b set b.产出数量=b.产出数量+a.diff from #filter a,#INOUT b where a.Itemfrom=b.成品
-----处理没有实际用量但是有理论用量的材料
select * into #NoActualUsage from #TheoryUsage a where not exists (select * from #INOUT b where a.成品=b.成品 and a.原材料=b.原材料)
	and exists (select * from #INOUT c where  a.成品=c.成品)
Insert into #INOUT
	Select distinct b.成品,b.成品描述,b.成品单位,b.产出数量,a.原材料,c.desc1 as 描述,c.Uom as 零件单位,a.理论用量,0 as 实际用量
		from #NoActualUsage a,#INOUT b,MD_Item c where a.成品=b.成品 and a.原材料=c.code
--Select @@ROWCOUNT as 没有实际用量但是有理论用量
 -------盘点 成本中心（213,214）
 Select b.Item as 原材料,sum(Qty) as 盘点数量 into #AuditInfro from  dbo.INV_StockTakemstr a with(nolock),INV_StockTakeDet b with(nolock) where a.stno=b.stno
	and a.Createdate between @DateFrom and @DateTo and a.CostCenter in ('213','214') group by b.Item
 -------盘点中的某颗料没有在任何的成品中使用要Show出来
 Insert into #INOUT
	Select '未被使用的盘点材料','','',0,原材料,b.desc1 as 描述,b.Uom as 零件单位,0 as 理论用量
	,a.盘点数量 as 实际用量 from #AuditInfro a,MD_Item b where a.原材料 not in 
	(select 原材料 from #INOUT)and a.原材料=b.Code
--Select @@ROWCOUNT as 未被使用的盘点材料
 -------每个材料对应的总用量
Select 原材料,sum(实际用量) as 材料用量 into #材料用量 from #INOUT Group by 原材料
	Update a
Set a.实际用量= abs(a.实际用量+isnull(c.盘点数量,0)*(a.实际用量/b.材料用量)) from #INOUT a left join #材料用量 b on a.原材料=b.原材料 
	left join #AuditInfro c on a.原材料=c.原材料 where b.材料用量!=0

 --Select * from #INOUT a left join #材料用量 b on a.原材料=b.原材料 
	--left join #AuditInfro c on a.原材料=c.原材料
 
Select a.*,case when 理论用量!=0 then cast(cast(100*(实际用量-理论用量)/理论用量 as decimal(10,2)) as varchar)+'%' else '' end as 偏差,b.MergeRow
	,cast(row_number()over(partition by a.成品 order by 原材料) as int) as SequencebyFG from #INOUT a ,(select 成品,cast(count(*)  as int) as MergeRow from #INOUT group by 成品) b where a.成品=b.成品 order by a.成品,SequencebyFG
End