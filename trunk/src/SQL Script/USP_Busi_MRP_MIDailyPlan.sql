USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_MIDailyPlan]    Script Date: 12/08/2014 15:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USP_Busi_MRP_MIDailyPlan '2013/6/27 15:38:28','MI01[炼胶主线]','Get'


ALTER PROCEDURE [dbo].[USP_Busi_MRP_MIDailyPlan]
(
	@PlanVersion datetime,
	@Flow varchar(50),
	@Type varchar(50),
	@ParaAll varchar(max)='',
	@SeqPara varchar(max)=''
)
AS
BEGIN
	SET NOCOUNT ON
    SELECT @Flow=LTRIM(RTRIM(@Flow)),@Type=LTRIM(RTRIM(@Type)),@ParaAll=LTRIM(RTRIM(@ParaAll))
    Select @ParaAll= REPLACE(REPLACE(@ParaAll,CHAR(13),''),CHAR(10),'')
	Set @Flow=Left(@Flow,4)
	If @Type ='GetSetValue'
		Begin
			select a.Value As ClearTime ,b.Value As MaxCars from SYS_EntityPreference a with(nolock) ,SYS_EntityPreference b with(nolock) where a.Id=20002 and b.Id =20003
			Return
		End
	If left(@Type,3)='Get'
	Begin
		Set @Flow=Left(@Flow,4)
		Declare @PlanVersionStartTime datetime, @PlanVersionEndTime datetime
		select @PlanVersionStartTime=MIN(PlanDate),@PlanVersionEndTime=max(PlanDate) from MRP_MrpMiPlan where PlanVersion =@PlanVersion 
		--select top 1000 * from MRP_MrpMiDateIndex a, MRP_MrpMiPlan b where IsActive =1 and a.PlanDate between @PlandateStart and @PlandateEnd
		--and a.ProductLine =@flow  and a.PlanVersion =b.PlanVersion and a.PlanDate =b.PlanDate and a.ProductLine =b.ProductLine and 
		--a.CreateDate=b.createdate 
		select a.Item,b.Desc1,round((Qty+AdjustQty)/UnitCount,0) as Qty,b.WorkHour As 工时,huto as 方向, dbo.FormatDate(a.Plandate,'YYYY-MM-DD')  As ShifDay into #tmp 
		from MRP_MrpMiPlan a,MD_Item b where a.ProductLine =@Flow and a.PlanVersion =@PlanVersion and a.Item =b.Code
		and Qty+AdjustQty!=0

		--select * from #tmp
		If @@rowcount =0
			Begin
				select 0 as rowcounts
				Select '所选择的查询条件，系统无数据，请重新选择!' As NG
				Return 
			End
		----显示运行版本时没有涉及到的物料
		--Insert into #tmp
		--select distinct Item AS AllowAddItem ,b.Desc1,0 as Qty,WorkHour as 工时,'' as 方向, dbo.FormatDate(@PlanVersionStartTime,'YYYY-MM-DD')  from SCM_FlowDet a with(nolock),MD_Item b with(nolock) where a.Flow =@flow and 
		--	(a.StartDate <=@PlanVersionEndTime or a.StartDate is null) and (a.EndDate>=@PlanVersionStartTime or a.EndDate is null)
		--	and a.Item =b.Code 

		--Update #tmp Set Qty=cast(qty as varchar(20))+'-'+cast(ID As varchar(20))
		Declare @SQL varchar(max)=''
		Declare @SQL1 varchar(max)=''
		SELECT DISTINCT ShifDay INTO #tmp1 FROM #tmp ORDER BY ShifDay
 
		SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),ShifDay)+'],0)'+' as ['+ShifDay +'],'
			,@SQL1=@SQL1+'['+ShifDay +'],'
		FROM #tmp1 ORDER BY ShifDay
		IF @SQL!=''
		BEGIN
			SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
			SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
		END		 
		set @SQL='SELECT Item 物料,Desc1 物料描述,isnull(方向,'''')方向,'''' as 方向描述,'''' As 胶料类型,round(工时,2) 工时,'+@SQL+' into #Record FROM (select * from #tmp) as D  pivot(sum(Qty)'+
		' for ShifDay in ('+@SQL1+')) as PVT order by Item desc; select count(*) from #Record ;select * from #Record '
		Print @SQL
		EXEC (@SQL)
	End
	If @Type='Update'
		Begin
			--select *,'N' As UpdateFlag into #MRP_MrpMiPlan from MRP_MrpMiPlan  where PlanVersion ='2013/6/21 13:55:41' and ProductLine=@flow
			select a.Item,b.Desc1,round((Qty+AdjustQty)/UnitCount,0) as Qty,b.WorkHour ,huto , dbo.FormatDate(a.Plandate,'YYYY-MM-DD')  As ShifDay into #tmp_1 
				from MRP_MrpMiPlan a,MD_Item b where a.ProductLine =@Flow and a.PlanVersion =@PlanVersion and a.Item =b.Code
				and Qty+AdjustQty!=0

			select a.*,'N' As UpdateFlag into #MRP_MrpMiPlan 
				from MRP_MrpMiPlan a,MD_Item b where a.ProductLine =@Flow and a.PlanVersion =@PlanVersion and a.Item =b.Code

			Declare @Para varchar(max),@Island varchar(100), @Machine varchar(100), @Item varchar(100),@Shift varchar(100), @Date varchar(100),@Qty varchar(100)
			Declare @ClearTime float,@ShiftTotalTime float,@plandate datetime,@startdate datetime,@Windowdate datetime,@CreateDate datetime 
			Declare @Huto varchar(1000),@id int
			select @ClearTime=Value from SYS_EntityPreference where id=20002--清洗时间
			Select * into #ParaListGroup from dbo.[Func_SplitStr](@ParaAll,';')
			Create table #ParaList(diagitem varchar(100),diagvalue varchar(100))
			while Exists (select top 1* from #ParaListGroup)
				Begin
					select top 1 @Para=F1 from #ParaListGroup
					Insert into #ParaList 
					select * from dbo.[Func_SplitStr_ItemValue](@Para,',')
					select @Item=diagvalue from #ParaList where diagitem='Item'
					select @Date=diagvalue from #ParaList where diagitem='Date'
					select @Qty=diagvalue from #ParaList where diagitem='Qty'
					select @Huto=diagvalue from #ParaList where diagitem='Huto'
					select @Huto='0'+@Huto where @Huto like '[123456789]'
					select @Qty='0' where rtrim(ltrim(@Qty))=''
					if exists(select 1 from #tmp_1 where HuTo =@Huto and Item =@Item and Qty=@Qty and dbo.FormatDate(ShifDay,'YYYYMMDD')=@date)
						Begin
							--delete #MRP_MrpMiPlan where HuTo =@Huto and Item =@Item and Qty=@Qty
							Delete #ParaListGroup where F1 = @Para
							Delete #ParaList
							continue 
						End
					else if (not exists(select 1 from #tmp_1 where HuTo =@Huto and Item =@Item and dbo.FormatDate(ShifDay,'YYYYMMDD')=@date)and @Qty=0)
						Begin
							Delete #ParaListGroup where F1 = @Para
							Delete #ParaList
							continue
						End
					--select * from #ParaList
					select @CreateDate=null	
					Set @plandate =dbo.format_to_date(@Date)
					--select @CreateDate=CreateDate,@planversion=PlanVersion from MRP_MrpMiDateIndex where PlanDate=@plandate and IsActive =1 and ProductLine=@Flow	

					If not exists(select top 1 * from #MRP_MrpMiPlan where Item=@Item 
						and dbo.FormatDate(Plandate,'YYYYMMDD')=@date and huto =@Huto )
						Begin
							--手动添加进去的的需求量设置为0,车数转化为调整数
							--Select * from MRP_MrpMiPlan
							select @id=MAX(id)+1 from MRP_MrpMiPlan with(nolock)
							--return
							Insert into MRP_MrpMiPlan(id,ProductLine, Item, PlanDate, LocationFrom, LocationTo, PlanVersion, Sequence, WorkHour, UnitCount, Qty,
								AdjustQty, MrpPriority, MaxStock, SafeStock, InvQty, HuTo, Bom, Uom, BatchSize)
								select top 1 @id, Flow, Item, @plandate, isnull(LocFrom,''), isnull(LocTo,''), @PlanVersion, Seq, WorkHour, b.UC,0 As Qty,a.UC*@Qty As AjQTY,
									MrpPriority, MaxStock, a.SafeStock, 0 As InvQty, @Huto,ISNULL ( a.Bom,@Item), b.Uom, BatchSize
									from  SCM_FlowDet a with(nolock),MD_Item b with(nolock) where Flow=@Flow and Item =@Item and a.Item=b.Code
									--and PlanDate =@plandate
							--Select @@ROWCOUNT As 插入的行数
							--select @Shift,@DateIndex,@Item
						End
						Else
						Begin
							Update #MRP_MrpMiPlan
								Set AdjustQty=  @QTy*UnitCount -Qty,UpdateFlag ='Y' from #MRP_MrpMiPlan 
									where Item=@Item  and dbo.FormatDate(Plandate,'YYYYMMDD')=@date
									and planversion=@planversion   and HuTo =@huto
						End
					
					
					----Record the abnormal update 
					If @@rowcount !=1
							Begin
								Insert into Sconit_log( SP_Name,Command,LogTime)
									select 'USP_Busi_GetMiShiftPlan',@Item+@date+cast(@planversion as varchar)+@Shift+'AbnormalUpdate',GetDate()
							End
					Delete #ParaListGroup where F1 = @Para
					Delete #ParaList
				End
				--select* from #MRP_MrpMiPlan
				--Return
				--Check if total workhour is  overflow
				select dbo.FormatDate(PlanDate,'YYYY-MM-DD')As Dates,sum((Qty +AdjustQty)/UnitCount*WorkHour)As MinTime into #Warning  from #MRP_MrpMiPlan 
					Group by dbo.FormatDate(PlanDate,'YYYY-MM-DD') having sum((Qty +AdjustQty)/UnitCount*WorkHour)>60*8*3-@ClearTime*3
				--select * from #Warning 
				--If @@ROWCOUNT>0
				--	Begin
				--		Declare @Msg varchar(max)=''
				--		select @Msg=@Msg+ ','+Dates+'超时：'+cast(MinTime/60 As varchar)+';' from #Warning
				--		select '以下班别的计划工作时间超时，请重新修正数量并更新系统：'+@Msg As NG
				--		Return
				--	End
				Update b
				Set b.AdjustQty=a.AdjustQty from #MRP_MrpMiPlan a, MRP_MrpMiPlan b where a.Id=b.Id and a.UpdateFlag ='Y'
				Select 'OK' As ChkResult ,'数据更新成功' AS ChkMessage
		End
END
