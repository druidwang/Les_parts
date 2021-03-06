USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_ExportSalesOrder]    Script Date: 12/08/2014 10:30:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_SAP_ExportSalesOrder]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
BEGIN
	----2014/06/22	Add UnitQty,单位全部传基本单位	--0001
	----2014/08/04	采购转手贸易 --0002
	----2014/09/01	LIFEX取值 --0003
	SET NOCOUNT ON
	--Insert into Sconit_20140414.dbo.test001 select null,''
		--exec [USP_SAP_ExportSalesOrder] 'ssssss','2014-05-01','2014-05-12'
		DECLARE @CurrDate datetime=GETDATE()
		--从申雅移库到重庆路线视同销售
		Declare @ChongQingSaleFlow varchar(1000)=''
		Select @ChongQingSaleFlow=Value from SYS_EntityPreference WHERE Id=90109
		SELECT F1 As Flow INTO #TransferFlowEqualWithSaleFlow FROM dbo.Func_SplitStr(@ChongQingSaleFlow,'‖')
		--从重庆直接销售需要走转手贸易（重庆---》申雅----》客户）
		DECLARE @ResaleTradeFlow varchar(4000)=''
		SELECT @ResaleTradeFlow=Value FROM SYS_EntityPreference where Id=90101
		SELECT F1 As Flow INTO #SalesFlowASResaleTradeFlow FROM dbo.Func_SplitStr(@ResaleTradeFlow,'‖')
		----
		--0002Begin
		DECLARE @PurTradeFlow varchar(4000)=''
		SELECT @PurTradeFlow=Value FROM SYS_EntityPreference where Id=90110
		SELECT F1 As Flow INTO #PurFlowASResaleTradeFlow FROM dbo.Func_SplitStr(@PurTradeFlow,'‖')
		--0002End
		--Select @StartTime,@EndTime
		--CREATE TABLE #TempSeq(Seq int)
		--INSERT INTO #TempSeq
		--EXEC USP_SYS_GetNextSeq 'SAPExportSalesOrder',@BatchNo OUTPUT
		INSERT INTO SAP_Interface_SDMES0001(ZMESGUID, ZMESSO, ZMESSOSEQ, DOCTYPE, SALESORG, DISTRCHAN, DIVISION, ORDREASON, 
			PRICEDATE, DOCDATE, PARTNNUMB, WADATIST, LIFEX, ITMNUMBER, MATERIAL, TARGETQTY, VRKME, LGORT, ZCSRQSJ, Status, BatchNo,SALEORDNO)
		SELECT rm.RecNo+'0',rm.RecNo,rd.Seq,CASE WHEN rm.OrderSubType=1 THEN 'ZKA' ELSE 'ZKB' END,fm.SalesOrg,fm.DistrChan,
			i.Division,CASE WHEN rm.OrderSubType=1 THEN '101' ELSE '' END,rm.EffDate,rm.EffDate,
			CASE WHEN rm.OrderSubType=1 THEN rm.PartyFrom ELSE rm.PartyTo END As PARTNNUMB,rm.CreateDate,SUBSTRING(rm.ExtRecNo,0,34),rd.Seq,rd.Item,
			CAST(rd.RecQty*rd.UnitQty AS decimal(10,3)),i.Uom,--0001
			CASE WHEN rm.OrderSubType=1 AND ISNULL(sfrt.Flow,'')='' THEN lt.SAPLocation 
				WHEN rm.OrderSubType=1 AND ISNULL(sfrt.Flow,'')<>'' THEN '7001'
				WHEN rm.OrderSubType=0 AND ISNULL(sfrt.Flow,'')='' THEN lf.SAPLocation
				WHEN rm.OrderSubType=0 AND ISNULL(sfrt.Flow,'')<>'' THEN '7001' END,
			@CurrDate,0,@BatchNo,rd.OrderNo
			FROM ORD_RecMstr_3 rm INNER JOIN ORD_RecDet_3 rd ON rm.RecNo=rd.RecNo
			INNER JOIN SCM_FlowMstr fm ON rm.Flow=fm.Code 	
			INNER JOIN MD_Item i ON rd.Item=i.Code
			LEFT JOIN MD_Location lf ON lf.Code=rd.LocFrom
			LEFT JOIN MD_Location lt ON lt.Code=rd.LocTo
			LEFT JOIN #SalesFlowASResaleTradeFlow sfrt ON sfrt.Flow=rm.Flow 
			WHERE rm.Type<>1 AND rm.CreateDate>@StartTime AND rm.CreateDate<=@EndTime AND rm.CreateUser<>3910
		
		
		INSERT INTO SAP_Interface_SDMES0002(ZMESGUID,ZMESSO,ZCSRQSJ,Status,BatchNo,UniqueCode,CancelDate)
		SELECT Distinct rm.RecNo+'1',rm.RecNo,@CurrDate,0,@BatchNo,@BatchNo,rm.LastModifyDate
			FROM ORD_RecMstr_3 rm 
			WHERE rm.LastModifyDate>@StartTime 
			AND rm.LastModifyDate<=@EndTime
			AND rm.Status=1
			AND rm.LastModifyUser<>3910
		
		INSERT INTO SAP_Interface_SDMES0001(ZMESGUID, ZMESSO, ZMESSOSEQ, DOCTYPE, SALESORG, DISTRCHAN, DIVISION, ORDREASON, 
			PRICEDATE, DOCDATE, PARTNNUMB, WADATIST, LIFEX, ITMNUMBER, MATERIAL, TARGETQTY, VRKME, LGORT, ZCSRQSJ, Status, BatchNo,SALEORDNO)
		SELECT rm.RecNo+'0',rm.RecNo,rd.Seq,CASE WHEN rm.OrderSubType=1 THEN 'ZKA' ELSE 'ZKB' END,ms.SalesOrg,ms.DistrChan,
			case when isnull(i.Division,'')='' then ms.Division else i.Division End,CASE WHEN rm.OrderSubType=1 THEN '101' ELSE '' END,rm.EffDate,rm.EffDate,
			ms.Customer,
			rm.CreateDate,rd.OrderNo,rd.Seq,rd.Item,
			CAST(rd.RecQty*rd.UnitQty AS decimal(10,3)),i.Uom,
			CASE WHEN rm.OrderSubType=1 THEN lt.SAPLocation ELSE lf.SAPLocation END,@CurrDate,0,@BatchNo,rd.OrderNo
			FROM ORD_RecMstr_2 rm INNER JOIN ORD_RecDet_2 rd ON rm.RecNo=rd.RecNo
			INNER JOIN SCM_FlowMstr fm ON rm.Flow=fm.Code 
			--INNER JOIN MD_SwitchTrading std ON fm.Code=std.Flow		
			INNER JOIN MD_Item i ON rd.Item=i.Code
			LEFT JOIN MD_Location lf ON lf.Code=rd.LocFrom
			LEFT JOIN MD_Location lt ON lt.Code=rd.LocTo
			LEFT JOIN MD_SwitchTrading ms ON rm.Flow = ms.Flow
			WHERE rm.Type<>1 AND rm.CreateDate>@StartTime 
			AND rm.CreateDate<=@EndTime AND rm.CreateUser<>3910
			AND rm.Flow in (Select Flow from #TransferFlowEqualWithSaleFlow)
			
		INSERT INTO SAP_Interface_SDMES0002(ZMESGUID,ZMESSO,ZCSRQSJ,Status,BatchNo,UniqueCode,CancelDate)
			SELECT Distinct rm.RecNo+'1',rm.RecNo,@CurrDate,0,@BatchNo,@BatchNo,rm.LastModifyDate
				FROM ORD_RecMstr_2 rm 
				WHERE rm.LastModifyDate>@StartTime 
				AND rm.LastModifyDate<=@EndTime
				AND rm.Status=1 AND rm.LastModifyUser<>3910
				AND rm.Flow in (Select Flow from #TransferFlowEqualWithSaleFlow)
		--0002Begin
		---插入转手贸易数据
		INSERT INTO SAP_Interface_SDMES0001(ZMESGUID, ZMESSO, ZMESSOSEQ, DOCTYPE, SALESORG, DISTRCHAN, DIVISION, ORDREASON, 
			PRICEDATE, DOCDATE, PARTNNUMB, WADATIST, LIFEX, ITMNUMBER, MATERIAL, TARGETQTY, VRKME, LGORT, ZCSRQSJ, Status, BatchNo)
		SELECT rm.RecNo+'0',rm.RecNo,rd.Seq,CASE WHEN rm.OrderSubType=1 THEN 'ZKA' ELSE 'ZKB' END,ms.SalesOrg,ms.DistrChan,
			case when isnull(i.Division,'')='' then ms.Division else i.Division End,CASE WHEN rm.OrderSubType=1 THEN '101' ELSE '' END,rm.EffDate,rm.EffDate,
			ms.Customer As PARTNNUMB,rm.CreateDate,SUBSTRING(Isnull(rm.ExtRecNo,rm.RecNo/*--0003*/),0,34),rd.Seq,rd.Item,
			CAST(rd.RecQty*rd.UnitQty AS decimal(10,3)),i.Uom,--0001
			CASE WHEN rm.OrderSubType=1 AND ISNULL(prtf.Flow,'')='' THEN lt.SAPLocation 
				WHEN rm.OrderSubType=1 AND ISNULL(prtf.Flow,'')<>'' THEN '7001'
				WHEN rm.OrderSubType=0 AND ISNULL(prtf.Flow,'')='' THEN lf.SAPLocation
				WHEN rm.OrderSubType=0 AND ISNULL(prtf.Flow,'')<>'' THEN '7001' END,
			@CurrDate,0,@BatchNo
		FROM ORD_RecMstr_1 rm INNER JOIN ORD_RecDet_1 rd ON rm.RecNo=rd.RecNo
		INNER JOIN SCM_FlowMstr fm ON rm.Flow=fm.Code 	
		INNER JOIN MD_Item i ON rd.Item=i.Code
		INNER JOIN BIL_PriceListMstr pm ON rd.PriceList=pm.Code 
		--INNER JOIN BIL_PriceListDet pd ON rd.Item=pd.Item AND pm.Code=pd.PriceList AND rd.UnitPrice=pd.UnitPrice
		LEFT JOIN MD_Supplier sf ON sf.Code=rm.PartyFrom
		LEFT JOIN MD_Supplier st ON st.Code=rm.PartyTo
		LEFT JOIN MD_Location lf ON lf.Code=rd.LocFrom
		LEFT JOIN MD_Location lt ON lt.Code=rd.LocTo
		INNER JOIN #PurFlowASResaleTradeFlow prtf ON prtf.Flow=rm.Flow
		LEFT JOIN MD_SwitchTrading ms ON rm.Flow = ms.Flow
		WHERE rm.CreateDate>@StartTime AND rm.CreateDate<=@EndTime AND rm.Type=0 AND rd.BillTerm=1 AND rm.CreateUser<>3910
		---插入寄售采购结算数据
		/*INSERT INTO SAP_Interface_SDMES0001(ZMESGUID, ZMESSO, ZMESSOSEQ, DOCTYPE, SALESORG, DISTRCHAN, DIVISION, ORDREASON, 
			PRICEDATE, DOCDATE, PARTNNUMB, WADATIST, LIFEX, ITMNUMBER, MATERIAL, TARGETQTY, VRKME, LGORT, ZCSRQSJ, Status, BatchNo)
		SELECT rd.RecNo+'0',ab.Id,1 As ZMESSOSEQ,CASE WHEN rm.OrderSubType=1 THEN 'ZKA' ELSE 'ZKB' END,ms.SalesOrg,ms.DistrChan,
			case when isnull(i.Division,'')='' then ms.Division else i.Division End,CASE WHEN rm.OrderSubType=1 THEN '101' ELSE '' END,rm.EffDate,rm.EffDate,
			CASE WHEN rm.OrderSubType=1 THEN rm.PartyFrom ELSE rm.PartyTo END As PARTNNUMB,rm.CreateDate,SUBSTRING(rm.ExtRecNo,0,34),rd.Seq,rd.Item,
			CAST(ab.BillQty *rd.UnitQty AS decimal(10,3)),i.Uom,
			Case when ISNULL(prtf.Flow,'')<>'' then '7001' Else lt.SAPLocation End AS LGORT,
			@CurrDate,0,@BatchNo
		FROM BIL_ActBill ab
		INNER JOIN ORD_RecDet_1 rd ON ab.RecNo=rd.RecNo AND ab.Item=rd.Item
		INNER JOIN MD_Item i ON rd.Item=i.Code
		INNER JOIN BIL_PriceListMstr pm ON ab.PriceList=pm.Code 
		--INNER JOIN BIL_PriceListDet pd ON ab.Item=pd.Item AND pm.Code=pd.PriceList AND ab.UnitPrice=pd.UnitPrice
		INNER JOIN MD_Supplier sf ON sf.Code=ab.Party
		INNER JOIN MD_Location lt ON lt.Code=rd.LocTo
		INNER JOIN ORD_RecMstr_1 rm ON rd.RecNo =rm.RecNo 
		INNER JOIN #PurFlowASResaleTradeFlow prtf ON prtf.Flow=rd.Flow
		LEFT JOIN MD_SwitchTrading ms ON rm.Flow = ms.Flow
		WHERE ab.BillTerm<>1 AND ab.CreateDate>@StartTime AND ab.CreateDate<=@EndTime
		
		INSERT INTO SAP_Interface_SDMES0002(ZMESGUID,ZMESSO,ZCSRQSJ,Status,BatchNo,UniqueCode)
		SELECT ab.RecNo+'1',ab.Id,@CurrDate,0,@BatchNo,@BatchNo FROM BIL_ActBill ab
		INNER JOIN ORD_RecDet_1 rd ON ab.RecNo=rd.RecNo
		WHERE ab.BillTerm<>1 AND ab.LastModifyDate>@StartTime AND ab.LastModifyDate<=@EndTime AND ab.VoidQty<>0*/
		
		INSERT INTO SAP_Interface_SDMES0002(ZMESGUID,ZMESSO,ZCSRQSJ,Status,BatchNo,UniqueCode,CancelDate)
			SELECT Distinct rm.RecNo+'1',rm.RecNo,@CurrDate,0,@BatchNo,@BatchNo,rm.LastModifyDate FROM ORD_RecMstr_1 rm ,ORD_RecDet_1 rd
				WHERE rm.RecNo=rd.RecNo 
				AND rm.LastModifyDate>@StartTime AND rm.LastModifyDate<=@EndTime
				AND rm.Status=1 AND rm.Type=0
				AND rd.BillTerm=1 AND rm.LastModifyUser<>3910
				AND rm.Flow in (select Flow from #PurFlowASResaleTradeFlow)
		--0002End
		----	
		SELECT s1.ZMESSO INTO #TEMP1 FROM SAP_Interface_SDMES0001 s1 INNER JOIN SAP_Interface_SDMES0002 s2 ON s1.ZMESSO=s2.ZMESSO
			WHERE s1.BatchNo=@BatchNo AND s2.BatchNo=@BatchNo
		IF @@ROWCOUNT>0
		BEGIN
			--如果同一个时间段内存在冲销都不传
			DELETE a FROM SAP_Interface_SDMES0001 a INNER JOIN #TEMP1 b ON a.ZMESSO=b.ZMESSO
			DELETE a FROM SAP_Interface_SDMES0002 a INNER JOIN #TEMP1 b ON a.ZMESSO=b.ZMESSO
		END
		Update SAP_Interface_SDMES0001 Set LIFEX=ZMESSO where BatchNo=@BatchNo and (LIFEX IS NULL OR LIFEX='')
		DECLARE @UniqueCode varchar(50)
		WHILE EXISTS(SELECT * FROM SAP_Interface_SDMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL)
		BEGIN
			DECLARE @LastOrderNo varchar(50)
			SET @UniqueCode=REPLACE(NEWID(),'-','')
			UPDATE TOP(5000) SAP_Interface_SDMES0001 SET UniqueCode=@UniqueCode WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			SELECT TOP 1 @LastOrderNo=ZMESSO FROM SAP_Interface_SDMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			PRINT @LastOrderNo
			IF EXISTS(SELECT 1 FROM SAP_Interface_SDMES0001 WHERE BatchNo=@BatchNo AND UniqueCode=@UniqueCode AND ZMESSO=@LastOrderNo )
			BEGIN
				UPDATE SAP_Interface_SDMES0001 SET UniqueCode=@UniqueCode WHERE BatchNo=@BatchNo AND ZMESSO=@LastOrderNo
			END
		END
		
		--
 
		SELECT Status=1,BatchNo=@BatchNo,'生成销售接口数据成功。'
		Drop table #TEMP1
		Drop table #TransferFlowEqualWithSaleFlow
END