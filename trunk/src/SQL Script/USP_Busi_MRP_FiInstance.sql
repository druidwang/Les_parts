USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_FiInstance]    Script Date: 12/08/2014 15:09:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USP_Busi_MRP_FiInstance '650001','600001','','2013-08-30'
--USP_Busi_MRP_FiInstance '','','','2013-08-30'
ALTER PROCEDURE [dbo].[USP_Busi_MRP_FiInstance]
(
	@Island varchar(50),
	@Machine varchar(50),
	@Item varchar(50),
	@DateIndex varchar(50)
)
AS
BEGIN
	SET NOCOUNT ON
Declare @CurrentDateTime datetime = getdate()
--岛区,模具,物料,生产线 650001M-K导槽501205Model K前门光亮导槽右600001M-K光亮导槽
--select * from MRP_MachineInstance where DateIndex ='2013-08-30'
---- m.Island,i.Desc1,m.Code,m.Desc1,f.Flow ,m.MachineType,m.ShiftPerDay,m.ShiftQuota*3/m.ShiftType as ShiftQuota,
----m.NormalWorkDayPerWeek,f.UC,f.Item,item.Desc1模具数量
--select top 1000 * from SYS_CodeMstr 
--select top 1000 * from scm_flowdet 
--select top 1000 * from SYS_CodeDet where Code like '%machine%'
--Kit = 1,    //成套
--Single = 2, //单件
SELECT @Island=LTRIM(RTRIM(@Island)),@Machine=LTRIM(RTRIM(@Machine)),@Item=LTRIM(RTRIM(@Item)),@DateIndex=LTRIM(RTRIM(@DateIndex))
select Distinct b.Island+'<br>'+e.Desc1+'<br>岛区数:'+cast(e.Qty as varchar) 岛区,b.Code+'<br>'+b.Desc1 模具,b.Qty as 模具数量,c.Code 物料,c.Desc1 物料描述,case when b.MachineType=1 then '1[成套]' 
	when b.MachineType=2 then '2[单件]' else CAST( b.MachineType as varchar) end as 模具类型,
	cast(b.ShiftPerDay As varchar(50)) + '['+cast(24/ShiftType As varchar)+'小时/每班]'  as [班/每天],NormalWorkDayPerWeek as 周工作天数,b.ShiftQuota as 班产定额,cast(a.UC as decimal(18,0)) as 单包装,
	a.Flow 生产线,d.Desc1 生产线描述, 0 as mergeisland,0 as mergemachine  into #tmp
	from SCM_FlowDet a with(nolock), MRP_Machine b with(nolock),MRP_Island e with(nolock),MD_Item c with(nolock),SCM_FlowMstr d with(nolock)
	where a.Machine is not null and a.Machine =b.Code and a.Item=c.Code and a.Flow=d.Code and b.Island=e.Code
	and (b.StartDate is null or b.StartDate<@CurrentDateTime)and (b.EndDate is null or b.EndDate>@CurrentDateTime)
	 ---and b.DateType=4  and b.DateIndex =@DateIndex
	and d.IsMRP = 1 and d.Type =4 and d.ResourceGroup = 30 and d.IsActive =1 and a.MrpWeight>0
	and (a.StartDate is null or a.StartDate<@CurrentDateTime)and (a.EndDate is null or a.EndDate>@CurrentDateTime)
	and isnull(a.Machine,'')!='' 
	--and b.DateIndex between a.StartDate and EndDate 
----Trace Island by Machine or item
If @@ROWCOUNT =0
	begin
		select 0 as totalcolumns,0 as mergerows
		return
	end
select 12 as totalcolumns,0 as mergerows
--根据
If isnull(@Machine ,'')!=''
	Begin
		select top 1 @Island = left(岛区,CHARINDEX('<',岛区)-1) from #tmp where  left(模具,CHARINDEX('<',模具)-1) = @Machine
	End
select * into #tmpRec from #tmp where 岛区 like isnull(@Island ,'')+'%' ---and 模具 like isnull(@Machine ,'')+'%'
		and 岛区 in (select distinct 岛区 from #tmp where 物料 like isnull(@Item ,'')+'%')

update a
	set a.mergeisland =b.mergeisland  from #tmpRec a ,(select 岛区,COUNT(*) mergeisland from #tmpRec group by 岛区) b where a.岛区=b.岛区
update a
	set a.mergemachine =b.mergemachine  from #tmpRec a ,(select 岛区,模具 ,COUNT(*) mergemachine from #tmpRec group by 岛区,模具) b where a.岛区=b.岛区
	and a.模具 =b.模具
--Set up column length here
select 50,50,50,50,50,50,50,70,50,50,50,120
select * from 	#tmpRec order by 岛区 ,模具

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
