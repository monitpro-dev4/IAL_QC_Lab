/* =============================================================
   Script   : 005_DocumentStatusMaster.sql
   Module   : Document Management
   Purpose  : Fixed list of version statuses used by the workflow.
              The status IDs are referenced in the stored procedures,
              so the rows are part of this table's definition and
              must not be edited from the application.

   Workflow : 1 Draft -> 2 Submitted -> 3 Supervisor Approved -> 4 Approved
              Rejected at level 1 or 2 -> 5 Rejected (chemist revises)
              When a new version is approved, the old one -> 6 Superseded
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.DocumentStatusMaster', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DocumentStatusMaster
    (
        StatusID    TINYINT      NOT NULL,
        StatusName  VARCHAR(50)  NOT NULL,
        StatusDesc  VARCHAR(250) NULL,
        CONSTRAINT PK_DocumentStatusMaster      PRIMARY KEY (StatusID),
        CONSTRAINT UQ_DocumentStatusMaster_Name UNIQUE (StatusName)
    );
    PRINT 'Table DocumentStatusMaster created.';
END
ELSE
    PRINT 'Table DocumentStatusMaster already exists.';
GO

-- Reference rows (added only if missing)
MERGE dbo.DocumentStatusMaster AS t
USING (VALUES
    (1, 'Draft',               'Saved by the chemist, not yet submitted'),
    (2, 'Submitted',           'Waiting for Lab Supervisor approval (level 1)'),
    (3, 'Supervisor Approved', 'Waiting for Lab Manager approval (level 2)'),
    (4, 'Approved',            'Current approved version, visible to all users'),
    (5, 'Rejected',            'Sent back to the chemist for changes'),
    (6, 'Superseded',          'Older version, kept in history'),
    (7, 'Cancelled',           'Pending revision cancelled by the Lab Manager'),
    (8, 'Archived',            'Approved document retired from use; can be restored')
) AS s (StatusID, StatusName, StatusDesc)
ON t.StatusID = s.StatusID
WHEN NOT MATCHED THEN
    INSERT (StatusID, StatusName, StatusDesc) VALUES (s.StatusID, s.StatusName, s.StatusDesc);
GO
