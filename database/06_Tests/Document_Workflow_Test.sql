/* Test script: full Document Management workflow, end to end.
   Runs inside a transaction and rolls back, so no data is left behind.
   Run in SSMS against IAL_QC (Results to Text is easiest to read). */
USE IAL_QC;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
BEGIN TRAN;

DECLARE @C INT, @S INT, @M INT, @E INT, @A INT, @X INT, @D INT, @V1 INT, @V2 INT, @D2 INT, @V3 INT, @D3 INT, @V4 INT;
DECLARE @chk VARCHAR(200);
EXEC UserInsertUpdate 0,'Test Chemist','T01','t_chem','testhash',NULL,NULL,NULL,NULL,'Y','5',1,@C OUTPUT;
EXEC UserInsertUpdate 0,'Test Supervisor','T02','t_sup','testhash',NULL,NULL,NULL,NULL,'Y','3',1,@S OUTPUT;
EXEC UserInsertUpdate 0,'Test Manager','T03','t_mgr','testhash',NULL,NULL,NULL,NULL,'Y','2',1,@M OUTPUT;
EXEC UserInsertUpdate 0,'Test Employee','T04','t_emp','testhash',NULL,NULL,NULL,NULL,'Y','6',1,@E OUTPUT;
EXEC UserInsertUpdate 0,'Test Admin','T05','t_adm','testhash',NULL,NULL,NULL,NULL,'Y','1',1,@A OUTPUT;

PRINT '--- Create';
BEGIN TRY EXEC DocumentCreate 'IAL-SOP-123','Inst Calibration',1,1,'a.docx','a1.docx','D:\Files',NULL,10,NULL,@E,@D OUTPUT,@V1 OUTPUT; PRINT 'FAIL 01'; END TRY BEGIN CATCH PRINT '01 employee cannot create      -> ' + ERROR_MESSAGE(); END CATCH
EXEC DocumentCreate 'ial-sop-123 ','Inst Calibration',1,1,'Inst Calibration.docx','a1.docx','D:\Files',NULL,10,'First issue',@C,@D OUTPUT,@V1 OUTPUT;
SELECT @chk = CONCAT(d.DocumentNumber,' rev ',v.RevisionNo,' status ',v.StatusID,' type ',v.FileType) FROM Document d JOIN DocumentVersion v ON v.VersionID=@V1 WHERE d.DocumentID=@D;
PRINT '02 chemist creates             -> ' + @chk;
BEGIN TRY EXEC DocumentCreate 'IAL-SOP-123','Dup',1,1,'b.docx','b.docx','D:\Files',NULL,10,NULL,@C,@X OUTPUT,@X OUTPUT; PRINT 'FAIL 03'; END TRY BEGIN CATCH PRINT '03 duplicate number            -> ' + ERROR_MESSAGE(); END CATCH
SELECT @chk = CONCAT('approved-only rows=', (SELECT COUNT(*) FROM Document WHERE CurrentVersionID IS NOT NULL)); PRINT '04 not in approved list yet    -> ' + @chk;

PRINT '--- Submit and level 1';
BEGIN TRY EXEC DocumentVersionApprove @V1,'Approved',NULL,@S; PRINT 'FAIL 05'; END TRY BEGIN CATCH PRINT '05 approve a draft             -> ' + ERROR_MESSAGE(); END CATCH
EXEC DocumentVersionSubmit @V1,NULL,@C;
BEGIN TRY EXEC DocumentVersionSubmit @V1,NULL,@C; PRINT 'FAIL 06'; END TRY BEGIN CATCH PRINT '06 submit twice                -> ' + ERROR_MESSAGE(); END CATCH
CREATE TABLE #p (VersionID INT, DocumentID INT, DocumentNumber VARCHAR(50), Title VARCHAR(200), CategoryName VARCHAR(100), RevisionNo INT, StatusName VARCHAR(50), ApprovalLevel INT, OriginalFileName VARCHAR(255), StoredFileName VARCHAR(255), FilePath VARCHAR(500), FileType VARCHAR(10), ChangeSummary VARCHAR(500), EditedBy VARCHAR(100), SubmittedOn DATETIME, ReviewedBy VARCHAR(100), ReviewedOn DATETIME);
INSERT INTO #p EXEC DocumentPendingApprovals @S; SELECT @chk = CONCAT('supervisor sees ',COUNT(*),' (level ',MAX(ApprovalLevel),')') FROM #p; DELETE #p;
INSERT INTO #p EXEC DocumentPendingApprovals @M; SELECT @chk = @chk + CONCAT(', manager sees ',COUNT(*)) FROM #p; DELETE #p;
PRINT '07 pending lists               -> ' + @chk;
BEGIN TRY EXEC DocumentVersionApprove @V1,'Approved',NULL,@M; PRINT 'FAIL 08'; END TRY BEGIN CATCH PRINT '08 manager at level 1          -> ' + ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC DocumentVersionApprove @V1,'Rejected',NULL,@S; PRINT 'FAIL 09'; END TRY BEGIN CATCH PRINT '09 reject without comments     -> ' + ERROR_MESSAGE(); END CATCH
EXEC DocumentVersionApprove @V1,'Rejected','Section 4 is missing',@S;
SELECT @chk = CONCAT('status ',StatusID) FROM DocumentVersion WHERE VersionID=@V1; PRINT '10 supervisor rejects          -> ' + @chk;

