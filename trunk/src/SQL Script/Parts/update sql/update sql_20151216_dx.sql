alter table WMS_PickTask add OrderNo varchar(50)
go
alter table WMS_PickTask add OrderSeq int
go
alter table WMS_PickTask add ShipPlanId int
go
alter table WMS_PickTask add TargetDock varchar(50)
go
alter table WMS_RepackTask add OrderNo varchar(50)
go
alter table WMS_RepackTask add OrderSeq int
go
alter table WMS_RepackTask add ShipPlanId int
go
alter table WMS_RepackTask add TargetDock varchar(50)
go
drop table WMS_PickOccupy
go
drop table WMS_RepackOccupy
go
