USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_GetFilterCapacity]    Script Date: 12/08/2014 15:15:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USP_Report_GetFilterCapacity '2013-07-19 14:53:24',5,'2013-30','2013-35','',''
ALTER   PROCEDURE [dbo].[USP_Report_GetFilterCapacity]
(
	@PlanVersion datetime,
	@DateType int,
	@startDateIndex varchar(50),
	@endDateIndex varchar(50),
	@Item varchar(50),
	@ProductLine varchar(50)
)
AS
BEGIN
	SET NOCOUNT ON
    SELECT @startDateIndex=LTRIM(RTRIM(@startDateIndex)),@endDateIndex=LTRIM(RTRIM(@endDateIndex)),@Item=LTRIM(RTRIM(@Item)),@ProductLine=LTRIM(RTRIM(@ProductLine))
	Begin
	--Sp_help 'MRP_RccpMiPlan'
	Declare @ShiftFilterTruck int=0
	select @ShiftFilterTruck=CAST(value as int ) from SYS_EntityPreference with(nolock) where id =20003
	--select top 1000 * from MRP_RccpMiPlan where DateType =@DateType and DateIndex between @startDateIndex and @endDateIndex 
	--	and Item like isnull(@Item,'')+'%' and @ProductLine like isnull(@ProductLine,'')+'%'
	--	and PlanVersion =@PlanVersion
	--	select top 1000 * from MD_Item
	select ProductLine as 生产线,Item as 物料,a.Qty/b.UC as 车数,DateIndex 日期 into #tmp from MRP_RccpMiPlan a with(nolock),MD_Item b with(nolock)
		where PlanVersion =@PlanVersion and DateType =@DateType and a.Item=b.Code and b.ItemOption=2
		and DateIndex between @startDateIndex and @endDateIndex and a.Item =b.Code and b.Code like '27%'
		and Item like isnull(@Item,'')+'%' and ProductLine like isnull(@ProductLine,'')+'%'
	--If @@rowcount =0
	--Begin
	--	Select '所选择的查询条件，系统无数据，请重新选择!' As NG
	--	Return 
	--End
	----可用时间/生产线的数目
	Declare @FlowCount int=1
	select @FlowCount=COUNT(distinct 生产线) from #tmp
	----Get max capacity
	Create index IX_TEMP on #tmp (生产线,日期)
	select distinct 生产线,日期,a.UpTime as 可用时间 into #UpTime from MRP_WorkCalendar a with(nolock),#tmp b 
		where a.Flow=b.生产线 and a.DateIndex =b.日期 and a.DateType=@DateType
	Insert into #tmp
		select '最大能力',' ',SUM(可用时间/@FlowCount)*3*@ShiftFilterTruck as 最大能力 ,日期 from #UpTime group by 日期
	----Get total capacity
	Insert into #tmp
		select '汇总',' ',sum(车数) as 车数,日期 from #tmp Group by 日期
	----Calculate loading rate
	Insert into #tmp
	select '负荷率',' ', (a.车数/b.车数)*100,a.日期 from #tmp a ,#tmp b 
		where a.日期=b.日期 and a.生产线='汇总' and b.生产线='最大能力'
	----Get avg truck weight
	select sum(a.Qty) as 数量,DateIndex 日期 into #totalqty from MRP_RccpMiPlan a with(nolock),MD_Item b with(nolock)
		where PlanVersion =@PlanVersion and DateType =@DateType and a.Item=b.Code and b.ItemOption=2
		and DateIndex between @startDateIndex and @endDateIndex and a.Item =b.Code and b.Code like '27%'
		and Item like isnull(@Item,'')+'%' and ProductLine like isnull(@ProductLine,'')+'%'
		group by DateIndex
	select a.数量/b.车数 as 平均车重,a.日期 into #CheAvg from #totalqty a ,#tmp b  where a.日期=b.日期 and b.生产线='汇总'
	Insert into #tmp
	select '溢出数(吨)',' ', (a.车数-b.车数)*c.平均车重/1000 as 溢出车重,a.日期 from #tmp a ,#tmp b ,#CheAvg c 
		where a.日期=b.日期 and a.日期 =c.日期  and a.生产线='汇总' and b.生产线='最大能力'
	Update #tmp Set 车数=ROUND(车数,1)
		--Update #tmp Set Qty=cast(qty as varchar(20))+'-'+cast(ID As varchar(20))
		--drop table #tmp1
		Declare @SQL varchar(max)=''
		Declare @SQL1 varchar(max)=''
		SELECT DISTINCT 日期 INTO #tmp1 FROM #tmp  
		select COUNT (*)+2 As ColumnCount from #tmp1
		SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),日期)+'],0)'+' as ['+日期 +'],'
			,@SQL1=@SQL1+'['+日期 +'],'
		FROM #tmp1 ORDER BY 日期
		IF @SQL!=''
		BEGIN
			SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
			SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
		END
			set @SQL='SELECT 生产线,物料,'+@SQL+'  FROM (select * from #tmp) as D  pivot(max(车数) for 日期 in ('+@SQL1+')) as PVT'+
				' order by case when 生产线=''最大能力'' then ''Total1'' when 生产线=''负荷率'' then ''Total2'' when 生产线=''溢出吨数''' +
				'then ''Total3'' when 生产线=''汇总'' then ''Total0'' else 生产线 End,物料'
		print @SQL
		EXEC (@SQL)
	End
End