PRINT '--- Revise after rejection';
SAVE TRAN t11;
EXEC DocumentVersionCreate @D,'c.docx','c.docx','D:\Files',NULL,10,NULL,@C,@X OUTPUT;
SELECT @chk = CONCAT('rejected rev now status ',(SELECT StatusID FROM DocumentVersion WHERE VersionID=@V1),', new rev ',(SELECT RevisionNo FROM DocumentVersion WHERE VersionID=@X),' status ',(SELECT StatusID FROM DocumentVersion WHERE VersionID=@X)); PRINT '11 new revision while rejected -> ' + @chk;
ROLLBACK TRAN t11;
EXEC DocumentVersionUpdate @V1,NULL,'Inst Calibration v2.pdf','a2.pdf','D:\Files',NULL,12,'Added section 4',@C;
SELECT @chk = CONCAT('status ',StatusID,' file ',OriginalFileName,' type ',FileType,' reviewedBy ',ISNULL(CAST(ReviewedBy AS VARCHAR),'cleared')) FROM DocumentVersion WHERE VersionID=@V1; PRINT '12 chemist re-uploads          -> ' + @chk;
EXEC DocumentVersionSubmit @V1,NULL,@C;
EXEC DocumentVersionApprove @V1,'Approved','OK',@S;
SELECT @chk = CONCAT('status ',StatusID) FROM DocumentVersion WHERE VersionID=@V1; PRINT '13 supervisor approves         -> ' + @chk;
BEGIN TRY EXEC DocumentVersionApprove @V1,'Approved',NULL,@S; PRINT 'FAIL 14'; END TRY BEGIN CATCH PRINT '14 supervisor at level 2       -> ' + ERROR_MESSAGE(); END CATCH
EXEC DocumentVersionApprove @V1,'Approved','Approved for issue',@M;
SELECT @chk = CONCAT('status ',v.StatusID,', current=',IIF(d.CurrentVersionID=@V1,'yes','no'),', issued ',v.IssuedDate) FROM DocumentVersion v JOIN Document d ON d.DocumentID=v.DocumentID WHERE v.VersionID=@V1; PRINT '15 manager approves            -> ' + @chk;

PRINT '--- Revision 2 replaces revision 1';
EXEC DocumentVersionCreate @D,'Inst Calibration r2.docx','a3.docx','D:\Files',NULL,15,'Updated limits',@C,@V2 OUTPUT;
SELECT @chk = CONCAT('rev ',RevisionNo,' status ',StatusID) FROM DocumentVersion WHERE VersionID=@V2; PRINT '16 new revision (auto number)  -> ' + @chk;
SAVE TRAN t17;
EXEC DocumentVersionCreate @D,'x.docx','x.docx','D:\Files',NULL,1,NULL,@C,@X OUTPUT;
SELECT @chk = CONCAT('rev 2 now status ',(SELECT StatusID FROM DocumentVersion WHERE VersionID=@V2),', rev ',(SELECT RevisionNo FROM DocumentVersion WHERE VersionID=@X),' status ',(SELECT StatusID FROM DocumentVersion WHERE VersionID=@X)); PRINT '17 second revision while waiting -> ' + @chk;
ROLLBACK TRAN t17;
CREATE TABLE #l (DocumentID INT, DocumentNumber VARCHAR(50), Title VARCHAR(200), CategoryID INT, CategoryCode VARCHAR(10), CategoryName VARCHAR(100), IsActive CHAR(1), VersionID INT, RevisionNo INT, VersionStatus VARCHAR(50), OriginalFileName VARCHAR(255), StoredFileName VARCHAR(255), FilePath VARCHAR(500), FileType VARCHAR(10), FileSizeKB INT, EditedBy VARCHAR(100), ReviewedBy VARCHAR(100), ApprovedBy VARCHAR(100), IssuedDate DATE, PendingVersionID INT, PendingRevisionNo INT, PendingStatus VARCHAR(50));
INSERT INTO #l EXEC DocumentList NULL,0,1,'Y';
SELECT @chk = CONCAT(DocumentNumber,' shows rev ',RevisionNo,' ',VersionStatus,', pending rev ',PendingRevisionNo,' ',PendingStatus) FROM #l; DELETE #l;
PRINT '18 list while rev 2 is draft   -> ' + @chk;
EXEC DocumentVersionSubmit @V2,NULL,@C;
EXEC DocumentVersionApprove @V2,'Approved',NULL,@S;
EXEC DocumentVersionApprove @V2,'Approved',NULL,@M;
SELECT @chk = CONCAT('rev1 status ',(SELECT StatusID FROM DocumentVersion WHERE VersionID=@V1),', rev2 status ',(SELECT StatusID FROM DocumentVersion WHERE VersionID=@V2),', current=rev ',(SELECT v.RevisionNo FROM Document d JOIN DocumentVersion v ON v.VersionID=d.CurrentVersionID WHERE d.DocumentID=@D)); PRINT '19 rev 2 approved              -> ' + @chk;
INSERT INTO #l EXEC DocumentList 'calib',1,1,'Y';
SELECT @chk = CONCAT(COUNT(*),' row, rev ',MAX(RevisionNo),', approved by ',MAX(ApprovedBy),', pending ',ISNULL(MAX(PendingStatus),'none')) FROM #l; DELETE #l;
PRINT '20 search list                 -> ' + @chk;
SELECT @chk = CONCAT((SELECT COUNT(*) FROM DocumentVersion WHERE DocumentID=@D),' revisions, ',(SELECT COUNT(*) FROM DocumentApprovalLog l JOIN DocumentVersion v ON v.VersionID=l.VersionID WHERE v.DocumentID=@D),' log rows'); PRINT '21 history                     -> ' + @chk;

