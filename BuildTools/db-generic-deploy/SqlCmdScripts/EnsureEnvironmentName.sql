USE [master]

IF (LEFT(CAST(SERVERPROPERTY('ProductVersion') As VARCHAR),1)='8')
BEGIN
    RAISERROR (N'[*** WARNING ***] SQL Server Instance "%s" is version 8 and does not support extended properties. DBGhost build is configured for "%s".', 10, 1, @@SERVERNAME, N'$(env)')
END
ELSE
BEGIN
    DECLARE @environment_name NVARCHAR(3)
    SET @environment_name = 
      (SELECT CAST([value] AS NVARCHAR(3))
       FROM   [master].[sys].[fn_listextendedproperty] (NULL, NULL, NULL, NULL, NULL, NULL, NULL)
       WHERE  [name] = N'Environment Name')
    IF (@environment_name IS NULL)
        EXEC [master].[sys].[sp_addextendedproperty] @name = N'Environment Name', @value = N'$(env)'
    ELSE IF (@environment_name <> N'$(env)')
        RAISERROR (N'[*** ERROR ***] SQL Server Instance "%s" is configured for "%s". DBGhost build is configured for "%s".', 11, 1, @@SERVERNAME, @environment_name, N'$(env)')
END
GO
