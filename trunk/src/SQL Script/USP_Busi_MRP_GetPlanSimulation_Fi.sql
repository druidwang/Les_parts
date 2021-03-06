USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_GetPlanSimulation_Fi]    Script Date: 12/08/2014 15:11:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_Busi_MRP_GetPlanSimulation_Fi]
(
	@PlanVersion datetime,
	@Flow varchar(50)
)
AS
BEGIN
	SET NOCOUNT ON;
	----2014/01/25    同一副模具下的物料显示同一底色  ----0001
	--EXEC [USP_Busi_MRP_GetPlanSimulation_Bk] '2014-01-20 15:14:55','FI21'
	
    --var mrpFlowDetials = genericMgr.FindAll<MrpFlowDetail>
    --    ("from MrpFlowDetail where SnapTime =? and Flow = ? and StartDate<=? and EndDate>? ",
    --    new object[] { planMaster.SnapTime, flow, planVersion, planVersion });
	--Set @Flow = LEFT(@Flow,4)
	Select @flow= left (@flow,case when CHARINDEX('[',@flow)=0 then LEN(@flow) else CHARINDEX('[',@flow)-1 end)
    Declare @SnapTime datetime 
    Declare @CurrentTime datetime =getdate()
    --这个变量很重要，算出当前的工作日，Example如果是18号，那么18号之前的算作已发已收的范畴
    Declare @CurrentPlandate date = dbo.FormatDate(@CurrentTime,'YYYY/MM/DD')
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
    select distinct Item into #Items from MRP_FlowDetail with(nolock) where SnapTime =@SnapTime and Flow =@Flow and StartDate <=@PlanVersion and EndDate >@PlanVersion
	Declare @StartDate varchar(50)
	--发
	select @StartDate=dbo.FormatDate(@PlanVersion,'YYYY/MM/DD') 
	--select @StartDate=dbo.FormatDate(MIN(PlanDate),'YYYY/MM/DD') from MRP_MrpFiShiftPlan where PlanVersion=@PlanVersion
    SELECT @Flow=LTRIM(RTRIM(@Flow))
    --2014/01/13---计划发减去已经转成订单的数量
	Select dbo.FormatDate(PlanDate,'YYYY/MM/DD')+'B发'  as PlanDate,cast(s.Item As varchar(100))Item,Case when s.Qty-s.OrderQty >0 then s.Qty-s.OrderQty else 0 end as Qty into #ShipQty from MRP_MrpPlan s 
	where PlanDate >=@StartDate
	--Select * from MRP_MrpFiPlan where PlanVersion ='2014/1/9 19:49:00' and ProductLine =@Flow

	--Select * from #StockConfigQty
	--收
	-- 
	--Flow	OrderType	Item	StartTime	WindowTime	LocationFrom	LocationTo	Qty	Bom	SourceType	SourceParty
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
	Insert into  #PlanInQty
		Exec USP_Busi_MRP_GetPlanIn @planversion,@flow
	Insert into  #ShipQty
		Select dbo.FormatDate(StartTime,'YYYY/MM/DD')+'A收',a.Item As 物料,sum(Qty) as Qty 
			from #PlanInQty a with(nolock)
			Group by a.Item,dbo.FormatDate(StartTime,'YYYY/MM/DD')+'A收'
			
	Select SPACE(200) As 岛区描述, Item As 物料,space(50) 模具,0 As 定额,b.Desc1 物料描述,round(cast(sum(a.SafeStock) as float),0) As 安全库存,round(cast(sum(a.MaxStock) as float),0) As 最大库存,cast(0 As decimal) As 期初库存 into #StockConfigQty 
		from SCM_FlowDet a with(nolock),MD_Item b with(nolock) ,SCM_FlowMstr c with(nolock)
		where a.Item =b.Code and a.Item in (
		select Item from #Items) 
		and a.Flow =c.Code /*and c.ResourceGroup=30*/ and c.IsMRP =1
		and MrpWeight >0 and (StartDate is null or StartDate< @CurrentTime)
		and (EndDate is null or EndDate> @CurrentTime)
		Group by Item,b.Desc1--,Machine
	
	Update a
		Set 模具=b.Machine from #StockConfigQty a, SCM_FlowDet b with(nolock) where a.物料=b.Item and b.Flow=@Flow
	Update a
		Set a.岛区描述 = c.Desc1 from #StockConfigQty a with(nolock) , MRP_Machine b , MRP_Island c  with(nolock) where a.模具 =b.Code and b.Island=c.Code
 
	UPdate a
		Set a.定额=b.ShiftQuota from #StockConfigQty a, MRP_Machine b with(nolock)  where a.模具 =b.Code
	--存
	/*
	select Item,SUM(ATPQty) As 期初库存 into #PrimaryInv 
		from VIEW_LocationDet as l inner join MD_Location as loc on l.Location = loc.Code 
        where loc.IsMrp = 1 and l.ATPQty>0 and Item in (
		select Item from #Items) 
        Group by Item*/
    --由取实时库存变为取快照库存,--取离当天9点最近的快照
	Create Table #PrimaryInv(Item varchar(50),期初库存 decimal)
	 Insert into #PrimaryInv
		Select * from  dbo.GetInvBySnapTime ([dbo].[GetStartInvSnapTimeByDate](GETDATE()))
	--补齐没有在库存快照中的物料
	Insert into #PrimaryInv
		Select distinct Item,0 from #Items where Item not in (select Item from #PrimaryInv)
    Update a
		Set a.期初库存 = b.期初库存 from #StockConfigQty a,#PrimaryInv b where a.物料 =b.Item
	--Insert into #ShipQty 
	--	Select Distinct Left(PlanDate,10)+'C存',Item,0 from #ShipQty where Left(PlanDate,10) not in (select Left(PlanDate,10) from #ShipQty where PlanDate like  '%C存')  
	Insert into #ShipQty 
		Select Distinct Left(PlanDate,10)+'A收',Item,0 from #ShipQty -- where Left(PlanDate,10) not in (select Left(PlanDate,10) from #ShipQty where PlanDate like  '%A收') 
	Insert into #ShipQty 
		Select Distinct Left(PlanDate,10)+'B发',Item,0 from #ShipQty  --where Left(PlanDate,10) not in (select Left(PlanDate,10) from #ShipQty where PlanDate like  '%B发') 
	--Insert into #ShipQty
	--2014/01/18 Begin
	--取得已收已发
	Create Table #RecedShippedQty(PlanDate varchar(20),Item varchar(50),PlanRecQty float,PlanShipQty float,ReceivedQty float,ShippedQty float)
	If @CurrentPlandate>@VersionPlandate
	Begin
		Insert into #RecedShippedQty
			Exec [USP_Busi_MRP_GetFinishedPlanInOut] @planversion,@flow
		Update #ShipQty Set Qty =0 where Left(PlanDate,10)<@CurrentPlandate 
		Insert into #ShipQty
			Select Distinct Left(PlanDate,10)+'A收',Item,ReceivedQty from #RecedShippedQty
		Insert into #ShipQty
			Select Distinct Left(PlanDate,10)+'B发',Item,ShippedQty from #RecedShippedQty
		--select * from #RecedShippedQty
	End
	--计算每一天的期末库存Begin

	--补齐即没有计划发也没有计划收的天Begin一共算16天的计划
	Declare @i int =1
	Declare @CheckDate varchar(20) 
	While @i<16
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
	--历史的期末库存倒着减
	select distinct PlanDate into #HisPlanDate from #CalsulateEndInv where PlanDate <@CurrentPlandate
	Select a.PlanDate PlanDate1,b.PlanDate PlanDate2 into #UpdatePlanDate from 
		(select PlanDate,ROW_NUMBER()Over(order by PlanDate )As NONO from #HisPlanDate) a,
		(select PlanDate,ROW_NUMBER()Over(order by PlanDate Desc )As NONO from #HisPlanDate) b where a.NONO =b.NONO
	--UPdate a
	--	Set  a.PlanDate=b.PlanDate2 from #CalsulateEndInv a,#UpdatePlanDate b where a.PlanDate=b.PlanDate1
	--select * from #HisPlanDate
	--select * from #ShipQty where LEFT(PlanDate,10) in (select *from #HisPlanDate)
	--Select * from #CalsulateEndInv
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
	--更新已发生的库存部分，在当天的库存上面根据已发生的收发差额来递减
	--select * from #RecedShippedQty
	--select * from #ShipQty
	--select * from #CalsulateEndInv
	select PlanDate,Item,SUM(ReceivedQty-ShippedQty) As InvQty into #CalsulateEndInvOfHis from  #RecedShippedQty
		Group by PlanDate,Item
	--补齐使每个料每一天都有一个C存
	Insert into #CalsulateEndInvOfHis
		Select PlanDate1,b.物料 As Item,0 As Qty from #UpdatePlanDate a,#AllItem b where not exists(select 0 from  #CalsulateEndInvOfHis c where a.PlanDate1=c.PlanDate and b.物料=c.Item)
	--时间倒过来
	UPdate a
		Set  a.PlanDate=b.PlanDate2 from #CalsulateEndInvOfHis a,#UpdatePlanDate b where a.PlanDate=b.PlanDate1
	;WITH SumData(PlanDate,Item,Seq,InvQty)
		  AS
		   (SELECT PlanDate,Item,Seq,InvQty FROM (SELECT *,ROW_NUMBER()OVER(PARTITION BY Item ORDER BY [PlanDate]) AS Seq FROM #CalsulateEndInvOfHis)A),
		  ShowSum(Item,Seq,SumHistoryInvQty)
		  AS(
			   SELECT A.Item,A.Seq,SUM(B.InvQty) AS SumHistoryInvQty FROM SumData A,SumData B
			   WHERE A.Item=B.Item AND B.Seq<=A.Seq GROUP BY A.Item,A.Seq
		   )
		SELECT A.PlanDate,A.Item,B.SumHistoryInvQty into #UpdateInvOfHis FROM SumData A,ShowSum B WHERE A.Item=B.Item AND A.Seq=B.Seq ORDER BY A.Item ,A.PlanDate
		--时间反倒回来，回到最初正确的日期
		UPdate a
			Set  a.PlanDate=b.PlanDate1 from #CalsulateEndInvOfHis a,#UpdatePlanDate b where a.PlanDate=b.PlanDate2
		UPdate a
			Set  a.PlanDate=b.PlanDate1 from #UpdateInvOfHis a,#UpdatePlanDate b where a.PlanDate=b.PlanDate2
		Update a
			Set a.SumHistoryInvQty = b.期初库存-a.SumHistoryInvQty from #UpdateInvOfHis a,#PrimaryInv b where a.Item=b.Item 
		Insert into #ShipQty 
			Select PlanDate+'C存' ,Item,SumHistoryInvQty from #UpdateInvOfHis 
		--因为把当天的库存给减掉了，所以这里各自各自己补上
		update a
			Set a.Qty =a.Qty + (b.ReceivedQty-b.ShippedQty)/*别忘了减掉发的部分*/ from #ShipQty a,#RecedShippedQty b 
			where a.PlanDate like '%存%' and LEFT(a.PlanDate,10)=b.PlanDate 
			and a.Item=b.Item and b.PlanDate <@CurrentPlandate
		--Insert into #ShipQty
		--	select PlanDate+'A收',Item,ReceivedQty from  #RecedShippedQty
		--Insert into #ShipQty
		--	select PlanDate+'B发',Item,ShippedQty from  #RecedShippedQty
		--select * from #UpdatePlanDate
		--select * from #CalsulateEndInvOfHis  
		--select * from #RecedShippedQty where   Item ='501943'
	--return
	--计算每一天的期末库存End
	--If @IsGetSnapInv ='Y'
	--	Begin
	--	Declare @StartDateTime datetime  = dbo.Format_To_Date(dbo.FormatDate(@StartDate,'YYYYMMDD')+'000000')
	--	select distinct snaptime into #snaptime from MRP_InventoryBalance where snaptime > @StartDateTime
	--	select*from MRP_InventoryBalance where snaptime>DATEADD(DAY,-3,GETDATE())
	--	Select * from #snaptimea where SnapTime in  (select  snaptime,min(abs(DATEDIFF(MINUTE,dbo.FormatDate(snaptime,'YYYY-MM-DD 09:00:00'),snaptime))) AS timegap from #snaptime)
	--	Select dbo.FormatDate(snaptime,'YYYY-MM-DD')+'C存'  As plandate, from MRP_InventoryBalance where 
	--	print 'Get SnapInv'
	--	End
	--2014/01/18 End
	--select * from SCM_FlowDet where Item ='501238'--457
	--透视
	Declare @SQL varchar(max)=''
	Declare @SQL1 varchar(max)=''
	SELECT DISTINCT PlanDate INTO #tmp1 FROM #ShipQty ORDER BY PlanDate
	SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),PlanDate)+'],0)'+' as ['+PlanDate +'],'
		,@SQL1=@SQL1+'['+PlanDate +'],'
	FROM #tmp1 ORDER BY PlanDate
	IF @SQL!=''
	BEGIN
		SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
		SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
	END
	Declare @SQLInterim varchar(max)=@SQL
	--拼接Update C存的字符
	  --if (currentQty < 0)
	  --  {
	  --      str.Append("<td class =\"WarningColor_Red\">");
	  --  }
	  --  else if (currentQty < inventoryBalance.SafeStock)
	  --  {
	  --      str.Append("<td class =\"WarningColor_Orange\">");
	  --  }
	  --  else if (currentQty > inventoryBalance.MaxStock && inventoryBalance.MaxStock > 0)
	  --  {
	  --      str.Append("<td class =\"WarningColor_Yellow\">");
	  --  }
	----@InsertINVIndex to determine which position should INV infor be inserted
	--select @startDate,@CurrentPlandate
	Declare @InsertINVIndex int =0;Set @InsertINVIndex=DATEDIFF(day,@startDate,@CurrentPlandate)
	print 'AAA'+cast(@InsertINVIndex as varchar)
	Declare @SQLHTML varchar(max)=''
	Declare @SQLHTMLRow varchar(max)=''
	Declare @BaseDailyFied varchar(max)='<td>''+cast([2014/01/17A收] as varchar)+''</td><td>''+cast([2014/01/17B发] as varchar)+Case when [2014/01/17C存]<0 then ''<td class =\"WarningColor_Red\">'' when [2014/01/17C存]<安全库存 then ''<td class =\"WarningColor_Orange\">'' when [2014/01/17C存]>最大库存 and 安全库存>0 then ''<td class =\"WarningColor_Yellow\">'' else ''<td>'' end+cast([2014/01/17C存]as varchar)+''</td>'
	--SELECT @SQLHTML=物料, 物料描述, 安全库存, 最大库存, 期初库存,',Case when 安全库存<0 then <td class =\"WarningColor_Orange\">'
	--	when [2014/01/17A存]<安全库存 then '<td class =\"WarningColor_Orange\">' 
	--	when [2014/01/17A存]>最大库存 and 安全库存>0 then '<td class =\"WarningColor_Yellow\"> else '<td>'+[2014/01/17A存]+<>
	Set @i = 0
	Set @SQLHTMLRow='''<tr><td>''+cast(物料 as varchar)+''</td><td>''+cast(物料描述 as varchar)+''</td><td>''+cast(定额 as varchar)+''</td>'--+cast(round(安全库存,1) as varchar)+''</td><td>''+cast(round(最大库存,0) as varchar)+''</td><td>''+cast(期初库存 as varchar)+''</td>'
	Declare @HeadHtml varchar(max)=''
	Set @HeadHtml='<table cellpadding="0" cellspacing="0" border="0" class="display" id="datatable" width="100%"><tr><th rowspan="2" style="text-align:center" >物料号</th><th rowspan="2" style="text-align:center;min-width:150px" >物料描述</th><th rowspan="2" style="text-align:center" >定额</th>'--<th colspan="3" style="text-align:center" >库存</th>
	Set @HeadHtml = @HeadHtml +'<th colspan="3" style="text-align:center" >'
	--select 'BBB',@HeadHtml
	While @i<17
	Begin
		if @i =@InsertINVIndex
			Begin
				Set @SQLHTMLRow=@SQLHTMLRow
				Set @HeadHtml= @HeadHtml + '库存</th><th colspan="3" style="text-align:center" >'
				Set @SQLHTMLRow=@SQLHTMLRow+'<td>''+cast(round(安全库存,1) as varchar)+''</td><td>''+cast(round(最大库存,0) as varchar)+''</td><td>''+cast(期初库存 as varchar)+''</td>'
			End
		Set @CheckDate = dbo.FormatDate( dateadd(day,@i,@StartDate),'YYYY/MM/DD')
		select @SQLHTMLRow=@SQLHTMLRow+ REPLACE(@BaseDailyFied,'[2014/01/17','['+@CheckDate) where @i!=16
		--if @SQLHTMLRow like '%+%'

		Set @HeadHtml = @HeadHtml + case when @i=16 then '</th></tr>' else REPLACE(right(@CheckDate,5),'/','-')+case when @i in(15,16) then '' else'</th><th colspan="3" style="text-align:center" >'End End
		Set @i=@i+1
	End
	--select 'CCC',@HeadHtml,@InsertINVIndex
	Set @HeadHtml=@HeadHtml+'<tr>'--<th style="text-align:center;min-width:30px" >安全</th><th style="text-align:center;min-width:30px" >最大</th><th style="text-align:center;min-width:30px" >期初</th>'
	Set @i=1
	while @i <17
	Begin
	    if  @i-1 =@InsertINVIndex
			Begin
				Set @HeadHtml= @HeadHtml + '<th style="text-align:center;min-width:30px" >安全</th><th style="text-align:center;min-width:30px" >最大</th><th style="text-align:center;min-width:30px" >期初</th>'
			--select 'DDD',@HeadHtml
			End
		Set @HeadHtml=@HeadHtml+'<th style="text-align:center" >收</th><th style="text-align:center" >发</th><th style="text-align:center" >存</th>'
		Set @i=@i+1
	End
	Set @HeadHtml =@HeadHtml+'</tr>'

	Set @SQLHTMLRow=@SQLHTMLRow+'</tr>'''
	--select 'AAAA',@HeadHtml
	print @HeadHtml --return
	print @SQLHTMLRow  ----return
	Create table #RowHTML(Seq int,MachineGroup int,Row varchar(max))
	--2014/01/15  Dense Rank to group same machine ----0001
	Set @SQLHTMLRow = 'Insert into #RowHTML Select dense_rank()over(order by 岛区描述) As seq,dense_rank()over(order by 岛区描述,模具) As MachineGroup,'+@SQLHTMLRow +' As HmtlStr from #jj '
	--Begin
	--SELECT @SQLHTMLRow 
	set @SQL='SELECT Item,'+@SQLInterim+' into #kk FROM (select * from #ShipQty) as D  pivot(sum(Qty) for PlanDate in ('+@SQL1+')) as PVT order by Item ;Select 物料,岛区描述,模具,定额, 物料描述, 安全库存, 最大库存, 期初库存,'+@SQLInterim+' into #jj from #StockConfigQty a left join #kk b on a.物料=b.item order by 岛区描述; ' +@SQLHTMLRow
	Print @SQL
	EXEC (@SQL)
	Update #RowHTML Set Row=REPLACE(Row,'<tr><td>','<tr class=\"t-alt\"><td>')where MachineGroup%2 = 1
	Declare @IPingJieHTML varchar(max)=''
	select  @IPingJieHTML=@IPingJieHTML+ Row from #RowHTML

	select @HeadHtml+@IPingJieHTML+'</table>'
 
	Return
	--Select distinct item from #ShipQty
END
 



 
