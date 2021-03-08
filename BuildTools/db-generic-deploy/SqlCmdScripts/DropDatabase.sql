IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'$(DatabaseName)')
BEGIN
    EXEC BZYDBA.util.usp_KillConnections @db_name = '$(DatabaseName)'

    DROP DATABASE [$(DatabaseName)]
END
GO
