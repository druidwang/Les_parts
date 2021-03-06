USE [Sconit_20140317]
GO
/****** Object:  StoredProcedure [dbo].[UPS_SAP_ProcessCustomer]    Script Date: 03/19/2014 08:04:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[UPS_SAP_ProcessCustomer]
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
			--exec [UPS_SAP_ProcessCustomer]'3585','1'
			--select * from MD_Customer where code in (select code from MD_supplier)
			--select * from MD_party where code ='custestier'
			--select * from  SAP_Customer
			--Insert into SAP_Customer
			--select 'custestier','测试','','CN','Shanghai','330002','222 ','111111','who','737372','5262251 ','188019999999',1,1,0,GETDATE() union
			--select '20001','淮安申雅New','','CN','Shanghai','330002','222 ','111111','who','737372','5262251 ','188019999999',1,1,0,GETDATE()

		
		BEGIN TRY 
			SELECT * INTO #TempCustomer FROM SAP_Customer ss WHERE BatchNo=@BatchNo AND NOT EXISTS(SELECT 1 FROM MD_Customer s where ss.KUNNR=s.Code) 
				-----插入地址 
				INSERT INTO MD_Address(Code, Address, PostCode, TelPhone, MobilePhone, Fax, Email, ContactPsnNm, 
					CreateUser, CreateUserNm, CreateDate, LastModifyUser, LastModifyUserNm, LastModifyDate) 
				SELECT DISTINCT KUNNR As Code ,REMARK As Address,PSTLZ As PostCode,TELF1 As TelPhone,TELF2 As MobilePhone,TELFX As Fax,
					TELBX As Email,PARNR As ContactPsnNm,@UserId,@UserName,@CurrentDate,@UserId,@UserName,@CurrentDate 
					FROM #TempCustomer WHERE KUNNR IS NOT NULL

				-----插入区域 
				INSERT INTO MD_Party(Code, Name, LongName, IsActive, CreateUser, CreateUserNm, CreateDate, LastModifyUser, LastModifyUserNm, LastModifyDate) 
					SELECT DISTINCT KUNNR As Code, NAME1 As Name, NAME1 As LongName, case when  LOEVM= 'X' then 0 else 1 end As IsActive, @UserId As CreateUser, @UserName As CreateUserNm,
						@CurrentDate As CreateDate, @UserId As LastModifyUser,@UserName As LastModifyUserNm, @CurrentDate As LastModifyDate 
						FROM #TempCustomer WHERE KUNNR IS NOT NULL

				------插入区域地址 
				INSERT INTO MD_PartyAddr(Party, Address, Type, IsPrimary, Seq, CreateUser, CreateUserNm, CreateDate, LastModifyUser, LastModifyUserNm, LastModifyDate) 
					SELECT DISTINCT KUNNR As Party,KUNNR As Address,1 As Type,1 As IsPrimary,1 As Seq,@UserId As CreateUser, @UserName As CreateUserNm,
						@CurrentDate As CreateDate, @UserId As LastModifyUser,@UserName As LastModifyUserNm, @CurrentDate As LastModifyDate 
						FROM #TempCustomer WHERE KUNNR IS NOT NULL
				UNION ALL 
					SELECT DISTINCT KUNNR As Party,KUNNR As Address,0 As Type,1 As IsPrimary,1 As Seq,@UserId As CreateUser, @UserName As CreateUserNm,
						@CurrentDate As CreateDate, @UserId As LastModifyUser,@UserName As LastModifyUserNm, @CurrentDate As LastModifyDate 
						FROM #TempCustomer WHERE KUNNR IS NOT NULL				
				-----插入供应商权限
				--select top 1000 * from ACC_Permission
				INSERT INTO ACC_Permission(Code,Desc1,Category,Sequence)
					SELECT DISTINCT KUNNR  As Code ,NAME1 As Desc1,'Customer' As Category,10000 As Sequence FROM #TempCustomer ts
						WHERE NOT EXISTS(SELECT 1 FROM ACC_Permission pm WHERE pm.Code=ts.KUNNR)
				
				-----插入客户
				UPDATE A 
					SET A.Name=B.NAME1,
					A.IsActive=case when B.LOEVM= 'X' then 0 else 1 end,
					A.LastModifyUser=@UserId,
					A.LastModifyUserNm=@UserName,
					A.LastModifyDate=@CurrentDate
					FROM MD_Party A LEFT JOIN SAP_Customer B
					ON A.Code=B.KUNNR 
					WHERE  B.BatchNo=@BatchNo AND B.KUNNR IS NOT NULL
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
					FROM MD_Address A LEFT JOIN SAP_Customer B
					ON A.Code=B.KUNNR 
					WHERE  B.BatchNo=@BatchNo AND B.KUNNR IS NOT NULL
				
				INSERT INTO MD_Customer(Code) 
					SELECT DISTINCT KUNNR As Code
						FROM #TempCustomer WHERE KUNNR IS NOT NULL
				--Select * from MD_Customer

				UPDATE SAP_Customer SET Status=1 WHERE BatchNo=@BatchNo  
				SELECT Status=1,BatchNo=@BatchNo,Message='SUCCESS UPDATE SAP Customer TO LES' 
		END TRY 
		BEGIN CATCH 
			UPDATE Sap_Item SET Status=2 WHERE BatchNo=@BatchNo  
			SELECT Status=2,BatchNo=@BatchNo,Message=ERROR_MESSAGE() 
		END CATCH
	END 
END