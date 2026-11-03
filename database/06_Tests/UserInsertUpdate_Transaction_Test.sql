/* Test script: runs inside a transaction and rolls back, so no data is left behind. Run in SSMS against IAL_QC. */
USE IAL_QC;
SET NOCOUNT ON;
BEGIN TRAN;
DECLARE @A INT, @X INT;
EXEC UserInsertUpdate 0,'Suresh K','E1001','suresh','testhash',NULL,NULL,NULL,NULL,'Y','5',1,@A OUTPUT;
DECLARE @C INT = (SELECT COUNT(*) FROM UserMaster); PRINT CONCAT('after insert: trancount=',@@TRANCOUNT,' xact=',XACT_STATE(),' users=',@C);
BEGIN TRY EXEC UserInsertUpdate 0,'Dup','E9999','suresh','testhash',NULL,NULL,NULL,NULL,'Y','5',1,@X OUTPUT; END TRY BEGIN CATCH PRINT '   ERR: '+ERROR_MESSAGE(); END CATCH
PRINT CONCAT('after dup error: trancount=',@@TRANCOUNT,' xact=',XACT_STATE());
IF @@TRANCOUNT > 0 ROLLBACK;
