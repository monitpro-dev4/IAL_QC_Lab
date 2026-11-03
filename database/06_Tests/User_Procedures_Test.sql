/* Test script: runs inside a transaction and rolls back, so no data is left behind. Run in SSMS against IAL_QC. */
USE IAL_QC;
SET NOCOUNT ON;
BEGIN TRAN;
DECLARE @A INT, @B INT, @X INT;
PRINT '1) insert two users';
EXEC UserInsertUpdate 0,'Suresh K','E1001','suresh','testhash','suresh@ial.com',NULL,'Chemist',NULL,'Y','5',1,@A OUTPUT;
EXEC UserInsertUpdate 0,'V Senthil Kumar','E1002','vsk','hash123','null',NULL,'Lab Supervisor',NULL,'Y','3, 4',1,@B OUTPUT;
PRINT CONCAT('   ids: ',@A,', ',@B);
PRINT '2) list all';
EXEC UsersGet NULL,0,NULL;
PRINT '3) update suresh: roles 5,2, password kept (NULL)';
EXEC UserInsertUpdate @A,'Suresh Kumar','E1001','suresh',NULL,'suresh@ial.com','9876543210','Senior Chemist',NULL,'Y','5,2',1,@X OUTPUT;
EXEC UserGet @A;
PRINT '4) vsk password kept on update?';
EXEC UserInsertUpdate @B,'V Senthil Kumar','E1002','vsk',NULL,NULL,NULL,'Lab Supervisor',NULL,'Y','3',1,@X OUTPUT;
EXEC UserGetByUserName 'vsk';
PRINT '5) filter role=2, search=sur';
EXEC UsersGet 'sur',2,'Y';
PRINT '6) duplicate username (expect error)';
BEGIN TRY EXEC UserInsertUpdate 0,'Dup','E9999','suresh','testhash',NULL,NULL,NULL,NULL,'Y','5',1,@X OUTPUT; END TRY BEGIN CATCH PRINT '   ERR: '+ERROR_MESSAGE(); END CATCH
PRINT '7) no role (expect error)';
BEGIN TRY EXEC UserInsertUpdate 0,'NoRole','E9998','norole','testhash',NULL,NULL,NULL,NULL,'Y','',1,@X OUTPUT; END TRY BEGIN CATCH PRINT '   ERR: '+ERROR_MESSAGE(); END CATCH
PRINT '8) bad role id 99 (expect error)';
BEGIN TRY EXEC UserInsertUpdate 0,'BadRole','E9997','badrole','testhash',NULL,NULL,NULL,NULL,'Y','5,99',1,@X OUTPUT; END TRY BEGIN CATCH PRINT '   ERR: '+ERROR_MESSAGE(); END CATCH
PRINT '9) deactivate suresh, then login lookup (expect no user row)';
EXEC UserActiveStatusUpdate @A,'N',1;
BEGIN TRY EXEC UserGetByUserName 'suresh'; END TRY BEGIN CATCH PRINT '   ERR: '+ERROR_MESSAGE(); END CATCH
PRINT '10) roles dropdown';
EXEC RoleMasterGet 'Y';
ROLLBACK TRAN;
SELECT UsersLeft = COUNT(*) FROM UserMaster;
SELECT RolesLinksLeft = COUNT(*) FROM UserRoles;
