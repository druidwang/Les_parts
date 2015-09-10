/****** Object:  StoredProcedure [dbo].[USP_Split_OrderDet_Update]    Script Date: 07/05/2012 14:55:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS(SELECT * FROM SYS.objects WHERE type='P' AND name='USP_Split_OrderDet_Update')
	DROP PROCEDURE USP_Split_OrderDet_Update
CREATE PROCEDURE [dbo].[USP_Split_OrderDet_Update]
(
	@Version int,
	@OrderNo varchar(50),
	@OrderType tinyint,
	@OrderSubType tinyint,
	@Seq int,
	@ExtNo varchar(50),
	@ExtSeq varchar(50),
	@StartDate datetime,
	@EndDate datetime,
	@ScheduleType tinyint,
	@Item varchar(50),
	@ItemDesc varchar(100),
	@RefItemCode varchar(50),
	@Uom varchar(5),
	@BaseUom varchar(5),
	@UC decimal(18,8),
	@UCDesc varchar(50),
	@MinUC decimal(18,8), 
	@QualityType tinyint,
	@ManufactureParty varchar(50),
	@ReqQty decimal(18,8),
	@OrderQty decimal(18,8),
	@ShipQty decimal(18,8),
	@RecQty decimal(18,8),
	@RejQty decimal(18,8),
	@ScrapQty decimal(18,8),
	@PickQty decimal(18,8),
	@UnitQty decimal(18,8),
	@RecLotSize decimal(18,8),
	@LocFrom varchar(50),
	@LocFromNm varchar(100),
	@LocTo varchar(50),
	@LocToNm varchar(100),
	@IsInspect bit,
	@BillAddr varchar(50),
	@BillAddrDesc varchar(256),
	@PriceList varchar(50),
	@UnitPrice decimal(18,8),
	@IsProvEst bit,
	@Tax varchar(50),
	@IsIncludeTax bit,
	@Currency varchar(50),
	@Bom varchar(50),
	@Routing varchar(50),
	@BillTerm tinyint,
	@IsScanHu bit,
	@ReserveNo varchar(50),
	@ReserveLine varchar(50),
	@ZOPWZ varchar(50),
	@ZOPID varchar(50),
	@ZOPDS varchar(50),
	@BinTo varchar(50),
	@WMSSeq varchar(50),
	@LastModifyUser int,
	@LastModifyUserNm varchar(100),
	@LastModifyDate datetime,
	@Container varchar(4000),
	@ContainerDesc varchar(50), 
	@PickStrategy varchar(50),
	@ExtraDmdSource varchar(256),
	@IsChangeUC bit,
	@AUFNR varchar(50),
	@ICHARG varchar(50),
	@BWART varchar(50),
	@Id int,
	@VersionBerfore int
)
AS
BEGIN
	IF @OrderType=1
	BEGIN
		UPDATE ORD_OrderDet_1 SET Version=@Version,OrderNo=@OrderNo,OrderType=@OrderType,OrderSubType=@OrderSubType,Seq=@Seq,ExtNo=@ExtNo,ExtSeq=@ExtSeq,StartDate=@StartDate,EndDate=@EndDate,ScheduleType=@ScheduleType,Item=@Item,ItemDesc=@ItemDesc,RefItemCode=@RefItemCode,Uom=@Uom,BaseUom=@BaseUom,UC=@UC,UCDesc=@UCDesc,MinUC=@MinUC,QualityType=@QualityType,ManufactureParty=@ManufactureParty,ReqQty=@ReqQty,OrderQty=@OrderQty,ShipQty=@ShipQty,RecQty=@RecQty,RejQty=@RejQty,ScrapQty=@ScrapQty,PickQty=@PickQty,UnitQty=@UnitQty,RecLotSize=@RecLotSize,LocFrom=@LocFrom,LocFromNm=@LocFromNm,LocTo=@LocTo,LocToNm=@LocToNm,IsInspect=@IsInspect,BillAddr=@BillAddr,BillAddrDesc=@BillAddrDesc,PriceList=@PriceList,UnitPrice=@UnitPrice,IsProvEst=@IsProvEst,Tax=@Tax,IsIncludeTax=@IsIncludeTax,Currency=@Currency,Bom=@Bom,Routing=@Routing,BillTerm=@BillTerm,IsScanHu=@IsScanHu,ReserveNo=@ReserveNo,ReserveLine=@ReserveLine,ZOPWZ=@ZOPWZ,ZOPID=@ZOPID,ZOPDS=@ZOPDS,BinTo=@BinTo,WMSSeq=@WMSSeq,LastModifyUser=@LastModifyUser,LastModifyUserNm=@LastModifyUserNm,LastModifyDate=@LastModifyDate,Container=@Container,ContainerDesc=@ContainerDesc,PickStrategy=@PickStrategy,ExtraDmdSource=@ExtraDmdSource,IsChangeUC=@IsChangeUC,AUFNR=@AUFNR,ICHARG=@ICHARG,BWART=@BWART
		WHERE Id= @Id AND Version= @VersionBerfore
	END
	ELSE IF @OrderType=2
	BEGIN
		UPDATE ORD_OrderDet_2 SET Version=@Version,OrderNo=@OrderNo,OrderType=@OrderType,OrderSubType=@OrderSubType,Seq=@Seq,ExtNo=@ExtNo,ExtSeq=@ExtSeq,StartDate=@StartDate,EndDate=@EndDate,ScheduleType=@ScheduleType,Item=@Item,ItemDesc=@ItemDesc,RefItemCode=@RefItemCode,Uom=@Uom,BaseUom=@BaseUom,UC=@UC,UCDesc=@UCDesc,MinUC=@MinUC,QualityType=@QualityType,ManufactureParty=@ManufactureParty,ReqQty=@ReqQty,OrderQty=@OrderQty,ShipQty=@ShipQty,RecQty=@RecQty,RejQty=@RejQty,ScrapQty=@ScrapQty,PickQty=@PickQty,UnitQty=@UnitQty,RecLotSize=@RecLotSize,LocFrom=@LocFrom,LocFromNm=@LocFromNm,LocTo=@LocTo,LocToNm=@LocToNm,IsInspect=@IsInspect,BillAddr=@BillAddr,BillAddrDesc=@BillAddrDesc,PriceList=@PriceList,UnitPrice=@UnitPrice,IsProvEst=@IsProvEst,Tax=@Tax,IsIncludeTax=@IsIncludeTax,Currency=@Currency,Bom=@Bom,Routing=@Routing,BillTerm=@BillTerm,IsScanHu=@IsScanHu,ReserveNo=@ReserveNo,ReserveLine=@ReserveLine,ZOPWZ=@ZOPWZ,ZOPID=@ZOPID,ZOPDS=@ZOPDS,BinTo=@BinTo,WMSSeq=@WMSSeq,LastModifyUser=@LastModifyUser,LastModifyUserNm=@LastModifyUserNm,LastModifyDate=@LastModifyDate,Container=@Container,ContainerDesc=@ContainerDesc,PickStrategy=@PickStrategy,ExtraDmdSource=@ExtraDmdSource,IsChangeUC=@IsChangeUC,AUFNR=@AUFNR,ICHARG=@ICHARG,BWART=@BWART
		WHERE Id= @Id AND Version= @VersionBerfore
	END
	ELSE IF @OrderType=3
	BEGIN
		UPDATE ORD_OrderDet_3 SET Version=@Version,OrderNo=@OrderNo,OrderType=@OrderType,OrderSubType=@OrderSubType,Seq=@Seq,ExtNo=@ExtNo,ExtSeq=@ExtSeq,StartDate=@StartDate,EndDate=@EndDate,ScheduleType=@ScheduleType,Item=@Item,ItemDesc=@ItemDesc,RefItemCode=@RefItemCode,Uom=@Uom,BaseUom=@BaseUom,UC=@UC,UCDesc=@UCDesc,MinUC=@MinUC,QualityType=@QualityType,ManufactureParty=@ManufactureParty,ReqQty=@ReqQty,OrderQty=@OrderQty,ShipQty=@ShipQty,RecQty=@RecQty,RejQty=@RejQty,ScrapQty=@ScrapQty,PickQty=@PickQty,UnitQty=@UnitQty,RecLotSize=@RecLotSize,LocFrom=@LocFrom,LocFromNm=@LocFromNm,LocTo=@LocTo,LocToNm=@LocToNm,IsInspect=@IsInspect,BillAddr=@BillAddr,BillAddrDesc=@BillAddrDesc,PriceList=@PriceList,UnitPrice=@UnitPrice,IsProvEst=@IsProvEst,Tax=@Tax,IsIncludeTax=@IsIncludeTax,Currency=@Currency,Bom=@Bom,Routing=@Routing,BillTerm=@BillTerm,IsScanHu=@IsScanHu,ReserveNo=@ReserveNo,ReserveLine=@ReserveLine,ZOPWZ=@ZOPWZ,ZOPID=@ZOPID,ZOPDS=@ZOPDS,BinTo=@BinTo,WMSSeq=@WMSSeq,LastModifyUser=@LastModifyUser,LastModifyUserNm=@LastModifyUserNm,LastModifyDate=@LastModifyDate,Container=@Container,ContainerDesc=@ContainerDesc,PickStrategy=@PickStrategy,ExtraDmdSource=@ExtraDmdSource,IsChangeUC=@IsChangeUC,AUFNR=@AUFNR,ICHARG=@ICHARG,BWART=@BWART
		WHERE Id= @Id AND Version= @VersionBerfore
	END
	ELSE IF @OrderType=4
	BEGIN
		UPDATE ORD_OrderDet_4 SET Version=@Version,OrderNo=@OrderNo,OrderType=@OrderType,OrderSubType=@OrderSubType,Seq=@Seq,ExtNo=@ExtNo,ExtSeq=@ExtSeq,StartDate=@StartDate,EndDate=@EndDate,ScheduleType=@ScheduleType,Item=@Item,ItemDesc=@ItemDesc,RefItemCode=@RefItemCode,Uom=@Uom,BaseUom=@BaseUom,UC=@UC,UCDesc=@UCDesc,MinUC=@MinUC,QualityType=@QualityType,ManufactureParty=@ManufactureParty,ReqQty=@ReqQty,OrderQty=@OrderQty,ShipQty=@ShipQty,RecQty=@RecQty,RejQty=@RejQty,ScrapQty=@ScrapQty,PickQty=@PickQty,UnitQty=@UnitQty,RecLotSize=@RecLotSize,LocFrom=@LocFrom,LocFromNm=@LocFromNm,LocTo=@LocTo,LocToNm=@LocToNm,IsInspect=@IsInspect,BillAddr=@BillAddr,BillAddrDesc=@BillAddrDesc,PriceList=@PriceList,UnitPrice=@UnitPrice,IsProvEst=@IsProvEst,Tax=@Tax,IsIncludeTax=@IsIncludeTax,Currency=@Currency,Bom=@Bom,Routing=@Routing,BillTerm=@BillTerm,IsScanHu=@IsScanHu,ReserveNo=@ReserveNo,ReserveLine=@ReserveLine,ZOPWZ=@ZOPWZ,ZOPID=@ZOPID,ZOPDS=@ZOPDS,BinTo=@BinTo,WMSSeq=@WMSSeq,LastModifyUser=@LastModifyUser,LastModifyUserNm=@LastModifyUserNm,LastModifyDate=@LastModifyDate,Container=@Container,ContainerDesc=@ContainerDesc,PickStrategy=@PickStrategy,ExtraDmdSource=@ExtraDmdSource,IsChangeUC=@IsChangeUC,AUFNR=@AUFNR,ICHARG=@ICHARG,BWART=@BWART
		WHERE Id= @Id AND Version= @VersionBerfore
	END
	ELSE IF @OrderType=5
	BEGIN
		UPDATE ORD_OrderDet_5 SET Version=@Version,OrderNo=@OrderNo,OrderType=@OrderType,OrderSubType=@OrderSubType,Seq=@Seq,ExtNo=@ExtNo,ExtSeq=@ExtSeq,StartDate=@StartDate,EndDate=@EndDate,ScheduleType=@ScheduleType,Item=@Item,ItemDesc=@ItemDesc,RefItemCode=@RefItemCode,Uom=@Uom,BaseUom=@BaseUom,UC=@UC,UCDesc=@UCDesc,MinUC=@MinUC,QualityType=@QualityType,ManufactureParty=@ManufactureParty,ReqQty=@ReqQty,OrderQty=@OrderQty,ShipQty=@ShipQty,RecQty=@RecQty,RejQty=@RejQty,ScrapQty=@ScrapQty,PickQty=@PickQty,UnitQty=@UnitQty,RecLotSize=@RecLotSize,LocFrom=@LocFrom,LocFromNm=@LocFromNm,LocTo=@LocTo,LocToNm=@LocToNm,IsInspect=@IsInspect,BillAddr=@BillAddr,BillAddrDesc=@BillAddrDesc,PriceList=@PriceList,UnitPrice=@UnitPrice,IsProvEst=@IsProvEst,Tax=@Tax,IsIncludeTax=@IsIncludeTax,Currency=@Currency,Bom=@Bom,Routing=@Routing,BillTerm=@BillTerm,IsScanHu=@IsScanHu,ReserveNo=@ReserveNo,ReserveLine=@ReserveLine,ZOPWZ=@ZOPWZ,ZOPID=@ZOPID,ZOPDS=@ZOPDS,BinTo=@BinTo,WMSSeq=@WMSSeq,LastModifyUser=@LastModifyUser,LastModifyUserNm=@LastModifyUserNm,LastModifyDate=@LastModifyDate,Container=@Container,ContainerDesc=@ContainerDesc,PickStrategy=@PickStrategy,ExtraDmdSource=@ExtraDmdSource,IsChangeUC=@IsChangeUC,AUFNR=@AUFNR,ICHARG=@ICHARG,BWART=@BWART
		WHERE Id= @Id AND Version= @VersionBerfore
	END
	ELSE IF @OrderType=6
	BEGIN
		UPDATE ORD_OrderDet_6 SET Version=@Version,OrderNo=@OrderNo,OrderType=@OrderType,OrderSubType=@OrderSubType,Seq=@Seq,ExtNo=@ExtNo,ExtSeq=@ExtSeq,StartDate=@StartDate,EndDate=@EndDate,ScheduleType=@ScheduleType,Item=@Item,ItemDesc=@ItemDesc,RefItemCode=@RefItemCode,Uom=@Uom,BaseUom=@BaseUom,UC=@UC,UCDesc=@UCDesc,MinUC=@MinUC,QualityType=@QualityType,ManufactureParty=@ManufactureParty,ReqQty=@ReqQty,OrderQty=@OrderQty,ShipQty=@ShipQty,RecQty=@RecQty,RejQty=@RejQty,ScrapQty=@ScrapQty,PickQty=@PickQty,UnitQty=@UnitQty,RecLotSize=@RecLotSize,LocFrom=@LocFrom,LocFromNm=@LocFromNm,LocTo=@LocTo,LocToNm=@LocToNm,IsInspect=@IsInspect,BillAddr=@BillAddr,BillAddrDesc=@BillAddrDesc,PriceList=@PriceList,UnitPrice=@UnitPrice,IsProvEst=@IsProvEst,Tax=@Tax,IsIncludeTax=@IsIncludeTax,Currency=@Currency,Bom=@Bom,Routing=@Routing,BillTerm=@BillTerm,IsScanHu=@IsScanHu,ReserveNo=@ReserveNo,ReserveLine=@ReserveLine,ZOPWZ=@ZOPWZ,ZOPID=@ZOPID,ZOPDS=@ZOPDS,BinTo=@BinTo,WMSSeq=@WMSSeq,LastModifyUser=@LastModifyUser,LastModifyUserNm=@LastModifyUserNm,LastModifyDate=@LastModifyDate,Container=@Container,ContainerDesc=@ContainerDesc,PickStrategy=@PickStrategy,ExtraDmdSource=@ExtraDmdSource,IsChangeUC=@IsChangeUC,AUFNR=@AUFNR,ICHARG=@ICHARG,BWART=@BWART
		WHERE Id= @Id AND Version= @VersionBerfore
	END
	ELSE IF @OrderType=7
	BEGIN
		UPDATE ORD_OrderDet_7 SET Version=@Version,OrderNo=@OrderNo,OrderType=@OrderType,OrderSubType=@OrderSubType,Seq=@Seq,ExtNo=@ExtNo,ExtSeq=@ExtSeq,StartDate=@StartDate,EndDate=@EndDate,ScheduleType=@ScheduleType,Item=@Item,ItemDesc=@ItemDesc,RefItemCode=@RefItemCode,Uom=@Uom,BaseUom=@BaseUom,UC=@UC,UCDesc=@UCDesc,MinUC=@MinUC,QualityType=@QualityType,ManufactureParty=@ManufactureParty,ReqQty=@ReqQty,OrderQty=@OrderQty,ShipQty=@ShipQty,RecQty=@RecQty,RejQty=@RejQty,ScrapQty=@ScrapQty,PickQty=@PickQty,UnitQty=@UnitQty,RecLotSize=@RecLotSize,LocFrom=@LocFrom,LocFromNm=@LocFromNm,LocTo=@LocTo,LocToNm=@LocToNm,IsInspect=@IsInspect,BillAddr=@BillAddr,BillAddrDesc=@BillAddrDesc,PriceList=@PriceList,UnitPrice=@UnitPrice,IsProvEst=@IsProvEst,Tax=@Tax,IsIncludeTax=@IsIncludeTax,Currency=@Currency,Bom=@Bom,Routing=@Routing,BillTerm=@BillTerm,IsScanHu=@IsScanHu,ReserveNo=@ReserveNo,ReserveLine=@ReserveLine,ZOPWZ=@ZOPWZ,ZOPID=@ZOPID,ZOPDS=@ZOPDS,BinTo=@BinTo,WMSSeq=@WMSSeq,LastModifyUser=@LastModifyUser,LastModifyUserNm=@LastModifyUserNm,LastModifyDate=@LastModifyDate,Container=@Container,ContainerDesc=@ContainerDesc,PickStrategy=@PickStrategy,ExtraDmdSource=@ExtraDmdSource,IsChangeUC=@IsChangeUC,AUFNR=@AUFNR,ICHARG=@ICHARG,BWART=@BWART
		WHERE Id= @Id AND Version= @VersionBerfore
	END
	ELSE IF @OrderType=8
	BEGIN
		UPDATE ORD_OrderDet_8 SET Version=@Version,OrderNo=@OrderNo,OrderType=@OrderType,OrderSubType=@OrderSubType,Seq=@Seq,ExtNo=@ExtNo,ExtSeq=@ExtSeq,StartDate=@StartDate,EndDate=@EndDate,ScheduleType=@ScheduleType,Item=@Item,ItemDesc=@ItemDesc,RefItemCode=@RefItemCode,Uom=@Uom,BaseUom=@BaseUom,UC=@UC,UCDesc=@UCDesc,MinUC=@MinUC,QualityType=@QualityType,ManufactureParty=@ManufactureParty,ReqQty=@ReqQty,OrderQty=@OrderQty,ShipQty=@ShipQty,RecQty=@RecQty,RejQty=@RejQty,ScrapQty=@ScrapQty,PickQty=@PickQty,UnitQty=@UnitQty,RecLotSize=@RecLotSize,LocFrom=@LocFrom,LocFromNm=@LocFromNm,LocTo=@LocTo,LocToNm=@LocToNm,IsInspect=@IsInspect,BillAddr=@BillAddr,BillAddrDesc=@BillAddrDesc,PriceList=@PriceList,UnitPrice=@UnitPrice,IsProvEst=@IsProvEst,Tax=@Tax,IsIncludeTax=@IsIncludeTax,Currency=@Currency,Bom=@Bom,Routing=@Routing,BillTerm=@BillTerm,IsScanHu=@IsScanHu,ReserveNo=@ReserveNo,ReserveLine=@ReserveLine,ZOPWZ=@ZOPWZ,ZOPID=@ZOPID,ZOPDS=@ZOPDS,BinTo=@BinTo,WMSSeq=@WMSSeq,LastModifyUser=@LastModifyUser,LastModifyUserNm=@LastModifyUserNm,LastModifyDate=@LastModifyDate,Container=@Container,ContainerDesc=@ContainerDesc,PickStrategy=@PickStrategy,ExtraDmdSource=@ExtraDmdSource,IsChangeUC=@IsChangeUC,AUFNR=@AUFNR,ICHARG=@ICHARG,BWART=@BWART
		WHERE Id= @Id AND Version= @VersionBerfore
	END
	ELSE
	BEGIN
		UPDATE ORD_OrderDet_0 SET Version=@Version,OrderNo=@OrderNo,OrderType=@OrderType,OrderSubType=@OrderSubType,Seq=@Seq,ExtNo=@ExtNo,ExtSeq=@ExtSeq,StartDate=@StartDate,EndDate=@EndDate,ScheduleType=@ScheduleType,Item=@Item,ItemDesc=@ItemDesc,RefItemCode=@RefItemCode,Uom=@Uom,BaseUom=@BaseUom,UC=@UC,UCDesc=@UCDesc,MinUC=@MinUC,QualityType=@QualityType,ManufactureParty=@ManufactureParty,ReqQty=@ReqQty,OrderQty=@OrderQty,ShipQty=@ShipQty,RecQty=@RecQty,RejQty=@RejQty,ScrapQty=@ScrapQty,PickQty=@PickQty,UnitQty=@UnitQty,RecLotSize=@RecLotSize,LocFrom=@LocFrom,LocFromNm=@LocFromNm,LocTo=@LocTo,LocToNm=@LocToNm,IsInspect=@IsInspect,BillAddr=@BillAddr,BillAddrDesc=@BillAddrDesc,PriceList=@PriceList,UnitPrice=@UnitPrice,IsProvEst=@IsProvEst,Tax=@Tax,IsIncludeTax=@IsIncludeTax,Currency=@Currency,Bom=@Bom,Routing=@Routing,BillTerm=@BillTerm,IsScanHu=@IsScanHu,ReserveNo=@ReserveNo,ReserveLine=@ReserveLine,ZOPWZ=@ZOPWZ,ZOPID=@ZOPID,ZOPDS=@ZOPDS,BinTo=@BinTo,WMSSeq=@WMSSeq,LastModifyUser=@LastModifyUser,LastModifyUserNm=@LastModifyUserNm,LastModifyDate=@LastModifyDate,Container=@Container,ContainerDesc=@ContainerDesc,PickStrategy=@PickStrategy,ExtraDmdSource=@ExtraDmdSource,IsChangeUC=@IsChangeUC,AUFNR=@AUFNR,ICHARG=@ICHARG,BWART=@BWART
		WHERE Id= @Id AND Version= @VersionBerfore
	END
END
GO
