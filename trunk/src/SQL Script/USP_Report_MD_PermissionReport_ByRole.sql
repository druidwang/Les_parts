USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_MD_PermissionReport_ByRole]    Script Date: 12/08/2014 15:17:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_Report_MD_PermissionReport_ByRole]
(
	@Code varchar(100)
)
AS
--USP_Report_MD_PermissionReport_ByRole 'wenxiangyong'
 
BEGIN
	SET NOCOUNT ON
	
	Select r.Code As 角色,r.Desc1 As 角色名称,p.Desc1 As 权限名称,case when g.Type=0 then '菜单' 
		when g.Type=1 then '页面' when g.Type=2 then '区域'when g.Type=3 then '客户'
		when g.Type=4 then '供应商'when g.Type=5 then '手持终端'when g.Type=6 then 'SI'
		else '订单类型' End +'权限' As 权限分类 into #RolePermission
		from ACC_RolePermission a
		join ACC_Role r on r.Id = a.RoleId
		join ACC_Permission p on p.Id = a.PermissionId
		join ACC_PermissionCategory g on g.Code = p.Category
		where r.Code like @Code+'%' and p.Sequence>0  order by p.Sequence
	----权限组
	Insert into #RolePermission
		SELECT Distinct f.Code 角色,f.Desc1 角色名称, c.Desc1 AS 权限名称,'权限组权限' As 权限分类 
			FROM dbo.ACC_RolePermissionGroup b WITH(NOLOCK) INNER JOIN
			dbo.ACC_PermissionGroup c WITH(NOLOCK) ON b.GroupId = c.Id INNER JOIN
			dbo.ACC_Role f WITH(NOLOCK) ON b.RoleId=f.Id and f.Code=@Code 
	----Merge permission by 角色 权限分类
	Declare @MergePermissions varchar(max)=''
	Select distinct 0 As Id,角色,角色名称,权限分类,@MergePermissions As 角色名称汇总  into #RolePermissionMerge from #RolePermission
	Update a
		Set a.Id=b.IdSeq from #RolePermissionMerge a,
		(select *,ROW_NUMBER()over(order by 角色,权限分类) As IdSeq from #RolePermissionMerge) b
		where a.角色=b.角色 and a.权限分类=b.权限分类
	--select * from #RolePermission
	--select * from #RolePermissionMerge
	Declare @Id int=1
	While exists(select top 1 * from #RolePermissionMerge where id=@Id)
		Begin
			Declare @角色 varchar(100)=''
			Declare @权限分类 varchar(100)=''
			select top 1 @角色=角色,@权限分类=权限分类 from #RolePermissionMerge where id=@Id
			Set @MergePermissions=''
			select @MergePermissions=@MergePermissions+权限名称+'<br>' from #RolePermission where 角色=@角色 and 权限分类=@权限分类
			Update #RolePermissionMerge Set 角色名称汇总=@MergePermissions where id=@Id
			Set @Id=@Id+1
		End
	
	SELECT 角色 ,角色名称,Isnull(菜单权限,'') as 菜单权限,Isnull(页面权限,'') as 页面权限,Isnull(区域权限,'') as 区域权限,
		Isnull(客户权限,'') as 客户权限,Isnull(供应商权限,'') as 供应商权限,Isnull(手持终端权限,'') as 手持终端权限,
		Isnull(权限组权限,'') as 权限组权限,Isnull(订单类型权限,'') as 订单类型权限
		FROM (select 角色,角色名称,权限分类,角色名称汇总 from #RolePermissionMerge) as D  pivot(max(角色名称汇总) for 权限分类 
		in ([菜单权限],[页面权限],[区域权限],[客户权限],[供应商权限],[手持终端权限],[权限组权限],[订单类型权限])) as PVT order by 角色 desc 
--select * from ACC_Role
--select * from ACC_PermissionCategory
--select * from ACC_RolePermission
End