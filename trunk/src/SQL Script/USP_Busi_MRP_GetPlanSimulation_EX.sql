USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_GetPlanSimulation_EX]    Script Date: 12/08/2014 15:11:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_Busi_MRP_GetPlanSimulation_EX]
(
	@PlanVersion datetime
)
AS
BEGIN
	SET NOCOUNT ON;
	--EXEC [USP_Busi_MRP_GetPlanSimulation_EX] '2014-03-07 08:25:21'
	Declare @Flow varchar(50)
	Select @flow= left (@flow,case when CHARINDEX('[',@flow)=0 then LEN(@flow) else CHARINDEX('[',@flow)-1 end)
    Declare @SnapTime datetime 
    Declare @CurrentTime datetime =getdate()
    --这个变量很重要，算出当前的工作日，Example如果是18号，那么18号之前的算作已发已收的范畴
    Declare @CurrentPlandate varchar(20) = dbo.FormatDate(@CurrentTime,'YYYY/MM/DD')
    Declare @VersionPlandate date = dbo.FormatDate(@PlanVersion,'YYYY/MM/DD')
    If  dbo.FormatDate(@CurrentTime,'HHNNSS') between '000000' and '074500' 
		Begin
			Set @CurrentPlandate=dbo.FormatDate(dateadd(day,-1,@CurrentTime),'YYYY/MM/DD')
		End
	print @CurrentPlandate  
    --这个变量很重要,若果是已经过了早上九点则取 @CurrentPlandate 的9点的SnapInv,如果是7点45 To 9点则取RealTime Inv
    Declare @IsGetSnapInv char(1)='Y'
    If dbo.FormatDate(@CurrentTime,'HHNNSS') between '074500' and '090000'
		Begin
			Set @IsGetSnapInv='N'
		End
	Print @IsGetSnapInv
    select top 1 @SnapTime=SnapTime from MRP_MrpPlanMaster where PlanVersion = @PlanVersion
    print @SnapTime
    --select distinct Item into #Items from MRP_FlowDetail with(nolock) where SnapTime =@SnapTime and Flow =@Flow and StartDate <=@PlanVersion and EndDate >@PlanVersion
	Declare @StartDate varchar(50)
	--发
	select @StartDate=dbo.FormatDate(GETDATE(),'YYYY/MM/DD') 
	Create Table #InsertFromSP ( 生产线 varchar(20),断面 varchar(20), 断面描述 varchar(50),	半制品	varchar(20),半制品描述 varchar(50),	Plandate varchar(20), 当前库存 varchar(20),待收 varchar(20),待发 varchar(20) )
	
	Exec [USP_Busi_MRP_ExPlanTrack_BK] @planversion
	Insert into #InsertFromSP
		--不能嵌套调用存储，所以这里用全局表过度一下  2014/03/16
		Select * from ##EXTRACK
	--update #InsertFromSP Set 待发=10000 where 半制品='300850'
	Create Table #ShipQty(PlanDate Varchar(20),Item Varchar(20),Qty float)
	Insert into #ShipQty
		Select PlanDate+'B发' as PlanDate ,半制品, 待发 from #InsertFromSP
	--Select * from MRP_MrpFiPlan where PlanVersion ='2014/1/9 19:49:00' and ProductLine =@Flow
	Select distinct 半制品 Item into #Items from #InsertFromSP
	--Select * from #InsertFromSP where 半制品='300786'
	--Select * from #PlanInQty where Item='300786'
	--收
	-- 
	--Flow	OrderType	Item	StartTime	WindowTime	LocationFrom	LocationTo	Qty	Bom	SourceType	SourceParty
	CREATE TABLE #PlanInQty(PlanDate Varchar(20),Item Varchar(20),Qty float)
	Insert into  #ShipQty
		Select PlanDate+'A收' as PlanDate,半制品, 待收 from #InsertFromSP

	--Insert into  #ShipQty
	--	Select dbo.FormatDate(StartTime,'YYYY/MM/DD')+'A收',a.Item As 物料,sum(Qty) as Qty 
	--		from #PlanInQty a with(nolock)
	--		Group by a.Item,dbo.FormatDate(StartTime,'YYYY/MM/DD')+'A收'		
	Select Distinct SPACE(50) As 生产线,SPACE(50) As 断面,Item As 物料, 0 As 定额,b.Desc1 物料描述, cast(0 As decimal) As 期初库存,cast(0 As decimal) As 车间库存,cast(0 As decimal) As 仓库库存 into #StockConfigQty 
		from SCM_FlowDet a with(nolock),MD_Item b with(nolock) ,SCM_FlowMstr c with(nolock)
		where a.Item =b.Code and a.Item in (
		select Item from #Items) 
		and a.Flow =c.Code and c.ResourceGroup=20 and c.Type =4 and c.IsMRP =1
		and c.IsActive =1
		and MrpWeight >0 and (StartDate is null or StartDate< @CurrentTime)
		and (EndDate is null or EndDate> @CurrentTime)
		Group by Item,b.Desc1 
	
	--存
	/*
	select Item,SUM(ATPQty) As 期初库存 into #PrimaryInv 
		from VIEW_LocationDet as l inner join MD_Location as loc on l.Location = loc.Code 
        where loc.IsMrp = 1 and l.ATPQty>0 and Item in (
		select Item from #Items) 
        Group by Item*/
    --由取实时库存变为取快照库存,--取离当天9点最近的快照
	Create Table #PrimaryInv(Item varchar(50),期初库存 decimal,车间库存 decimal,仓库库存 decimal)
	 Insert into #PrimaryInv
		Select Item,SUM( case when Qty <0 then 0 else Qty end) As 期初库存,  
		SUM( case when Qty <0 then 0 else Qty end * case when left (location,2)='92' then 1 else 0 end ) As 车间库存,
		SUM( case when Qty <0 then 0 else Qty end * case when left (location,2)='92' then 0 else 1 end ) As 仓库库存
			from  dbo.GetInvBySnapTime_ByItemLoc ([dbo].[GetStartInvSnapTimeByDate](GETDATE()))
			Group by Item
	--补齐没有在库存快照中的物料
	Insert into #PrimaryInv
		Select distinct Item,0,0,0 from #Items where Item not in (select Item from #PrimaryInv)
    Update a
		Set a.期初库存 = b.期初库存,a.车间库存=b.车间库存,a.仓库库存=b.仓库库存 from #StockConfigQty a,#PrimaryInv b where a.物料 =b.Item
	Update a
		Set a.生产线=b.生产线,a.断面=b.断面 from #StockConfigQty a,#InsertFromSP b where a.物料 =b.半制品  
	--Insert into #ShipQty 
	--	Select Distinct Left(PlanDate,10)+'C存',Item,0 from #ShipQty where Left(PlanDate,10) not in (select Left(PlanDate,10) from #ShipQty where PlanDate like  '%C存')  
	Insert into #ShipQty 
		Select Distinct Left(PlanDate,10)+'A收',Item,0 from #ShipQty -- where Left(PlanDate,10) not in (select Left(PlanDate,10) from #ShipQty where PlanDate like  '%A收') 
	Insert into #ShipQty 
		Select Distinct Left(PlanDate,10)+'B发',Item,0 from #ShipQty  --where Left(PlanDate,10) not in (select Left(PlanDate,10) from #ShipQty where PlanDate like  '%B发') 
	--Insert into #ShipQty
	--2014/01/18 Begin
	--计算每一天的期末库存Begin

	--补齐即没有计划发也没有计划收的天Begin一共算16天的计划
	Declare @i int =1
	Declare @CheckDate varchar(20) 
	While @i<14
	Begin
		Set @CheckDate = dbo.FormatDate( dateadd(day,@i,@StartDate),'YYYY/MM/DD')
		If not exists(select 0 from #ShipQty where PlanDate like @CheckDate+'%')
			Begin
			    print @CheckDate
				Insert into #ShipQty
					Select top 1 @CheckDate+'A收',物料,0 from #StockConfigQty union
					Select top 1 @CheckDate+'B发',物料,0 from #StockConfigQty
			End
		Set @i=@i+1
	End
	--补齐所有天和物料通过笛卡尔乘积
	select distinct left(PlanDate,10)PlanDate into #AllPlanDate from #ShipQty
	select distinct 物料 into #AllItem from #StockConfigQty
	Insert into #ShipQty
		Select PlanDate+'A收',物料,0 from #AllItem, #AllPlanDate union
		Select PlanDate+'B发',物料,0 from #AllItem, #AllPlanDate
	--补齐即没有计划发也没有计划收的天End
	--2014/01/22 没有计划的物料的补齐,所有的天和缺失的料交叉排列
	--Insert into #ShipQty
	--	Select b.PlanDate+'A收',a.物料,0  from(Select * from #StockConfigQty where 物料 not in (select Item from #ShipQty)) a,(Select distinct left(plandate,10)plandate from #ShipQty) b 
	--	Union Select b.PlanDate+'B发',a.物料,0  from(Select * from #StockConfigQty where 物料 not in (select Item from #ShipQty)) a,(Select distinct left(plandate,10)plandate from #ShipQty) b 

	Select PlanDate ,Item,SUM(Qty) Qty into #ShipQtySum from #ShipQty Group by PlanDate ,Item
	Select Left(a.PlanDate,10)PlanDate,a.Item,a.Qty-b.Qty  As InvQty into #CalsulateEndInv 
		from #ShipQtySum a,#ShipQtySum b where Left(a.PlanDate,10)=Left(b.PlanDate,10)
		and a.Item=b.Item
		and a.PlanDate like '%A收'and b.PlanDate like '%B发'
	----更新未来的库存部分，在当天的库存上面根据收发差额来增加
   ;WITH SumData(PlanDate,Item,Seq,InvQty)
      AS
       (SELECT PlanDate,Item,Seq,InvQty FROM (SELECT *,ROW_NUMBER()OVER(PARTITION BY Item ORDER BY [PlanDate]) AS Seq FROM #CalsulateEndInv where left(PlanDate,10)>=@CurrentPlandate)A),
      ShowSum(Item,Seq,SumHistoryInvQty)
      AS(
		   SELECT A.Item,A.Seq,SUM(B.InvQty) AS SumHistoryInvQty FROM SumData A,SumData B
		   WHERE A.Item=B.Item AND B.Seq<=A.Seq GROUP BY A.Item,A.Seq
       )
	SELECT A.PlanDate,A.Item,B.SumHistoryInvQty into #UpdateInv FROM SumData A,ShowSum B WHERE A.Item=B.Item AND A.Seq=B.Seq ORDER BY A.Item ,A.PlanDate
	Update a
		Set a.SumHistoryInvQty = a.SumHistoryInvQty+b.期初库存 from #UpdateInv a,#PrimaryInv b where a.Item=b.Item 
	Insert into #ShipQty 
		Select PlanDate+'C存' ,Item,SumHistoryInvQty from #UpdateInv where LEFT(PlanDate,10)>=@CurrentPlandate/*
		>=@CurrentPlandate非常重要的一个条件,因为我把前面的收发变成了0，依据#ReceiveshpQty重新计算每天的期末库存*/
	--Select top 1000 * from #ShipQty
	--Select top 1000 * from #PlanInQty
	--透视
	Declare @SQL varchar(max)=''
	Declare @SQL1 varchar(max)=''
	SELECT DISTINCT PlanDate INTO #tmp1 FROM #ShipQty ORDER BY PlanDate
	SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),PlanDate)+'],0)'+' as ['+PlanDate +'],'
		,@SQL1=@SQL1+'['+PlanDate +'],'
	FROM #tmp1 ORDER BY PlanDate
	--为了拼接表头返回下面的值
	select 48 As totalcolumn ,6 As settledcolumn
	IF @SQL!=''
	BEGIN
		SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
		SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
	END
	Declare @SQLInterim varchar(max)=@SQL
	set @SQL='SELECT Item,'+@SQLInterim+' into #kk FROM (select * from #ShipQty) as D  pivot(sum(Qty) for PlanDate in ('+@SQL1+')) as PVT order by Item ;Select 生产线,物料, 物料描述, 期初库存,车间库存,仓库库存,'+@SQLInterim+' into #jj from #StockConfigQty a left join #kk b on a.物料=b.item order by a.生产线,a.断面,物料描述;Select * from #jj '
	Print @SQL
	EXEC (@SQL)
	--设置固定表头的列宽
	select 60,60,120,30,30,30
	Return
	--Select distinct item from #ShipQty
END
 



 
