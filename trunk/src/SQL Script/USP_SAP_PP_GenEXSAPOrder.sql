USE [Sconit_20150106]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_PP_GenEXSAPOrder]    Script Date: 01/07/2015 15:56:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<>
-- Create date: <2014/03/09>
-- Description:	<Received order information of interface for EX>
-- =============================================
ALTER PROCEDURE [dbo].[USP_SAP_PP_GenEXSAPOrder]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
BEGIN
	SET NOCOUNT ON;
	--2014/04/14  因为接口会人为调用，收集的时间段会不足8小时，这时候，参考的已经生成的SAP Order强制取8个小时的时间段  ---0001
	--2014/04/14  当前时间段新生成的SAP Order 也要参考  ---0002
	--2014/05/05  计算工时,同一生产线相邻两个收货单时间差,时间差>6hours则当做1小时算  ---0003
	--2014/08/04  计算工时,同一生产线相邻两个收货单时间差,时间差>6hours则取生产单的开始结束时间之差  --0004
	--2014/09/02  先临时表，再正式表	--0005
	--2014/09/18  判断是否加入临时表	--0006
	--EXEC USP_Interface_EX_ReceivedOrder  '2014-03-08 23:56:38.000'
	--Insert into SAP_TransTimeCtrl Select 'GenSapEXOrder',GETDATE(),GETDATE()
	Declare @CurDate datetime=Getdate()
	declare @ExecutionTime datetime
	Declare @refHourGap int =16----由当前时间往前推的参考小时数
	declare @refHourGapTimeBegin datetime
	--If @ExecutionTime is null
	--	Begin
	--		Set @ExecutionTime = dbo.Format_To_Date( dbo.FormatDate(GETDATE(),'YYYYMMDD'+'080000'))
	--	End
	Declare @ReferedSAPRecTime DateTime 
	Select @ReferedSAPRecTime=CurrTransDate  from SAP_TransTimeCtrl where SysCode ='GenSapEXOrder'
	Select @ExecutionTime=MAX(RecTime) from SAP_EX001 
	---0001Begin
	if @refHourGapTimeBegin is null
		Begin
			Set @refHourGapTimeBegin=DATEADD(HOUR,-@refHourGap,@ExecutionTime)
		End
	---0001End
	---收集8小时内的收货单--

	Select SPACE(50) As 批次号,a.OrderNo As 生产订单号,a.RecNo As 生产收货单 ,a.CreateDate AS 时间,
	Shift As 班次,a.Flow As 生产线 ,a.Item As 物料 ,SPACE(50) As 周, c.RefOrderNo As 断面 ,0 As 订单数,a.RecQty As 收货数
	,c.ExtOrderNo As SymbolOfPlan, ROW_NUMBER()Over(Order by a.Createdate) As Seq,b.OrderQty As 明细订单数,c.Priority As 是否紧急,
	CAST(0 As float) As ISM,
	--0004
	ABS(DATEDIFF(Minute,c.StartTime,c.WindowTime))As OrdISM,
	--0004
	Case when Isnull(c.ExtOrderNo,'')='' then 1 else 0 End As IsPriority,
	c.StartTime as PlanNoStartTime,c.WindowTime As PlanNoWindowTime
		into #SAP_EX001_Temp
		from ORD_RecDet_4 a,ORD_orderDet_4 b,ORD_orderMstr_4 c
		where a.OrderDetId =b.Id and b.OrderNo =c.OrderNo
		and c.ResourceGroup=20 
		and c.SubType=0
		and a.CreateDate > @StartTime and a.CreateDate<=@EndTime
		order by a.CreateDate
	Alter table #SAP_EX001_Temp alter column PlanNoStartTime datetime null 
	Alter table #SAP_EX001_Temp alter column PlanNoWindowTime datetime null 
	Update a
		Set a.周=d.WeekIndex  from #SAP_EX001_Temp	a ,MRP_WeekIndex d
		where dbo.FormatDate(a.时间,'YYYY-MM-DD') > =d.StartDate and dbo.FormatDate(a.时间,'YYYY-MM-DD')<=d.EndDate 
	--Select top 1000 * from MRP_WeekIndex
	--对所有的收货记录进行排序,循环处理
	--Update a
	--	Set a.Seq=b.NONO from #SAP_EX001_Temp a,
	--	(Select *,ROW_NUMBER()Over(Order by RecTime) As NONO  from #SAP_EX001_Temp where 批次号='')b
	--	Where a.生产收货单=b.生产收货单 and a.时间=b.时间


	---找到上一次传送的记录里面每组“生产线,物料”的最后一笔收货记录
	Select *,ROW_NUMBER()Over(Partition by ProductLine,Item Order by RecTime desc) As NONO 
		,StartTime PlanNoStartTime,WindowTime PlanNoWindowTime
		into #SAP_EX001_Temp1 
		from SAP_EX001 a 
		where a.RecTime > @refHourGapTimeBegin
		and RecNo like 'R%'
	Delete #SAP_EX001_Temp1 where NONO !=1
	---用循环去处理每条收货记录，批量更新是不合理的,因为批量更新后的数据需要实时塞入正式表，
	--这时候剩下的未更新的数据还会有一批是接着刚塞入的数据，Loading上应该OK
	Declare @i int =1
	Declare @ProductLine varchar(50)
	Declare @Item varchar(50)
	Declare @Section varchar(50)
	Declare @SerialNO varchar(50)
	Declare @SerialNNew varchar(50)
	Declare @WeekIndex varchar(50)
	Declare @RecTime DateTime
	Declare @RefOrderNo varchar(50)
	Declare @Priority varchar(10)
	Declare @Planversion DateTime
	Declare @ItemId Int
	Declare @DENSERANKNO Int
	Declare @CurrentItemIdSeq Int--当前这个ItemID所占的序号
	Declare @SumSeqStart Int--从这个序号开始聚合批次号的订单数量
	Declare @SumSeqEnd Int--从这个序号结束聚合批次号的订单数量
	Declare @ISM Float
	--PlanNo 规则是OE+两位年+两位周+六位物料号+流水号,Example:OE140930108501	
	Declare @NewPlanNo varchar(50)
	Declare @PlanNoQty Decimal(18,8)
	Declare @RateQty Float
	Declare @Speed Float
	Declare @IfInsertTemp Int
	Declare @PlanNoStartTime DateTime
	Declare @PlanNoWindowTime DateTime
	Set @IfInsertTemp=0
	----0003舍弃用速度折算的逻辑
	--Select b.Bom,b.Item,CAST(b.RateQty/m.Qty as float) as UnitQty 
	--into #ParentSubItems
	--from Sconit.dbo.PRD_BomDet b,Sconit.dbo.PRD_BomMstr m where b.Bom =m.Code
	--and  b.StartDate<=GETDATE() 
	--and b.EndDate> GETDATE() 
	--and b.Item like '29%'
	--and m.IsActive=1
	Select 生产线 As ProductLine,生产收货单 As RecNo ,时间 As RecTime into #SAP_EX001OISM from #SAP_EX001_Temp
	Insert into #SAP_EX001OISM 
		Select ProductLine,max(RecNo) ,max(RecTime) from SAP_EX001 
			Group by  ProductLine 
	Select *,ROW_NUMBER()Over(partition by ProductLine order by RecNo) AS NONO
		into #SortByProductLine
		from #SAP_EX001OISM 
	Select b.RecNo,ABS(DATEDIFF(minute,a.recTime,b.recTime)) As ISM into #CalculateISM from #SortByProductLine a,#SortByProductLine b 
		where a.ProductLine=b.ProductLine 
		And a.NONO=b.NONO-1
	Update a
		Set a.ISM=case when ISNULL(b.ISM,360)>360 then a.OrdISM/*--0004*/ else ISNULL(b.ISM,360) End from #SAP_EX001_Temp a left join #CalculateISM b 
		on a.生产收货单=b.RecNo
	----0003
	While exists(select * from #SAP_EX001_Temp where Seq=@i)
	Begin
		Set @ISM=0
		Select @ProductLine=生产线,@Item=物料,@RecTime=时间,@RefOrderNo=SymbolOfPlan,@WeekIndex=周,@Priority =是否紧急,@Section=断面
			from #SAP_EX001_Temp where Seq=@i

		UPdate b
			Set b.批次号=a.PlanNo,订单数=OrderQty,b.PlanNoStartTime =a.PlanNoStartTime,b.PlanNoWindowTime=a.PlanNoWindowTime from #SAP_EX001_Temp1 a,#SAP_EX001_Temp b 
				where Seq=@i 
				and a.ProductLine=b.生产线 and a.Item=b.物料 
				and DATEDIFF(MINUTE,a.RecTime,b.时间)<=480
				and a.Section=b.断面
				and a.IsPriority =0
				and b.IsPriority !=1
		If @@ROWCOUNT =0 --虽然下面的循环比较长，但是按照实际的业务，一次运行创建的新的批次号不会很多，所以被调用的也不会很多，性能应该OK
			Begin
				--Create New PlanNO
				Set @NewPlanNo=null 
				Set @SerialNO=null 
				Set @SerialNNew=null 
				Set @PlanNoStartTime=null
				Set @PlanNoWindowTime=null
				Set @NewPlanNo='OE'+SUBSTRING(@WeekIndex,3,2)+Right(@WeekIndex,2)+@Item
				Select @SerialNNew=right('00'+Cast(Cast(right(MAX(批次号),2)As int)+1 as varchar(10)),2) from #SAP_EX001_Temp --0005
					where 批次号 like @NewPlanNo+'%' -- and IsPriority=0

				--0002Begin
				If ISNULL(@SerialNO,'')=''
					Begin
						Select @SerialNO=right('00'+Cast(Cast(right(MAX(PlanNo),2)As int)+1 as varchar(10)),2) from SAP_EX001 --0005
							where PlanNo like @NewPlanNo+'%' and RecNo like 'R%' --and IsPriority=0
					End
				if ISNULL(@SerialNNew,'')!=''
					Begin
						If @SerialNNew>Isnull(@SerialNO,'')
							Begin
								Select @SerialNO=@SerialNNew
							End
					End
				--0002End
				Set @NewPlanNo =@NewPlanNo + ISNULL(@SerialNO,'00')
				--Calculate PlanNoQty --正常的订单
				--Situation One:有计划的生产单ShiftPlan.ItemId>0 正常的生产单,且ShiftPlan.ItemId==0(插单)
				If @Priority !='1' --正常和插单全部放到ShiftPlan里面算
					Begin
						Select @ItemId=ItemId,@WeekIndex = DateIndex,@Section=Section,@RateQty=RateQty,@Speed=Speed  from MRP_MrpExShiftPlan where Id =@RefOrderNo
						If 1=1--正常和插单都根据ShiftPlan里面的Section排班的连续性来算出批次号的数量
							Begin
								--
								Select @Planversion=PlanVersion from MRP_MrpExItemPlan where Id = @ItemId
								Select a.*,StartTime As SeailStartTimeOriginal,StartTime As SeailStartTime,0 As TimeGap,WindowTime As SeailWindowTime,
									ROW_NUMBER()Over(Order by StartTime ,WindowTime) As Seq,0 As DENSERANKNO
									into #TempMRP_MrpExItemPlan 
									from MRP_MrpExShiftPlan a
									where  a.ProductLine = @ProductLine 
									and a.Section =@Section 
									and a.DateIndex = @WeekIndex
									--2014/10/10
									and exists(Select * from MRP_MrpEXPlanMaster b where 
									a.PlanVersion =b.PlanVersion and a.ProductLine =b.ProductLine and a.PlanDate =b.PlanDate and
									a.ReleaseVersion =b.ReleaseVersion and a.Shift =b.Shift and IsActive =1 )
								Select @CurrentItemIdSeq=Seq from #TempMRP_MrpExItemPlan where Id = @RefOrderNo--一定要是ShiftPlanId
								update a 
									Set a.SeailStartTime=b.StartTime,TimeGap=Case when DateDiff(minute,a.WindowTime,b.StartTime)<0 then 0 else DateDiff(minute,a.WindowTime,b.StartTime) End
										from #TempMRP_MrpExItemPlan a,#TempMRP_MrpExItemPlan b 
										Where a.Seq =b.Seq-1
								Update #TempMRP_MrpExItemPlan Set TimeGap =0 where TimeGap<=15
								--Get @SumSeqStart/@SumSeqEnd value
								Select @SumSeqStart=MAX(seq)+1 from #TempMRP_MrpExItemPlan 
									where Seq<@CurrentItemIdSeq 
									and TimeGap!=0
								Set @SumSeqStart = ISNULL(@SumSeqStart,1)
								Select @SumSeqEnd=MIN(seq) from #TempMRP_MrpExItemPlan 
									where Seq>=@CurrentItemIdSeq 
									and TimeGap!=0
								If @SumSeqEnd is null
									Begin
										Select @SumSeqEnd=MAX(seq) from #TempMRP_MrpExItemPlan
									End
								---???版本被覆盖ItemId找不到怎么办？
								--
								--Update a
								--	Set a.DENSERANKNO=b.DENSERANKNO_1 from #TempMRP_MrpExItemPlan a,(
								--	Select *,DENSE_RANK()Over(Partition by Item Order by TimeGap) As DENSERANKNO_1  
								--		from #TempMRP_MrpExItemPlan) b
								--		where a.Id=b.Id
								--Select @DENSERANKNO=DENSERANKNO from  #TempMRP_MrpExItemPlan where Id =@ItemId
								Select @PlanNoQty=SUM(Qty)from #TempMRP_MrpExItemPlan  
									where Seq between @SumSeqStart and @SumSeqEnd and Item =@Item
								----Update PlanNo 开始结束时间
								Select @PlanNoStartTime=SeailStartTimeOriginal from #TempMRP_MrpExItemPlan  
									where Seq=@SumSeqStart and Item =@Item
								Select @PlanNoWindowTime=SeailWindowTime from #TempMRP_MrpExItemPlan  
									where Seq=@SumSeqEnd and Item =@Item
								----Update PlanNo 开始结束时间
								Drop table #TempMRP_MrpExItemPlan
								if @PlanNoQty is null or @PlanNoQty=0
									Begin
										Select @PlanNoQty=Qty from MRP_MrpExShiftPlan where Id =@RefOrderNo
										print 'cqty by shitplanid'
									End
							End
							--Else--插单，因为没衔接到历史的批次号，所以直接汇总当前时间段
							--Begin
							--	Select @PlanNoQty=SUM(b.Qty) from #SAP_EX001_Temp a ,MRP_MrpExShiftPlan b 
							--		where a.SymbolOfPlan=b.Id and b.ItemId=0 
							--		and a.生产线=@ProductLine
							--		and a.物料 =b.Item 
							--End
					End
					Else--紧急收货
					Begin
						------0003

						--Select @RateQty = UnitQty from #ParentSubItems where Item =@Item and Bom =@Section
						--Select @Speed=MrpSpeed from MRP_ProdLineEx  where Item= @Section
						------0003
						Select @PlanNoQty=SUM(明细订单数) from #SAP_EX001_Temp 
							where 生产线=@ProductLine
							and 物料=@Item and SymbolOfPlan is null
							and Seq = @i
					End
			Update #SAP_EX001_Temp Set 批次号=@NewPlanNo ,订单数 = @PlanNoQty/*,ISM=收货数*@RateQty/@Speed/60*/,
				PlanNoStartTime =ISNULL(@PlanNoStartTime,PlanNoStartTime),PlanNoWindowTime=ISNULL(@PlanNowindowTime,PlanNoWindowTime) where Seq = @i 
			End
		
		--Insert into #SAP_EX001_Temp1 正式表 继续循环
		--Select * from SAP_EX001 
		Insert into #SAP_EX001_Temp1(PlanNo, OrderNo, RecNo, RecTime, Shift, ProductLine, Item, WeekIndex, Section, OrderQty, RecQty,ISM,IsPriority,PlanNoStartTime,PlanNoWindowTime)
			Select a.批次号 As PlanNo,a.生产订单号 As OrderNo,a.生产收货单 As RecNO,a.时间 As RecTime,a.班次 As Shift,
			a.生产线 As ProductLine,a.物料 As Item,a.周 As WeekIndex,a.断面 As Section,订单数 As OrderQty,a.收货数 As RecQty,ISM,IsPriority,
			PlanNoStartTime,PlanNoWindowTime
			from #SAP_EX001_Temp a where Seq =@i
		Set @i =@i +1
	End
	--塞入正式表
	Insert into SAP_EX001(PlanNo, OrderNo, RecNo, RecTime, Shift, ProductLine, Item, WeekIndex, Section, OrderQty, RecQty,ZCSRQSJ,BatchNo,ISM,IsPriority,StartTime,WindowTime)
			Select a.批次号 As PlanNo,a.生产订单号 As OrderNo,a.生产收货单 As RecNO,a.时间 As RecTime,a.班次 As Shift,
				a.生产线 As ProductLine,a.物料 As Item,a.周 As WeekIndex,a.断面 As Section,订单数 As OrderQty,
				a.收货数 As RecQty ,@CurDate,@BatchNo As BatchNo,ISM,IsPriority,PlanNoStartTime,PlanNoWindowTime
				from #SAP_EX001_Temp a
			
	----update timecontroll
	Update SAP_TransTimeCtrl
	Set LastTransDate =@ReferedSAPRecTime,CurrTransDate=@ExecutionTime where SysCode ='GenSapEXOrder'
END
