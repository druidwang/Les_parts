USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_SnapHitory_Machine]    Script Date: 12/08/2014 15:14:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USP_Busi_MRP_SnapHitory_Machine  4,'','','','True','','','','','','',''
--bool isShiftQuota, bool isShiftPerDay, bool isNormalWorkDayPerWeek, bool isMaxWorkDayPerWeek
--            , bool isQty, bool isIslandQty, bool isShiftType, bool isMachineType, int checkboxcheckedCount

ALTER PROCEDURE [dbo].[USP_Busi_MRP_SnapHitory_Machine]
(
	@DateType int,
	@SnapTime datetime,
	@Island varchar(50),
	@Machine varchar(50),
	@isShiftQuota bit,
	@isShiftPerDay bit,
	@isNormalWorkDayPerWeek bit,
	@isMaxWorkDayPerWeek bit,
	@isQty bit,
	@isIslandQty bit,
	@isShiftType bit,
	@isMachineType bit
	
)
AS
BEGIN
	SET NOCOUNT ON
	--	班产定额	105
	--班次/天	2
	--周正常工作天数	5
	--周最大工作天数	6
	--数量	1
	--岛区数量	1
	--班制	3[8小时/班]
	--模具类型	  2[单件(∑)]   1[成套(Max)]
    SELECT @Island=LTRIM(RTRIM(@Island)),@Machine=LTRIM(RTRIM(@Machine))
	Create table #ColumnType (ColName varchar(50),TypeName varchar(50))
	--select top 100 * from Mrp_SnapMachine ---@isQty
	if @isShiftQuota='True' Begin Insert into #ColumnType select 'ShiftQuota','a班产定额' End
	if @isShiftPerDay='True' Begin Insert into #ColumnType select 'ShiftPerDay','b班次/天' End
	if @isNormalWorkDayPerWeek='True' Begin Insert into #ColumnType select 'NormalWorkDayPerWeek','c周正常工作天数' End
	if @isMaxWorkDayPerWeek='True' Begin Insert into #ColumnType select 'MaxWorkDayPerWeek','d周最大工作天数' End
	if @isQty='True' Begin Insert into #ColumnType select 'Qty','e数量' End
	if @isIslandQty='True' Begin Insert into #ColumnType select 'IslandQty','f岛区数量' End
	if @isShiftType='True' Begin Insert into #ColumnType select 'ShiftType','g班制' End
	if @isMachineType='True' Begin Insert into #ColumnType select 'MachineType','h模具类型' End 
	Declare @ShowTypes int 
	select @ShowTypes=COUNT(*) from #ColumnType
	--select* from #ColumnType
	select 0 as mergerows,a.island as 岛区,b.Code+'<br>'+b.desc1 as 模具 , case when datetype=4 then dbo.FormatDate(dateindex,'MM-DD') else dateindex end As dateindex,cast(a.ShiftQuota  as varchar)ShiftQuota
		,cast(a.ShiftPerDay as varchar)ShiftPerDay,cast(a.NormalWorkDayPerWeek as varchar)NormalWorkDayPerWeek,cast(a.MaxWorkDayPerWeek as varchar)MaxWorkDayPerWeek,cast(a.Qty as varchar)Qty,
		cast(a.IslandQty as varchar)IslandQty,CAST(a.shifttype as varchar)+'['+CAST(24/a.shifttype as varchar)+'小时/班]'
		as shifttype,case when a.MachineType =1 then '1[成套(Max)]' else '2[单件(∑)]' end as  MachineType into #tmp
		from Mrp_SnapMachine a with(nolock), MRP_Machine b with(nolock) where snaptime =@SnapTime and a.island like ISNULL(@Island,'') +'%' 
		and a.code like ISNULL(@Machine,'')+'%' and datetype=@DateType and a.code=b.code
	select 岛区,模具,COUNT(模具)*@ShowTypes as mergerows into #mergerows from #tmp group by 岛区,模具
	If @@rowcount =0
	Begin
		select 0 as rowcounts,0 as mergerows
		Select '所选择的查询条件，系统无数据，请重新选择!' As NG
		Return 
	End
	update b
		Set b.mergerows=a.mergerows from #mergerows a,#tmp b where a.岛区=b.岛区 and a.模具=b.模具

		Declare @SQL varchar(max)=''
		Declare @SQL1 varchar(max)=''
		Declare @InitialSQL varchar(max)=''
		SELECT DISTINCT dateindex INTO #tmp1 FROM #tmp ORDER BY dateindex
		SELECT COUNT(*) +3 as colcount,@ShowTypes as Mergecount FROM #tmp1
		SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),dateindex)+'],'''')'+' as ['+dateindex +'],'
			,@SQL1=@SQL1+'['+dateindex +'],'
		FROM #tmp1 ORDER BY dateindex
		IF @SQL!=''
		BEGIN
			SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
			SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
		END	
		Set @InitialSQL=@SQL
		--set @SQL='SELECT 岛区,模具, ''班产定额'' as 类型,'+@SQL+' into #Record FROM (select * from #tmp) as D  pivot(sum('+@ShiftQuota+')'+
		--' for dateindex in ('+@SQL1+')) as PVT order by 岛区,模具;select * from #Record '
		select 'SELECT 岛区,模具,'''' as 物料, '''+TypeName+''' as 类型,'+@InitialSQL+' FROM (select * from #tmp) as D  pivot(max('+ColName+')'+
		' for dateindex in ('+@SQL1+')) as PVT ' as EXECSQL into #EXECSQL from #ColumnType
		--order by 岛区,模具
		Declare @SummaryEXECSQL varchar(max)=''
		select @SummaryEXECSQL=@SummaryEXECSQL+EXECSQL +' union all ' from #EXECSQL
		Set @SummaryEXECSQL=LEFT(@SummaryEXECSQL,LEN(@SummaryEXECSQL)-10)+ ' order by 岛区,模具,类型'
		
		Print @SummaryEXECSQL
		EXEC (@SummaryEXECSQL)

 
 End