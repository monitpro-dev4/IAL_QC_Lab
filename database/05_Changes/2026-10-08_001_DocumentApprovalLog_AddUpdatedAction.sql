/* =============================================================
   Change   : 2026-10-08_001
   Table    : DocumentApprovalLog
   Purpose  : Allow the action 'Updated' (chemist re-uploads a draft
              or rejected version), so every change is in the audit trail.
   Safe to run again: only changes the rule if 'Updated' is missing.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints
           WHERE name = N'CK_DocumentApprovalLog_ActionType'
             AND definition NOT LIKE '%Updated%')
BEGIN
    ALTER TABLE dbo.DocumentApprovalLog DROP CONSTRAINT CK_DocumentApprovalLog_ActionType;
    ALTER TABLE dbo.DocumentApprovalLog ADD CONSTRAINT CK_DocumentApprovalLog_ActionType
        CHECK (ActionType IN ('Created','Updated','Submitted','Approved','Rejected','Superseded'));
    PRINT 'CK_DocumentApprovalLog_ActionType now allows Updated.';
END
ELSE
    PRINT 'Change already applied - nothing changed.';
GO
