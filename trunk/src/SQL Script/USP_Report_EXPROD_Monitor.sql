USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_EXPROD_Monitor]    Script Date: 12/08/2014 15:15:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
--[USP_Report_EXPROD_Monitor] 
-- =============================================
ALTER PROCEDURE [dbo].[USP_Report_EXPROD_Monitor]
 
AS
BEGIN
SET NOCOUNT ON;
	/*-----Get first and last day of the week that need to be tracked.
	Declare @WeekDayBegin datetime
	Declare @WeekDayEnd datetime
	Declare @DateInDex varchar(50)
	----@WeekDayBegin  '2013-06-03 00:00:00.000'
	
	SELECT @WeekDayBegin = DATEADD(wk,  DATEDIFF(wk,0,getdate()),0)
	SELECT @WeekDayEnd=DATEADD(Day,7,@WeekDayBegin)
	SELECT  @WeekDayBegin,@WeekDayEnd
	SELECT  @DateInDex=cast(year(getdate()) as varchar)+'-'+Right('00'+cast(DATEPART(ww,getdate()) as varchar),2)
 
	--2013-24(06-10 -> 06-16)
	--线别:实际,总量,当前,当前周开始的基础时间
	--CoordinateBeign/CoordinateEnd----每一个计划单在时间轴上的*计划*开始与结束坐标
	--StartCoordinate/CloseCoordinate----每一个计划单在时间轴上的*实际*开始与结束坐标
	--Table: MRP_MrpExMonitor_Report 记录释放出来的计划工时，Table: MRP_MrpExMonitor_Report_Actual 
	--记录实际生产所经历的工时,Table: MRP_MrpExMonitor_Rep_RecordSet汇总前台所需要的数据，
	--每当看板的需要数据更新，这些表的数据将被全部被清空,重新计算最新的数据。
	Truncate table MRP_MrpExMonitor_Report
	Insert into MRP_MrpExMonitor_Report(Productline,PlanNo,CoordinateBegin,CoordinateEnd,PlanNoNeedTime,CoordinateTop,
		 TheoCoordinate,Seq)
		Select productline,PlanNo,cast(cast(datediff(minute,@WeekDayBegin,StartTime)as decimal)/60 as decimal(18,2))as CoordinateBegin,
		cast(cast(DateDiff(minute,@WeekDayBegin,WindowTime)as decimal)/60 as decimal(18,2))as CoordinateEnd,
		cast(cast(DateDiff(minute,StartTime,WindowTime)as decimal)/60 as decimal(18,2))as PlanNoNeedTime,
		168 as CoordinateTop,
		cast(cast(DateDiff(minute,@WeekDayBegin,GetDate())as decimal)/60 as decimal(18,2))as TheoCoordinate,
		cast(row_number()over(partition by Productline order by starttime,WindowTime) as decimal) as Seq 
		/*DateDiff(minute,@WeekDayBegin,@WeekDayEnd)*/ from MRP_MrpExOrder 
			where dateindex=@DateInDex ---and Productline ='EX01'
	Insert into MRP_MrpExMonitor_Report(Productline,PlanNo,CoordinateBegin,CoordinateEnd,
		PlanNoNeedTime,CoordinateTop, StartCoordinate ,CloseCoordinate,TheoCoordinate,Seq)
	    Select a.Productline,a.PlanNo+'UnWorkTime'PlanNo,a.CoordinateEnd 
			as CoordinateBegin,b.CoordinateBegin as CoordinateEnd,
			b.CoordinateBegin-a.CoordinateEnd as PlanNoNeedTime,a.CoordinateTop, 
			a.StartCoordinate,a.CloseCoordinate,a.TheoCoordinate,
			a.Seq+0.1 as Seq from MRP_MrpExMonitor_Report a,MRP_MrpExMonitor_Report b where 
			a.Productline=b.Productline and a.Seq=b.Seq-1 and a.CoordinateEnd !=b.CoordinateBegin 
	--第一个生产单号的计划开始时间跟一周的开始时间不一致,塞入一笔空闲的时间
	Insert into MRP_MrpExMonitor_Report
	Select  Productline,PlanNo+'PrePareUnWorkTime'PlanNo,0.00 as CoordinateBegin,CoordinateBegin as CoordinateEnd,
		CoordinateBegin as PlanNONeedTime,CoordinateTop ,null,null,TheoCoordinate,0.5 as Seq
		from MRP_MrpExMonitor_Report where seq=1 and coordinateBegin!=0 
	-- 
	
	------即使按照生产单号的StartTime顺序生产，StartTime 和StartDate也会不一样，所以对于实际的生产的坐标另开一张表来记录	Truncate table MRP_MrpExMonitor_Report_Actual
	Truncate Table MRP_MrpExMonitor_Report_Actual
	Insert into MRP_MrpExMonitor_Report_Actual(Productline,PlanNo,PlanNoNeedTime,CoordinateTop,
		StartCoordinate ,CloseCoordinate,TheoCoordinate,Seq)
		Select productline,PlanNo,
		cast(cast(DateDiff(minute,StartDate,CloseDate)as decimal)/60 as decimal(18,2))as PlanNoNeedTime,
		168 as CoordinateTop,
		cast(cast(DateDiff(minute,@WeekDayBegin,StartDate)as decimal)/60 as decimal(18,2))as StartCoordinate,
		cast(cast(DateDiff(minute,@WeekDayBegin,CloseDate)as decimal)/60 as decimal(18,2))as CloseCoordinate,
		cast(cast(DateDiff(minute,@WeekDayBegin,GetDate())as decimal)/60 as decimal(18,2))as TheoCoordinate,
		cast(row_number()over(partition by Productline order by StartDate,CloseDate) as decimal) as Seq 
		from MRP_MrpExOrder 
		where dateindex=@DateInDex and CloseDate is not null
		--and Productline ='EX01'----and productline='EX01'
	Insert into MRP_MrpExMonitor_Report_Actual(Productline,PlanNo,StartCoordinate,CloseCoordinate,
		PlanNoNeedTime,CoordinateTop,TheoCoordinate,Seq)
	    Select a.Productline,a.PlanNo+'UnWorkTime'PlanNo,a.CloseCoordinate 
			as StartCoordinate,b.StartCoordinate as CloseCoordinate,
			b.StartCoordinate-a.CloseCoordinate as PlanNoNeedTime,a.CoordinateTop, 
			a.TheoCoordinate,
			a.Seq+0.1 as Seq from MRP_MrpExMonitor_Report_Actual a,MRP_MrpExMonitor_Report_Actual b where 
			a.Productline=b.Productline and a.Seq=b.Seq-1 and a.CloseCoordinate !=b.StartCoordinate 
	--第一个生产单号的实际开始时间跟一周的开始时间不一致,塞入一笔空闲的时间
	Insert into MRP_MrpExMonitor_Report_Actual
	Select  Productline,PlanNo+'PrePareUnWorkTime'PlanNo,null,null,
		StartCoordinate as PlanNONeedTime,CoordinateTop ,0.00 as StartCoordinate,StartCoordinate as CloseCoordinate,TheoCoordinate,0.5 as Seq
		from MRP_MrpExMonitor_Report_Actual where seq=1 and StartCoordinate!=0 
	--  
	Truncate table MRP_MrpExMonitor_Rep_RecordSet
	--Drop table MRP_MrpExMonitor_Rep_RecordSet
	Insert into MRP_MrpExMonitor_Rep_RecordSet
	select ProductLine+'Released',PlanNo,PlanNoNeedTime,
		row_number() over (partition by ProductLine order by seq) as Seq,
		Case when PlanNo like '%UnWorkTime'then 2 else 1 end as IType  
		from MRP_MrpExMonitor_Report --order by Productline,SeqUpdate
	Union all
	select ProductLine+'Actual',PlanNo,PlanNoNeedTime,
		row_number() over (partition by ProductLine order by seq) as Seq,
		Case when PlanNo like '%UnWorkTime'then 4 else 3 end as IType
		from MRP_MrpExMonitor_Report_Actual --order by Productline,SeqUpdate
