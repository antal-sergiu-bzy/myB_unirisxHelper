SET NOCOUNT ON
GO
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

PRINT 'Initialising Database Role Generator Process'

GO 

CREATE SCHEMA BzdAuto

GO

CREATE TABLE BzdAuto.Bzd_RoleControl (OkToContinue BIT);
GO
INSERT INTO BzdAuto.Bzd_RoleControl (OkToContinue) VALUES (1);
GO

CREATE TABLE BzdAuto.Bzd_RoleBaseline
(objectId INT, 
objectName SYSNAME COLLATE DATABASE_DEFAULT, 
objectType CHAR(2) COLLATE DATABASE_DEFAULT,
typeDesc NVARCHAR(256) COLLATE DATABASE_DEFAULT,
schemaId int)

GO




INSERT INTO BzdAuto.Bzd_RoleBaseline (objectId, objectName, objectType, typeDesc, schemaId)
SELECT	o.object_id, 
		ISNULL(tt.name, o.name)	COLLATE DATABASE_DEFAULT, 
		o.type		COLLATE DATABASE_DEFAULT, 
		o.type_desc	COLLATE DATABASE_DEFAULT, 
		ISNULL(tt.schema_id, o.schema_id) as schema_id
FROM sys.Objects o
		
LEFT OUTER JOIN sys.table_types tt
	ON o.object_id = tt.type_table_object_id
WHERE o.type IN ('U','V','IF', 'TT', 'P', 'FN');

GO

DECLARE @count INT;
SELECT @count = COUNT(*) FROM BzdAuto.Bzd_RoleBaseline


PRINT CAST(@count AS VARCHAR) + ' objects prior to schema gen step.'
