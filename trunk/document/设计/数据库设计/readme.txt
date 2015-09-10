1.所有的描述字段命名成：Desc1、类型为Varchar(100)，有特殊需求的企业例外。
2.Code字段类型长度默认Varchart(50)，字段Value默认为Varchart(50)，字段Seq默认Int型。
3.CodeMstr，ACC_Role表增加Type字段来区分用户级与系统级。
4.“是”与“否”类型的字段定义Bit型。
5.审计字段CreateUser、LastModifyUser Varchar(50)记录int，不建外键。CreateUserNm、LastModifyUserNm Varchar(100)，CreateDate、LastModifyDate DateTime。
	建立对象,lazyLoad
6.业务表加Version字段来实现乐观锁，其它表不需要。
7.零件支持多种类型，编程时要考虑类型。
8.用户菜单浏览历史通过Html5缓存在浏览器上，不用记录在数据库中。
9.LocationLotDet isActive, isFreeze, isOccupy
10.那些表需要审计字段待定，是否会影响性能？
11.OrderDet上记录UnitQty
12.IpMstr。IsRecCreateHu收货时创建条码，来源于OrderMstr.CreateBarCodeOpt == 收货时创建条码
13.IpMstr.BarCodeOpt 表示ASN中是否包含条码/批号
14.UnitQty是转换为库存单位的换算因子
15.找价格单，要单位相同才认为找到，不做单位转换。
16.PlanBill.LocFrom记录销售时，来源库位属于那里。
17.抽盘，只计算盘点到的零件。
18.扫描条码，盘点并上架。
19.不用要货单，直接创建拣货单。
20.工序中是否要加入OpRef？？？？？
21.INP_RejectDet.Defect是用户可以维护的CodeDetail.
22.路线明细增加道口字段。