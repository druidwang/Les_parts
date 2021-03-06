USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_PickTransRecords]    Script Date: 12/08/2014 15:18:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <温祥永>
-- Create date: <Create Date,2013/09/02>
-- Description: <Description,To trace pick transaction records>
--[USP_Report_PickTransRecords] '9101','9305','200000','200019'
--[USP_Report_PickTransRecords] '','','','','','','2010-09-03 06:11:23.257','2014-09-03 06:11:23.257',''
-- =============================================
ALTER PROCEDURE [dbo].[USP_Report_PickTransRecords]
(
 @Item varchar(50),
 @HuId varchar(50),
 @Bin varchar(50),
 @Location varchar(50),
 @LotNo varchar(50),
 @CreateUser varchar(50),
 @StartDate datetime,
 @EndDate datetime,
 @Type varchar(20)
)
AS
 
BEGIN
 SET NOCOUNT ON;
 --Id, Item, ItemDescription, HuId, LotNo, Location, Bin, IsPick, CreateUser, CreateUserNm, CreateDate
 If @Type='GetPick'
 Begin
	select GETDATE()
	select top 100 * into #INV_PickTrans from INV_PickTrans with(nolock) 
		where CreateDate between @StartDate and @EndDate and Item like isnull(@Item,'')+'%'
		and HuId like isnull(@HuId,'')+'%'and Bin like isnull(@Bin,'')+'%'and Location like isnull(@Location,'')+'%'
		and CreateUser like isnull(@CreateUser,'')+'%'and LotNo like isnull(@LotNo,'')+'%' order by Item,CreateDate
 End
 Else
 Begin
	 select top 100 *into #INV_FreezeTrans from INV_FreezeTrans with(nolock) 
		--where CreateDate between @StartDate and @EndDate and Item like isnull(@Item,'')+'%'
		--and HuId like isnull(@HuId,'')+'%'and Location like isnull(@Location,'')+'%'
		--and CreateUser like isnull(@CreateUser,'')+'%'and LotNo like isnull(@LotNo,'')+'%' order by Item,CreateDate
 End
If @@ROWCOUNT =0
	begin
		select 0 as totalcolumns,0 as mergerows
		return
	end

 If @Type='GetPick' 
	Begin 
		--update INV_PickTrans set ispick='false'
		select 10 as totalcolumns,0 as mergerows
		select 50,80,60,40,40,40,30,40,60
		select top 100 Item 物料, ItemDescription 物料描述, HuId 条码, LotNo 批号, Location 库位, Bin 库格, 
			case when IsPick=1 then '下架' else '上架' end 状态, CreateUserNm 创建用户, CreateDate 创建日期 from  #INV_PickTrans 
	End
	Else
	Begin 
		--select * from  INV_FreezeTrans where Item like '%'
		select 9 as totalcolumns,0 as mergerows
		select  50,80,60,40,40,20,40,60
		select top 100 Item 物料, ItemDescription 物料描述,  HuId 条码,LotNo 批号,Location 库位, 
			case when Freeze=1 then '冻结'else '解冻' end 状态,  CreateUserNm 创建用户, CreateDate 创建日期 from  #INV_FreezeTrans 
	End

END




