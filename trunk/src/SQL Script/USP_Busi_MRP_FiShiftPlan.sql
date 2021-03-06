USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_FiShiftPlan]    Script Date: 12/08/2014 15:09:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USP_Busi_MRP_FiShiftPlan '2014/1/11 11:09:02','FI21[后加工二区(申舒)]','Get'
ALTER PROCEDURE [dbo].[USP_Busi_MRP_FiShiftPlan]
(
	@DateIndex datetime,
	@Flow varchar(50),
	@Type varchar(50),
	@ParaAll varchar(max)=''
	
)
AS
BEGIN
	SET NOCOUNT ON
	----00001   每天的开始时间取PRD_shiftDet里的设定
	----00002   MachineType取最新的值
	----00003	补齐系统运行没有拍到的班别			--2014/01/17
    SELECT @Flow=LTRIM(RTRIM(@Flow)),@Type=LTRIM(RTRIM(@Type)),@ParaAll=LTRIM(RTRIM(@ParaAll))
    --Kit = 1,    //成套
    --Single = 2, //单件
	Set @Flow=Left(@Flow,4)
	If left(@Type,3)='Get'
	Begin
		Select Island As 岛区代码, Island+Islanddescription As 岛区,MachineType As 类型,Machine as 模具,a.Item As 物料,b.Desc1 As 物料描述,dbo.FormatDate(Plandate,'MM-DD-')+Shift As ShifDay,
			case when @Type='Get' then round(ShiftQuota*machineQty/*case when shifttype=2 /*and shiftperday=3*/ then 1.5 else 1 end*/,0) else 0 end As ShiftQuotaQty  ,
			case when @type='get' then round(Qty,0) else 0 end as Qty,0 as colorindex into #tmp  
			from MRP_MrpFiShiftPlan a with(nolock) ,MD_Item b with(nolock) where a.PlanVersion=@DateIndex and a.ProductLine=@Flow
		And a.Item=b.Code
		If @@rowcount =0
			Begin
				Select '所选择的查询条件，系统无数据，请重新选择!' As NG
				Return 
			End
		--00002
		Update a
			Set a.类型 =b.MachineType from #tmp a,MRP_Machine b where a.模具=b.Code 
		--Update colorindex SigleQty 1"=",2"<",3">" shiftQuota 1不变色，2绿色，3红色
		update a
			Set a.colorindex=case when a.ShiftQuotaQty=b.singleQty then 1 when a.ShiftQuotaQty>singleQty then 2 else 3 end from #tmp a ,
			(select 岛区代码,岛区,类型,模具,ShifDay,SUM(Qty)as singleQty from #tmp where 类型=2 group by 岛区代码,岛区,类型,模具,ShifDay) b where 
			 a.岛区=b.岛区 and a.类型 =b.类型 and a.模具=b.模具 and a.ShifDay =b.ShifDay 
		update #tmp set colorindex=case when  ShiftQuotaQty=  Qty then 1 when ShiftQuotaQty>Qty then 2 else 3 end where 类型=1
		--and StartTime='2013-07-11 00:00:00.000' and  Island='650013' and machine='600026'
		--and Bom='501064'
		--Select top 1000 bom,* from MRP_MrpFiShiftPlan
		--Select top 1000 bom,* from MD_Item
		--Select top 1000 * from #tmp
		-----加入没有排计划的物料
		Declare @ShiftDay varchar(20)
		select top 1 @ShiftDay=ShifDay from #tmp 
		Insert into #tmp
		select distinct Island,Island+c.Desc1,MachineType ,Machine,b.Item,d.Desc1,@ShiftDay,case when @Type='Get' then round(ShiftQuota*a.Qty/**case when shifttype=2 /*and shiftperday=3*/ then 1.5 else 1 end*/,0) else 0 end As ShiftQuotaQty  ,
			case when @type='get' then round(0,0) else 0 end as Qty,1 as colorindex  from MRP_Machine a with(nolock),SCM_FlowDet b  with(nolock),MRP_Island c with(nolock),MD_Item d with(nolock)
			where a.Code =b.Machine and Flow =@Flow and a.Island =c.Code and b.Item =d.Code 
				and (b.StartDate is null or b.StartDate< GETDATE())
				and (b.EndDate is null or b.EndDate> GETDATE())
		--select *  from MRP_Machine a with(nolock),SCM_FlowDet b  with(nolock) where Code =b.Machine and Flow =@Flow
        UPdate  a
			Set a.物料描述='[定额='+CAST(ShiftQuota As varchar)+']'+ 物料描述  from #tmp a, MRP_Machine b with(nolock) where a.模具 = b.Code
		Update #tmp Set ShifDay =replace(replace(replace(ShifDay,'FI2-','FI-'),'FI3-','FI-'),'FI1-','FI-')
		--Update #tmp Set Qty=cast(qty as varchar(20))+'-'+cast(ID As varchar(20))
		Declare @SQL varchar(max)=''
		Declare @SQL1 varchar(max)=''
		--00003
		Create table #tmp1(ShifDay varchar(20))
		Insert into #tmp1
			Select distinct LEFT(ShifDay,6) +'FI-1' from #tmp union
			Select distinct LEFT(ShifDay,6) +'FI-2' from #tmp
		If exists(select * from #tmp where ShifDay like '%FI-3%')
		Begin 
			Insert into #tmp1
				Select distinct LEFT(ShifDay,6) +'FI-3' from #tmp 
		End
		---XXX
		select distinct 物料 into #物料 from #tmp
		Declare @StartDate1 date 
		Select @StartDate1=dbo.FormatDate(MIN(PlanDate),'YYYY/MM/DD') from MRP_MrpFiShiftPlan where PlanVersion=@DateIndex
		Declare @i int =1
		Declare @CheckDate varchar(20) 
		While @i<15
		Begin
			Set @CheckDate = dbo.FormatDate( dateadd(day,@i,@StartDate1),'MM-DD')
			If not exists(select 0 from #tmp1 where ShifDay like '%'+@CheckDate+'%')
				Begin
					print @CheckDate
					Insert into #tmp1
						Select @CheckDate+'-FI-1'union
						Select @CheckDate+'-FI-2'
					If exists(select * from #tmp where ShifDay like '%FI-3%')
					Begin 
						Insert into #tmp1
							Select @CheckDate+'-FI-3'
					End
				End
			Set @i=@i+1
		End
		--SELECT DISTINCT ShifDay INTO #tmp1 FROM #tmp ORDER BY ShifDay
		SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),ShifDay)+'],0)'+' as ['+ShifDay +'],'
			,@SQL1=@SQL1+'['+ShifDay +'],'
		FROM #tmp1 ORDER BY ShifDay
		IF @SQL!=''
		BEGIN
			SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
			SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
		END
		--按模具Seq排序

		Declare @SnapTime datetime 
		    select top 1 @SnapTime=SnapTime from MRP_MrpPlanMaster where PlanVersion = @DateIndex
		print @SnapTime
		select distinct Item into #Items from MRP_FlowDetail with(nolock) where SnapTime =@SnapTime and Flow =@Flow and StartDate <=@DateIndex and EndDate >@DateIndex
		--Declare @StartDate varchar(50)
		Declare @CurrentTime datetime =getdate()
		Select 0 Seq, Item As 物料,space(50) 模具,b.Desc1 物料描述,sum(a.SafeStock) As 安全库存,sum(MaxStock) As 最大库存,cast(0 As decimal) As 期初库存 into #StockConfigQty 
			from SCM_FlowDet a with(nolock),MD_Item b with(nolock) ,SCM_FlowMstr c with(nolock)
			where a.Item =b.Code and b.Code in (select *  from #Items)
			and a.Flow =c.Code and c.ResourceGroup=30 and c.IsMRP =1
			and MrpWeight >0 and (a.StartDate is null or a.StartDate< @CurrentTime)
			and (a.EndDate is null or a.EndDate> @CurrentTime)
			Group by Item,b.Desc1--,Machine
		Update a
			Set a.Seq=b.Seq,模具=b.Machine from #StockConfigQty a, SCM_FlowDet b with(nolock) where a.物料=b.Item and b.Flow=@Flow
		--按模具Seq排序
		Declare @SQLInterim varchar(max)=@SQL
		--If @type='Get'
		--Begin
			set @SQL='SELECT 岛区代码,岛区,模具,物料,物料描述,'+@SQLInterim+' into #Record FROM (select 岛区代码,岛区,模具,物料,物料描述,Qty,ShifDay from #tmp) as D  pivot(max(Qty) for ShifDay in ('+@SQL1+')) as PVT order by 岛区 desc ; Select count(*) As TotalRow from #Record ; Select b.* from #StockConfigQty a left join #Record b on a.物料=b.物料 order by 模具,Seq;'
			Print @SQL
			EXEC (@SQL)
		--End
		--else if @type='Color'
		--Begin
			set @SQL='SELECT 岛区代码,类型,模具,物料,物料描述,'+@SQLInterim+' into #Record  FROM (select 岛区代码,岛区,类型,模具,物料,物料描述,ShiftQuotaQty,ShifDay from #tmp) as D  pivot(max(ShiftQuotaQty) for ShifDay in ('+@SQL1+')) as PVT order by 岛区 desc;Select b.* from #StockConfigQty a left join #Record b on a.物料=b.物料 order by 模具,Seq;'
			Print @SQL
			EXEC (@SQL)

		--End
		--Else
		--Begin
			set @SQL='SELECT 岛区代码,类型,模具,物料,物料描述,'+@SQLInterim+' into #Record  FROM (select 岛区代码,岛区,类型,模具,物料,物料描述,colorindex,ShifDay from #tmp) as D  pivot(max(colorindex) for ShifDay in ('+@SQL1+')) as PVT order by 岛区 desc;Select b.* from #StockConfigQty a left join #Record b on a.物料=b.物料 order by 模具,Seq;'
			Print @SQL
			EXEC (@SQL)
		--End

	End
	If @Type='Update'
		Begin
			
			Declare @Para varchar(1000),@Island varchar(100), @Machine varchar(100), @Item varchar(100),@Shift varchar(100), @Date varchar(100),@Qty varchar(100)
			Declare @plandate datetime,@startdate datetime,@Windowdate datetime,@ShiftType int,@sequence int
			--Declare @CheckResult varchar(max)='',@MachineType int ,@MaxQty float,@MaxDateIndex varchar(20),@MinDateIndex varchar(20),@CurrentQty float
			--Select *,'N' As UpdateFl ag into #MRP_MrpFiShiftPlan from MRP_MrpFiShiftPlan a with(nolock) where a.PlanVersion=@DateIndex and a.ProductLine=@Flow	
			--Select @MaxDateIndex=dbo.formatdate(max(Plandate),'YYYY-MM-DD'),@MinDateIndex=dbo.formatdate(min(Plandate),'YYYY-MM-DD') from #MRP_MrpFiShiftPlan
			--select * into #MRP_MachineInstance from MRP_MachineInstance with(nolock)
			--	where dateindex between @MinDateIndex and @MaxDateIndex and datetype=4
			Select * into #ParaListGroup from dbo.[Func_SplitStr](@ParaAll,';')
			Create table #ParaList(diagitem varchar(100),diagvalue varchar(100))
			while Exists (select top 1* from #ParaListGroup)
				Begin
					select top 1 @Para=F1 from #ParaListGroup
					Insert into #ParaList 
					select * from dbo.[Func_SplitStr_ItemValue](@Para,',')
					select @island=diagvalue from #ParaList where diagitem='island'
					select @machine=diagvalue from #ParaList where diagitem='machine'
					select @Item=diagvalue from #ParaList where diagitem='Item'
					select @Shift=diagvalue from #ParaList where diagitem='Shift'
					select @Date=diagvalue from #ParaList where diagitem='Date'
					select @Qty=diagvalue from #ParaList where diagitem='Qty'
					--select * from #ParaList
					If not exists(select top 1 * from MRP_MrpFiShiftPlan with(nolock) where Item=@Item and replace(replace(Shift,'FI2-','FI-'),'FI3-','FI-') =@Shift 
						and dbo.FormatDate(Plandate,'YYYYMMDD')=@date and planversion=@DateIndex)
						Begin

							select top 1 @ShiftType=ShiftType from MRP_MrpFiPlan with(nolock) where PlanVersion=@DateIndex and Item =@Item

							Set @Shift=REPLACE(@Shift,'FI','FI'+CAST(@ShiftType As varchar))
							Set @plandate =dbo.Format_To_Date(@Date)
							--select @Island,@Shift,@plandate
							select @sequence=MAX(Sequence) from MRP_MrpFiShiftPlan with(nolock) 
								where Island=@Island and Shift =@Shift and PlanDate =@plandate 

							If @sequence is null
								Begin
								--select 'AA'
									Set @sequence=10
								End
							select @startdate=DATEADD(HOUR,case when @Shift like 'FI_-1' then 0 when @Shift like 'FI_-2' then 8 else 16 end,@plandate),
								@Windowdate=DATEADD(HOUR,case when @Shift like 'FI_-1' then 8 when @Shift like 'FI_-2' then 16 else 24 end,@plandate)
							----00001
							Declare @TimeDiff int 
							select @TimeDiff=substring(shifttime,1,2)*60+substring(shifttime,4,2)*1 from PRD_ShiftDet where Shift like 'FI3-1%'
							select @startdate =DATEADD(MINUTE,@TimeDiff,@startdate),@Windowdate =DATEADD(MINUTE,@TimeDiff,@Windowdate)
							----00001
							--select @Shift,@sequence,@startdate,@Windowdate
							 --Select top 3 * from MRP_MrpFiShiftPlan
							-- Select top 3  * from MRP_MrpFiPlan
							Insert into MRP_MrpFiShiftPlan(ProductLine, Item, PlanDate, Shift, Sequence, PlanVersion, Qty, Machine, MachineDescription, MachineQty, MachineType, Island, IslandDescription, ShiftQuota, ShiftType, WorkDayPerWeek, ShiftPerDay, UnitCount, StartTime, WindowTime, LocationFrom, LocationTo, Bom)
								select top 1 ProductLine,Item,@plandate,@Shift,@sequence,PlanVersion, @Qty,@Machine,MachineDescription,machineqty,
									MachineType,Island ,IslandDescription,ShiftQuota,ShiftType,WorkDayPerWeek,ShiftPerDay ,UnitCount,@startdate,@Windowdate,LocationFrom,LocationTo ,Bom 
									from dbo.MRP_MrpFiPlan with(nolock) where /*shift =@Shift and*/ PlanVersion=@DateIndex  and Item =@Item
									And Island =@Island and Machine =@Machine and ProductLine=@Flow--and PlanDate =@plandate ----考虑取消
							--Select @@ROWCOUNT As 插入的行数
							--select @Shift,@DateIndex,@Item
						End
						Else
						Begin
							Update MRP_MrpFiShiftPlan
								Set Qty=@Qty from MRP_MrpFiShiftPlan where Island=@island and machine=@machine
									and Item=@Item and replace(replace(Shift,'FI2-','FI-'),'FI3-','FI-') =@Shift and dbo.FormatDate(Plandate,'YYYYMMDD')=@date
									and planversion=@DateIndex
						End
					----Record the abnormal update 
					If @@rowcount !=1
							Begin
								Insert into Sconit_log (SP_Name, Command, LogTime)
									select 'USP_Busi_GetFiShiftPlan','AbnormalUpdate',GetDate()
							End
					Delete #ParaListGroup where F1 = @Para
					Delete #ParaList
				End
				Select 'OK' As ChkResult ,'数据更新成功' AS ChkMessage
		End
END




















					------检查班产定额是否有超出Begin 班别为12小时的以8小时为基数换算
					------****************************
					--Update #MRP_MrpFiShiftPlan
					--	Set Qty=@Qty,UpdateFlag='Y' from #MRP_MrpFiShiftPlan where Island=@island and machine=@machine
					--		and Item=@Item and replace(replace(Shift,'FI2-','FI-'),'FI3-','FI-') =@Shift and dbo.FormatDate(Plandate,'YYYY-MM-DD')=@date
					--		and planversion=@DateIndex
					----Set @Date=Substring(@Date,1,4)+'-'+Substring(@Date,5,2)+'-'+Substring(@Date,7,2)
					----select top 1 @MachineType=MachineType,@MaxQty=ShiftQuota*Qty*case when shifttype=2 then 1.5 else 1 end from #MRP_MachineInstance where Code =@machine
					----	and  dateindex =@Date and datetype=4
					----If @MachineType=2
					----	Begin
					----		select machine, sum(Qty) As Qty into #Interim from #MRP_MrpFiShiftPlan where machine=@machine
					----			and replace(replace(Shift,'FI2-','FI-'),'FI3-','FI-') =@Shift and dbo.FormatDate(Plandate,'YYYY-MM-DD')=@date
					----			Group by machine Having sum(Qty)>@MaxQty
					----			If @@Rowcount!=0
					----			Begin
					----				--select 'DD'
					----				select @CurrentQty=Qty from #Interim
					----				select  @CheckResult=@CheckResult+@machine+':班别'+@Shift+'现有数量'+cast(@Qty as varchar)+'超过上限'+cast(@MaxQty As varchar)+'; ' --from #Interim
					----			End
					----		Drop table #Interim
					----	End
					----Else
					----	Begin
					----		If @Qty>@MaxQty
					----			Begin
					----				Set @CheckResult=@CheckResult+'模具'+@machine+'数量超过'+cast(@MaxQty As varchar)+'; '
					----			End
					----	End
					
					------检查班产定额是否有溢出End
					------***************************

					----Select @machine,@island,@date,@Item,@Qty
					----Select * from MRP_MrpFiShiftPlan where Island=@island and machine=@machine
					----	and Item=@Item and shift =@Shift and dbo.FormatDate(Plandate,'YYYYMMDD')=@date
					----	and planversion='2013-06-19 11:16:30'
