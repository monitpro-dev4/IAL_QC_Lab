/* =============================================================
   Script   : 008_DocumentApprovalLog.sql
   Module   : Document Management
   Purpose  : Audit trail: every action on every version
              (created, submitted, approved, rejected), with who,
              when, the approval level and comments. Never updated
              or deleted, only added to.
   Depends  : 002_UserMaster.sql, 005_DocumentStatusMaster.sql, 007_DocumentVersion.sql
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.DocumentApprovalLog', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DocumentApprovalLog
    (
        LogID          BIGINT IDENTITY(1,1) NOT NULL,
        VersionID      INT            NOT NULL,
        ActionType     VARCHAR(20)    NOT NULL,
        ApprovalLevel  TINYINT        NULL,
        FromStatusID   TINYINT        NULL,
        ToStatusID     TINYINT        NOT NULL,
        Comments       VARCHAR(1000)  NULL,
        ActionBy       INT            NOT NULL,
        ActionOn       DATETIME       NOT NULL CONSTRAINT DF_DocumentApprovalLog_ActionOn DEFAULT (GETDATE()),
        CONSTRAINT PK_DocumentApprovalLog            PRIMARY KEY (LogID),
        CONSTRAINT CK_DocumentApprovalLog_ActionType CHECK (ActionType IN ('Created','Submitted','Approved','Rejected','Superseded')),
        CONSTRAINT CK_DocumentApprovalLog_Level      CHECK (ApprovalLevel IS NULL OR ApprovalLevel IN (1, 2)),
        CONSTRAINT FK_DocumentApprovalLog_Version    FOREIGN KEY (VersionID)    REFERENCES dbo.DocumentVersion (VersionID),
        CONSTRAINT FK_DocumentApprovalLog_FromStatus FOREIGN KEY (FromStatusID) REFERENCES dbo.DocumentStatusMaster (StatusID),
        CONSTRAINT FK_DocumentApprovalLog_ToStatus   FOREIGN KEY (ToStatusID)   REFERENCES dbo.DocumentStatusMaster (StatusID),
        CONSTRAINT FK_DocumentApprovalLog_ActionBy   FOREIGN KEY (ActionBy)     REFERENCES dbo.UserMaster (UserID)
    );
    CREATE INDEX IX_DocumentApprovalLog_VersionID ON dbo.DocumentApprovalLog (VersionID);
    PRINT 'Table DocumentApprovalLog created.';
END
ELSE
    PRINT 'Table DocumentApprovalLog already exists - nothing changed.';
GO
