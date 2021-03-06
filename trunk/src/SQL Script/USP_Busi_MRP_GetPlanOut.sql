USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_GetPlanOut]    Script Date: 12/08/2014 15:10:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		liqiuyun
-- Create date: 20130809
-- Description:	GetPlanOut 待发
-- =============================================
ALTER PROCEDURE [dbo].[USP_Busi_MRP_GetPlanOut]
(
	@PlanVersion datetime,
	@Flow varchar(50)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    SELECT @Flow=LTRIM(RTRIM(@Flow))
	select cast(CONVERT(varchar(12),s.StartTime,111) as DateTime) as PlanDate,s.Item,SUM(s.Qty) as Qty from MRP_MrpShipPlan s 
	where s.PlanVersion =@PlanVersion and s.Flow = @Flow and (SourceFlow!=@Flow)
	group by  CONVERT(varchar(12),s.StartTime,111),Item

END


