--程序{0}的输入参数{0}不能为空。
EXEC sp_addmessage @msgnum = 50001, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_PARM_NULL</MSG_ID><PARMS><PARM>%s</PARM><PARM>%s</PARM></PARMS></ERR_MSG>',  @replace = 'replace'
GO

--获取顺序号存储过程的BatchSize参数不能小于等于0。
EXEC sp_addmessage @msgnum = 50002, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_BATCH_SIZE_LE_ZERO</MSG_ID></ERR_MSG>',  @replace = 'replace'
GO

--{0}时发生错误:{1}，行数：{2}。
EXEC sp_addmessage @msgnum = 50003, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_EXEC_SP</MSG_ID><PARMS><PARM>%s</PARM><PARM>%s</PARM><PARM>%d</PARM></PARMS></ERR_MSG>',  @replace = 'replace'
GO

--程序执行时发生错误:{1}，行数：{2}。
EXEC sp_addmessage @msgnum = 50004, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_INNER_ERROR</MSG_ID><PARMS><PARM>%s</PARM><PARM>%d</PARM></PARMS></ERR_MSG>',  @replace = 'replace'
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

--价格单标识{0}不存在。
EXEC sp_addmessage @msgnum = 60004, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_PUR_PL_ID_NOT_EXIST</MSG_ID><PARMS><PARM>%d</PARM></PARMS></ERR_MSG>',  @replace = 'replace'
GO

--数据已经被更新，请重试。
EXEC sp_addmessage @msgnum = 60005, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_DATA_CONCURRENCY</MSG_ID>',  @replace = 'replace'
GO

--采购价格单标识{0}不存在。
EXEC sp_addmessage @msgnum = 60006, @severity = 16, @msgtext = N'<ERR_MSG><MSG_ID>ERRORS_PUR_PL_ID_NOT_FOUND</MSG_ID><PARMS><PARM>%d</PARM></PARMS></ERR_MSG>',  @replace = 'replace'
GO