PRINT '--- Other rules';
EXEC DocumentCreate 'IAL-SOP-200','Supervisor SOP',1,1,'s.docx','s.docx','D:\Files',NULL,5,NULL,@S,@D2 OUTPUT,@V3 OUTPUT;
EXEC DocumentVersionSubmit @V3,NULL,@S;
INSERT INTO #p EXEC DocumentPendingApprovals @S; SELECT @chk = CAST(COUNT(*) AS VARCHAR(10)) FROM #p WHERE VersionID=@V3; DELETE #p;
PRINT '23 own revision in my list     -> rows ' + @chk;
SAVE TRAN t22;
EXEC DocumentVersionApprove @V3,'Approved',NULL,@S;
SELECT @chk = CONCAT('status ',StatusID) FROM DocumentVersion WHERE VersionID=@V3; PRINT '22 supervisor approves own     -> ' + @chk;
ROLLBACK TRAN t22;
BEGIN TRY EXEC DocumentActiveStatusUpdate @D,'N',@C; PRINT 'FAIL 24'; END TRY BEGIN CATCH PRINT '24 chemist makes obsolete      -> ' + ERROR_MESSAGE(); END CATCH
EXEC DocumentActiveStatusUpdate @D,'N',@M;
BEGIN TRY EXEC DocumentVersionCreate @D,'y.docx','y.docx','D:\Files',NULL,1,NULL,@C,@X OUTPUT; PRINT 'FAIL 25'; END TRY BEGIN CATCH PRINT '25 revise obsolete document    -> ' + ERROR_MESSAGE(); END CATCH
INSERT INTO #l EXEC DocumentList NULL,0,1,'Y'; SELECT @chk = CAST(COUNT(*) AS VARCHAR(10)) FROM #l WHERE DocumentID=@D; DELETE #l;
PRINT '26 obsolete hidden from list   -> rows ' + @chk;
EXEC DocumentCreate 'IAL-SOP-126','PIBSA Analysis',1,22,'PIBSA.docx','p.docx','D:\Files',NULL,40,'Loaded existing ISO document',@C,@D3 OUTPUT,@V4 OUTPUT;
SELECT @chk = CONCAT('rev ',RevisionNo) FROM DocumentVersion WHERE VersionID=@V4; PRINT '27 load existing doc at rev 22 -> ' + @chk;
BEGIN TRY EXEC DocumentVersionApprove @V4,'Maybe',NULL,@S; PRINT 'FAIL 28'; END TRY BEGIN CATCH PRINT '28 invalid action             -> ' + ERROR_MESSAGE(); END CATCH

PRINT '--- History detail for IAL-SOP-123';
EXEC DocumentHistory @D;

ROLLBACK TRAN;
DROP TABLE IF EXISTS #p; DROP TABLE IF EXISTS #l;
SELECT LeftOver_Documents = (SELECT COUNT(*) FROM Document), LeftOver_Versions = (SELECT COUNT(*) FROM DocumentVersion), LeftOver_Users = (SELECT COUNT(*) FROM UserMaster);
