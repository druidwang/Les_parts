USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_SnapHitory_ProdLineEx]    Script Date: 12/08/2014 15:14:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USP_Busi_MRP_SnapHitory_ProdLineEx  5,'2013/8/5 8:16:45','EX01','','True','True','','','','','','','','','',''
--bool isShiftQuota, bool isShiftPerDay, bool isNormalWorkDayPerWeek, bool isMaxWorkDayPerWeek
--            , bool isQty, bool isIslandQty, bool isShiftType, bool isMachineType, int checkboxcheckedCount
ALTER PROCEDURE [dbo].[USP_Busi_MRP_SnapHitory_ProdLineEx]
(
	@DateType int,
	@SnapTime datetime,
	@ProductLine varchar(50),
	@item varchar(50),
	@isMrpSpeed bit,
	@isRccpSpeed bit,
	@isApsPriority bit,
	@isQuota bit,
	@isSwichTime bit,
	@isSpeedTimes bit,
	@isMinLotSize bit,
	@isEconomicLotSize bit,
	@isMaxLotSize bit,
	@isTurnQty bit,
	@isCorrection bit,
	@isShiftType bit
)
AS
BEGIN
	SET NOCOUNT ON
    SELECT @ProductLine=LTRIM(RTRIM(@ProductLine)),@item=LTRIM(RTRIM(@item))
	Create table #ColumnType (ColName varchar(50),TypeName varchar(50))
	--select top 100 * from Mrp_SnapMachine ---@isQty
	if @isMrpSpeed='True' Begin Insert into #ColumnType select 'MrpSpeed','a排产速度' End
	if @isRccpSpeed='True' Begin Insert into #ColumnType select 'RccpSpeed','b工艺速度' End
	if @isApsPriority='True' Begin Insert into #ColumnType select 'ApsPriority','c优先级' End
	if @isQuota='True' Begin Insert into #ColumnType select 'Quota','d配额' End
	if @isSwichTime='True' Begin Insert into #ColumnType select 'SwitchTime','e切换时间' End
	if @isSpeedTimes='True' Begin Insert into #ColumnType select 'SpeedTimes','f腔口数' End
	if @isMinLotSize='True' Begin Insert into #ColumnType select 'MinLotSize','g最小批量' End
	if @isEconomicLotSize='True' Begin Insert into #ColumnType select 'EconomicLotSize','h经济批量' End 
	if @isMaxLotSize='True' Begin Insert into #ColumnType select 'MaxLotSize','i最大批量' End 
	if @isTurnQty='True' Begin Insert into #ColumnType select 'TurnQty','j切换倍数' End 
	if @isCorrection='True' Begin Insert into #ColumnType select 'Correction','k修正因子' End 
	if @isShiftType='True' Begin Insert into #ColumnType select 'ShiftType','l班制' End 
	Declare @ShowTypes int 
	select @ShowTypes=COUNT(*) from #ColumnType
	--select* from #ColumnType '2013-08-05 08:16:45.000' 
	--Normal = 5,  //常用
	--Backup = 3, //备用
	select b.Code+'<br>'+b.desc1 as 模具 , case when datetype=4 then dbo.FormatDate(dateindex,'MM-DD') else dateindex end As dateindex,cast(a.MrpSpeed  as varchar)MrpSpeed
		,cast(a.RccpSpeed as varchar)RccpSpeed,case when a.ApsPriority =5 then '5[常用]' else '3[备用]' end ApsPriority,cast(a.Quota as varchar)Quota,cast(a.SwitchTime as varchar)SwitchTime,
		cast(a.SpeedTimes as varchar)SpeedTimes,cast(a.MinLotSize as varchar)MinLotSize,cast(a.EconomicLotSize as varchar)EconomicLotSize,
		cast(a.MaxLotSize as varchar)MaxLotSize,cast(a.TurnQty as varchar)TurnQty,cast(a.Correction as varchar)Correction,
		CAST(a.shifttype as varchar)+'['+CAST(24/a.shifttype as varchar)+'小时/班]' as shifttype  into #tmp 
		from MRP_SnapProdLineEx a with(nolock), MD_Item b with(nolock) where snaptime =@SnapTime
		and a.item like ISNULL(@item,'')+'%' and datetype=@DateType and a.item=b.code and productline like isnull(@ProductLine,'')+'%'
		If @@rowcount =0
			Begin
				select 0 as rowcounts,0 as mergerows
				Select '所选择的查询条件，系统无数据，请重新选择!' As NG
				Return 
			End

		Declare @SQL varchar(max)=''
		Declare @SQL1 varchar(max)=''
		Declare @InitialSQL varchar(max)=''
		SELECT DISTINCT dateindex INTO #tmp1 FROM #tmp ORDER BY dateindex
		SELECT COUNT(*) +2 as colcount,@ShowTypes as Mergecount FROM #tmp1
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
		select 'SELECT 模具, '''+TypeName+''' as 类型,'+@InitialSQL+' FROM (select * from #tmp) as D  pivot(max('+ColName+')'+
		' for dateindex in ('+@SQL1+')) as PVT ' as EXECSQL into #EXECSQL from #ColumnType
		--order by 岛区,模具
		Declare @SummaryEXECSQL varchar(max)=''
		select @SummaryEXECSQL=@SummaryEXECSQL+EXECSQL +' union all ' from #EXECSQL
		Set @SummaryEXECSQL=LEFT(@SummaryEXECSQL,LEN(@SummaryEXECSQL)-10)+ ' order by 模具,类型'
		
		Print @SummaryEXECSQL
		EXEC (@SummaryEXECSQL)

 
 End