--存储过程{0]的输入参数{0}不能为空。
EXEC sp_addmessage @msgnum = 50001, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_PARM_NULL</MSG_ID><PARMS><PARM>%s</PARM><PARM>%s</PARM></PARMS></ERR_MSG>',  @replace = 'replace'
GO

--没有维护物料{0}从单位{1}到单位{2}转换率。
EXEC sp_addmessage @msgnum = 60001, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_UOM_CONVERTION_NOT_FOUND</MSG_ID><PARMS><PARM>%s</PARM><PARM>%s</PARM><PARM>%s</PARM></PARMS></ERR_MSG>',  @replace = 'replace'
GO
--物料代码{0}不存在。
EXEC sp_addmessage @msgnum = 60002, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_PT_NO_NOT_EXIST</MSG_ID><PARMS><PARM>%s</PARM></PARMS></ERR_MSG>',  @replace = 'replace'
GO
--计量单位{0}不存在。
EXEC sp_addmessage @msgnum = 60003, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_UOM_NOT_EXIST</MSG_ID><PARMS><PARM>%s</PARM></PARMS></ERR_MSG>',  @replace = 'replace'
GO
--转换计量单位时发生错误:{0}。
EXEC sp_addmessage @msgnum = 60004, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_CONVERT_UOM</MSG_ID><PARMS><PARM>%s</PARM></PARMS></ERR_MSG>',  @replace = 'replace'
GO


