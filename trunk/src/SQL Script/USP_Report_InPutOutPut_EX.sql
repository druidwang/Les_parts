USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_InPutOutPut_EX]    Script Date: 12/08/2014 15:16:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
--[USP_Report_InPutOutPut_EX]  '','','2014-09-01','2014-09-30 00:00' ,''
-- =============================================
ALTER PROCEDURE [dbo].[USP_Report_InPutOutPut_EX]
(
 @OrderNo varchar(50),
 @Flow varchar(50),
 @DateFrom varchar(50),
 @DateTo varchar(50),
 @SearchType varchar(50)
)
AS

--declare 
 --@OrderNo varchar(50)='O400001EX02',
 --@Flow varchar(50)='EX02',
 --@DateFrom varchar(50)='2010-04-27 21:44:27.000',
 --@DateTo varchar(50)='2018-04-27 21:44:27.000'
 
BEGIN
 SET NOCOUNT ON;
 SELECT @OrderNo=LTRIM(RTRIM(@OrderNo)),@Flow=LTRIM(RTRIM(@Flow)),@DateFrom=LTRIM(RTRIM(@DateFrom)),@DateTo=LTRIM(RTRIM(@DateTo))
--Declare @AllActualUsage decimal(18,8)
--Create table #SourceGroupLine (GroupLine varchar(50))
--------将传进来的@ResourceGroup转换为线别条件(现在已经取消ResourceGroup的条件，所以注释掉下面的取Line的代码
-- If isnull(@ResourceGroup,'')!=''
--	Begin
--		Insert into #SourceGroupLine
--			Select Distinct Code from SCM_FlowMstr with(nolock) where resourcegroup =@ResourceGroup
--	End
--基本信息,成品号FGItem 每个成品的投入=每个成品的正常投入+（每个成品的废品报工*每个成品的正常投入/总的正常投入）
Declare @LocFrom varchar(20)=''
Select @LocFrom=LocFrom from SCM_FlowMstr where Code =@Flow
Create Table #OrderNo(OrderNo varchar(50))
Insert into #OrderNo
	Select distinct a.OrderNo from ord_orderbackflushdet a,ord_ordermstr_4 c 
		where a.OrderNo=c.OrderNo and c.Subtype=0
		--当没有选择@OrderNo的时候将不限定查询时间的条件//现在已经没有生产单的查询条件 2013/12/26
		and a.Createdate between @DateFrom and @DateTo 
		and a.ProdLine like '%'+isnull(@Flow,'')+'%' and a.isvoid='0'
		--and a.OrderNO like '%'+isnull(@OrderNO,'')+'%'
		----XXXX
		and c.ResourceGroup =20 
Create index IX_OrderNo on #OrderNo(OrderNo)

Select a.FGItem as 成品,b.Desc1 as 成品描述,b.Uom as 成品单位,Cast(0 as int) as 产出数量 ,a.Item as 原材料,
	a.Itemdesc as 描述,a.Uom as 零件单位,Cast(0 as decimal(18,8)) as 理论用量, sum(BFQty)as 实际用量
	into #INOUT from ord_orderbackflushdet a with(nolock) ,MD_Item b with(nolock)
	where a.FGItem=b.code and a.OrderNo in (Select OrderNo from #OrderNo)
	----XXXX
	--and c.ResourceGroup =20
	Group by a.FGItem,b.Desc1,b.Uom,a.Item,a.Itemdesc,a.Uom 
Select a.Item as 原材料,sum(BFQty)as 实际报工用量 into #废品报工 from ord_orderbackflushdet a with(nolock) ,
	MD_Item b with(nolock),ord_ordermstr_4 c with(nolock)
	where a.FGItem=b.code and a.OrderNo=c.OrderNo and c.Subtype=40
	--and a.OrderNO like '%'+isnull(@OrderNO,'')+'%'
	--当没有选择@OrderNo的时候将不限定查询时间的条件
	and a.Createdate between @DateFrom and @DateTo 
	and a.ProdLine like '%'+isnull(@Flow,'')+'%' and a.isvoid='0'
	--and a.OrderNo in (Select OrderNo from #OrderNo)
	Group by a.Item
Select 原材料,sum(实际用量) as 实际用量 into #实际用量 from #INOUT Group by 原材料
Update a
	Set a.实际用量= a.实际用量+isnull(c.实际报工用量,0)*(a.实际用量/b.实际用量) from #INOUT a left join #实际用量 b on a.原材料=b.原材料 
	left join #废品报工 c on a.原材料=c.原材料 where b.实际用量!=0
 --产出数量:可能有一个成品号对应几个产出的记录
 --Drop table #OUTPUT
Select Item as 成品,sum( RecQty) as  产出数量 into #OUTPUT from ord_recdet_4 with(nolock)
	where Item in (select 成品 from  #INOUT) ---and Flow like '%EX%' 
	and OrderNo in (select OrderNo from #OrderNo)
	group by Item
 --Select * from #OUTPUT
 
 --理论用量:产品号取ord_orderdet_4里的Bom
 --Drop table #TheoryUsage
Select case when b.Bom is not null then b.Bom else a.Bom end as 成品,a.Item as 原材料,sum(a.OrderQty) as 理论用量 into #TheoryUsage 
	from ord_orderBomdet a with(nolock) left join ord_orderdet_4 b with(nolock) 
	on a.OrderDetId=b.Id --and a.bom=b.bom --and a.item=b.item 
	inner join  ORD_OrderMstr_4 c with(nolock) on b.OrderNo =c.OrderNo
	where Isnull(b.Bom,a.Bom) in (select distinct 成品 from  #INOUT) ---and a.OrderNo like '%EX%'
	and a.OrderNo in (select OrderNo from #OrderNo)
	group by case when b.Bom is not null then b.Bom else a.Bom end ,a.Item
 --select * from #TheoryUsage
 
 --Update 产出数量,理论用量
Update a set a.产出数量=b.产出数量 from #INOUT a,#OUTPUT b where a.成品=b.成品
Update a set a.理论用量=b.理论用量 from #INOUT a,#TheoryUsage b where a.成品=b.成品 and a.原材料=b.原材料

--处理没有实际用量但是有理论用量的材料
select * into #NoActualUsage from #TheoryUsage a 
	where not exists (select * from #INOUT b where a.成品=b.成品 and a.原材料=b.原材料)
	and exists (select * from #INOUT c where  a.成品=c.成品)
Insert into #INOUT
	Select distinct b.成品,b.成品描述,b.成品单位,b.产出数量,a.原材料,c.desc1 as 描述,c.Uom as 零件单位,a.理论用量,0 as 实际用量
		from #NoActualUsage a,#INOUT b,MD_Item c where a.成品=b.成品 and a.原材料=c.code
 --Select @@ROWCOUNT as 没有实际用量但是有理论用量
 
 --收集报废的部分用来更新产出的用量
 Select a.Item as 成品,sum(case when b.MoveType ='261' then -1 else 1 End* Qty) as 报废数量 into #MiscInfor from ORD_MiscOrderDet a ,ORD_MiscOrdermstr b 
	where a.MiscOrderNO=b.MiscOrderNO and b.CostCenter in ('212')
	and b.SubType =26
	and b.CloseDate between @DateFrom and @DateTo
	group by a.Item
 --Select 成品,sum(产出数量) as 材料用量 into #成品产出 from #INOUT Group by 成品
 --2014/10/29 废品报废暂时不更新成品
 --Update b Set b.产出数量=b.产出数量-a.报废数量 from #MiscInfor a,#INOUT b where a.成品=b.成品
 --
 --收集盘点 成本中心（213,214）用来更新投入的部分
Select b.Item as 原材料,sum(DiffQty) as 盘点数量 into #AuditInfro from INV_StockTakeMstr a, INV_StockTakeResult b 
where a.StNo =b.StNo  and Status =3 and b.DiffQty !=0
and a.CompleteDate between @DateFrom and @DateTo
and a.CostCenter in ('212')
and not(b.StQty =0 and b.InvQty <0)
group by b.Item

 --Show出盘点中的某颗料没有在任何的成品中使用
 Insert into #INOUT
	Select '未被使用的盘点材料','','',0,原材料,b.desc1 as 描述,b.Uom as 零件单位,0 as 理论用量
	,a.盘点数量 as 实际用量 from #AuditInfro a,MD_Item b where a.原材料 not in 
	(select 原材料 from #INOUT)and a.原材料=b.Code
	and a.原材料 not in (select 成品  from #INOUT)
--Select @@ROWCOUNT as 未被使用的盘点材料

 --每个材料分别对应的总用量
Select 原材料,sum(实际用量) as 材料用量 into #材料用量 from #INOUT Group by 原材料
Update a
	Set a.实际用量= abs(a.实际用量+isnull(c.盘点数量,0)*(a.实际用量/b.材料用量)) 
		from #INOUT a left join #材料用量 b on a.原材料=b.原材料 
		left join #AuditInfro c on a.原材料=c.原材料 where b.材料用量!=0
		and a.成品 !='未被使用的盘点材料'
 
Select a.*,case when 理论用量!=0 then cast(cast(100*(实际用量-理论用量)/理论用量 as decimal(10,2)) as varchar)+'%' else '' end as 偏差,b.MergeRow
	,cast(row_number()over(partition by a.成品 order by 原材料) as int) as SequencebyFG from #INOUT a ,
	(select 成品,cast(count(*)  as int) as MergeRow from #INOUT group by 成品) b 
	where a.成品=b.成品 order by a.成品,SequencebyFG
END


