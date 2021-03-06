USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_GetPlanSimulation]    Script Date: 12/08/2014 15:10:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		wenxiangyong
-- Create date: 20140113
-- Description:	GetPlanOf 待收,待发
-- =============================================
ALTER PROCEDURE [dbo].[USP_Busi_MRP_GetPlanSimulation]
(
	@PlanVersion datetime,
	@Flow varchar(50)
)
AS
BEGIN
	SET NOCOUNT ON;
	--EXEC [USP_Busi_MRP_GetPlanSimulation] '2014-01-17 09:48:57','FI21'
	
    --var mrpFlowDetials = genericMgr.FindAll<MrpFlowDetail>
    --    ("from MrpFlowDetail where SnapTime =? and Flow = ? and StartDate<=? and EndDate>? ",
    --    new object[] { planMaster.SnapTime, flow, planVersion, planVersion });
	Set @Flow = LEFT(@Flow,4)
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
	select @StartDate=dbo.FormatDate(MIN(PlanDate),'YYYY/MM/DD') from MRP_MrpFiShiftPlan where PlanVersion=@PlanVersion
    SELECT @Flow=LTRIM(RTRIM(@Flow))
	Select dbo.FormatDate(StartTime,'YYYY/MM/DD')+'B发'  as PlanDate,cast(s.Item As varchar(100))Item,SUM(s.Qty) as Qty into #ShipQty from MRP_MrpShipPlan s 
		where s.PlanVersion =@PlanVersion and s.Flow = @Flow and (SourceFlow!=@Flow)
		group by dbo.FormatDate(StartTime,'YYYY/MM/DD')+'B发' ,Item 
	--Select * from MRP_MrpFiPlan where PlanVersion ='2014/1/9 19:49:00' and ProductLine =@Flow

	Delete #ShipQty where PlanDate <@StartDate
	--Select * from #StockConfigQty
	--收
	-- 
	Insert into  #ShipQty
		Select dbo.FormatDate(StartTime,'YYYY/MM/DD')+'A收',a.Item As 物料,sum(Qty) as Qty 
			from MRP_MrpFiShiftPlan a with(nolock) ,MD_Item b with(nolock) 
			where a.PlanVersion=@PlanVersion and a.ProductLine=@Flow And a.Item=b.Code
			Group by a.Item,dbo.FormatDate(StartTime,'YYYY/MM/DD')+'A收'
	Select distinct 0 As Seq, Item As 物料,space(50) 模具,b.Desc1 物料描述,sum(a.SafeStock) As 安全库存,sum(MaxStock) As 最大库存,cast(0 As decimal) As 期初库存 into #StockConfigQty 
		from SCM_FlowDet a with(nolock),MD_Item b with(nolock) ,SCM_FlowMstr c with(nolock)
		where a.Item =b.Code and a.Item in (
		select Item from #Items) 
		and a.Flow =c.Code /*and c.ResourceGroup=30*/ and c.IsMRP =1
		and MrpWeight >0 and (StartDate is null or StartDate< @CurrentTime)
		and (EndDate is null or EndDate> @CurrentTime)
		Group by Item,b.Desc1--,Machine
	Update a
		Set a.Seq=b.Seq,模具=b.Machine from #StockConfigQty a, SCM_FlowDet b with(nolock) where a.物料=b.Item and b.Flow=@Flow
	UPdate a
		Set a.物料描述='[定额:='+cast(b.ShiftQuota as varchar)+']'+物料描述 from #StockConfigQty a, MRP_Machine b with(nolock)  where a.模具 =b.Code
	--存
	select Item,SUM(ATPQty) As 期初库存 into #PrimaryInv 
		from VIEW_LocationDet as l inner join MD_Location as loc on l.Location = loc.Code 
        where loc.IsMrp = 1 and l.ATPQty>0 and Item in (
		select Item from #Items) 
        Group by Item
    Update a
		Set a.期初库存 =b.期初库存 from #StockConfigQty a,#PrimaryInv b where a.物料 =b.Item
	--Insert into #ShipQty 
	--	Select Distinct Left(PlanDate,10)+'C存',Item,0 from #ShipQty where Left(PlanDate,10) not in (select Left(PlanDate,10) from #ShipQty where PlanDate like  '%C存')  
	Insert into #ShipQty 
		Select Distinct Left(PlanDate,10)+'A收',Item,0 from #ShipQty -- where Left(PlanDate,10) not in (select Left(PlanDate,10) from #ShipQty where PlanDate like  '%A收') 
	Insert into #ShipQty 
		Select Distinct Left(PlanDate,10)+'B发',Item,0 from #ShipQty  --where Left(PlanDate,10) not in (select Left(PlanDate,10) from #ShipQty where PlanDate like  '%B发') 
	--Insert into #ShipQty
	--2014/01/18 Begin
	--取得已收已发	
	/*If @CurrentPlandate>@VersionPlandate
	Begin
		Create Table #RecedShippedQty(PlanDate varchar(20),Item varchar(50),PlanRecQty float,PlanShipQty float,ReceivedQty float,ShippedQty float)
		Insert into #RecedShippedQty
			Exec [USP_Busi_MRP_GetFinishedPlanInOut] @planversion,@flow
		Update #ShipQty Set Qty =0 where Left(PlanDate,10)<@CurrentPlandate 
		Insert into #ShipQty
			Select Distinct Left(PlanDate,10)+'A收',Item,ReceivedQty from #RecedShippedQty
		Insert into #ShipQty
			Select Distinct Left(PlanDate,10)+'B发',Item,ShippedQty from #RecedShippedQty
		--select * from #RecedShippedQty
	End*/
	--计算每一天的期末库存Begin
	select distinct PlanDate into #AllPlanDate from #ShipQty
	select distinct Item into #AllItem from #ShipQty
	Insert into #ShipQty
		Select PlanDate,Item,0 from #AllItem, #AllPlanDate
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
					Select @CheckDate+'A收',Item,0 from #AllItem union
					Select @CheckDate+'B发',Item,0 from #AllItem
			End
		Set @i=@i+1
	End
	--补齐即没有计划发也没有计划收的天End
	Select PlanDate ,Item,SUM(Qty) Qty into #ShipQtySum from #ShipQty Group by PlanDate ,Item
	Select Left(a.PlanDate,10)PlanDate,a.Item,a.Qty-b.Qty  As InvQty into #CalsulateEndInv 
		from #ShipQtySum a,#ShipQtySum b where Left(a.PlanDate,10)=Left(b.PlanDate,10)
		and a.Item=b.Item
		and a.PlanDate like '%A收'and b.PlanDate like '%B发'
	--历史的期末库存倒着减
	/*select distinct PlanDate into #HisPlanDate from #CalsulateEndInv where PlanDate <@CurrentPlandate
	Select a.PlanDate PlanDate1,b.PlanDate PlanDate2 into #UpdatePlanDate from 
		(select PlanDate,ROW_NUMBER()Over(order by PlanDate )As NONO from #HisPlanDate) a,
		(select PlanDate,ROW_NUMBER()Over(order by PlanDate Desc )As NONO from #HisPlanDate) b where a.NONO =b.NONO
	UPdate a
		Set  a.PlanDate=b.PlanDate2 from #CalsulateEndInv a,#UpdatePlanDate b where a.PlanDate=b.PlanDate1*/
	--Select * from #CalsulateEndInv
   ;WITH SumData(PlanDate,Item,Seq,InvQty)
      AS
       (SELECT PlanDate,Item,Seq,InvQty FROM (SELECT *,ROW_NUMBER()OVER(PARTITION BY Item ORDER BY [PlanDate]) AS Seq FROM #CalsulateEndInv)A),
      ShowSum(Item,Seq,SumHistoryInvQty)
      AS(
		   SELECT A.Item,A.Seq,SUM(B.InvQty) AS SumHistoryInvQty FROM SumData A,SumData B
		   WHERE A.Item=B.Item AND B.Seq<=A.Seq GROUP BY A.Item,A.Seq
       )
	SELECT A.PlanDate,A.Item,B.SumHistoryInvQty into #UpdateInv FROM SumData A,ShowSum B WHERE A.Item=B.Item AND A.Seq=B.Seq ORDER BY A.Item ,A.PlanDate
	Update a
		Set a.SumHistoryInvQty = a.SumHistoryInvQty+b.期初库存 from #UpdateInv a,#PrimaryInv b where a.Item=b.Item 
	Insert into #ShipQty 
		Select PlanDate+'C存' ,Item,SumHistoryInvQty from #UpdateInv 

	--计算每一天的期末库存End
	If @IsGetSnapInv ='Y'
		Begin
			--to do
			print 'Get SnapInv'
		End
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
	--If @type='Get'
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

	/*Declare @SQLHTML varchar(max)=''
	Declare @SQLHTMLRow varchar(max)=''
	Declare @BaseDailyFied varchar(200)='cast([2014/01/17A发]+cast([2014/01/17B收]+Case when 安全库存<0 then ''<td class =\"WarningColor_Orange\">''
		when [2014/01/17C存]<安全库存 then ''<td class =\"WarningColor_Orange\">''
		when [2014/01/17C存]>最大库存 and 安全库存>0 then ''<td class =\"WarningColor_Yellow\">'' else ''<td>''+cast([2014/01/17C存]as varchar)+''</td>'''
		
	--SELECT @SQLHTML=物料, 物料描述, 安全库存, 最大库存, 期初库存,',Case when 安全库存<0 then <td class =\"WarningColor_Orange\">'
	--	when [2014/01/17A存]<安全库存 then '<td class =\"WarningColor_Orange\">' 
	--	when [2014/01/17A存]>最大库存 and 安全库存>0 then '<td class =\"WarningColor_Yellow\"> else '<td>'+[2014/01/17A存]+<>
	Set @i = 1
	While @i<16
	Begin
		Set @CheckDate = dbo.FormatDate( dateadd(day,@i,@StartDate),'YYYY/MM/DD')
		Set @SQLHTMLRow='<tr><td>物料</td>+<td>物料描述</td>+<td>安全库存</td>+<td>最大库存</td>+<td>期初库存</td>'+REPLACE(@BaseDailyFied,'[2014/01/17','['+@CheckDate)
	End
	Set @SQLHTMLRow=@SQLHTMLRow+'</tr>'
	Create table #RowHTML(Row varchar(max))
	Set @SQLHTMLRow = 'Insert into #RowHTML Select '+@SQLHTMLRow +'from #jj'*/
	--Begin
	set @SQL='SELECT Item,'+@SQLInterim+' into #kk FROM (select * from #ShipQty) as D  pivot(sum(Qty) for PlanDate in ('+@SQL1+')) as PVT order by Item ;Select 物料, 物料描述, 安全库存, 最大库存, 期初库存,'+@SQLInterim+' from #StockConfigQty a left join #kk b on a.物料=b.item order by 模具,Seq;'/*+@SQLHTMLRow*/
	Print @SQL
	EXEC (@SQL)

	--Select distinct item from #ShipQty
END


