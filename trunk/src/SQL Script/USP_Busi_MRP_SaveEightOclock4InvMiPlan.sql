USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_SaveEightOclock4InvMiPlan]    Script Date: 12/08/2014 15:13:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[USP_Busi_MRP_SaveEightOclock4InvMiPlan]  
--Mrp Mi Plan的库存需要从每天早晨8点开始推算

ALTER PROCEDURE [dbo].[USP_Busi_MRP_SaveEightOclock4InvMiPlan]

AS
BEGIN
	SET NOCOUNT ON
Select top 0 * into #MRP_InventoryBalance_MIPlan from MRP_InventoryBalance_MIPlan where 1=2
Insert into #MRP_InventoryBalance_MIPlan(Location,Item,Qty,IpQty,SnapTime)
Select Location ,Item ,SUM(Qty) ,0 As IpQty,GETDATE() As SnapTime from 
	VIEW_LocationLotDet where Location in('9201','9202','9203','9204')
	Group by Location ,Item
--IPQty
Select a.Item as Item,a.LocFrom as Location,
	sum((Qty - RecQty)*UnitQty) As IpQty into #TempTransQty
	from ORD_IpDet_2 a  where a.IsClose =0 and ABS(Qty)>ABS(RecQty) 
	and a.LocFrom in('9201','9202','9203','9204')
	group by a.Item,a.LocFrom
Update a
	Set a.IpQty=b.IpQty from #MRP_InventoryBalance_MIPlan a,#TempTransQty b 
	where a.location=b.Location and a.item =b.Item
Insert into MRP_InventoryBalance_MIPlan Select Location,Item,Qty,IpQty,SnapTime from #MRP_InventoryBalance_MIPlan
Delete MRP_InventoryBalance_MIPlan where snaptime < DATEADD(day,-7,Getdate())
Drop table #TempTransQty
--Select top 100 * from MRP_InventoryBalance_MIPlan
END
