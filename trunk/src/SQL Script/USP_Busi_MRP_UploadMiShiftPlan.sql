USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_UploadMiShiftPlan]    Script Date: 12/08/2014 15:14:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USP_Busi_GetMiShiftPlan '2013/6/21 13:55:41','MI01[炼胶主线]','Get'


ALTER PROCEDURE [dbo].[USP_Busi_MRP_UploadMiShiftPlan]
(
	@Plandate varchar(50),
	@Flow varchar(50),
	@ParaAll varchar(max)='',
	@ParaAll1 varchar(max)=''
	--@SeqPara varchar(max)=''
)
AS
BEGIN
	SET NOCOUNT ON
	----00001   每天的开始时间取PRD_shiftDet里的设定  2013/11/01 10:23
	----00002   路线和物料的信息部匹配则给一个提醒	  2013/11/01 10:55
	----00003   时间精确到秒，舍弃毫秒	  2013/11/04 10:55
    Select @ParaAll= REPLACE(REPLACE(@ParaAll,CHAR(13),''),CHAR(10),'')
    Set @Plandate=REPLACE(REPLACE(REPLACE(@Plandate,'年','-'),'月','-'),'日','-')
	--select *,'N' As UpdateFlag into #MRP_MrpMiShiftPlan_U from MRP_MrpMiShiftPlan  where PlanVersion ='2013/6/21 13:55:41' and ProductLine=@flow
	Declare @Para varchar(max),@Island varchar(100), @Machine varchar(100), @Item varchar(100),@Shift varchar(100),@Qty varchar(100)
	Declare @ClearTime float,@ShiftTotalTime float,@startdate datetime,@Windowdate datetime,@CreateDate datetime,@planversion datetime
	Declare @Huto varchar(1000),@Date datetime
	select @CreateDate=dbo.FormatDate(GETDATE(),'YYYY-MM-DD HH:NN:SS'),@planversion=dbo.FormatDate(GETDATE(),'YYYY-MM-DD HH:NN:SS')
	select @ClearTime=Value from SYS_EntityPreference where id=20002--清洗时间
	Select 'MI01' as Productline,* into #ParaListGroup from dbo.[Func_SplitStr](@ParaAll,';')
	Insert into #ParaListGroup 
		Select 'MI02' as Productline,*from dbo.[Func_SplitStr](@ParaAll1,';')
	Create table #ParaList(diagitem varchar(100),diagvalue varchar(100))
	select top 0 * into #MRP_MrpMiShiftPlan from MRP_MrpMiShiftPlan with(nolock)
	while Exists (select top 1* from #ParaListGroup)
		Begin
			select top 1 @Para=F1,@Flow=Productline from #ParaListGroup
			Insert into #ParaList 
			select * from dbo.[Func_SplitStr_ItemValue](@Para,',')
			select @Item=replace(diagvalue,'-','') from #ParaList where diagitem='Item'
			select @Shift=diagvalue from #ParaList where diagitem='Shift'
			select @Qty=diagvalue from #ParaList where diagitem='Qty'
			select @Huto=diagvalue from #ParaList where diagitem='Huto'
			select @Huto='0'+@Huto where @Huto like '[123456789]'
			select @Qty='0' where rtrim(ltrim(@Qty))=''
			if  (LEN(@Item)in (1,0))
				Begin
					--delete #MRP_MrpMiPlan where HuTo =@Huto and Item =@Item and Qty=@Qty
					print 'ignore:'+@Item
					Delete #ParaListGroup where F1 = @Para
					Delete #ParaList
					continue 
				End
			select @Shift=case when @Shift ='早' then 'MI-1'when @Shift ='中' then 'MI-2' else 'MI-3' end
			--select * from #ParaList

			--Begin to insert plans
			Set @Shift=REPLACE(@Shift,'MI-','MI3-')
			--Set @plandate =dbo.format_to_date(@Plandate)
			select @startdate=DATEADD(HOUR,case when @Shift='MI3-1' then 0 when @Shift='MI3-2' then 8 else 16 end,@plandate),
				@Windowdate=DATEADD(HOUR,case when @Shift='MI3-1' then 8 when @Shift='MI3-2' then 16 else 24 end,@plandate)
			If ISNUMERIC(@Qty)=0
				Begin
					Declare @Msg varchar(max)=''
					select @Msg=@Msg+':Shift='+@Shift+':item='+@Item+':QTY='+@Qty
					select '以下计划的数量格式不正确：'+@Msg As NG
					Return
				End
			----00002
			--select distinct a.Item,ProductLine  into #WarningItems from #MRP_MrpMiShiftPlan a where not exists (select 0 from SCM_FlowDet b with(nolock) where a.Item=b.Item and a.ProductLine=b.Flow)
			if not exists(select top 1 0 from SCM_FlowDet with(nolock) where Flow=@Flow and Item =@Item )

				Begin
					Declare @Msg1 varchar(max)=''
					select @Msg1=@Msg1+':item='+@Item+':ProdLine='+@Flow 
					select '以下物料和产线的匹配关系不存在。'+@Msg1 As NG
					Return
				End
			----00002
			--Location 优先取 FlowDet,null 则 FlowMstr---炼胶有两个单包装概念，一个是车单包装:MINUC,另一个是箱单包装:UC,手动上传计划是以"车"为单位。
			Insert into #MRP_MrpMiShiftPlan(Sequence, ProductLine, PlanVersion, PlanDate, Shift, Item, Qty, AdjustQty, Uom, UnitCount, WorkHour, HuTo, 
				OrderedQty, StartTime, WindowTime, Bom, LocationFrom, LocationTo, CreateDate)
				select top 1 Seq,@Flow,@planversion,dbo.FormatDate(@plandate,'YYYY-MM-DD'),@Shift,Item,/*b.UC*/case when a.MinUC=0 then a.UC else a.MinUC end *@Qty As Qty,0 As AjQTY,a.Uom,a.MinUC,WorkHour,@Huto,
					0 As orderedQty,@startdate,@Windowdate ,isnull(a.Bom,@Item) ,isnull(a.LocFrom,c.LocFrom),isnull(a.LocTo,c.locto),@CreateDate
					from  SCM_FlowDet a with(nolock),MD_Item b with(nolock),SCM_FlowMstr c with(nolock) where Item =@Item and a.Item=b.Code
					and a.Flow =c.Code and a.Flow =@Flow
			--select top 1000* from SCM_FlowMstr

			----Record the abnormal update 
			If @@rowcount !=1
					Begin
						Insert into Sconit_log (SP_Name,Command,LogTime)
							select 'USP_Busi_GetMiShiftPlan',@Item+@Plandate+cast(@planversion as varchar)+@Shift+'AbnormalUpdate',GetDate()
					End
			Delete top(1) #ParaListGroup where F1 = @Para
			Delete #ParaList
		End
		--Process table MRP_MrpMiDateIndex
		--select * from MRP_MrpMiDateIndex
		--select * from PRD_ShiftDet where Shift like 'MI3%'
		--select top 1000 * from MRP_MrpMiShiftPlan


		Insert into MRP_MrpMiShiftPlan(Sequence, ProductLine, PlanVersion, PlanDate, Shift, Item, Qty, AdjustQty, Uom, UnitCount, WorkHour, HuTo, 
			OrderedQty, StartTime, WindowTime, Bom, LocationFrom, LocationTo, CreateDate)
		select Sequence, ProductLine, PlanVersion, PlanDate, Shift, Item, Qty, AdjustQty, Uom, UnitCount, WorkHour, HuTo, 
			OrderedQty, StartTime, WindowTime, Bom, LocationFrom, LocationTo, CreateDate from #MRP_MrpMiShiftPlan
		----00001
		Declare @TimeDiff int 
		select @TimeDiff=substring(shifttime,1,2)*60+substring(shifttime,4,2)*1 from PRD_ShiftDet where Shift like 'MI3-1%'
		Update MRP_MrpMiShiftPlan set StartTime =DATEADD(MINUTE,@TimeDiff,StartTime),WindowTime =DATEADD(MINUTE,@TimeDiff,WindowTime)
			where PlanVersion=@PlanVersion--- and PlanDate =@startdate
		
		----00001
		Update MRP_MrpMiDateIndex Set IsActive =0 from MRP_MrpMiDateIndex  where PlanDate=@plandate and IsActive =1 and ProductLine in('MI01','MI02')	
		Insert into MRP_MrpMiDateIndex(ProductLine, PlanDate, PlanVersion, IsActive, CreateUser, CreateUserNm, CreateDate, LastModifyUser, LastModifyUserNm, LastModifyDate)
			select 'MI01',dbo.FormatDate(@startdate,'YYYY-MM-DD HH:NN:SS'),dbo.FormatDate(@planversion,'YYYY-MM-DD HH:NN:SS'),1,2603,'超级用户',@CreateDate,2603,'超级用户',GETDATE()
			Union
			select 'MI02',dbo.FormatDate(@startdate,'YYYY-MM-DD HH:NN:SS'),dbo.FormatDate(@planversion,'YYYY-MM-DD HH:NN:SS'),1,2603,'超级用户',@CreateDate,2603,'超级用户',GETDATE()

		Select 'OK' As ChkResult ,'数据上传成功' AS ChkMessage
END
