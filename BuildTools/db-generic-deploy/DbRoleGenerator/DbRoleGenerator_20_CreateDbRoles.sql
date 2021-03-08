SET NOCOUNT ON
GO

DECLARE @IsComponentASchema BIT = '$(isComponentASchema)'

IF EXISTS (SELECT * FROM BzdAuto.Bzd_RoleControl WHERE OkToContinue = 0)
	BEGIN
		PRINT 'Role Generator step 20 (Create Roles) detects a prior failure, and will be skipped';
	END
ELSE
BEGIN
	PRINT 'Role Generator step 20  - Create Roles in Model Database';
	BEGIN TRY

		DECLARE @processStep NVARCHAR(MAX) = 'Prepping Role Creation';

		DECLARE @newObjects TABLE (objectId INT,
					objectName SYSNAME COLLATE DATABASE_DEFAULT,
					objectType CHAR(2) COLLATE DATABASE_DEFAULT,
					typeDesc NVARCHAR(256) COLLATE DATABASE_DEFAULT,
					schemaId int);

		INSERT INTO @newObjects (objectId, objectName, objectType, typeDesc, schemaId)
		SELECT	o.object_id,
				ISNULL(tt.name, o.name)	COLLATE DATABASE_DEFAULT,
				o.type		COLLATE DATABASE_DEFAULT,
				o.type_desc	COLLATE DATABASE_DEFAULT,
				ISNULL(tt.schema_id, o.schema_id) as schema_id
		FROM sys.Objects o

		LEFT OUTER JOIN sys.table_types tt
			ON o.object_id = tt.type_table_object_id
		WHERE o.type IN ('U','V','IF', 'TT', 'P', 'FN')
		EXCEPT
		SELECT	objectId,
				objectName	COLLATE DATABASE_DEFAULT,
				objectType	COLLATE DATABASE_DEFAULT,
				typeDesc	COLLATE DATABASE_DEFAULT,
				schemaId
		FROM BzdAuto.Bzd_RoleBaseline;


		DECLARE @count INT;
		SELECT @count = COUNT(*) FROM @newObjects


		PRINT CAST(@count AS VARCHAR) + ' new objects after schema gen step.'


		SET @processStep = 'Create $(componentName)_Reader, $(componentName)_Upserter, and $(componentName)_Deleter roles';

		CREATE ROLE [$(componentName)_Reader];
		CREATE ROLE [$(componentName)_Upserter];
		CREATE ROLE [$(componentName)_Deleter];
		CREATE ROLE [$(componentName)_Execer];
		CREATE ROLE [$(componentName)_DefinitionViewer];
		CREATE ROLE [$(componentName)_Creator];

		DECLARE @grantReadWriteTemplate NVARCHAR(MAX)  = 'GRANT SELECT ON {0} TO [$(componentName)_Reader];
		GRANT INSERT, UPDATE ON {0} TO [$(componentName)_Upserter];
		GRANT DELETE ON {0} TO [$(componentName)_Deleter];'

		DECLARE @grantExecToReaderTemplate NVARCHAR(MAX) = 'GRANT EXECUTE ON TYPE::{0} TO [$(componentName)_Reader];'

		DECLARE @grantExecTemplate NVARCHAR(MAX)= 'GRANT EXEC ON {0} TO [$(componentName)_Execer];'

		/*******************
		grant view def for everything - (means view def is not component specific any more) but otherwise have to worry about a whole bunch of object types..including full text catalogs!
		*******************/
		DECLARE @grantViewDefinitionTemplateAll NVARCHAR(MAX) = 'GRANT VIEW DEFINITION TO [$(componentName)_DefinitionViewer];';
		PRINT @grantViewDefinitionTemplateAll;
		EXEC sp_ExecuteSql @grantViewDefinitionTemplateAll;



		/***********************************************************************************************************

		Go ahead and do all the GRANT statements

		***********************************************************************************************************/
		SET @processStep = 'Granting appropriate permissions to $(componentName)_Reader, $(componentName)_Upserter, and $(componentName)_Deleter roles';
		DECLARE @createStatement NVARCHAR(MAX);

		IF @IsComponentASchema = 1
		BEGIN
			DECLARE @SchemaDefinition NVARCHAR(MAX) = 'SCHEMA::[$(componentName)]';

			--read/write
			SET @createStatement = REPLACE(@grantReadWriteTemplate, '{0}', @SchemaDefinition);
			PRINT @createStatement;
			EXEC sp_ExecuteSql @createStatement;

			-- No idea how to grant exec perms to all table types in a schema, fix if needed
			--exec
			SET @createStatement = REPLACE(@grantExecTemplate, '{0}', @SchemaDefinition);
			PRINT @createStatement;
			EXEC sp_ExecuteSql @createStatement;

			--creator
			--users need create table on db and alter on schema to create a schema table
			DECLARE @grantCreatorTemplate NVARCHAR(MAX) = 'GRANT DELETE, ALTER ON {0} TO [$(componentName)_Creator];
									GRANT CREATE TABLE TO [$(componentName)_Creator]'

			SET @createStatement = REPLACE(@grantCreatorTemplate, '{0}', @SchemaDefinition);
			PRINT @createStatement;
			EXEC sp_ExecuteSql @createStatement;
		END;
		ELSE
		BEGIN
			DECLARE CreateReadWriteCursor  CURSOR STATIC LOCAL FORWARD_ONLY FOR
			SELECT CASE WHEN objectType IN ('U','V','IF')
				THEN REPLACE(@grantReadWriteTemplate, '{0}', '[' + SCHEMA_NAME(schemaId)  + '].[' + objectName + ']')

				WHEN objectType IN ('TT')
				THEN REPLACE(@grantExecToReaderTemplate, '{0}', '[' + SCHEMA_NAME(schemaId)  + '].[' + objectName + ']')

				ELSE REPLACE(@grantExecTemplate, '{0}', '[' + SCHEMA_NAME(schemaId)  + '].[' + objectName + ']')
			END

			FROM @newObjects

			OPEN CreateReadWriteCursor;
			FETCH NEXT FROM CreateReadWriteCursor INTO @createStatement;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @processStep = @createStatement;

				PRINT @createStatement;

				EXEC sp_ExecuteSql @createStatement;
				FETCH NEXT FROM CreateReadWriteCursor INTO @createStatement;
			END
			CLOSE CreateReadWriteCursor;
			DEALLOCATE CreateReadWriteCursor;
    	END;


		/***********************************************************************************************************/

		PRINT 'Role Generator step 20 (Create Roles) succeeded'

	END TRY
	BEGIN CATCH

	    UPDATE BzdAuto.Bzd_RoleControl SET OkToContinue = 0;

		DECLARE @ErMessage NVARCHAR(2048) =
'Failure of Role Generator step 20 (Create Roles)
Last process step:
'+ @processStep +'
Error message:
' + ERROR_MESSAGE(),
                @ErSeverity INT = ERROR_SEVERITY(),
		        @ErState INT = ERROR_STATE()

		PRINT @ErMessage

		RAISERROR (@ErMessage,
				   @ErSeverity,
				   @ErState)
	END CATCH


	PRINT 'DB Role Generation - Cleaning Up'

	EXEC('DROP TABLE BzdAuto.Bzd_RoleControl');

	EXEC('DROP TABLE BzdAuto.Bzd_RoleBaseline');

	EXEC('DROP SCHEMA BzdAuto');

	PRINT 'DB Role Generation - Complete'


END
