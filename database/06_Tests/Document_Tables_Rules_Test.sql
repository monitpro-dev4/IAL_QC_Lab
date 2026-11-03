/* Test script: checks the Document Management table rules.
   Runs inside a transaction and rolls back, so no data is left behind.
   Uses direct INSERTs on purpose, to prove the database itself blocks bad data. */
USE IAL_QC;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
BEGIN TRAN;
DECLARE @U INT, @D INT, @V1 INT, @V2 INT;
EXEC UserInsertUpdate 0,'Test Chemist','T0001','testchem','testhash',NULL,NULL,NULL,NULL,'Y','5',1,@U OUTPUT;
INSERT INTO Document (DocumentNumber, Title, CategoryID) VALUES ('IAL-SOP-123','Inst Calibration',(SELECT CategoryID FROM DocumentCategory WHERE CategoryCode='SOP'));
SET @D = SCOPE_IDENTITY();
INSERT INTO DocumentVersion (DocumentID,RevisionNo,OriginalFileName,StoredFileName,FilePath,EditedBy,StatusID) VALUES (@D,1,'a.docx','a1.docx','\\docs',@U,4);
SET @V1 = SCOPE_IDENTITY();
UPDATE Document SET CurrentVersionID = @V1 WHERE DocumentID = @D;
PRINT '1) document + approved revision 1 saved';
BEGIN TRY INSERT INTO Document (DocumentNumber, Title, CategoryID) VALUES ('IAL-SOP-123','Dup',1); PRINT '   FAIL: duplicate number allowed'; END TRY BEGIN CATCH PRINT '2) duplicate document number blocked'; END CATCH
BEGIN TRY INSERT INTO DocumentVersion (DocumentID,RevisionNo,OriginalFileName,StoredFileName,FilePath,EditedBy,StatusID) VALUES (@D,1,'b','b','x',@U,1); PRINT '   FAIL'; END TRY BEGIN CATCH PRINT '3) duplicate revision number blocked'; END CATCH
BEGIN TRY INSERT INTO DocumentVersion (DocumentID,RevisionNo,OriginalFileName,StoredFileName,FilePath,EditedBy,StatusID) VALUES (@D,2,'b','b','x',@U,4); PRINT '   FAIL'; END TRY BEGIN CATCH PRINT '4) second Approved version blocked'; END CATCH
INSERT INTO DocumentVersion (DocumentID,RevisionNo,OriginalFileName,StoredFileName,FilePath,EditedBy,StatusID) VALUES (@D,2,'b','b2','x',@U,1);
SET @V2 = SCOPE_IDENTITY();
PRINT '5) draft revision 2 allowed next to approved revision 1';
BEGIN TRY INSERT INTO DocumentVersion (DocumentID,RevisionNo,OriginalFileName,StoredFileName,FilePath,EditedBy,StatusID) VALUES (@D,3,'c','c','x',@U,2); PRINT '   FAIL'; END TRY BEGIN CATCH PRINT '6) second in-progress version blocked'; END CATCH
BEGIN TRY INSERT INTO DocumentVersion (DocumentID,RevisionNo,OriginalFileName,StoredFileName,FilePath,EditedBy,StatusID) VALUES (@D,3,'c','c','x',9999,5); PRINT '   FAIL'; END TRY BEGIN CATCH PRINT '7) unknown user blocked'; END CATCH
BEGIN TRY INSERT INTO DocumentApprovalLog (VersionID,ActionType,ToStatusID,ActionBy) VALUES (@V2,'Deleted',1,@U); PRINT '   FAIL'; END TRY BEGIN CATCH PRINT '8) invalid log action blocked'; END CATCH
INSERT INTO DocumentApprovalLog (VersionID,ActionType,ApprovalLevel,FromStatusID,ToStatusID,ActionBy,Comments) VALUES (@V2,'Submitted',NULL,1,2,@U,'ok');
PRINT '9) valid log row saved';
ROLLBACK TRAN;
SELECT Documents=COUNT(*) FROM Document; SELECT Versions=COUNT(*) FROM DocumentVersion; SELECT Users=COUNT(*) FROM UserMaster;
