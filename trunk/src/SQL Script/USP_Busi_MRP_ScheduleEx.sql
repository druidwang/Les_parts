USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_ScheduleEx]    Script Date: 12/08/2014 15:13:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		liqiuyun
-- Create date:20130727
-- Description:	对挤出天计划排产进行算法修正
-- =============================================
ALTER PROCEDURE [dbo].[USP_Busi_MRP_ScheduleEx]
	(
	@DateIndex varchar(50),
	@SnapTime datetime,
	@PlanVersion datetime
	)
AS
--declare @DateIndex varchar(50)='2013-36',
--@PlanVersion datetime='2013/8/26 09:34:32'
--#######################--Modification History
--DateTime			Modifier	Action																	LogNo
--2013/09/01 21:12	温祥永		Change group by condition from "ProductLine ,section" to "section"		--0001
--2013/09/04 09:40	温祥永		Correct update commands													--0002
--2013/09/05 10:01	温祥永		Pay attention to the key words "Top 1" ,
--								it can't be missed otherwise wrong max value will be assigned			--0003
--2014/01/06 09:34  温祥永      Use  MRP_ProductType instead of enumeration								--0004

--#######################--
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
    --Return
	Declare @TestFlag char(1)='Y'
	--select Item ,COUNT(distinct ProductLine)  from MRP_prodlineex group by Item having COUNT(distinct ProductLine)>1
	--select top 1000 Section ,COUNT(*) from MRP_MrpExSectionPlan where PlanVersion=@PlanVersion and DateIndex =@DateIndex group by Section having COUNT( ProductLine)>5

	----Get the week start and end time 
	Declare @WeekEnd datetime,@Id int,@ProductLine varchar(20),@MaxLotSize float,@LotSize float,@Section varchar(20),@Id_1 int,@LotBatch int
	Declare @tmpdate1 datetime
	Select @tmpdate1=dateadd(week,cast(substring(@DateIndex,charindex('-',@DateIndex,1)+1,2)as int),left(@DateIndex,4)+'-01-01')
	Select @WeekEnd= dateadd(day,-datepart(weekday,@tmpdate1)+2,@tmpdate1)
	--drop table #MRP_MrpExSectionPlan ;drop table #LastPlanOfLines ;drop table #NeedInsertExSectionPlan ;drop table #OriginalArray
	select * into #MRP_MrpExSectionPlan from MRP_MrpExSectionPlan with(nolock)where PlanVersion=@PlanVersion and DateIndex =@DateIndex --and PlanDate >=@WeekEnd
	if @TestFlag='Y'
		Begin
			select @WeekEnd as 'WeekEnd',@tmpdate1 as 'tmpdate1'
		End
	If 1=1
		----Reminding:Insert into shift qty need to take maxlotsize into consideration (MRP_prodlineex) 插入办别数需要考虑最大经济批量
		Begin
		
			----Get each last plan record for these lines that have idle shcedule 获取所有的空置的线别
			select *,ROW_NUMBER()over(partition by  productline order by WindowTime desc) as NONO into #LastPlanOfLines 
				from #MRP_MrpExSectionPlan where  WindowTime <=@WeekEnd and Section !='299999'
			select IDENTITY(int,1,1) as id ,ProductLine,DATEDIFF(HOUR,WindowTime,@WeekEnd)/8 as RemainShiftQty into #AllowInsertShiftQty 
				from #LastPlanOfLines where NONO=1
			select IDENTITY(int,1,1) as id, ProductLine,Section,MaxLotSize,SUM(ShiftQty)ShiftQty into #NeedInsertExSectionPlan 
				from #MRP_MrpExSectionPlan where PlanDate >=@WeekEnd group by ProductLine,Section,MaxLotSize
			select ProductLine,Section ,PlanDate,ShiftQty ,starttime ,windowtime,
				ROW_NUMBER()over(order by ProductLine,starttime/*PlanDate*/)*10 as NONO ,cast(0 as float)Lotsize ,cast(0 as float)MaxLotSize,
				0 as LotBatch,'Y' as Insertable,'N' as OverFlow,CAST(0 as float) as TotalBySection,ProductType 
				into #OriginalArray from #MRP_MrpExSectionPlan where  Section !='299999' and StartTime <@WeekEnd order by ProductLine,starttime

			select ProductLine,Section ,PlanDate,ShiftQty,ShiftQty As OriginalShiftQty ,starttime ,windowtime,
				ROW_NUMBER()over(order by ProductLine,starttime/*PlanDate*/)*10 as NONO ,cast(0 as float)Lotsize ,cast(0 as float)MaxLotSize,
				0 as LotBatch,'N' as Insertable,'Y' as OverFlow,CAST(0 as float) as TotalBySection,ProductType 
				into #OriginalArrayOverFlow from #MRP_MrpExSectionPlan where  Section !='299999' and StartTime >=@WeekEnd order by ProductLine,PlanDate
			If not exists(select top 1 0 from #OriginalArrayOverFlow)
				Begin
					Insert into Sconit_Log (SP_Name,Command,LogTime)
						select 'USP_Busi_MRP_ScheduleEx',CAST(@DateIndex as varchar)+':'+dbo.FormatDate(@SnapTime,'YYYY-MM-DD-HHNNSS')+':'+ dbo.FormatDate(@PlanVersion,'YYYY-MM-DD-HHNNSS')+'没有溢出的排产!',GETDATE()
					Return
				End
			Update a Set a.TotalBySection=b.TotalBySection from #OriginalArrayOverFlow a,(select /*ProductLine,*/Section,SUM(ShiftQty) TotalBySection--0001 
				 from #OriginalArrayOverFlow group by /*ProductLine,*/Section)b--0001
				 where /*a.ProductLine =b.ProductLine  and */a.Section =b.Section--0001 
			--select * from #OriginalArray a, (select *,NONO+10 NONOB from #OriginalArray ) b where a.NONO=NONOB and a.Section =b.Section and a.ProductLine =b.ProductLine 
			--Declare @WeekEnd datetime,@Id int,@ProductLine varchar(20),@MaxLotSize float,@LotSize float,@Section varchar(20),@Id_1 int,@LotBatch int
			select @Id=10,@Id_1 =0,@LotBatch=1
			while exists(select top 1 * from #OriginalArray where NONO =@id)
				Begin
					select @LotSize=LotSize,@ProductLine =ProductLine,@Section =Section from #OriginalArray where NONO =@id
					select @Id_1=@Id
					while exists(select * from #OriginalArray where NONO =@Id_1+10 and ProductLine=@ProductLine and Section=@Section)
						Begin
							select @ProductLine =ProductLine,@Section =Section from #OriginalArray where NONO =@Id_1+10
							Set @Id_1=@Id_1+10
						End
					select @LotSize=SUM(ShiftQty)from #OriginalArray where NONO between @Id and @Id_1
					update #OriginalArray set LotSize=@LotSize ,LotBatch=@LotBatch  where ProductLine=@ProductLine and Section=@Section and NONO between @Id and @Id_1
					select @Id=@Id_1+10,@LotBatch=@LotBatch+1
				End
				if @TestFlag='Y'
					Begin
						print '已经完成连续生产端面班别总和的计算'
					End
			Update a
				Set a.MaxLotSize =b.MaxLotSize  from #OriginalArray a,MRP_ProdLineEx b with(nolock) where a.ProductLine=b.ProductLine and a.Section =b.Item 
			Update #OriginalArray set Insertable ='N' where Lotsize >=MaxLotSize
			delete #AllowInsertShiftQty where RemainShiftQty=0
			--select * from #AllowInsertShiftQty ;select * from #OriginalArray;drop table #SectionPriority
			If @TestFlag='Y'
				Begin
					select * into #OriginalArray_Track_1 from #OriginalArray
					select * into #OriginalArrayOverFlow_1 from #OriginalArrayOverFlow
					select * into #AllowInsertShiftQty_Track_1 from #AllowInsertShiftQty
				End
			Create table #SectionPriority(Section varchar(20),Prioritty float)
			Declare @RemainQty float,@allocableShiftQty float,@acTualAllocation float,@alowInsertQty float
			Declare @InsertNONO int,@Rowcount int=0
			while exists(select top 1 * from #AllowInsertShiftQty)
				Begin 
					----按线一条一条地填充空缺的班别数,符合条件的断面优先级排列规则:如果该断面可以在除了这条线以外的其他线生产，则这个断面的优先级往后面靠，
					----如果是在相同多的线别生产，则已经在本条线排了计划的断面优先级往前靠，即柔性先排，刚性后排PS:要注意看下是否已经达到最大的批量
					select top 1 @Id=id,@ProductLine=ProductLine,@RemainQty=RemainShiftQty from #AllowInsertShiftQty order by ProductLine
				If @TestFlag='Y'
					Begin
						print '@Id1'+cast(@Id as varchar)+':'+@ProductLine
					End
					--Insert into #SectionPriority
					--	select top 10 Item,0 from MRP_prodlineex with(nolock) where ProductLine ='EX03' and Item in 
					--		(select Section from #NeedInsertExSectionPlan)
					--select * from #NeedInsertExSectionPlan 
					--select * from #SectionPriority 
					Insert into #SectionPriority
					select Item,COUNT(*) from MRP_prodlineex with(nolock) where Item in (select Section from #NeedInsertExSectionPlan)
						and ProductLine in (select ProductLine from #AllowInsertShiftQty where RemainShiftQty >0) and ProductLine=@ProductLine Group by Item
					if @@Rowcount=0
						Begin
							If @TestFlag='Y'
								Begin
									print 'continue:'+@ProductLine
								End
							Delete #AllowInsertShiftQty where id =@Id
							continue
						End
					Update #SectionPriority Set Prioritty =Prioritty-0.5  from #SectionPriority where Section in(
						select Section from #OriginalArray where ProductLine=@ProductLine)
					while exists(select top 1 * from #SectionPriority)
					Begin
						select top 1 @Section =section from #SectionPriority order by Prioritty 
						select @allocableShiftQty=ShiftQty,@acTualAllocation=ShiftQty,@MaxLotSize =MaxLotSize from #NeedInsertExSectionPlan where Section =@Section
						select @alowInsertQty=RemainShiftQty from #AllowInsertShiftQty where ProductLine=@ProductLine
						If @alowInsertQty<=@allocableShiftQty
						Begin
							Select  @acTualAllocation=@alowInsertQty,@alowInsertQty=0
						End
						Else
						Begin
							Select @acTualAllocation=@allocableShiftQty,@alowInsertQty=@alowInsertQty-@allocableShiftQty
						End
						----至此已经得到实际能够分配的断面班别数量@acTualAllocation,现在开始往#OriginalArray里面插入
						set @Rowcount=0
						----不能用Max函数，max函数后面取的@@ROWCOUNT值是不对的,Order By 必须记得加Top 1
						----0003
						select top 1 @InsertNONO= NONO from #OriginalArray where ProductLine=@ProductLine and Insertable ='Y' and Section=@Section order by NONO desc
						select top 1 @LotBatch =LotBatch from #OriginalArray where ProductLine=@ProductLine and Insertable ='Y' and Section=@Section order by LotBatch desc
						----
						If @@ROWCOUNT =0
							Begin
								Select @InsertNONO=MAX(NONO),@LotBatch =max(LotBatch) from #OriginalArray where ProductLine=@ProductLine and Insertable ='Y'
								Update #OriginalArray set NONO=NONO+10,LotBatch=LotBatch+1,StartTime=DATEADD(HOUR,@acTualAllocation*8,StartTime),
									WindowTime=DATEADD(HOUR,@acTualAllocation*8,WindowTime) where NONO >@InsertNONO and ProductLine=@ProductLine
								Update #OriginalArray set NONO=NONO+10,LotBatch=LotBatch+1
									where NONO >@InsertNONO and ProductLine!=@ProductLine
								select top 1 @MaxLotSize=MaxLotSize from mrp_prodlineex with(nolock) where Item =@Section and ProductLine=@ProductLine
								Insert into #OriginalArray
									select ProductLine,@Section ,PlanDate,@acTualAllocation ,windowtime ,dateadd(hour,@acTualAllocation*8,windowtime),
									@InsertNONO+10 as nono , @acTualAllocation as lotsize , @MaxLotSize, @LotBatch+1,'Y' as Insertable,'N' as OverFlow,TotalBySection,
									ProductType from #OriginalArray where NONO =@InsertNONO
									select ProductLine,@Section ,PlanDate,@acTualAllocation ,windowtime ,dateadd(hour,@acTualAllocation*8,windowtime),
									@InsertNONO+10 as nono , @acTualAllocation as lotsize , @MaxLotSize, @LotBatch+1,'Y' as Insertable,'N' as OverFlow,TotalBySection,
									ProductType from #OriginalArray where NONO =@InsertNONO 
								print 'InsertSection：'+@Section
							End
							Else
							Begin
								--print 'Updatewindowtime' return
								
								Update #OriginalArray Set StartTime=DATEADD(HOUR,@acTualAllocation*8,StartTime),
									WindowTime=DATEADD(HOUR,@acTualAllocation*8,WindowTime)where NONO >@InsertNONO
								----0002
									and ProductLine=@ProductLine
								----
								Update #OriginalArray Set WindowTime=DATEADD(HOUR,@acTualAllocation*8,WindowTime)where NONO =@InsertNONO
								----0002
									and ProductLine=@ProductLine
								----
								Update #OriginalArray set Lotsize =Lotsize+@acTualAllocation where LotBatch =@LotBatch
								print 'UpdateSection：'+@Section
							End
						----------
						----Delete already inserted section and update @alowInsertQty
						--select top 1000 * from #OriginalArrayOverFlow where  section='290059'
						Delete #SectionPriority where Section =@Section
						update #AllowInsertShiftQty set RemainShiftQty =@alowInsertQty
						Update #OriginalArrayOverFlow Set ShiftQty =ShiftQty -(OriginalShiftQty /case when TotalBySection=0 then 1 else TotalBySection end)*@acTualAllocation
							where Section=@Section ----and ProductLine=@ProductLine 
						Update #OriginalArray set Insertable ='N' where Lotsize >=MaxLotSize
						Delete #AllowInsertShiftQty where RemainShiftQty=0
						
					End
					--290044
					Delete #AllowInsertShiftQty where id =@Id
					print '@Id'+cast(@Id as varchar)
					--select * from MRP_prodlineex with(nolock) where Item ='290046'
					----检查有没有可以在末尾添加班别的断面

					----Process every idle line to maximum the rationality of plan distribution balance

				End
				----将跨天的班别分割
				If @TestFlag='Y'
					Begin
						print 'Finshed inserting the overflowed shifts'
						select * into #OriginalArray_Track_2 from #OriginalArray
					End
				Set @Id=10;
				Declare @StartTime datetime ;Declare @WindowTime datetime
				While exists(select top 1 * from #OriginalArray where NONO =@Id)
					Begin
						--Declare @StartTime datetime ;Declare @WindowTime datetime
					
						select @StartTime=StartTime,@WindowTime=WindowTime from #OriginalArray where NONO =@Id

						If dbo.FormatDate(@WindowTime,'YYYY-MM-DD')>dbo.FormatDate(@StartTime,'YYYY-MM-DD') and DATEPART(HOUR,@WindowTime)>0
						Begin
							--select '分割',@Id return select * from #OriginalArray where NONO =180
							Update #OriginalArray set WindowTime =dbo.FormatDate(@WindowTime,'YYYY-MM-DD')+' 00:00:00' where NONO =@Id
							update #OriginalArray set NONO =NONO+10 where NONO >@Id
							Insert into #OriginalArray
								select ProductLine,Section ,PlanDate,ShiftQty ,dbo.FormatDate(@WindowTime,'YYYY-MM-DD')+' 00:00:00' ,
								@WindowTime,@Id+10 as nono , lotsize ,MaxLotSize,LotBatch,Insertable,OverFlow,
								TotalBySection,ProductType from #OriginalArray where NONO =@Id 
							--Set @Id=@Id+10
						End

						Set @Id=@Id+10
					End
				Update #OriginalArray set PlanDate =dbo.FormatDate(StartTime,'YYYY-MM-DD')

				update #OriginalArray Set ShiftQty =(cast(DATEDIFF(MINUTE,StartTime,WindowTime) as decimal)/60/8)
				If @TestFlag ='Y'
					Begin
						select * into #OriginalArray_Track_3 from #OriginalArray
					End
				delete #OriginalArray where ShiftQty =0
				--select * from #OriginalArray
				--拼字串，调用 调整存储
				--prodLine=EX01,section=290008,Qty=A0.75,sectiondesc=C346导槽A1条,seq=5,weekday=星期一;
				--prodLine=EX01,section=290059,Qty=A0.5,sectiondesc=NBC（56117)后风窗
				
				Create Table #ProductType(Code varchar(5),CType int)
				--Declare @int int=65
				--while @int<91
				--Begin
				--	Insert into #ProductType values(CHAR(@int),(@int-64)*10)
				--	Set @int=@int+1
				--End
				--0004
				Insert into #ProductType
					Select Code,0 from MRP_ProductType where IsActive =1
				--0004
				Insert into #OriginalArray 
				select ProductLine ,Section,PlanDate ,ShiftQty ,StartTime ,WindowTime ,NONO ,Lotsize ,MaxLotSize ,LotBatch ,Insertable ,
						OverFlow,TotalBySection ,ProductType  from #OriginalArrayOverFlow where ShiftQty !=0
				Select a.*, b.Code+cast(a.shiftqty as varchar) as Qty,ROW_NUMBER()over(partition by plandate order by productline ,starttime) as seq into #OriginalArray_Merge  from #OriginalArray a,#ProductType b where a.ProductType =b.Code
				Select a.*, b.Code+cast(a.shiftqty as varchar) as Qty,ROW_NUMBER()over(partition by plandate order by productline ,starttime) as seq into #OriginalArray_Merge_track  from #OriginalArray a,#ProductType b where a.ProductType =b.Code
				Declare @ProdLine varchar(20),@ParaAdjust varchar(max)='',@seq int
				--select * from #OriginalArray_Merge
				Declare @plandate varchar(20),@weekdaydesc varchar(30),@PlanDateTime datetime,@Datediff int
				while exists(select top 1 * from #OriginalArray_Merge)
					Begin
						set @seq =1
						select top 1 @plandate=PlanDate from #OriginalArray_Merge order by PlanDate 
						--print @plandate
						select @PlanDateTime=dbo.Format_To_Date(replace(@plandate,'-',''))
						while exists(select top 1 1 from #OriginalArray_Merge where PlanDate =@plandate and seq =@seq)
							Begin
								select @Datediff=DATEDIFF(day,@PlanDateTime,@WeekEnd)
								--select @PlanDateTime
								print @datediff
								select @weekdaydesc= case when @Datediff=1 then '星期日'
									when @Datediff=2 then '星期六'when @Datediff=3 then '星期五'when @Datediff=4 then '星期四'
									when @Datediff=5 then '星期三'when @Datediff=6 then '星期二'when @Datediff=7 then '星期一'
									Else '溢出' End
								--prodLine=EX01,section=290008,Qty=A0.75,sectiondesc=C346导槽A1条,seq=5,weekday=星期一;
								select @ParaAdjust=@ParaAdjust+'prodLine='+ProductLine+',section='+Section+',Qty='+Qty+',sectiondesc='''''
									+',seq='+cast(seq as varchar) +',weekday='+@weekdaydesc+';' from #OriginalArray_Merge where PlanDate =@plandate and seq =@seq
								--if @plandate='2013-09-05' begin select * from #OriginalArray_Merge where PlanDate =@plandate and seq =@seq end
								Delete from #OriginalArray_Merge where PlanDate =@plandate and seq =@seq
								Set @seq =@seq +1
							End
						delete from #OriginalArray_Merge where PlanDate =@plandate 
					End
					set @ParaAdjust=LEFT(@ParaAdjust,LEN(@ParaAdjust)-1)
					select @dateindex,@planversion,@paraadjust,'update',LEN(@paraadjust)
					print @paraadjust
					----Add excution log
					Declare @Track1Count int;Declare @Track3Count int
					select @Track1Count=COUNT(*) from #OriginalArray_Track_1 
					select @Track3Count=COUNT(*) from #OriginalArray_Track_3 
					--Insert into Sconit_Log 
					--	select 'USP_Busi_MRP_ScheduleEx',CAST(@Track1Count as varchar)+':'+CAST(@Track3Count as varchar),GETDATE() from Sconit_Log
						
					--exec  USP_Busi_MRP_ExShiftPlan @dateindex,@planversion,@paraadjust,'update'
		End
END
--select ProductLine ,Section,PlanDate ,ShiftQty ,StartTime ,WindowTime ,NONO ,Lotsize ,MaxLotSize ,LotBatch ,Insertable ,
--	OverFlow,TotalBySection ,ProductType  from #OriginalArrayOverFlow
--select * from #OriginalArray where section='290009'
--select * from #OriginalArray_Track_1  where section='290009'
--select * from #OriginalArray_Track_3 order by NONO
-- select * from #OriginalArrayOverFlow_1 

-- select Section ,SUM(shiftqty) shiftqty into #1 from #OriginalArray group by Section
-- select Section ,SUM(shiftqty) shiftqty into #2 from #MRP_MrpExSectionPlan  group by Section
-- select * from #1 a,#2 b where a.Section =b.Section and a.shiftqty  =b.shiftqty 
-- select * from #OriginalArray where Section ='290059'
-- select * from #MRP_MrpExSectionPlan where Section ='290059'
----select * from #OriginalArray_Merge order by ProductLine , StartTime
----select * from #OriginalArray_Track_2  order by ProductLine , StartTime 
----select * from #OriginalArray  order by ProductLine , StartTime
--				--Select a.*, b.Code+cast(a.shiftqty as varchar) as Qty,ROW_NUMBER()over(partition by plandate order by productline ,starttime) as seq  from #OriginalArray a,#ProductType b where a.ProductType =b.CType
-- select * from #OriginalArray_Merge_track where ProductLine ='EX08' and PlanDate ='2013-09-05'
 
 