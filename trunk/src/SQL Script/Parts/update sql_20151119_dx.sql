alter table WMS_ShipPlan add OrderSeq int
go
alter table WMS_ShipPlan add OrderDetId int
go
alter table WMS_ShipPlan add IsOccupyInv bit
go
alter table WMS_ShipPlan add CloseUser int
go
alter table WMS_ShipPlan add CloseUserNm varchar(100)
go
alter table WMS_ShipPlan add CloseDate datetime
go
alter table MD_Location add PickScheduleNo varchar(50)
go
/****** Object:  Table [dbo].[WMS_PickSchedule]    Script Date: 2015/11/19 13:26:39 ******/
DROP TABLE [dbo].[WMS_PickSchedule]
GO

/****** Object:  Table [dbo].[WMS_PickSchedule]    Script Date: 2015/11/19 13:26:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[WMS_PickSchedule](
	[PickScheduleNo] [varchar](50) NOT NULL,
	[PickLeadTime] [decimal](18, 8) NOT NULL,
	[RepackLeadTime] [decimal](18, 8) NOT NULL,
	[SpreadLeadTime] [decimal](18, 8) NOT NULL,
	[CreateUser] [int] NOT NULL,
	[CreateUserNm] [varchar](100) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUser] [int] NOT NULL,
	[LastModifyUserNm] [varchar](100) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_WMS_PickSchedule] PRIMARY KEY CLUSTERED 
(
	[PickScheduleNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


/****** Object:  Table [dbo].[WMS_PickWinTime]    Script Date: 2015/11/19 13:26:54 ******/
DROP TABLE [dbo].[WMS_PickWinTime]
GO

/****** Object:  Table [dbo].[WMS_PickWinTime]    Script Date: 2015/11/19 13:26:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[WMS_PickWinTime](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PickScheduleNo] [varchar](50) NOT NULL,
	[ShiftCode] [varchar](50) NOT NULL,
	[WinTime] [varchar](255) NOT NULL,
	[CreateUser] [int] NOT NULL,
	[CreateUserNm] [varchar](100) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUser] [int] NOT NULL,
	[LastModifyUserNm] [varchar](100) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_WMS_PickWinTime] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


