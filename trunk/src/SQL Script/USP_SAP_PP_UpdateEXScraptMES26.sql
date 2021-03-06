USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_PP_UpdateEXScraptMES26]    Script Date: 12/08/2014 10:34:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
--[USP_SAP_PP_UpdatePPMES001Interim]  
--[USP_SAP_PP_UpdatePPMES001Interim]  
-- =============================================
ALTER PROCEDURE [dbo].[USP_SAP_PP_UpdateEXScraptMES26]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
--declare 
 --@LocationFrom varchar(50),
 --@LocationTo varchar(50),
 --@ItemFrom varchar(50),
 --@ItemTo varchar(50)
 
 
BEGIN
  SET NOCOUNT ON;
 --2014/10/27	XXXXXX ----0001

 Declare @CurrentTime datetime=Getdate()
 Declare @ZMESGUID varchar(50)=dbo.FormatDate(GETDATE(),'YYYYMMDDHHNNSS0000')
 Declare @ZMESGUID1 varchar(50)=dbo.FormatDate(Dateadd(Second,1,GETDATE()),'YYYYMMDDHHNNSS0000')
 Declare @WERKS varchar(50)
 Select @WERKS=Value from SYS_EntityPreference where Id = 90107
 Select Code into #NONSAP from MD_Location where SAPLocation ='N/A'
 
