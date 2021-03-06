USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_MRP_MIShiftPlanSearch]    Script Date: 12/08/2014 15:18:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_Report_MRP_MIShiftPlanSearch]
(
	@PlandateStart datetime,
	@Flow varchar(50),
	@Type varchar(50)=''
)
AS
--USP_Report_MRP_MIShiftPlanSearch '2013/8/1 0:00:00','MI01[炼胶主线]' ,'shift'
--declare 
--	@PlandateStart datetime='2013/6/21 13:55:41',
--	@Flow varchar(50)='MI01[炼胶主线]',
--	@Type varchar(50)='Get'
 
--USP_Report_MRP_MIShiftPlanSearch '2013/6/21 13:55:41','MI01[炼胶主线]','Get'
 
BEGIN
	SET NOCOUNT ON
    SELECT @Flow=LTRIM(RTRIM(@Flow))
	Set @Flow=Left(@Flow,4)

		declare @PlandateEnd datetime=dateadd(day, case when @Type ='shift' then 6 else 13 end,@PlandateStart)
		--select top 1000 * from MRP_MrpMiDateIndex a, MRP_MrpMiShiftPlan b where IsActive =1 and a.PlanDate between @PlandateStart and @PlandateEnd
		--and a.ProductLine ='MI01'  and a.PlanVersion =b.PlanVersion and a.PlanDate =b.PlanDate and a.ProductLine =b.ProductLine and 
		--a.CreateDate=b.createdate 
		select b.Item,c.Desc1,round((Qty+AdjustQty)/UnitCount,0) as Qty, dbo.FormatDate(a.Plandate,'MM-DD')+
			'-'+Shift As ShifDay into #tmp 
			from MRP_MrpMiDateIndex a with(nolock), MRP_MrpMiShiftPlan b with(nolock),MD_Item c with(nolock) where a.ProductLine =@Flow and a.IsActive =1 
			and a.PlanDate between @PlandateStart and @PlandateEnd and a.PlanVersion =b.PlanVersion and a.PlanDate =b.PlanDate 
			and a.ProductLine =b.ProductLine and a.CreateDate=b.createdate  and b.Item =c.Code 
		If @@rowcount =0
			Begin
				select 0 as rowcounts
				Select '所选择的查询条件，系统无数据，请重新选择!' As NG
				Return 
			End
		If @Type ='Day'
			Begin
				Select Item,Desc1,sum(Qty) As Qty ,left(ShifDay,5) as ShifDay into #tmp_Interim 
					from  #tmp Group by Item,Desc1,left(ShifDay,5)
				Delete #tmp
				Insert into #tmp
					Select * from #tmp_Interim 
			End
		--select * from #tmp


		Create table #PlanDate (Plandate varchar(20))
		declare @i int=0
		declare @j int=0
		while @i<case when @Type ='Shift' then 7 else 14 end
		Begin
			Insert into #PlanDate
				Select dbo.FormatDate(DATEADD(DAY,@i,@PlandateStart),'MM-DD')+case when @Type ='Shift' then'-MI3-1' else ''end union
				Select dbo.FormatDate(DATEADD(DAY,@i,@PlandateStart),'MM-DD')+case when @Type ='Shift' then'-MI3-2'else ''end union
				Select dbo.FormatDate(DATEADD(DAY,@i,@PlandateStart),'MM-DD')+case when @Type ='Shift' then'-MI3-3'else ''end
			Set @i=@i+1
		End
		Insert into #tmp
			select Item, Desc1 ,0 as qty,a.Plandate  from #PlanDate a ,(select distinct Item, Desc1 from #tmp) b
 
		--合并班次
		Update #tmp Set ShifDay =replace(replace(ShifDay,'MI2-','MI-'),'MI3-','MI-')
 
		--Update #tmp Set Qty=cast(qty as varchar(20))+'-'+cast(ID As varchar(20))
		Declare @SQL varchar(max)=''
		Declare @SQL1 varchar(max)=''
		SELECT DISTINCT ShifDay INTO #tmp1 FROM #tmp ORDER BY ShifDay
		select COUNT(*)+2 from #tmp1
		SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),ShifDay)+'],0)'+' as ['+ShifDay +'],'
			,@SQL1=@SQL1+'['+ShifDay +'],'
		FROM #tmp1 ORDER BY ShifDay
		IF @SQL!=''
		BEGIN
			SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
			SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
		END		 
		set @SQL='SELECT Item 物料,Desc1 物料描述,'+@SQL+' FROM (select * from #tmp) as D  pivot(sum(Qty)'+
		' for ShifDay in ('+@SQL1+')) as PVT order by Item desc '
		Print @SQL
		EXEC (@SQL)
End