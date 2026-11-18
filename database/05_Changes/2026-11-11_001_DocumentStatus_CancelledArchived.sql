/* =============================================================
   Change   : 2026-11-11_001
   Tables   : DocumentStatusMaster, DocumentApprovalLog
   Purpose  : Two new statuses, set by the Lab Manager:
                7 Cancelled - a pending revision (Under Review, Under
                              Approval or Rejected) is stopped; final
                8 Archived  - an approved document is retired from use;
                              it can be restored to Approved
              and the matching log actions Cancelled / Archived / Restored.
   Safe to run again.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

MERGE dbo.DocumentStatusMaster AS t
USING (VALUES
    (7, 'Cancelled', 'Pending revision cancelled by the Lab Manager'),
    (8, 'Archived',  'Approved document retired from use; can be restored')
) AS s (StatusID, StatusName, StatusDesc)
ON t.StatusID = s.StatusID
WHEN NOT MATCHED THEN
    INSERT (StatusID, StatusName, StatusDesc) VALUES (s.StatusID, s.StatusName, s.StatusDesc);
PRINT 'Statuses 7 Cancelled and 8 Archived are in place.';
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints
           WHERE name = N'CK_DocumentApprovalLog_ActionType'
             AND definition NOT LIKE '%Archived%')
BEGIN
    ALTER TABLE dbo.DocumentApprovalLog DROP CONSTRAINT CK_DocumentApprovalLog_ActionType;
    ALTER TABLE dbo.DocumentApprovalLog ADD CONSTRAINT CK_DocumentApprovalLog_ActionType
        CHECK (ActionType IN ('Created','Updated','Submitted','Approved','Rejected','Superseded',
                              'Cancelled','Archived','Restored'));
    PRINT 'CK_DocumentApprovalLog_ActionType now allows Cancelled, Archived and Restored.';
END
ELSE
    PRINT 'Log actions already allowed - nothing changed.';
GO
