USE [Sconit_20140317]
GO
/****** Object:  StoredProcedure [dbo].[UPS_SAP_ProcessSupplier]    Script Date: 03/19/2014 08:07:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[UPS_SAP_ProcessSupplier]
(
	@UserId int,
	@BatchNo varchar(50)
)
AS
BEGIN
	SET NOCOUNT ON 
	DECLARE @UserName varchar(50) 
	DECLARE @CurrentDate datetime
	SELECT @UserName=FirstName+LastName FROM ACC_User WHERE Id=@UserId 
	SET @CurrentDate=GETDATE()
	IF(ISNULL(@BatchNo,'')<>'') 
	BEGIn
			--exec [UPS_SAP_ProcessSupplier]'3585','1'
			--select * from SAP_Supplier
			--select * from MD_Supplier
			--select * from MD_party where code ='40078'
			--Insert into SAP_Supplier
			--select 'sptestier','测试','','CN','Shanghai','330002','222 ','111111','who','737372','5262251 ','188019999999','G2',1,1,0,GETDATE()
			--select '40078','ssss','','CN','Shanghai','330002','222 ','111111','who','737372','5262251 ','188019999999','G2',1,1,0,GETDATE()

		
		BEGIN TRY 
			SELECT * INTO #TempSupplier FROM SAP_Supplier ss WHERE BatchNo=@BatchNo AND NOT EXISTS(SELECT 1 FROM MD_Supplier s where ss.LIFNR=s.Code) 
				-----插入地址 
				INSERT INTO MD_Address(Code, Address, PostCode, TelPhone, MobilePhone, Fax, Email, ContactPsnNm, 
					CreateUser, CreateUserNm, CreateDate, LastModifyUser, LastModifyUserNm, LastModifyDate) 
				SELECT DISTINCT LIFNR As Code ,REMARK As Address,PSTLZ As PostCode,TELF1 As TelPhone,TELF2 As MobilePhone,TELFX As Fax,
					TELBX As Email,PARNR As ContactPsnNm,@UserId,@UserName,@CurrentDate,@UserId,@UserName,@CurrentDate 
					FROM #TempSupplier WHERE LIFNR IS NOT NULL

				-----插入区域 
				INSERT INTO MD_Party(Code, Name, LongName, IsActive, CreateUser, CreateUserNm, CreateDate, LastModifyUser, LastModifyUserNm, LastModifyDate) 
					SELECT DISTINCT LIFNR As Code, NAME1 As Name, NAME1 As LongName, case when  LOEVM= 'X' then 0 else 1 end As IsActive, @UserId As CreateUser, @UserName As CreateUserNm,
						@CurrentDate As CreateDate, @UserId As LastModifyUser,@UserName As LastModifyUserNm, @CurrentDate As LastModifyDate 
						FROM #TempSupplier WHERE LIFNR IS NOT NULL

				------插入区域地址 
				INSERT INTO MD_PartyAddr(Party, Address, Type, IsPrimary, Seq, CreateUser, CreateUserNm, CreateDate, LastModifyUser, LastModifyUserNm, LastModifyDate) 
					SELECT DISTINCT LIFNR As Party,LIFNR As Address,1 As Type,1 As IsPrimary,1 As Seq,@UserId As CreateUser, @UserName As CreateUserNm,
						@CurrentDate As CreateDate, @UserId As LastModifyUser,@UserName As LastModifyUserNm, @CurrentDate As LastModifyDate 
						FROM #TempSupplier WHERE LIFNR IS NOT NULL
				UNION ALL 
					SELECT DISTINCT LIFNR As Party,LIFNR As Address,0 As Type,1 As IsPrimary,1 As Seq,@UserId As CreateUser, @UserName As CreateUserNm,
						@CurrentDate As CreateDate, @UserId As LastModifyUser,@UserName As LastModifyUserNm, @CurrentDate As LastModifyDate 
						FROM #TempSupplier WHERE LIFNR IS NOT NULL				
				-----插入供应商权限
				--select top 1000 * from ACC_Permission
				INSERT INTO ACC_Permission(Code,Desc1,Category,Sequence)
					SELECT DISTINCT LIFNR  As Code ,NAME1 As Desc1,'Supplier' As Category,10000 As Sequence FROM #TempSupplier ts
						WHERE NOT EXISTS(SELECT 1 FROM ACC_Permission pm WHERE pm.Code=ts.LIFNR)
				
				-----插入供应商
				UPDATE A 
					SET A.Name=B.NAME1,
					A.IsActive=case when B.LOEVM= 'X' then 0 else 1 end,
					A.LastModifyUser=@UserId,
					A.LastModifyUserNm=@UserName,
					A.LastModifyDate=@CurrentDate
					FROM MD_Party A LEFT JOIN SAP_Supplier B
					ON A.Code=B.LIFNR 
					WHERE  B.BatchNo=@BatchNo AND B.LIFNR IS NOT NULL
				
				UPDATE A 
					SET A.Address=REMARK,
					A.Telphone=TELF1,
					A.Fax=TELFX,
					A.ContactPsnNm=PARNR,
					A.PostCode=PSTLZ,
					A.Email=TELBX,
					A.MobilePhone=TELF2,
					A.LastModifyUser=@UserId,
					A.LastModifyUserNm=@UserName,
					A.LastModifyDate=@CurrentDate
					FROM MD_Address A LEFT JOIN SAP_Supplier B
					ON A.Code=B.LIFNR 
					WHERE  B.BatchNo=@BatchNo AND B.LIFNR IS NOT NULL

				UPDATE TOP(1) A 
					SET A.PurchaseGroup=B.EKGRP,
					A.ShortCode=B.NAME1
					FROM MD_Supplier A LEFT JOIN SAP_Supplier B
					ON A.Code=B.LIFNR 
					WHERE  B.BatchNo=@BatchNo AND B.LIFNR IS NOT NULL
				
				INSERT INTO MD_Supplier(Code, ShortCode, PurchaseGroup) 
					SELECT DISTINCT LIFNR As Code,NAME1 As ShortCode,EKGRP As PurchaseGroup 
						FROM #TempSupplier WHERE LIFNR IS NOT NULL
				--Select * from MD_Supplier

				UPDATE SAP_Supplier SET Status=1 WHERE BatchNo=@BatchNo  
				SELECT Status=1,BatchNo=@BatchNo,Message='SUCCESS UPDATE SAP SUPPLIER TO LES' 
		END TRY 
		BEGIN CATCH 
			UPDATE Sap_Item SET Status=2 WHERE BatchNo=@BatchNo  
			SELECT Status=2,BatchNo=@BatchNo,Message=ERROR_MESSAGE() 
		END CATCH
	END 
END