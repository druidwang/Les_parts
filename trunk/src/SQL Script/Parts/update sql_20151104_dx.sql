alter table TMS_Driver add LicenseNo varchar(50)
go
alter table TMS_OrderMstr drop column DrivingNo
go
alter table TMS_OrderMstr add LicenseNo varchar(50)
go