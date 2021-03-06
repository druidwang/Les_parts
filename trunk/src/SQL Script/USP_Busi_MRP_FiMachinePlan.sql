USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_FiMachinePlan]    Script Date: 12/22/2014 18:27:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [USP_Busi_MRP_FiMachinePlan] '2014-02-13 11:17:47' ,'FI31','GetWebDisPlay',''
ALTER PROCEDURE [dbo].[USP_Busi_MRP_FiMachinePlan]
(
	@Planversion datetime,
	@Flow varchar(50),
	@Type varchar(50),
	@ParaAll varchar(max)=''
)
AS
BEGIN
	Begin try
	SET NOCOUNT ON
	----更新模具计划的模具对应的岛区为最新的信息	2014-06-09	--0001
	----模具计划上传，今天（含）以前的班产计划不变，根据今天早晨9点的库存推算到明天早上的库存再进行排产	2014/06/14	--0002	
	----从版本的开始日期进行更新	2014-06-20	--0003
	Declare @CurrentTime DateTime =getdate()
	Select @ParaAll= REPLACE(REPLACE(@ParaAll,CHAR(13),''),CHAR(10),'')
	Declare @DateIndex varchar(50) ,@WeekStartDay DateTime ,@WeekEndDay DateTime 
	Select @DateIndex=DateIndex from MRP_MrpPlanMaster with(nolock) where PlanVersion =@Planversion
	Select @WeekStartDay=StartDate,@WeekEndDay=EndDate from MRP_WeekIndex where WeekIndex =@DateIndex
    SELECT @Flow=LTRIM(RTRIM(@Flow)),@Type=LTRIM(RTRIM(@Type)),@ParaAll=LTRIM(RTRIM(@ParaAll))
    --Kit = 1,    //成套
    --Single = 2, //单件
	Set @Flow=Left(@Flow,4)
	If left(@Type,3)='Get'
	Begin
		----
		--生产线	岛区	模具	模具描述	班产定额
		--select	a.Code,COUNT(distinct ShiftType) from MRP_Island a ,MRP_Machine b where a.Code=b.Island
		--group by a.Code having count(distinct ShiftType)>1
		--select * from MRP_Island where Island ='650028'
		--2014/01/26   返回模具的天最大能力
		select Code ,Desc1,Qty*ShiftPerDay As MachineShiftQtyQuota into #MAXMachineshiftQty from MRP_Machine
			where (StartDate is null or StartDate<@CurrentTime)and (EndDate is null or EndDate>@CurrentTime)
		--2014/01/26   返回岛区的天最大能力
		select a.Code,a.Desc1 ,a.Qty*ShiftType As IslandShiftQtyQuota  into #MAXIslandhiftQty from MRP_Island a ,MRP_Machine b 
		where a.Code=b.Island and (b.StartDate is null or b.StartDate<@CurrentTime)and (b.EndDate is null or b.EndDate>@CurrentTime)
		--select * from #MAXMachineshiftQty a, #MAXIslandhiftQty b
		--select distinct * from #MAXIslandhiftQty

		--0001
		Update a
			Set a.Island=b.Island from MRP_MrpFiMachinePlan a with(nolock) ,MRP_Machine b 
			where planversion =@Planversion and productline=@Flow
			and a.Machine=b.Code and(b.StartDate is null or b.StartDate<@CurrentTime)and (b.EndDate is null or b.EndDate>@CurrentTime)
		--0001
		select ProductLine 生产线,a.island 岛区,b.MachineType,0 As IslandShiftQtyQuota ,islanddescription 岛区描述,machine 模具,0 As MachineShiftQtyQuota,machineDescription  模具描述, 
			'模具数量='+cast(machineqty as varchar)+'定额='+cast(b.ShiftQuota as varchar) 班产定额,dbo.FormatDate(plandate,'YYYY/MM/DD')plandate ,case DATEPART(weekday,plandate) 
			when 1 then '星期天' when 2 then '星期一' when 3 then '星期二' when 4 then '星期三' when 5 then '星期四'
			when 6 then '星期五' when 7 then '星期六'else '' End As WeekDayIndex,
			Max(shiftsplit)shiftsplit into  #tmpSum
			from  MRP_MrpFiMachinePlan a with(nolock) ,MRP_Machine b 
			where planversion =@Planversion and productline=@Flow
			and a.Machine=b.Code and (b.StartDate is null or StartDate < @CurrentTime) and (b.EndDate is null or EndDate > @CurrentTime)
			Group by productline  ,a.Island,islanddescription ,machine ,b.MachineType ,machineDescription  , b.ShiftQuota  ,plandate,machineqty

		--补齐没有排到的模具
		Declare @OnePlanDate varchar(20)=''
		Select top 1 @OnePlanDate =plandate from #tmpSum
		if @OnePlanDate=''
			Begin
				Set @OnePlanDate= dbo.FormatDate(@WeekStartDay,'YYYY/MM/DD')
			End
		select  distinct Flow 生产线,b.island 岛区,b.MachineType,0 As IslandShiftQtyQuota ,e.Desc1 岛区描述,machine 模具,0 As MachineShiftQtyQuota,b.Desc1 模具描述, 
			'模具数量='+cast(b.Qty as varchar)+'定额='+cast(b.ShiftQuota as varchar) 班产定额,@OnePlanDate plandate ,case DATEPART(weekday,@OnePlanDate) 
				when 1 then '星期天' when 2 then '星期一' when 3 then '星期二' when 4 then '星期三' when 5 then '星期四'
				when 6 then '星期五' when 7 then '星期六'else '' End As WeekDayIndex,null As shiftsplit
			Into #MachineInstance1
			from SCM_FlowDet a with(nolock), MRP_Machine b with(nolock),MRP_Island e with(nolock),MD_Item c with(nolock),SCM_FlowMstr d with(nolock)
			where a.Machine is not null and a.Machine =b.Code and a.Item=c.Code and a.Flow=d.Code and b.Island=e.Code
			and (b.StartDate is null or b.StartDate<@CurrentTime)and (b.EndDate is null or b.EndDate>@CurrentTime)
			and Flow=@Flow
			and d.IsMRP = 1 and d.Type =4 and d.ResourceGroup = 30
			and not exists(select * from #tmpSum f where f.模具=b.Code)
			and d.IsActive =1 and a.MrpWeight>0
			and (a.StartDate is null or a.StartDate<@CurrentTime)and (a.EndDate is null or a.EndDate>@CurrentTime)
			and isnull(a.Machine,'')!='' 
		Insert into #tmpSum
			select * from #MachineInstance1 
		--Delete 数量总数量为0的模具  需要显示为0的模具
		--Delete a from #tmpSum  a ,(select 模具,SUM(shiftqty) As shiftqty  from #tmpSum group by 模具) b where a.模具=b.模具 and b.shiftqty=0
		--Delete 数量总数量为0的模具
		select distinct plandate into #plandate from #tmpSum
		Select a.生产线,a.岛区,MachineType,a.IslandShiftQtyQuota,a.岛区描述,a.模具,a.MachineShiftQtyQuota,a.模具描述,a.班产定额,SPACE(50)plandate,
				Cast(0 as float) As shiftsplit into #tmpSum_interim from #tmpSum a
		Insert into #tmpSum
			Select a.生产线,a.岛区,MachineType,a.IslandShiftQtyQuota,a.岛区描述,a.模具,a.MachineShiftQtyQuota,a.模具描述,a.班产定额,b.plandate,case DATEPART(weekday,b.plandate) 
				when 1 then '星期天' when 2 then '星期一' when 3 then '星期二' when 4 then '星期三' when 5 then '星期四'
				when 6 then '星期五' when 7 then '星期六'else '' End As WeekDayIndex,
				0 As shiftsplit from #tmpSum_interim a,#plandate b

		
		Update a
			Set a.MachineShiftQtyQuota=b.MachineShiftQtyQuota,a.模具描述=b.Desc1 from #tmpSum a,#MAXMachineshiftQty b where a.模具=b.Code
		Update a
			Set a.IslandShiftQtyQuota=b.IslandShiftQtyQuota,a.岛区描述 =b.Desc1 from #tmpSum a,#MAXIslandhiftQty b where a.岛区=b.Code
		
		If @@rowcount =0
				Begin
					Select '所选择的查询条件，系统无数据，请重新选择!' As NG
					Return 
				End
		Select distinct plandate into #tmp1 from #tmpSum
		Declare @i int =1
		Declare @CheckDate varchar(20) 
		Declare @StartDate1 dateTime 
		Declare @EndDate1 dateTime 
		Select @StartDate1=MIN(plandate)  From #tmp1
		Select @EndDate1=MAX(plandate)  From #tmp1
		If dbo.FormatDate(@StartDate1,'YYYY/MM/DD')>@WeekStartDay
			Begin
				Set @StartDate1=@WeekStartDay
				Insert into #tmp1
					Select dbo.FormatDate(@WeekStartDay,'YYYY/MM/DD') 
			End
		If dbo.FormatDate(@EndDate1,'YYYY/MM/DD')<@WeekEndDay
			Begin
				Set @EndDate1=@WeekEndDay
				Insert into #tmp1
					Select dbo.FormatDate(@WeekEndDay,'YYYY/MM/DD') 
			End
		While @i<16
		Begin
			Set @CheckDate = dbo.FormatDate( dateadd(day,@i,@StartDate1),'YYYY/MM/DD')
			If not exists(select 0 from #tmp1 where PlanDate = @CheckDate)
				Begin
					print @CheckDate
					Insert into #tmp1
						Select @CheckDate where @CheckDate<=@EndDate1
				End
			Set @i=@i+1
		End
		
		--2014/03/23若果是Type = 'GetWebDisPlay' 则日期要变下格式
		If @Type ='GetWebDisPlay'
			Begin
				Update #tmpSum Set plandate=+cast(plandate as varchar)+'<br>'+WeekDayIndex 
				Update #tmp1 Set plandate =plandate ++'<br>'+case DATEPART(weekday,plandate) 
				when 1 then '星期天' when 2 then '星期一' when 3 then '星期二' when 4 then '星期三' when 5 then '星期四'
				when 6 then '星期五' when 7 then '星期六'else '' End
			End
			
			
		Declare @SQL varchar(MAX)=''
		Declare @SQL1 varchar(MAX)=''
		--select * from #tmpSum
		--SELECT DISTINCT plandate INTO #tmp1 FROM #tmp ORDER BY plandate
		SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),plandate)+'],0)'+' as ['+plandate +'],'
			,@SQL1=@SQL1+'['+plandate +'],'
		FROM #tmp1 ORDER BY plandate
		IF @SQL!=''
		BEGIN
			SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
			SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
		END
		Declare @SQLInterim varchar(max)=@SQL
		--select @SQL
			--MachinePlanQty
			
			set @SQL='SELECT 生产线,岛区,模具,模具描述,班产定额,'+@SQLInterim+' FROM (select 生产线,岛区,岛区描述,模具,模具描述,班产定额,shiftsplit,plandate from #tmpSum) as D  pivot(max(shiftsplit) for plandate in ('+@SQL1+')) as PVT order by 岛区描述;'
			If @Type ='GetWebDisPlay'
				Begin
					Select COUNT(*)+4 As TotalColumn from #tmp1
					set @SQL='SELECT 生产线,岛区,模具,模具描述,'+@SQLInterim+' FROM (select 生产线,岛区,岛区描述,模具,模具描述,班产定额,shiftsplit,plandate from #tmpSum) as D  pivot(max(shiftsplit) for plandate in ('+@SQL1+')) as PVT order by 岛区描述;'

				End
			Print @SQL
			EXEC (@SQL)
			If @Type ='GetWebDisPlay'
				Begin
					Return
				End
			--MachineShiftQuotaQty
			set @SQL='SELECT 生产线,岛区,模具,模具描述,MachineType,'+@SQLInterim+' FROM (select 生产线,岛区,岛区描述,模具,模具描述,MachineType,MachineShiftQtyQuota,plandate from #tmpSum) as D  pivot(max(MachineShiftQtyQuota) for plandate in ('+@SQL1+')) as PVT order by 岛区描述;'
			Print @SQL
			EXEC (@SQL)
			--IslandShiftQuotaQty
			set @SQL='SELECT 生产线,岛区,模具,模具描述,MachineType,'+@SQLInterim+' FROM (select 生产线,岛区,岛区描述,模具,模具描述,MachineType,IslandShiftQtyQuota,plandate from #tmpSum) as D  pivot(max(IslandShiftQtyQuota) for plandate in ('+@SQL1+')) as PVT order by 岛区描述;'
 
			Print @SQL
			EXEC (@SQL)
			Select Distinct 生产线,岛区,模具,模具描述,s.MachineType,b.ShiftType,isnull(a.Qty,1) As IslandQty,isnull(b.Qty,1) As MachineQty,a.Desc1 from #tmpSum s left join  MRP_Island a on s.岛区=a.Code left join MRp_machine b on s.模具=b.Code order by a.Desc1

	End
	If @Type='Update'
		Begin
			
			Declare @Para varchar(1000),@Island varchar(100), @Machine varchar(100), @Item varchar(100),@Shift varchar(100), @Date varchar(100),@Qty float
			Declare @plandate datetime,@startdate datetime,@Windowdate datetime,@ShiftType int,@sequence int,@ShiftSplit varchar(100)
			CREATE TABLE [dbo].#MRP_MrpFiMachinePlan(
					[Id] [int]NOT NULL,
					[PlanVersion] [datetime] NOT NULL,
					[PlanDate] [datetime] NOT NULL,
					[ProductLine] [varchar](50) NOT NULL,
					[Island] [varchar](50) NOT NULL,
					[IslandDescription] [varchar](50) NOT NULL,
					[Machine] [varchar](50) NOT NULL,
					[MachineDescription] [varchar](50) NOT NULL,
					[MachineQty] [float] NOT NULL,
					[MachineType] [int] NOT NULL,
					[ShiftQuota] [float] NOT NULL,
					[ShiftType] [int] NOT NULL,
					[WorkDayPerWeek] [float] NOT NULL,
					[ShiftPerDay] [int] NOT NULL,
					[UnitCount] [float] NOT NULL,
					[ShiftQty] [float] NOT NULL,
					[ShiftSplit] [varchar](50) NULL)
			Insert into #MRP_MrpFiMachinePlan
				Select *  from MRP_MrpFiMachinePlan with(nolock) where PlanVersion=@Planversion and ProductLine =@Flow 
			Select * into #ParaListGroup from dbo.[Func_SplitStr](@ParaAll,';')
			Create table #ParaList(diagitem varchar(100),diagvalue varchar(100))
			while Exists (select top 1* from #ParaListGroup)
				Begin
					select top 1 @Para=F1 from #ParaListGroup
					Insert into #ParaList 
					select * from dbo.[Func_SplitStr_ItemValue](@Para,',')
					select @island=diagvalue from #ParaList where diagitem='island'
					select @machine=diagvalue from #ParaList where diagitem='machine'
					select @Date=diagvalue from #ParaList where diagitem='Date'
					select @ShiftSplit=Case when diagvalue like '.%' then '0'+ diagvalue else diagvalue End from #ParaList where diagitem='Qty'
					select @Qty=isnull(SUM(cast(replace(F1,'-','0') As float)),0)  from dbo.Func_SplitStr_Id(@ShiftSplit,'+')
					--select * from #ParaList
					print @island+';'+@machine+';'+@Date+';'+cast(@Qty as varchar)

					update #MRP_MrpFiMachinePlan Set ShiftQty=@Qty,ShiftSplit=@ShiftSplit where Island =@Island and Machine =@Machine and dbo.FormatDate(Plandate,'YYYYMMDD')=@date
					----新增的模具计划  2014/02/13 Begin
					If @@ROWCOUNT=0 and @Qty!=0
					Begin
						
						Select top 1 * into #MRP_MrpFiMachinePlan_Interim from #MRP_MrpFiMachinePlan where Machine =@Machine
						Update #MRP_MrpFiMachinePlan_Interim Set Plandate=dbo.Format_To_Date(@Date) ,ShiftQty=@Qty , Island =@Island,shiftsplit=@ShiftSplit
						Insert into #MRP_MrpFiMachinePlan
							Select 0 As Id, PlanVersion, PlanDate, ProductLine, Island, IslandDescription, Machine, MachineDescription, MachineQty, MachineType, 
								ShiftQuota, ShiftType, WorkDayPerWeek, ShiftPerDay, UnitCount, ShiftQty,isnull(ShiftSplit,'0') from #MRP_MrpFiMachinePlan_Interim
						If @@ROWCOUNT = 0
							Begin
								Insert into #MRP_MrpFiMachinePlan
									select top 1 0As Id, @Planversion,@Date ,@Flow ,a.Code,a.Desc1 ,b.Code ,b.Desc1 ,b.Qty As MachineQty,b.MachineType,b.ShiftQuota ,b.ShiftType
									 ,0 As WorkDayPerWeek,b.ShiftPerDay,c.UC ,@QTY,@ShiftSplit As ShiftSplit
									 from MRP_Island a,MRP_Machine b,SCM_FlowDet c where a.Code=b.Island and b.Code =c.Machine 
									 and (b.StartDate is null or b.StartDate<@CurrentTime)and (b.EndDate is null or b.EndDate>@CurrentTime)
									 and b.Code =@Machine
							End
						Drop table #MRP_MrpFiMachinePlan_Interim
					End
					----新增的模具计划  2014/02/13 End
					Delete #ParaListGroup where F1 = @Para
					Delete #ParaList
				End
			--Check 模具和岛区是否溢出
			Declare @Msg varchar(max)=''
			--
			--select Distinct b.Code,b.Qty*a.ShiftPerDay Qty into #MAXIlandShiftQty from #MRP_MrpFiMachinePlan a,MRP_Island b with(nolock)
			--	where a.PlanVersion=@Planversion and a.ProductLine =@Flow
			--	and a.Island =b.Code 
			select a.Code ,max(a.Qty*ShiftType) As Qty into #MAXIlandShiftQty
				from MRP_Island a ,MRP_Machine b where a.Code=b.Island
				and a.IsActive =1 and (b.StartDate is null or b.StartDate<@CurrentTime)and (b.EndDate is null or b.EndDate>@CurrentTime)
				Group by a.Code
			--select Code ,COUNT(distinct Island) from MRP_Machine group by Code having COUNT(distinct Island)>1
			--select * from MRP_Machine
			select Code ,Qty*ShiftPerDay As ShiftQtyQuota into #MAXIMachinehiftQty 
				from MRP_Machine b with(nolock)
				where (b.StartDate is null or b.StartDate<@CurrentTime)and (b.EndDate is null or b.EndDate>@CurrentTime)
			--select * from #MAXIlandShiftQty
			--select * from #MAXIMachinehiftQty
			select Island ,Machine ,PlanDate ,SUM(ShiftQty) ShiftQty into #CheckMachine from #MRP_MrpFiMachinePlan a 
			where a.PlanVersion=@Planversion and a.ProductLine =@Flow
			Group by Island ,Machine ,PlanDate 
			--if exists(select * from #CheckMachine a ,#MAXIMachinehiftQty b where a.Machine=b.Code and a.ShiftQty>b.ShiftQtyQuota)
			--	Begin
			--		Set @Msg='以下的模具班别数溢出，'
			--		select @Msg=@Msg+dbo.FormatDate(PlanDate,'YYYY-MM-DD')+','+a.Machine+';' from #CheckMachine a ,#MAXIMachinehiftQty b 
			--			where a.Machine=b.Code and a.ShiftQty>b.ShiftQtyQuota
			--		Select 'NG' As ChkResult ,@Msg AS ChkMessage
			--		return
			--	End
			select Island,PlanDate,SUM(ShiftQty) ShiftQty into #CheckIsland from #CheckMachine
			Group by Island ,PlanDate 
			--if exists(select * from #CheckIsland a ,#MAXIlandShiftQty b where a.Island=b.Code and a.ShiftQty>b.Qty)
			--	Begin
			--		Set @Msg='以下的岛区班别数溢出，'
			--		select @Msg=@Msg+dbo.FormatDate(PlanDate,'YYYY-MM-DD')+','+a.Island+';' from #CheckIsland a ,#MAXIlandShiftQty b 
			--			where a.Island=b.Code and a.ShiftQty>b.Qty
			--	Select 'NG' As ChkResult ,@Msg AS ChkMessage
			--		return
			--	End
			Declare @CurrentPlandate DateTime =dbo.FormatDate(getdate(),'YYYY-MM-DD '+'00:00:00')
			--如果在周五排下周一的版本，计划要推算到下周一的初始库存
			Declare @CurrentPlandate1 DateTime =dbo.FormatDate(getdate() ,'YYYY-MM-DD '+'00:00:00')
			--Declare @EndPlanversionPlandate DateTime  
			--Select @EndPlanversionPlandate=MAX(plandate) from MRP_MrpFiMachinePlan where PlanVersion=@Planversion
			----0003
			If  @CurrentPlandate1<(select MIN(Dateadd(day,-1,plandate)) from MRP_MrpFiMachinePlan where PlanVersion=@Planversion) 
				Begin
					select @CurrentPlandate1=MIN(Dateadd(day,-1,plandate)) from MRP_MrpFiMachinePlan where PlanVersion=@Planversion
				End
			----0003
			update  b Set b.ShiftQty =a.ShiftQty,b.ShiftSplit=a.ShiftSplit from #MRP_MrpFiMachinePlan a, MRP_MrpFiMachinePlan b where a.Id =b.Id and b.PlanDate >=@CurrentPlandate
			Insert into MRP_MrpFiMachinePlan(PlanVersion, PlanDate, ProductLine, Island, IslandDescription, Machine, MachineDescription, MachineQty, MachineType, 
						ShiftQuota, ShiftType, WorkDayPerWeek, ShiftPerDay, UnitCount, ShiftQty, ShiftSplit)
				Select PlanVersion, PlanDate, ProductLine, Island, IslandDescription, Machine, MachineDescription, MachineQty, MachineType, ShiftQuota, ShiftType, 
					WorkDayPerWeek, ShiftPerDay, UnitCount, ShiftQty,ShiftSplit from #MRP_MrpFiMachinePlan where Id =0 
			----排产
			--delete from #MRP_MrpFiMachinePlan where PlanVersion  = '2014-01-19 19:24:15.000' and ProductLine !='FI21'
			--delete from #MRP_MrpFiMachinePlan where ShiftQty =0
			--select * from #MRP_MrpFiMachinePlan
			--select * from MD_Item where Code ='600002'
			----取得模具物料
			----Get latest machine instance
			Declare @DateIndex1 varchar(50)=''
			Select @DateIndex1=MAX(DateIndex ) from  MRP_MachineInstance where DateType =4 
			select Distinct b.Island 岛区,b.Code 模具,b.Qty as 模具数量,c.Code 物料,c.Desc1 物料描述,case when b.MachineType=1 then '1[成套]' 
				when b.MachineType=2 then '2[单件]' else CAST( b.MachineType as varchar) end as 模具类型,
				b.ShiftPerDay as [班/每天],NormalWorkDayPerWeek as 周工作天数,b.ShiftQuota as 班产定额,cast(a.UC as decimal(18,0)) as 单包装,
				a.Flow 生产线,d.Desc1 生产线描述, 0 as mergeisland,0 as Mergemachine  into #MachineInstance 
				from SCM_FlowDet a with(nolock), MRP_Machine b with(nolock),MRP_Island e with(nolock),MD_Item c with(nolock),SCM_FlowMstr d with(nolock)
				where a.Machine is not null and a.Machine =b.Code and a.Item=c.Code and a.Flow=d.Code and b.Island=e.Code
				and (b.StartDate is null or b.StartDate<@CurrentTime)and (b.EndDate is null or b.EndDate>@CurrentTime)
		        and a.Flow =@flow
				and d.IsMRP = 1 and d.Type =4 and d.ResourceGroup = 30
				and d.IsActive =1 and a.MrpWeight>0
				and (a.StartDate is null or a.StartDate<@CurrentTime)and (a.EndDate is null or a.EndDate>@CurrentTime)
				and isnull(a.Machine,'')!='' 
			----单独更新 Shift Quota
			Update  a
				Set a.班产定额=b.ShiftQuota,a.[班/每天]=b.ShiftPerDay from #MachineInstance  a,MRP_Machine b 
				where a.岛区=b.Island and a.模具=b.Code And (StartDate<=@CurrentTime Or StartDate Is null) and (EndDate>@CurrentTime Or  EndDate Is null)
			Update  a
				Set a.ShiftQuota=b.ShiftQuota,a.ShiftPerDay=b.ShiftPerDay from #MRP_MrpFiMachinePlan  a,MRP_Machine b 
				where a.Island=b.Island and a.Machine=b.Code And (StartDate<=@CurrentTime Or StartDate Is null) and (EndDate>@CurrentTime Or  EndDate Is null)
			--Select 物料 from #MachineInstance
			--取得物料库存
			--0002Begin
			
			Create Table #PrimaryInv(Item varchar(50),期初库存 decimal)
			Insert into #PrimaryInv
				Select * from  dbo.GetInvBySnapTime ([dbo].[GetStartInvSnapTimeByDate](GETDATE()))
			Delete #PrimaryInv where Item not in(
				Select 物料 from #MachineInstance) 
			Select Item ,SUM(Qty) As InQty into #InPlan from MRP_MrpFiShiftPlan 
				where PlanVersion=@Planversion
				and PlanDate >=@CurrentPlandate
				and PlanDate<=@CurrentPlandate1
				/*and ProductLine =@Flow*/ Group by Item
			--发的库存不管(因为当天没过完，发的数量抓不准影响单件的排产优先级)，所以只以当天9点+当天计划推算到第二天的初始库存
			/*Select cast(s.Item As varchar(100))Item ,
				Case when s.Qty-s.OrderQty >0 then s.Qty-s.OrderQty else 0 end as Qty  into #Ship
				from MRP_MrpPlan s 
				where PlanDate =@CurrentPlandate
				and Item in(
				Select 物料 from #MachineInstance)*/
			Update c
				Set c.期初库存=c.期初库存 +ISNULL(a.InQty,0) from #PrimaryInv c Inner join #InPlan a on c.Item =a.Item
			--Select Item,SUM(ATPQty) As 期初库存 into #PrimaryInv 
			--	from VIEW_LocationDet  as l with(nolock)inner join MD_Location as loc with(nolock) on l.Location = loc.Code 
			--	where loc.IsMrp = 1 and l.ATPQty>0 and Item in (
			--	Select 物料 from #MachineInstance) 
			--	Group by Item
			--0002End
			--select * from #PrimaryInv
			Insert into #PrimaryInv
				Select 物料,0 As Inv from #MachineInstance where 物料 not in (select Item from #PrimaryInv)
				
			--每一个模具计划经行拆分计算
			select *,ShiftQuota*ShiftQty As ItemQty,ShiftQty/ShiftPerDay As workshift,CAST(0 as float) As FI1Qty,CAST(0 as float) As FI2Qty,CAST(0 as float) As FI3Qty  
				into #MRP_MrpFiMachinePlanSplitQtyToShift from #MRP_MrpFiMachinePlan
			--Select * from #MRP_MrpFiMachinePlanSplitQtyToShift
			--2014/02/14  三班的产能由认为控制 Begin
			--update #MRP_MrpFiMachinePlanSplitQtyToShift Set FI1Qty=ItemQty from #MRP_MrpFiMachinePlanSplitQtyToShift where ShiftType = 2 and ShiftQty/MachineQty <=1
			--update #MRP_MrpFiMachinePlanSplitQtyToShift Set FI1Qty=ShiftQuota*MachineQty,FI2Qty=ItemQty-ShiftQuota*MachineQty from #MRP_MrpFiMachinePlanSplitQtyToShift where ShiftType = 2 and ShiftQty/MachineQty >1
			--update #MRP_MrpFiMachinePlanSplitQtyToShift Set FI1Qty=ItemQty from #MRP_MrpFiMachinePlanSplitQtyToShift where ShiftType = 3 and  ShiftQty/MachineQty <=1
			--update #MRP_MrpFiMachinePlanSplitQtyToShift Set FI1Qty=ShiftQuota*MachineQty,FI2Qty=ItemQty-ShiftQuota*MachineQty from #MRP_MrpFiMachinePlanSplitQtyToShift where ShiftType = 3 and  ShiftQty/MachineQty >1 and ShiftQty/MachineQty<= 2
			--update #MRP_MrpFiMachinePlanSplitQtyToShift Set FI1Qty=ShiftQuota*MachineQty,FI2Qty=ItemQty-ShiftQuota*MachineQty,FI3Qty=ItemQty-2*ShiftQuota*MachineQty from #MRP_MrpFiMachinePlanSplitQtyToShift where ShiftType = 3 and  ShiftQty/MachineQty >2  
			Select * into #MRP_MrpFiMachinePlan_Split from #MRP_MrpFiMachinePlan T1 
				cross apply dbo.Func_SplitStr_Ids(T1.ShiftSplit,'+')
			Update a
				Set a.FI1Qty=b.F1*a.ShiftQuota from #MRP_MrpFiMachinePlanSplitQtyToShift a ,#MRP_MrpFiMachinePlan_Split b 
				where a.Id=b.Id and a.Island=b.Island and a.Machine=b.Machine 
				and a.PlanDate=b.PlanDate and a.ProductLine=b.ProductLine and b.Ids=0
			Update a
				Set a.FI2Qty=b.F1*a.ShiftQuota from #MRP_MrpFiMachinePlanSplitQtyToShift a ,#MRP_MrpFiMachinePlan_Split b 
				where a.Id=b.Id and a.Island=b.Island and a.Machine=b.Machine 
				and a.PlanDate=b.PlanDate and a.ProductLine=b.ProductLine and b.Ids=1
			Update a
				Set a.FI3Qty=b.F1*a.ShiftQuota from #MRP_MrpFiMachinePlanSplitQtyToShift a ,#MRP_MrpFiMachinePlan_Split b 
				where a.Id=b.Id and a.Island=b.Island and a.Machine=b.Machine 
				and a.PlanDate=b.PlanDate and a.ProductLine=b.ProductLine and b.Ids=2
			--2014/02/14  三班的产能由人为控制 Begin
			
			Declare @TableId int,@MachineType int,@可分配数 float ,@PlanDates Date --,@IsLand varchar(50),@machine varchar(50)
			Declare @FI1Qty float,@FI2Qty float,@FI3Qty float--,@ShiftType int
			Set @IsLand=''
			Set @machine=''
			Create table #SplitItemQty(PlanDate DateTime,Island varchar(50),Machine varchar(50),Item varchar(50),Shift varchar(50),allocationQty Float)
			Select @startdate=MIN(PlanDate) from #MRP_MrpFiMachinePlanSplitQtyToShift
			--Print @startdate
			----0002Begin
			Delete #MRP_MrpFiMachinePlanSplitQtyToShift where PlanDate <=@CurrentPlandate
			----0002End
			while exists(Select top 1 * from #MRP_MrpFiMachinePlanSplitQtyToShift)
				Begin
					print 'rows'
					--Select * from #MachineInstance where 岛区=650005 and 模具=600009
					--select * from #PrimaryInv
					--select * from #MRP_MrpFiMachinePlanSplitQtyToShift where PlanDate =@Planversion order by Id
					select top 1 @PlanDates=PlanDate,@TableId=Id,@Island=Island,@ShiftType=ShiftType ,@Machine =Machine,@MachineType=MachineType,@可分配数=ItemQty
						,@FI1Qty=FI1Qty,@FI2Qty=FI2Qty,@FI3Qty=FI3Qty
						from #MRP_MrpFiMachinePlanSplitQtyToShift order by PlanDate
					print @Island+';'+@Machine+';'
					
					Select 物料,期初库存,单包装 ,@可分配数 As 可分配数量,CAST(0 As float) As 已分配数 into #temp
					      from #MachineInstance a,#PrimaryInv b where a.岛区=@Island and a.模具=@Machine and a.物料 =b.Item
					--600015
					 
					--成套
					if @MachineType=1
						Begin
							Insert into #SplitItemQty
								select @PlanDates,@Island,@Machine,物料,'FI'+cast(@ShiftType as varchAR )+'-1'As Shift,@FI1Qty from #temp  union
								select @PlanDates,@Island,@Machine,物料,'FI'+cast(@ShiftType as varchAR )+'-2'As Shift,@FI2Qty from #temp
							If @ShiftType=3
							Begin
								Insert into #SplitItemQty
									select @PlanDates,@Island,@Machine,物料,'FI'+cast(@ShiftType as varchAR )+'-3'As Shift,@FI3Qty from #temp 
							End
						End
					print @ShiftType
					--单件，按最小库存补足
					if @MachineType=2
						Begin
							Declare @MinInvItem varchar(50),@MinInvItemUC float,@AllowedQty float=0,@Break char(1)='N'
							--运算插入第一班
							Update #temp Set 可分配数量=@FI1Qty,已分配数=0
							While 1=1 and @FI1Qty >0
							Begin
								Select @MinInvItem=物料,@MinInvItemUC=单包装,@AllowedQty=可分配数量 from (select *,ROW_NUMBER()over(Order by 期初库存) As NONO  from #temp) a where NONO=1
								print @AllowedQty
								print @MinInvItemUC
								If @AllowedQty=0
									Begin
										Insert into #SplitItemQty
											select @PlanDates,@Island,@Machine,物料,'FI'+cast(@ShiftType as varchAR)+'-1'As Shift,已分配数 from #temp
										Break;
									End
								If @AllowedQty<@MinInvItemUC
									Begin
										Set @MinInvItemUC=@AllowedQty
									End
								UpDate #temp Set 已分配数=已分配数+@MinInvItemUC,期初库存=期初库存+@MinInvItemUC,可分配数量=可分配数量-@MinInvItemUC 
											where 物料=@MinInvItem
								UpDate #temp Set 可分配数量=可分配数量-	@MinInvItemUC where 物料!=@MinInvItem
								--select * from #temp
								print 'ing'
							End
							--运算插入第二班
							Update #temp Set 可分配数量=@FI2Qty,已分配数=0
							While 1=1 and @FI2Qty>0
							Begin
								Select @MinInvItem=物料,@MinInvItemUC=单包装,@AllowedQty=可分配数量 from (select *,ROW_NUMBER()over(Order by 期初库存) As NONO  from #temp) a where NONO=1
								If @AllowedQty=0
									Begin
										Insert into #SplitItemQty
											select @PlanDates,@Island,@Machine,物料,'FI'+cast(@ShiftType as varchAR)+'-2'As Shift,已分配数 from #temp
										Break;
									End
								If @AllowedQty<@MinInvItemUC
									Begin
										Set @MinInvItemUC=@AllowedQty
									End
								UpDate #temp Set 已分配数=已分配数+@MinInvItemUC,期初库存=期初库存+@MinInvItemUC,可分配数量=可分配数量-@MinInvItemUC 
											where 物料=@MinInvItem
								UpDate #temp Set 可分配数量=可分配数量-	@MinInvItemUC where 物料!=@MinInvItem
									print 'ing2'
							End
							--运算插入第三班
							Update #temp Set 可分配数量=@FI3Qty,已分配数=0
							While 1=1 and @FI3Qty>0 and @ShiftType=3
							Begin
								Select @MinInvItem=物料,@MinInvItemUC=单包装,@AllowedQty=可分配数量 from (select *,ROW_NUMBER()over(Order by 期初库存) As NONO  from #temp) a where NONO=1
								If @AllowedQty=0
									Begin
										Insert into #SplitItemQty
											select @PlanDates,@Island,@Machine,物料,'FI'+cast(@ShiftType as varchAR)+'-3'As Shift,已分配数 from #temp
										Break;
									End
								If @AllowedQty<@MinInvItemUC
									Begin
										Set @MinInvItemUC=@AllowedQty
									End
								UpDate #temp Set 已分配数=已分配数+@MinInvItemUC,期初库存=期初库存+@MinInvItemUC,可分配数量=可分配数量-@MinInvItemUC 
											where 物料=@MinInvItem
								UpDate #temp Set 可分配数量=可分配数量-	@MinInvItemUC where 物料!=@MinInvItem
								print 'ing1'	
							End
						End	
					--更新期初库存
					Update a
						Set a.期初库存=b.期初库存 from #PrimaryInv a,#temp b where a.Item=b.物料 
					Drop Table #temp
					--return 
					--Check script
					--Select Machine,SUM (allocationQty) from #SplitItemQty Group by Machine order by Machine
					--select Machine,SUM(ShiftQuota*ShiftQty) from MRP_MrpFiMachinePlan where PlanVersion='2014/1/19 19:24:15' and ProductLine ='FI11'
					--select *  from MRP_MrpFiMachinePlan where PlanVersion='2014/1/19 19:24:15' and ProductLine ='FI11' and  Machine ='600143'
					--select * from MRP_MrpFiShiftPlan  where PlanVersion='2014/1/19 19:24:15' and ProductLine ='FI11' 
					--and  Machine ='600143'
					--Select * from #SplitItemQty where Machine ='600143' and Item ='502012' order by Machine
					--select * from MRP_MrpFiMachinePlan where PlanVersion='2014/1/19 19:24:15' and ProductLine ='FI11'
					--and Machine ='600143' order by Machine
					Delete #MRP_MrpFiMachinePlanSplitQtyToShift where Id = @TableId
				End
			--select ItemQty, FI1Qty+FI2Qty+FI3Qty ,* from #MRP_MrpFiMachinePlanSplitQtyToShift where ItemQty=FI1Qty+FI2Qty+FI3Qty 
			--Select distinct item,unitcount  from MRP_MrpFiShiftPlan where PlanVersion = '2014-01-19 19:24:15.000' and Machine='600001'
			--select 模具,物料,单包装  from #MachineInstance where 模具='600001'
			----select 模具,单包装  from #MachineInstance where 模具='600001'
			--覆盖已经存在的shiftPlan
			
			--select top 1000 * from MRP_MachineInstance
			--Last step ,generate FI shift plan seq--order by island,machine,seq
			Delete MRP_MrpFiShiftPlan where PlanVersion =@Planversion and ProductLine =@Flow and PlanDate >@CurrentPlandate1/*0002*/
			Insert into MRP_MrpFiShiftPlan(ProductLine, Item, PlanDate, Shift, Sequence, PlanVersion, Qty, Machine, MachineDescription, MachineQty, MachineType,
				 Island, IslandDescription, ShiftQuota, ShiftType, WorkDayPerWeek,
				 ShiftPerDay, UnitCount, StartTime, WindowTime, LocationFrom, LocationTo, Bom,OrderDetailId) 
			select @Flow As ProductLine, a.Item, a.PlanDate, a.Shift, ROW_NUMBER()over(order by a.island,a.machine,b.seq)*10 As  Sequence, @Planversion As PlanVersion, a.allocationQty As Qty , 
				a.Machine, b.Desc1 MachineDescription, b.Qty As MachineQty, MachineType, a.Island, c.Desc1 IslandDescription, ShiftQuota, 
				ShiftType,0 As WorkDayPerWeek, ShiftPerDay, d.UC UnitCount,
				dateadd(MINUTE,465+case when Shift ='FI3-2' then 480 when Shift ='FI3-3'  then 960 when Shift ='FI2-2' then 720 else 0 end ,PlanDate) As StartTime,
				dateadd(minute,465+case when Shift ='FI3-2' then 480+480 when Shift ='FI3-3'  then 960+480 when Shift ='FI2-2' then 720+720 when Shift ='FI2-1' then 720 when Shift ='FI3-1' then 480 else 0 end ,PlanDate) As WindowTime,
				 e.LocFrom LocationFrom,  e.LocTo LocationTo, isnull(d.Bom,a.Item) As Bom, '' OrderDetailId
				from #SplitItemQty a ,MRP_Machine b with(nolock),MRP_Island c with(nolock),SCM_FlowDet d with(nolock),SCM_FlowMstr e with(nolock)
				where a.Island =c.Code and a.Machine=b.Code and d.Flow=@Flow and d.Item=a.Item and d.Flow =e.Code
				and (b.StartDate is null or b.StartDate<@CurrentTime)and (b.EndDate is null or b.EndDate>@CurrentTime)
				and c.IsActive =1 and (d.StartDate is null or d.StartDate<@CurrentTime)and (d.EndDate is null or d.EndDate>@CurrentTime)
			--2014/02/26 以单包装向上圆整
			Update MRP_MrpFiShiftPlan
				Set Qty=CEILING (Qty/UnitCount)*UnitCount from MRP_MrpFiShiftPlan 
				where Qty/UnitCount like '%.%'  and  Qty/ShiftQuota like '%.%' and UnitCount!=0  
				and PlanVersion =@Planversion and ProductLine =@Flow
			
			--select top 1000 Seq,* from MRP_Machine 
			--select top 1000 Seq,* from MRP_Island 
			--select top 1000 * from MRP_MrpFiShiftPlan a order by Id desc
			
			----排产
			Select 'OK' As ChkResult ,'数据更新成功' AS ChkMessage
		End
	End Try
	Begin catch
		Select 'NG' As NG ,ERROR_MESSAGE() AS ChkMessage
	End catch
END
 