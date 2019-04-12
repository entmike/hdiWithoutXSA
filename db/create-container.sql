
--Connect in hdbsql - First Tenant
-n hanapm.local.com:30015 -m
--Multiline
\Mu
--Aligned Output
\al

--First/One Time Setup to activate diserver on HANA - Must be done on SYSTEM DB
DO
BEGIN
  DECLARE dbName NVARCHAR(25) = 'HXE'; --<-- substitute XY1 by the name of your tenant DB
  -- Start diserver
  DECLARE diserverCount INT = 0;
  SELECT COUNT(*) INTO diserverCount FROM SYS_DATABASES.M_SERVICES WHERE SERVICE_NAME = 'diserver' AND DATABASE_NAME = :dbName AND ACTIVE_STATUS = 'YES';
  IF diserverCount = 0 THEN
    EXEC 'ALTER DATABASE ' || :dbName || ' ADD ''diserver''';
  END IF;   
  
END;

--One Time Setup - Create HDI_ADMIN User and make SYSTEM and HDI_ADMIN HDI Admins
CREATE USER HDI_ADMIN PASSWORD "HanaRocks01" NO FORCE_FIRST_PASSWORD_CHANGE;
CREATE LOCAL TEMPORARY TABLE #PRIVILEGES LIKE _SYS_DI.TT_API_PRIVILEGES;
INSERT INTO #PRIVILEGES (PRINCIPAL_NAME, PRIVILEGE_NAME, OBJECT_NAME) SELECT 'SYSTEM', PRIVILEGE_NAME, OBJECT_NAME FROM _SYS_DI.T_DEFAULT_DI_ADMIN_PRIVILEGES;
INSERT INTO #PRIVILEGES (PRINCIPAL_NAME, PRIVILEGE_NAME, OBJECT_NAME) SELECT 'HDI_ADMIN', PRIVILEGE_NAME, OBJECT_NAME FROM _SYS_DI.T_DEFAULT_DI_ADMIN_PRIVILEGES;

CALL _SYS_DI.GRANT_CONTAINER_GROUP_API_PRIVILEGES('_SYS_DI', #PRIVILEGES, _SYS_DI.T_NO_PARAMETERS, ?, ?, ?);
DROP TABLE #PRIVILEGES;


--Create Container
CALL _SYS_DI.CREATE_CONTAINER('HDI_WITHOUT_XSA', _SYS_DI.T_NO_PARAMETERS, ?, ?, ?);

--Grant Container Admin to Development User(s)
CREATE LOCAL TEMPORARY COLUMN TABLE #PRIVILEGES LIKE _SYS_DI.TT_API_PRIVILEGES;
INSERT INTO #PRIVILEGES (PRINCIPAL_NAME, PRIVILEGE_NAME, OBJECT_NAME) SELECT 'WORKSHOP_00', PRIVILEGE_NAME, OBJECT_NAME FROM _SYS_DI.T_DEFAULT_CONTAINER_ADMIN_PRIVILEGES;
INSERT INTO #PRIVILEGES (PRINCIPAL_NAME, PRIVILEGE_NAME, OBJECT_NAME) SELECT 'SYSTEM', PRIVILEGE_NAME, OBJECT_NAME FROM _SYS_DI.T_DEFAULT_CONTAINER_ADMIN_PRIVILEGES;
CALL _SYS_DI.GRANT_CONTAINER_API_PRIVILEGES('HDI_WITHOUT_XSA', #PRIVILEGES, _SYS_DI.T_NO_PARAMETERS, ?, ?, ?); 
DROP TABLE #PRIVILEGES;

--Grant Container User to Development User(s)
CREATE LOCAL TEMPORARY COLUMN TABLE #PRIVILEGES LIKE _SYS_DI.TT_SCHEMA_PRIVILEGES;
INSERT INTO #PRIVILEGES ( PRIVILEGE_NAME, PRINCIPAL_SCHEMA_NAME, PRINCIPAL_NAME ) VALUES ( 'SELECT', '', 'WORKSHOP_00' );
INSERT INTO #PRIVILEGES ( PRIVILEGE_NAME, PRINCIPAL_SCHEMA_NAME, PRINCIPAL_NAME ) VALUES ( 'SELECT', '', 'SYSTEM' );
CALL HDI_WITHOUT_XSA#DI.GRANT_CONTAINER_SCHEMA_PRIVILEGES( #PRIVILEGES, _SYS_DI.T_NO_PARAMETERS, ?, ?, ?);
DROP TABLE #PRIVILEGES;

--Configure Default Libraries for Container
CALL HDI_WITHOUT_XSA#DI.CONFIGURE_LIBRARIES(_SYS_DI.T_DEFAULT_LIBRARIES, _SYS_DI.T_NO_PARAMETERS, ?, ?, ?);

-- To Drop
-- CALL _SYS_DI.DROP_CONTAINER('HDI_WITHOUT_XSA', _SYS_DI.T_NO_PARAMETERS, ?, ?, ?);

--CALL HDI_WITHOUT_XSA#DI.LIST_CONFIGURED_LIBRARIES(_SYS_DI.T_NO_PARAMETERS, ?, ?, ?, ?); 

-- Build
npm run start -- --exit