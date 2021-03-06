USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_GetTransitOrder]    Script Date: 12/08/2014 15:11:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_Busi_MRP_GetTransitOrder]
(
	@SnapTime datetime
)
AS
BEGIN
select 
row_number() over(order by getdate()) as Id,* from 
(
---------------------------采购在途-------------------------------------
--select 
--det.OrderNo as OrderNo,
--det.OrderDetId as OrderDetId,
--det.IpNo as IpNo,
--det.Flow as Flow,
--det.OrderType as OrderType,
--case det.OrderSubType when 0 then det.LocTo else det.LocFrom end as Location,
--det.Item as Item,
--det.Qty * det.UnitQty as ShipQty,
--det.RecQty * det.UnitQty as RecQty,
--det.StartTime as StartTime,
--det.Windowtime as Windowtime,
--@SnapTime as SnapTime
--from ORD_IpDet_1 as det
--where det.IsClose = 0 and det.QualityType=0 and det.OrderSubType in(0,1)
--union all 
---------------------------移库在途-------------------------------------
select 
det.OrderNo as OrderNo,
det.OrderDetId as OrderDetId,
det.IpNo as IpNo,
det.Flow as Flow,
det.OrderType as OrderType,
case det.OrderSubType when 0 then det.LocTo else det.LocFrom end as Location,
det.Item as Item,
det.Qty * det.UnitQty as ShipQty,
det.RecQty * det.UnitQty as RecQty,
det.StartTime as StartTime,
det.Windowtime as Windowtime,
@SnapTime as SnapTime
from ORD_IpDet_2 as det
where det.IsClose = 0 and det.QualityType=0 and det.OrderSubType in(0,1)
union all 
---------------------------客供品在途-------------------------------------
--select 
--det.OrderNo as OrderNo,
--det.OrderDetId as OrderDetId,
--det.IpNo as IpNo,
--det.Flow as Flow,
--det.OrderType as OrderType,
--case det.OrderSubType when 0 then det.LocTo else det.LocFrom end as Location,
--det.Item as Item,
--det.Qty * det.UnitQty as ShipQty,
--det.RecQty * det.UnitQty as RecQty,
--det.StartTime as StartTime,
--det.Windowtime as Windowtime,
--@SnapTime as SnapTime
--from ORD_IpDet_6 as det
--where det.IsClose = 0 and det.QualityType=0 and det.OrderSubType in(0,1)
--union all 
---------------------------委外领料在途-------------------------------------
select 
det.OrderNo as OrderNo,
det.OrderDetId as OrderDetId,
det.IpNo as IpNo,
det.Flow as Flow,
det.OrderType as OrderType,
case det.OrderSubType when 0 then det.LocTo else det.LocFrom end as Location,
det.Item as Item,
det.Qty * det.UnitQty as ShipQty,
det.RecQty * det.UnitQty as RecQty,
det.StartTime as StartTime,
det.Windowtime as Windowtime,
@SnapTime as SnapTime
from ORD_IpDet_7 as det
where det.IsClose = 0 and det.QualityType=0 and det.OrderSubType in(0,1)
--union all 
---------------------------计划协议在途-------------------------------------
--select 
--det.OrderNo as OrderNo,
--det.OrderDetId as OrderDetId,
--det.IpNo as IpNo,
--det.Flow as Flow,
--det.OrderType as OrderType,
--case det.OrderSubType when 0 then det.LocTo else det.LocFrom end as Location,
--det.Item as Item,
--det.Qty * det.UnitQty as ShipQty,
--det.RecQty * det.UnitQty as RecQty,
--det.StartTime as StartTime,
--det.Windowtime as Windowtime,
--@SnapTime as SnapTime
--from ORD_IpDet_8 as det
--where det.IsClose = 0 and det.QualityType=0 and det.OrderSubType in(0,1)
) as a
END