END
--select * from MRP_MrpExMonitor_Rep_RecordSet_1 order by ProductLine,seq
--Update MRP_MrpExMonitor_Rep_RecordSet_1 set theocapacity=130.00
--SP_Help'PRD_PlanBackflush'
--select * from MRP_MrpExOrder where planno='13241EX04290055'
--将要使用到的Series按批次整理好
Truncate table MRP_MrpExOrder_LineInfor
Insert into MRP_MrpExOrder_LineInfor
select ProdLineInfor,row_number()over(order by ProdLineInfor) as Seq  from  (select distinct replace(replace(productline,
	'Released',''),'Actual','')+'Released' as ProdLineInfor from MRP_MrpExMonitor_Rep_RecordSet  union
	select distinct replace(replace(productline,'Released',''),'Actual','')+'Actual' from MRP_MrpExMonitor_Rep_RecordSet)A

Truncate table MRP_MrpExMonitor_Rep_RecordSet_1
--SP_help'MRP_MrpExMonitor_Rep_RecordSet_1'
 
Declare @SelectSeq int=1
Declare @ProcessNo int=1
Declare @Batch int=1
Declare @Color varchar(50)=''
while exists(select top 1 * from MRP_MrpExMonitor_Rep_RecordSet )--where Seq=@SelectSeq)
	Begin
		If exists(select top 1 * from MRP_MrpExMonitor_Rep_RecordSet where Seq=@SelectSeq and PlanNo like '%UnWorkTime%')
			Begin
				Insert into MRP_MrpExMonitor_Rep_RecordSet_1--ProductLine ,PlanNo,PlanNoNeedTime,Seq as BatchNo,Color
					select a.Productline,PlanNo,PlanNoNeedTime,@Batch,'#FBFBFF'white,
					cast(cast(DateDiff(minute,@WeekDayBegin,GetDate())as decimal)/60 as decimal(18,2))as TheoCoordinate from MRP_MrpExOrder_LineInfor a Left join 
					(select * from MRP_MrpExMonitor_Rep_RecordSet where Seq=@SelectSeq and PlanNo like '%UnWorkTime%') b on a.productline=b.productline
						Set @Batch=@Batch+1
			End
		If exists(select top 1 * from MRP_MrpExMonitor_Rep_RecordSet where Seq=@SelectSeq and PlanNo not like '%UnWorkTime%')
			Begin
				Insert into MRP_MrpExMonitor_Rep_RecordSet_1--ProductLine ,PlanNo,PlanNoNeedTime,Seq as BatchNo,Color
					select a.Productline,PlanNo,PlanNoNeedTime,@Batch,case when (@ProcessNo % 2)=1 then '#0072E3'else '#00DB00'end
						,cast(cast(DateDiff(minute,@WeekDayBegin,GetDate())as decimal)/60 as decimal(18,2))as TheoCoordinate from MRP_MrpExOrder_LineInfor a Left join (select * from MRP_MrpExMonitor_Rep_RecordSet
						where Seq=@SelectSeq and PlanNo not like '%UnWorkTime%') b on a.productline=b.productline
						Set @Batch=@Batch+1
						Set @ProcessNo=@ProcessNo+1
						
			End
		delete MRP_MrpExMonitor_Rep_RecordSet where Seq=@SelectSeq
		Set @SelectSeq=@SelectSeq+1
	End
Update MRP_MrpExMonitor_Rep_RecordSet_1 set PlanNo='' where PlanNo is null
Update MRP_MrpExMonitor_Rep_RecordSet_1 set PlanNoNeedTime=0 where PlanNoNeedTime is null*/
Select * from MRP_MrpExMonitor_Rep_RecordSet_1
End
--#FBFBFF white
--#0072E3 white
--#00DB00 white
--select * from MRP_MrpExOrder_LineInfor a Left join (select * from MRP_MrpExMonitor_Rep_RecordSet
--where Seq=1) b on a.productline=b.productline



--Update MRP_MrpExMonitor_Rep_RecordSet set productline=productline+'Released' where itype in (1,2)
--Update MRP_MrpExMonitor_Rep_RecordSet set productline=productline+'Actual' where itype in (3,4)
--select top 100 ProductLine ,PlanNo,PlanNoNeedTime,Seq as BatchNo,space(50) as Color into MRP_MrpExMonitor_Rep_RecordSet_1 from MRP_MrpExMonitor_Rep_RecordSet 




