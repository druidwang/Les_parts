USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_SnapHitory_MrpPlan]    Script Date: 12/08/2014 15:14:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--USP_Busi_MRP_SnapHitory_MrpPlan  '','','2013-08-05 08:16:45' 


ALTER PROCEDURE [dbo].[USP_Busi_MRP_SnapHitory_MrpPlan]
(
	@Flow varchar(50),
	@Item varchar(50),
	@SnapTime datetime
)
AS
BEGIN
	SET NOCOUNT ON
	Begin
    SELECT @Flow=LTRIM(RTRIM(@Flow)),@Item=LTRIM(RTRIM(@Item))
		--select distinct plandate,item,flow,location,planversion  from MRP_SnapMrpPlan where snaptime ='2013-08-03 20:50:10.403'
		--select count(*) from MRP_SnapMrpPlan where snaptime ='2013-08-03 20:50:10.403'
		--select top 1000* from MRP_SnapMrpPlan where snaptime ='2013-08-02 21:36:55.483' and plandate='2013-08-03 00:00:00.000'
		--and item='200003' and flow='9101-600000' and location='9101'
		--select * from MRP_SnapMrpPlan where snaptime ='2013-08-03 20:50:10.403' and flow='9101-600000' and planversion='7'
		--select GETDATE()
		select Flow as 路线,a.location as 库位,a.Item as 物料,b.Desc1 as 物料描述,b.Uom as 单位, dbo.FormatDate(a.Plandate,'YYYY-MM-DD')  As plandate,Qty into #tmp 
			from MRP_SnapMrpPlan a with(nolock),MD_Item b with(nolock) where a.snaptime =@SnapTime and a.flow like ISNULL(@Flow,'')+'%' and a.item like isnull(@Item,'')+'%' 
			and a.Item=b.Code
		--Sp_help'MRP_SnapMrpPlan'
		--select GETDATE()

		--select * from #tmp
		--drop table #tmp
		If @@rowcount =0
			Begin
				select 0 as rowcounts
				Select @SnapTime As NG
				Return 
			End

		Declare @SQL varchar(max)=''
		Declare @SQL1 varchar(max)=''
		SELECT DISTINCT plandate INTO #tmp1 FROM #tmp ORDER BY plandate
		SELECT COUNT(*) +5 as colcount FROM #tmp1
		SELECT @SQL=@SQL+'Isnull(['+Convert(varchar(100),plandate)+'],0)'+' as ['+plandate +'],'
			,@SQL1=@SQL1+'['+plandate +'],'
		FROM #tmp1 ORDER BY plandate
		IF @SQL!=''
		BEGIN
			SET @SQL =Substring(@SQL,1,LEN(@SQL)-1)
			SET @SQL1 =Substring(@SQL1,1,LEN(@SQL1)-1)	
		END		 
		set @SQL='SELECT 路线,库位,物料, 物料描述,单位,'+@SQL+' into #Record FROM (select * from #tmp) as D  pivot(sum(Qty)'+
		' for plandate in ('+@SQL1+')) as PVT order by 路线,库位,物料;select * from #Record '
		Print @SQL
		EXEC (@SQL)
	End
 End