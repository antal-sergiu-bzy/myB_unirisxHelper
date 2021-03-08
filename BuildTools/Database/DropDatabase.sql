IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'$(DatabaseName)')
    DROP DATABASE $(DatabaseName)
GO
