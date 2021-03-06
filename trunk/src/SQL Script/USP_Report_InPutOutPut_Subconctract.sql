USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_InPutOutPut_Subconctract]    Script Date: 12/08/2014 15:17:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
--[USP_Report_InPutOutPut_FI] '30','FI21','2014-03-01 00:00','2014-03-14 00:00' ,1
-- =============================================
ALTER PROCEDURE [dbo].[USP_Report_InPutOutPut_Subconctract]
(
 @ResourceGroup varchar(50) ,
 @Flow varchar(50),
 @DateFrom varchar(50),
 @DateTo varchar(50),
 @SearchType varchar(50)
)
AS

--declare 
 --@ResourceGroup varchar(50)=20,
 --@Flow varchar(50)='FI11',
 --@DateFrom varchar(50)='2010-04-27 21:44:27.000',
 --@DateTo varchar(50)='2018-04-27 21:44:27.000'
----2014/03/14	配件线的投入产出算到主线上面  --0001
BEGIN
 SET NOCOUNT ON;
 ------基本信息,成品号FGItem
SELECT @ResourceGroup=LTRIM(RTRIM(@ResourceGroup)),@Flow=LTRIM(RTRIM(@Flow)),@DateFrom=LTRIM(RTRIM(@DateFrom)),@DateTo=LTRIM(RTRIM(@DateTo))
 If @Flow=''
	Begin
		Set @Flow=null
	End
Select c.LocFrom As 库位,a.FGItem as 成品,b.Desc1 as 成品描述,b.Uom as 成品单位,Cast(0 as int) as 产出数量 ,a.Item as 原材料,
	a.Itemdesc as 描述,a.Uom as 零件单位,Cast(0 as decimal(18,8)) as 理论用量, sum(-BFQty)as 实际用量
	into #INOUT_P
	from ord_orderbackflushdet a with(nolock) ,MD_Item b with(nolock),ord_ordermstr_4 c with(nolock) 
	where a.FGItem=b.code and a.OrderNo=c.OrderNo --and c.Subtype=0
	and c.EffDate between @DateFrom and @DateTo 
	----0001
	--and a.ProdLine = case when ISNULL(@Flow,'')='' then a.ProdLine else @Flow end 
	and a.ProdLine like ISNULL(@Flow,'')+'%'
	and a.isvoid='0'
	----XXXX
	and c.ResourceGroup =@ResourceGroup
	Group by c.LocFrom,a.FGItem,b.Desc1,b.Uom,a.Item,a.Itemdesc,a.Uom 
Update #INOUT_P Set 理论用量=实际用量
 -------车间盘点 SY05
 Select a.Location As 库位, b.Item as 原材料,sum(Qty) as 盘点数量 into #AuditInfro from ORD_MiscOrderMstr a,ORD_MiscOrderDet b 
	where a.MiscOrderNo =b.MiscOrderNo
	and a.SubType =50 
	and a.Status in (0,1)
	and a.EffDate between @DateFrom and Dateadd(day,1,@DateTo) 
	and a.Location in (select 库位 from #INOUT_P)
	----不需线别条件
	--and a.Flow = case when ISNULL(@Flow,'')='' then a.Flow else @Flow end
	Group by a.Location,b.Item


--Select @@ROWCOUNT as 未被使用的盘点材料
 -------每个材料对应的总用量
Select 库位,原材料,sum(实际用量) as 材料用量 into #材料用量 from #INOUT_P Group by 库位,原材料

Update a
Set a.实际用量= a.实际用量+isnull(c.盘点数量,0)*(a.实际用量/b.材料用量) from (select * from #INOUT_P where 成品 != '未被使用的盘点材料') a 
	left join #材料用量 b on a.原材料=b.原材料 and a.库位=b.库位 
	left join #AuditInfro c on a.原材料=c.原材料 and a.库位=c.库位 where b.材料用量!=0

 --Select * from #INOUT a left join #材料用量 b on a.原材料=b.原材料 
	--left join #AuditInfro c on a.原材料=c.原材料
 ------产出数量,可能有一个成品号对应几个产出的记录
 --Drop table #OUTPUT a.RecQty 包含了冲销部分
Select 成品,成品描述,成品单位,sum(产出数量) As 产出数量,原材料,描述,零件单位,sum(理论用量) As 理论用量,sum(实际用量) As 实际用量 
	into #INOUT from #INOUT_P
	Group by 成品,成品描述,成品单位,原材料,描述,零件单位
 -------盘点中的某颗料没有在任何的成品中使用要Show出来
 Insert into #INOUT
	Select '未被使用的盘点材料','','',0,原材料,b.desc1 as 描述,b.Uom as 零件单位,0 as 理论用量
	,a.盘点数量 as 实际用量 from #AuditInfro a,MD_Item b where a.原材料 not in 
	(select 原材料 from #INOUT_P)and a.原材料=b.Code
Select a.Item as 成品,sum( a.RecQty) as  产出数量 into #OUTPUT 
	from ORD_OrderDet_4 a with(nolock),ORD_OrderMstr_4 b
	where a.OrderNo =b.OrderNo  
	and b.EffDate between @DateFrom and @DateTo 
	--0001
	--and b.Flow = case when ISNULL(@Flow,'')='' then b.Flow else @Flow end
	and b.Flow like ISNULL(@Flow,'')+'%'
	and b.ResourceGroup =@ResourceGroup
	group by a.Item
 -------Update 产出数量,理论用量
Update a set a.产出数量=b.产出数量 from #INOUT a,#OUTPUT b where a.成品=b.成品
----返回结果集
if @SearchType ='1'--ByFG
	Begin
		Select a.*,case when 理论用量!=0 then cast(cast(100*(实际用量-理论用量)/理论用量 as decimal(10,2)) as varchar)+'%' else '' end as 偏差,b.MergeRow
			,cast(row_number()over(partition by a.成品 order by 原材料) as int) as SequencebyFG from #INOUT a ,(select 成品,cast(count(*)  as int) as MergeRow from #INOUT group by 成品) b where a.成品=b.成品 order by a.成品,SequencebyFG
	End
Else
	Begin
		----由材料推成品
		Select top 1000 a.原材料,a.描述,a.零件单位,a.产出数量,a.成品,a.成品描述,a.成品单位,a.理论用量,a.实际用量
			,case when 理论用量!=0 then cast(cast(100*(实际用量-理论用量)/理论用量 as decimal(10,2)) as varchar)+'%' else '' end as 偏差,b.MergeRow
			,cast(row_number()over(partition by a.原材料 order by 成品) as int) as SequencebyFG from #INOUT a ,(select 原材料,cast(count(*)  as int) as MergeRow from #INOUT group by 原材料) b where a.原材料=b.原材料 order by a.原材料,SequencebyFG
	END
END


