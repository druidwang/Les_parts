USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_ReleaseMiPlan]    Script Date: 12/08/2014 15:12:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		liqiuyun
-- Create date: 20130727
-- Description:	修正炼胶天计划释放算法:天计划转班产计划
-- =============================================
ALTER PROCEDURE [dbo].[USP_Busi_MRP_ReleaseMiPlan]
(@MrpMiDateIndexId int
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

END