Select md.Id ,mm.MiscOrderNo ,SPACE(50) As ZMESSC,mm.MiscOrderNo+Right('00'+CAST(Seq As varchar),2) As OrderNo,Flow As ProdLine,mm.EffDate As EffectDate ,
	'' As Shift,md.Item, md.Qty ScraptQty ,mm.CloseDate As CreateDate,
	'MES26' As Reason,mm.MoveType,mm.Location,md.Uom into #Scrap_02 
	FROM ORD_MiscOrderMstr mm INNER JOIN ORD_MiscOrderDet md ON mm.MiscOrderNo=md.MiscOrderNo
	INNER JOIN MD_Location l ON l.Code=mm.Location
	WHERE mm.SubType in(26) AND mm.CloseDate>@StartTime AND mm.CloseDate<=@EndTime AND mm.IsCs=0
	AND mm.Location not in (Select Code from #NONSAP) AND mm.CreateUser<>3910
Select distinct mm.MiscOrderNo into #CancelMiscOrderNo FROM ORD_MiscOrderMstr mm INNER JOIN ORD_MiscOrderDet md ON mm.MiscOrderNo=md.MiscOrderNo
		INNER JOIN MD_Location l ON l.Code=mm.Location
		WHERE mm.SubType in(26) AND mm.Status=2 AND mm.CancelDate>@StartTime AND mm.CancelDate<=@EndTime AND mm.IsCs=0
		--0004--0005
		AND mm.Location not in (Select Code from #NONSAP) AND mm.CreateUser<>3910
Delete #Scrap_02 where MiscOrderNo in (Select MiscOrderNo from #CancelMiscOrderNo)
----冲销的ExRecNo
Select RecNo into #RecNo from ORD_RecMstr_4 where Status =1 and OrderSubType =0  
	and Flow in(Select Code from SCM_FlowMstr where ResourceGroup =20) and CreateDate >@StartTime
----
Declare @OrderNO varchar(20),@Shift varchar(20),@ProdLine varchar(20),@CreateDate DateTime,@EffectDateTime DateTime
Declare @RecDateTimeLt DateTime,@RecDateTimeGt DateTime,@EXItem varchar(20),@PlanNO varchar(20),@OrderQty float,@I Int=1
Declare @NewPlanNo varchar(30),@WeekIndex varchar(30),@SerialNO varchar(30),@Section varchar(20),@ScrpQty float
Select @WeekIndex= WeekIndex from MRP_WeekIndex d
		where dbo.FormatDate(Getdate(),'YYYY-MM-DD') >=d.StartDate and dbo.FormatDate(Getdate(),'YYYY-MM-DD')<=d.EndDate 
  while exists(Select 0 from #Scrap_02 where isnull(ZMESSC,'')='')
	Begin
		Select @PlanNo=null,@OrderQty =null
		Select top 1 @OrderNO=OrderNO,@Shift=Shift,@ProdLine=ProdLine,@CreateDate=EffectDate,@EffectDateTime=EffectDate,@EXItem=Item 
			,@ScrpQty =ScraptQty from #Scrap_02 where isnull(ZMESSC,'')=''
		--Select @OrderNO,@Shift,@ProdLine,@CreateDate,@EffectDateTime,@EXItem
		Declare @TimeDiff int=0
		Select @EffectDateTime=DATEADD(minute,@TimeDiff,@EffectDateTime)
		Select @RecDateTimeLt=MAX(RecTime) from SAP_EX001 
			where Item =@EXItem and RecTime <@EffectDateTime
			and RecNo not in (Select RecNo from #RecNo)
		Select @RecDateTimeGt=MIN(RecTime) from SAP_EX001 
			where Item =@EXItem and RecTime >@EffectDateTime
			and RecNo not in (Select RecNo from #RecNo)
		if @RecDateTimeGt is null and @RecDateTimeLt is null
		Begin
			print 'no matched planno'
		End
		Else
		Begin
			Select @RecDateTimeLt=ISNULL(@RecDateTimeLt,'1753-01-01'),@RecDateTimeGt=ISNULL(@RecDateTimeGt,'1900-01-01')
			If ABS(DATEDIFF(minute,@RecDateTimeLt,@EffectDateTime))>ABS(DATEDIFF(minute,@EffectDateTime,@RecDateTimeGt))
			Begin
				Set @EffectDateTime= @RecDateTimeGt
			End
			Else
			Begin
				Set @EffectDateTime= @RecDateTimeLt
			End
			Select top 1 @PlanNO =PlanNo,@OrderQty=OrderQty from SAP_EX001 
				where Item =@EXItem  and RecTime=@EffectDateTime
				and RecNo not in (Select RecNo from #RecNo)
		End
 
		If Isnull(@PlanNo,'')='' 
			Begin 
			--0006
			--Create New PlanNO
			Set @NewPlanNo='OE'+SUBSTRING(@WeekIndex,3,2)+Right(@WeekIndex,2)+Isnull(@EXItem,'')
			Select @SerialNO=right('00'+Cast(Cast(right(MAX(PlanNo),2)As int)+1 as varchar(10)),2) from SAP_EX001 where PlanNo like @NewPlanNo+'%'
			Set @NewPlanNo =@NewPlanNo + ISNULL(@SerialNO,'00')
			Set @PlanNo=@NewPlanNo
			If Isnull(@PlanNo,'')='' Begin Set @PlanNo='NoneUpdate' End
			Update #Scrap_02 Set ZMESSC = @PlanNo where orderNO =@orderNO 
			--Select top 100 * from SAP_EX001
			Insert into SAP_EX001(PlanNo, OrderNo, RecNo, RecTime, Shift, ProductLine, Item, WeekIndex, Section, OrderQty, RecQty,ZCSRQSJ,BatchNo,ISM)
				Select @NewPlanNo,dbo.FormatDate(dateadd(second,@I,Getdate()),'YYYYMMDDHHNNSS') As OrderNO,@OrderNO As RecNo,GETDATE() As RecTime,
					@Shift As Shift ,@ProdLine As ProductLine,@EXItem As Item,@WeekIndex As WeekIndex,'' As Section ,ceiling(@ScrpQty) As OrderQty,
					Case when @ScrpQty=0 then 1 else ceiling(@ScrpQty) End AS RecQty,Getdate() As ZCSRQSJ ,@BatchNO As BatchNo,0 As ISM
			End
			Else
			Begin
				Update #Scrap_02 Set ZMESSC = @PlanNo where orderNO =@orderNO 
			End
	End
 
	Declare @UinqCode varchar(100)=Replace(Newid(),'-','')

	--为了补传MES历史生产单,把非投料类型放在这里生成
	Insert into SAP_Interface_PPMES0003(ZMESSC, ZMESLN, ZPTYPE, WERKS, XMNGA,GMEIN_H, GRUND, ZComnum, BLDAT, BUDAT, 
			MTSNR, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status)
			Select ZMESSC As ZMESSC,1 As ZMESLN ,'BUSBG01' As ZPTYPE,@WERKS As WERKS,
				Left(cast(Case when ceiling(ScraptQty)=0 then 1 else ceiling(ScraptQty) End As  varchar),13) XMNGA,Uom As GMEIN_H ,Reason As GRUND,
				OrderNo As ZComnum,CreateDate As BLDAT,CreateDate As BUDAT,MiscOrderNo As MTSNR, '' As BWART_I, '' As MATNR_I,
				 '' As ERFMG_I, '' As GMEIN_I, '' As LGORT_I ,@ZMESGUID As ZMESGUID ,
				GETDATE() As ZCSRQSJ,@BatchNo As BatchNo,@BatchNo As UniqueCode,'0' as Status
				from #Scrap_02 
 
		----0010End
	--Select top 1000 * from SAP_Interface_PPMES0003
	Update SAP_Interface_PPMES0003 Set XMNGA='1' where CAST(XMNGA As float)=0 and XMNGA!='' and BatchNo =@BatchNo

	--补传MES历史生产单
	--0006

	Select Distinct a.ZMESSC, ZMESLN, 'BUSCO01' As ZPTYPE, 'SY01' As AUFART, @WERKS As WERKS, b.Item As MATNR_H,Cast('0' As varchar(13))  As GAMNG_H, GMEIN_H,
	@CurrentTime As GLTRP, @CurrentTime As GSTRP, BLDAT, BUDAT,MTSNR As LFSNR,'101' As  BWART_H, c.SAPLocation As LGORT_H, 
	Cast('0' As varchar(13)) As ERFMG_H, replace(ZComnum,'S','S')ZComnum, MTSNR, Cast('0' As varchar(13)) As LMNGA_H, Cast('0' As varchar(13)) As ISM, '261' As BWART_I, MATNR_I, 
	Cast('0' As varchar(13)) As ERFMG_I, GMEIN_I, c.SAPLocation LGORT_I, @ZMESGUID1 As ZMESGUID, ZCSRQSJ, BatchNo, @UinqCode As UniqueCode, '0' As Status,'HistoryEXOrder' OrderType, '0' As TailQty
	 into #Interface_PPMES0001
	 from SAP_Interface_PPMES0003 a,#Scrap_02 b,MD_Location c 
	 where a.ZMESSC =b.ZMESSC and a.BatchNo =@BatchNo
	 and b.Location=c.Code
	 and not exists(Select 0 from  SAP_Interface_PPMES0001 d where a.ZMESSC=d.ZMESSC and a.ZMESLN=d.ZMESLN)
	 Delete a from (select *,ROW_NUMBER()Over(partition by ZMESSC,ZMESLN order by MATNR_H) As NONO from #Interface_PPMES0001)
		a where a.nono!=1
		Select * into #PRD_BomDet from PRD_BomDet with(nolock) 
			where Bom in (select MATNR_H from #Interface_PPMES0001 /*where GMEIN_I=''*/)
			and (StartDate is null or  StartDate<@CurrentTime) 
			and (EndDate is null or  EndDate>@CurrentTime) 
		Update a
			Set a.MATNR_I=b.Item,a.GMEIN_I=b.Uom,LGORT_I=LGORT_H 
			from #Interface_PPMES0001 a , #PRD_BomDet b 
			where a.MATNR_H=b.Bom -- and isnull(MATNR_I,'')=''
		--29再往下拆一层
		Select * into #PRD_BomDet_I from PRD_BomDet with(nolock) 
			where Bom in (select MATNR_I from #Interface_PPMES0001 where MATNR_I like '29%')
			and (StartDate is null or  StartDate<@CurrentTime) 
			and (EndDate is null or  EndDate>@CurrentTime) 
		Update a
			Set a.MATNR_I=b.Item,a.GMEIN_I=b.Uom,LGORT_I=LGORT_H 
			from #Interface_PPMES0001 a , #PRD_BomDet_I b 
			where a.MATNR_I=b.Bom
			
		----
		Update a
			Set a.GMEIN_H=b.Uom from #Interface_PPMES0001 a,MD_Item b where a.MATNR_H=b.Code 
		Update #Interface_PPMES0001 Set MATNR_I =MATNR_H,GMEIN_I=GMEIN_H where MATNR_I=''
	Update a
		Set a.GAMNG_H=Left(Cast(b.OrderQty As varchar),13) from #Interface_PPMES0001 a,SAP_EX001 b where a.ZMESSC=b.PlanNo 
	 Insert into SAP_Interface_PPMES0001(ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H,
		GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, BWART_H, LGORT_H, ERFMG_H, ZComnum, MTSNR, LMNGA_H, ISM, BWART_I, MATNR_I, 
		ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status, OrderType, TailQty)
		Select ZMESSC, ZMESLN, ZPTYPE, AUFART, WERKS, MATNR_H, GAMNG_H, GMEIN_H,
		GLTRP, GSTRP, BLDAT, BUDAT, LFSNR, BWART_H, LGORT_H, ERFMG_H, ZComnum, MTSNR, LMNGA_H, ISM, BWART_I, MATNR_I, 
		ERFMG_I, GMEIN_I, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status, OrderType, TailQty from #Interface_PPMES0001
	--0006
	--Select top 1000 * from SAP_Interface_ExscraptDet  
	Insert into SAP_Interface_ExscraptMstr(MiscOrderNo,MiscOrder,Reason,BatchNO,CreateDate)
		Select Id ,MiscOrderNo As MiscOrder ,'MES26' As Reason,@BatchNo,@CurrentTime from #Scrap_02
	Insert into  SAP_Interface_ExscraptDet(MiscOrder, MiscOrderDet, AdjustSAPOrder,ScraptQty,  BatchNo,CreateDate)
		Select MiscOrderNo As MiscOrder ,OrderNo,ZMESSC ,ScraptQty ,@BatchNo ,@CurrentTime from #Scrap_02 
	--冲销
	Insert into SAP_Interface_PPMES0003(ZMESSC, ZMESLN, ZPTYPE, WERKS, XMNGA, GRUND, ZComnum, BLDAT, BUDAT, 
	MTSNR, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, LGORT_I,GMEIN_H, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status)
		Select Distinct b.AdjustSAPOrder As ZMESSC,1 As ZMESLN ,'BUSCX02' As ZPTYPE,@WERKS As WERKS,'' As XMNGA,Reason As GRUND,
			MiscOrderDet As ZComnum,'' As BLDAT,'' As BUDAT,a.MiscOrder As MTSNR, '' As BWART_I, '' As MATNR_I,
			 '' As ERFMG_I, '' As GMEIN_I,'' As GMEIN_H, '' As LGORT_I ,@ZMESGUID As ZMESGUID ,
			GETDATE() As ZCSRQSJ,@BatchNo As BatchNo,@BatchNo As UniqueCode,'0' as Status
			from SAP_Interface_ExscraptMstr a,SAP_Interface_ExscraptDet b 
			where a.MiscOrder=b.MiscOrder
			and a.MiscOrder in 
			(Select MiscOrderNo from #CancelMiscOrderNo)
	Select Distinct MiscOrderNo into #NoCancelInSAP from #CancelMiscOrderNo a where not exists(select 0 
	from SAP_Interface_ExscraptMstr b where Reason ='MES26' and a.MiscOrderNo=b.MiscOrder)
	if exists(select 0 from #NoCancelInSAP where 1=2/*上线前冲销的废品数不管*/)
	Begin
		Insert into SAP_Interface_PPMES0003(ZMESSC, ZMESLN, ZPTYPE, WERKS, XMNGA, GRUND, ZComnum, BLDAT, BUDAT, 
		MTSNR, BWART_I, MATNR_I, ERFMG_I, GMEIN_I, GMEIN_H, LGORT_I, ZMESGUID, ZCSRQSJ, BatchNo, UniqueCode, Status)
			Select Distinct 'OE'+SUBSTRING(@WeekIndex,3,2)+Right(@WeekIndex,2)+Isnull(md.Item,'')+'00' As ZMESSC,1 As ZMESLN ,'BUSCX02' As ZPTYPE,@WERKS As WERKS,'' As XMNGA,'MES26' As GRUND,
				mm.MiscOrderNo+Right('00'+CAST(Seq As varchar),2)  As ZComnum,'' As BLDAT,'' As BUDAT,mm.MiscOrderNo As MTSNR, '' As BWART_I, '' As MATNR_I,
				 '' As ERFMG_I, '' As GMEIN_I,'' As GMEIN_H, '' AsLGORT_I ,@ZMESGUID As ZMESGUID ,
				GETDATE() As ZCSRQSJ,@BatchNo As BatchNo,@BatchNo As UniqueCode,'0' as Status
		FROM ORD_MiscOrderMstr mm INNER JOIN ORD_MiscOrderDet md ON mm.MiscOrderNo=md.MiscOrderNo
				INNER JOIN MD_Location l ON l.Code=mm.Location
				WHERE mm.SubType in(26) AND mm.Status=2 AND mm.CancelDate>@StartTime AND mm.CancelDate<=@EndTime AND mm.IsCs=0
				and mm.MiscOrderNo in (Select * from #NoCancelInSAP)
	End
	--Delete ,Update在测试阶段启用下面的代码，测试完后要把所有存储整合在一起，一起更新
	Update a
		Set a.BLDAT =b.CancelDate ,a.BUDAT =b.CancelDate from SAP_Interface_PPMES0003 a,ORD_MiscOrderMstr b 
			where BatchNo=@BatchNo and a.MTSNR =b.MiscOrderNo and a.ZPTYPE='BUSCX02'
	Update SAP_Interface_PPMES0001 Set MTSNR =LFSNR where BatchNo =@BatchNo 
	
END




