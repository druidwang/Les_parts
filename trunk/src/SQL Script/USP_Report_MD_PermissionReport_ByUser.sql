USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_MD_PermissionReport_ByUser]    Script Date: 12/08/2014 15:17:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_Report_MD_PermissionReport_ByUser]
(
	@Code varchar(100),
	@Depart varchar(100),
	@Position varchar(100)
)
AS
--USP_Report_MD_PermissionReport_ByUser '','',''
 
BEGIN
SET NOCOUNT ON
----2013/12/26	增加是否有效/*--0001*/字段 WenXiangYong  ----0001
	--MI0101	刘	军	炼胶区域	主线
	--用户名	姓	名	部门	岗位	角色
Declare @MergePermissions varchar(max)=''
--Declare @Code varchar(100)
--Declare @Depart varchar(100)
--Declare @Position varchar(100)
Select distinct b.Code As 用户名,ISNULL(b.FirstName,'') As 姓,ISNULL(b.LastName,'') As 名,ISNULL(b.depart,'') As 部门,ISNULL(b.position,'')  As 岗位,
	c.Desc1 As 权限名称 ,case when d.Type=0 then '菜单' 
	when d.Type=1 then '页面' when d.Type=2 then '区域'when d.Type=3 then '客户'
	when d.Type=4 then '供应商'when d.Type=5 then '手持终端'when d.Type=6 then '权限组'
	else '订单类型' End +'权限' As 权限分类 ,Case when b.IsActive = 1 then 'Y' else 'N' End As 有效/*--0001*/ into #RolePermission
	from ACC_UserPermission a join ACC_User b on a.UserId=b.Id
	join ACC_Permission c on a.PermissionId = c.Id
	join ACC_PermissionCategory d on d.Code = c.Category
	----Null值不参与运算
	where b.Code like isnull(@Code,'')+'%' and c.Sequence>=0 
	--and b.Depart like isnull(@Depart,'')+'%' and b.Position like isnull(@Position,'')+'%' order by c.Sequence
	----Merge permission by 角色 权限分类
	Select distinct 0 As Id,用户名,姓,名,部门,岗位,权限分类,
		@MergePermissions As 角色名称汇总,有效/*--0001*/
		into #RolePermissionMerge from #RolePermission
	----2013/12/18 有可能该用户除了角色之外没有任何的权限，所以要单独Insert role permission
	Insert into #RolePermissionMerge
		Select distinct Id,用户名,isnull(姓,''),isnull(名,''),isnull(部门,''),isnull(岗位,''),'用户角色' As 权限分类,
		@MergePermissions As 角色名称汇总,有效/*--0001*/ from #RolePermissionMerge
	--If @@ROWCOUNT =0
	--	Begin

	--End
	Create index IX_Code on #RolePermission(用户名)
	Create index IX_Code on #RolePermissionMerge(用户名)
	Insert into #RolePermissionMerge
		Select distinct 0 Id,Code ,isnull(FirstName,'') ,isnull(LastName,''),isnull(Depart,'') ,isnull(Position,''),'用户角色' As 权限分类,
			@MergePermissions As 角色名称汇总,Case when IsActive = 1 then 'Y' else 'N' End As 有效/*--0001*/  from ACC_User a With(nolock) where Code like isnull(@Code,'')+'%' and 
			not exists(select 0 from #RolePermissionMerge b where a.Code =b.用户名) ---and a.IsActive =1
	Update a
		Set a.Id=b.IdSeq from #RolePermissionMerge a with(index=IX_Code),
		(select *,ROW_NUMBER()over(order by 用户名,姓,名,部门,岗位) As IdSeq from #RolePermissionMerge) b 
		where a.用户名=b.用户名 and a.权限分类=b.权限分类
	--select * from #RolePermission
	--select * from #RolePermissionMerge
	--select * from VIEW_UserPermission
	Declare @Id int=1
	select b.Code,c.Desc1 into #RolePermissionSum 
		from ACC_UserRole a with(nolock),ACC_User b with(nolock),ACC_Role c with(nolock) 
		where a.UserId=b.Id and a.RoleId=c.Id
	Create index IX_Code on #RolePermissionSum(Code)
	--Select * from #RolePermissionSum
	While exists(select top 1 * from #RolePermissionMerge where id=@Id)
		Begin
			Declare @用户名 varchar(100)=''
			Declare @权限分类 varchar(100)=''
			select top 1 @用户名=用户名,@权限分类=权限分类 from #RolePermissionMerge where id=@Id
			print @Id
			print @用户名
			print @权限分类
			Set @MergePermissions=''
			Select @MergePermissions=@MergePermissions+权限名称+'<br>' 
				from #RolePermission with(index=IX_Code) where 用户名=@用户名 and 权限分类=@权限分类
			Update #RolePermissionMerge Set 角色名称汇总=@MergePermissions where id=@Id
			If @权限分类='用户角色'
			Begin
				Set @MergePermissions=''
				select @MergePermissions=@MergePermissions+Desc1+'<br>' 
					from #RolePermissionSum where Code = @用户名
				print @MergePermissions
				Update #RolePermissionMerge Set 角色名称汇总=@MergePermissions where id=@Id and 权限分类='用户角色'
			End
			Set @Id=@Id+1
			--print @Id
		End
	----0001
		
	----0001
	
	SELECT 用户名,姓+名 As 姓名,有效/*--0001*/,部门,岗位,Isnull(用户角色,'') as 用户角色,Isnull(菜单权限,'') as 菜单权限,Isnull(页面权限,'') as 页面权限,Isnull(区域权限,'') as 区域权限,
		Isnull(客户权限,'') as 客户权限,Isnull(供应商权限,'') as 供应商权限,Isnull(手持终端权限,'') as 手持终端权限,
		Isnull(权限组权限,'') as 权限组权限,Isnull(订单类型权限,'') as 订单类型权限
		FROM (select 用户名,姓,名,部门,有效/*--0001*/,岗位,权限分类,角色名称汇总 from #RolePermissionMerge) as D  pivot(max(角色名称汇总) for 权限分类 
		in ([用户角色],[菜单权限],[页面权限],[区域权限],[客户权限],[供应商权限],[手持终端权限],[权限组权限],[订单类型权限])) as PVT order by 部门 desc,岗位 desc,有效 desc,用户名 desc 
--select * from ACC_Role
--select * from ACC_PermissionCategory
--select * from ACC_RolePermission
End