CREATE TABLE [dbo].[TMS_FlowMstr](
	[Code] [varchar](50) NOT NULL,
	[Desc] [varchar](255) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsAutoStart] [bit] NOT NULL,
	[IsAutoRelease] [bit] NOT NULL,
	[MinLoadRate] [decimal](18, 8) NULL,
	[CreateUserNm] [varchar](100) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](100) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL
 CONSTRAINT [PK_TMS_FLOWMSTR] PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[TMS_FlowCarrier](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Flow] [varchar](50) NOT NULL,
	[Seq] [int] NOT NULL,
	[TransMode] [int] NOT NULL,
	[Carrier] [varchar](50) NOT NULL,
	[CarrierNm] [varchar](100) NOT NULL,
	[PriceList] [varchar](50) NULL,
	[BillAddr] [varchar](50) NULL,
	[CreateUserNm] [varchar](100) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](100) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL
 CONSTRAINT [PK_TMS_FlowCarrier] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[TMS_FlowRoute](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Flow] [varchar](50) NOT NULL,
	[Seq] [int] NOT NULL,
	[ShipAddr] [varchar](50) NOT NULL,
	[ShipAddrDesc] [varchar](255) NOT NULL,
	[CreateUserNm] [varchar](100) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](100) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL
 CONSTRAINT [PK_TMS_FlowStation] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]



CREATE TABLE [dbo].[TMS_PriceList](
	[Code] [varchar](50) NOT NULL,
	[Desc] [varchar](255) NULL,
	[TransMode] [int] NOT NULL,
	[Carrier] [varchar](50) NOT NULL,
	[CarrierNm] [varchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreateUserNm] [varchar](255) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](255) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TMS_PRICELIST] PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[TMS_PriceListDet](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PriceList] [varchar](50) NOT NULL,
	[ShipFrom] [varchar](50) NOT NULL,
	[ShipFromDesc] [varchar](255) NOT NULL,
	[ShipTo] [varchar](50) NOT NULL,
	[ShipToDesc] [varchar](255) NOT NULL,
	[PricingMethod] [varchar](20) NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[Currency] [varchar](50) NOT NULL,
	[UnitPrice] [decimal](18, 8) NOT NULL,
	[IsProvEst] [bit] NOT NULL,
	[Tonnage] [varchar](50) NULL,
	[MinPrice] [decimal](18, 8) NULL,
	[MaxPrice] [decimal](18, 8) NULL,
	[DeliveryFee] [decimal](18, 8) NULL,
	[ServiceFee] [decimal](18, 8) NULL,
	[LoadingFee] [decimal](18, 8) NULL,
	[StartQty] [decimal](18, 8) NULL,
	[EndQty] [decimal](18, 8) NULL,
	[CreateUserNm] [varchar](100) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](100) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TMS_PRICELISTDET] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[TMS_Tonnage](
	[Code] [varchar](50) NOT NULL,
	[Desc] [varchar](255) NOT NULL,
	[LoadWeight] [decimal](18, 8) NOT NULL,
	[LoadVolume] [decimal](18, 8) NOT NULL,
	[CreateUserNm] [varchar](100) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](100) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TMS_TONNAGE] PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE TABLE [dbo].[TMS_Vechile](
	[Code] [varchar](50) NOT NULL,
	[Desc] [varchar](255) NOT NULL,
	[DrivingNo] [varchar](50) NULL,
	[Owner] [varchar](50) NOT NULL,
	[Phone] [varchar](50) NULL,
	[MobilePhone] [varchar](50) NULL,
	[VIN] [varchar](50) NULL,
	[EngineNo] [varchar](50) NULL,
	[Address] [varchar](255) NULL,
	[Fax] [varchar](50) NULL,
	[Driver] [varchar](50) NULL,
	[Tonnage] [varchar](50) NOT NULL,
	[CreateUserNm] [varchar](100) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](100) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TMS_VEHICLE] PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
go

CREATE TABLE [dbo].[TMS_Driver](
	[Code] [varchar](50) NOT NULL,
	[Name] [varchar](255) NOT NULL,
	[Phone] [varchar](50) NULL,
	[MobilePhone] [varchar](50) NULL,
	[Email] [varchar](50) NULL,
	[Address] [varchar](255) NULL,
	[Fax] [varchar](50) NULL,
	[PostCode] [varchar](50) NULL,
	[IdNumber] [varchar](50) NULL,
	[CreateUserNm] [varchar](100) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](100) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TMS_Driver] PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
go
