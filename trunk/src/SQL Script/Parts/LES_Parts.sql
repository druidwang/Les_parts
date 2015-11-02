CREATE TABLE [dbo].[TMS_FlowMstr](
	[Code] [varchar](50) NOT NULL,
	[Desc] [varchar](255) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsAutoStart] [bit] NOT NULL,
	[IsAutoRelease] [bit] NOT NULL,
	[CreateUserNm] [varchar](255) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](255) NOT NULL,
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
	[Category] [varchar](20) NOT NULL,
	[CarrierDesc] [varchar](255) NOT NULL,
	[Carrier] [varchar](50) NOT NULL,
	[PriceList] [varchar](50) NULL,
	[BillAddr] [varchar](50) NULL,
	[CreateUserNm] [varchar](255) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](255) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL
 CONSTRAINT [PK_TMS_FlowCarrier] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[TMS_FlowStation](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Flow] [varchar](50) NOT NULL,
	[Seq] [int] NOT NULL,
	[Station] [varchar](20) NOT NULL,
	[CreateUserNm] [varchar](255) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](255) NOT NULL,
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
	[Category] [varchar](50) NOT NULL,
	[Carrier] [varchar](50) NOT NULL,
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
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[Currency] [varchar](50) NOT NULL,
	[UnitPrice] [decimal](18, 8) NOT NULL,
	[IsProvEst] [bit] NOT NULL,
	[MinLotSize] [decimal](18, 8) NULL,
	[Tonnage] [varchar](50) NULL,
	[MinPrice] [decimal](18, 8) NULL,
	[SendFee] [decimal](18, 8) NULL,
	[InOutFee] [decimal](18, 8) NULL,
	[ServiceFee] [decimal](18, 8) NULL,
	[PricingMethod] [varchar](20) NOT NULL,
	[MonthlyQty] [decimal](18, 8) NULL,
	[MonthlyPrice] [decimal](18, 8) NULL,
	[StepUom] [varchar](10) NULL,
	[StartQty] [decimal](18, 8) NULL,
	[EndQty] [decimal](18, 8) NULL,
	[ShipFromDesc] [varchar](255) NOT NULL,
	[ShipFrom] [varchar](50) NOT NULL,
	[ShipToDesc] [varchar](255) NOT NULL,
	[ShipTo] [varchar](50) NOT NULL,
	[MaxPrice] [decimal](18, 9) NULL,
 CONSTRAINT [PK_TMS_PRICELISTDET] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[TMS_Tonnage](
	[Code] [varchar](50) NOT NULL,
	[Desc] [varchar](255) NOT NULL,
	[Volume] [decimal](18, 9) NOT NULL,
	[CreateUserNm] [varchar](255) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](255) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL,
	[Weight] [decimal](18, 9) NOT NULL,
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
	[MPhone] [varchar](50) NULL,
	[Phone] [varchar](50) NULL,
	[VIN] [varchar](50) NULL,
	[EngineNo] [varchar](50) NULL,
	[Address] [varchar](255) NULL,
	[Fax] [varchar](50) NULL,
	[Driver] [varchar](50) NULL,
	[Tonnage] [varchar](50) NOT NULL,
	[CreateUserNm] [varchar](255) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastModifyUserNm] [varchar](255) NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TMS_VEHICLE] PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[TMS_OrderMstr](
	[OrderNo] [varchar](50) NOT NULL,
	[FreightNo] [varchar](50) NULL,
	[PalletQty] [decimal](18, 9) NOT NULL,
	[ActPalletQty] [decimal](18, 9) NOT NULL,
	[Tonnage] [varchar](50) NULL,
	[LoadRate] [decimal](18, 9) NULL,
	[PalletVolume] [decimal](18, 9) NULL,
	[TonnageVolume] [decimal](18, 9) NULL,
	[ActVolume] [decimal](18, 9) NOT NULL,
	[ActUnitPack] [decimal](18, 9) NOT NULL,
	[UnitPack] [decimal](18, 9) NOT NULL,
	[Volume] [decimal](18, 9) NOT NULL,
	[RefNo] [varchar](50) NULL,
	[ExtNo] [varchar](255) NULL,
	[StartTime] [datetime] NULL,
	[WinTime] [datetime] NOT NULL,
	[Status] [varchar](50) NOT NULL,
	[Type] [varchar](50) NOT NULL,
	[Category] [varchar](50) NOT NULL,
	[CarrierDesc] [varchar](255) NOT NULL,
	[Carrier] [varchar](50) NOT NULL,
	[BillAddr] [varchar](50) NULL,
	[FlowCurrency] [varchar](50) NULL,
	[Currency] [varchar](50) NULL,
	[PriceList] [varchar](50) NULL,
	[ShipFromDesc] [varchar](255) NOT NULL,
	[ShipFrom] [varchar](50) NOT NULL,
	[ShipToDesc] [varchar](255) NOT NULL,
	[ShipTo] [varchar](50) NOT NULL,
	[AuthVehicle] [bit] NOT NULL,
	[Vehicle] [varchar](50) NULL,
	[DriverDesc] [varchar](255) NULL,
	[AuthDriver] [bit] NOT NULL,
	[Driver] [varchar](50) NULL,
	[SettleTime] [datetime] NULL,
	[Remark] [varchar](600) NULL,
	[IsFreeCharge] [bit] NOT NULL,
	[Freight] [decimal](18, 9) NULL,
	[IsProvEst] [bit] NOT NULL,
	[PricingMethod] [varchar](20) NULL,
	[RoundUpOpt] [int] NOT NULL,
	[MinPrice] [decimal](18, 8) NULL,
	[SendFee] [decimal](18, 8) NULL,
	[InOutFee] [decimal](18, 8) NULL,
	[ServiceFee] [decimal](18, 8) NULL,
	[UnitPrice] [decimal](18, 8) NULL,
	[CreateDate] [datetime] NOT NULL,
	[CreateUserNm] [varchar](255) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[LastModifyDate] [datetime] NOT NULL,
	[LastModifyUser] [varchar](50) NOT NULL,
	[LastModifyUserNm] [varchar](255) NOT NULL,
	[CancelDate] [datetime] NULL,
	[CancelUserNm] [varchar](255) NULL,
	[CancelUser] [varchar](50) NULL,
	[SubmitDate] [datetime] NULL,
	[SubmitUser] [varchar](50) NULL,
	[SubmitUserNm] [varchar](255) NULL,
	[StartDate] [datetime] NULL,
	[StartUserNm] [varchar](255) NULL,
	[StartUser] [varchar](50) NULL,
	[CompleteDate] [datetime] NULL,
	[CompleteUser] [varchar](50) NULL,
	[CompleteUserNm] [varchar](255) NULL,
	[CloseUserNm] [varchar](255) NULL,
	[CloseDate] [datetime] NULL,
	[CloseUser] [varchar](50) NULL,
	[VoidDate] [datetime] NULL,
	[VoidUserNm] [varchar](255) NULL,
	[VoidUser] [varchar](50) NULL,
	[Version] [int] NOT NULL,
	[IsAutoStart] [bit] NOT NULL,
	[IsAutoRelease] [bit] NOT NULL,
	[SubType] [varchar](50) NULL,
	[ActVolume2] [decimal](18, 9) NULL,
	[Weight] [decimal](18, 9) NULL,
	[ActWeight] [decimal](18, 9) NULL,
	[MaxPrice] [decimal](18, 9) NULL,
	[Phone] [varchar](50) NULL,
	[IsAutoComplete] [bit] NULL,
	[IsASN] [bit] NULL,
	[TonnageWeight] [decimal](18, 9) NULL,
	[ItemQty] [decimal](18, 9) NOT NULL,
 CONSTRAINT [PK_TMS_OrderMstr] PRIMARY KEY CLUSTERED 
(
	[OrderNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[TMS_OrderDet](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[OrderNo] [varchar](50) NOT NULL,
	[FrontWaybillNo] [varchar](50) NULL,
	[IpNo] [varchar](50) NOT NULL,
	[UnitPack] [decimal](18, 9) NOT NULL,
	[Volume] [decimal](18, 9) NOT NULL,
	[PalletQty] [decimal](18, 9) NOT NULL,
	[PartyFromDesc] [varchar](255) NOT NULL,
	[PartyFrom] [varchar](50) NOT NULL,
	[PartyTo] [varchar](50) NOT NULL,
	[PartyToDesc] [varchar](255) NOT NULL,
	[DepartTime] [datetime] NULL,
	[ArriveTime] [datetime] NULL,
	[CreateUserNm] [varchar](255) NOT NULL,
	[CreateUser] [varchar](50) NOT NULL,
	[ShipFrom] [varchar](50) NOT NULL,
	[ShipFromDesc] [varchar](255) NOT NULL,
	[ShipTo] [varchar](50) NOT NULL,
	[ShipToDesc] [varchar](255) NOT NULL,
	[Status] [varchar](50) NOT NULL,
	[Dock] [varchar](50) NULL,
	[Seq] [int] NOT NULL,
	[Remark] [varchar](255) NULL,
	[Weight] [decimal](18, 9) NOT NULL,
	[ItemQty] [decimal](18, 9) NOT NULL,
 CONSTRAINT [PK_TMS_OrderDet] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[TMS_OrderStation](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[OrderNo] [varchar](50) NOT NULL,
	[Station] [varchar](50) NULL
 CONSTRAINT [PK_TMS_OrderStation] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]