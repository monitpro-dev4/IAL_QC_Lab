/* =============================================================
   Script   : 007_DocumentVersion.sql
   Module   : Document Management
   Purpose  : Every revision of a document: the file, its status,
              and who edited, reviewed (level 1) and approved (level 2).
   Rules    : - Revision numbers are unique per document
              - Only ONE Approved version per document
              - Only ONE version in progress (Draft / Submitted /
                Supervisor Approved) per document
   Files    : The file itself is stored in a server folder;
              only its path is saved here.
   Depends  : 002_UserMaster.sql, 005_DocumentStatusMaster.sql, 006_Document.sql
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.DocumentVersion', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DocumentVersion
    (
        VersionID         INT IDENTITY(1,1) NOT NULL,
        DocumentID        INT           NOT NULL,
        RevisionNo        INT           NOT NULL,
        OriginalFileName  VARCHAR(255)  NOT NULL,
        StoredFileName    VARCHAR(255)  NOT NULL,
        FilePath          VARCHAR(500)  NOT NULL,
        FileType          VARCHAR(10)   NULL,
        FileSizeKB        INT           NULL,
        ChangeSummary     VARCHAR(500)  NULL,
        StatusID          TINYINT       NOT NULL CONSTRAINT DF_DocumentVersion_StatusID  DEFAULT (1),
        EditedBy          INT           NOT NULL,
        SubmittedOn       DATETIME      NULL,
        ReviewedBy        INT           NULL,
        ReviewedOn        DATETIME      NULL,
        ApprovedBy        INT           NULL,
        ApprovedOn        DATETIME      NULL,
        IssuedDate        DATE          NULL,
        CreatedBy         INT           NULL,
        CreatedOn         DATETIME      NOT NULL CONSTRAINT DF_DocumentVersion_CreatedOn DEFAULT (GETDATE()),
        ModifiedBy        INT           NULL,
        ModifiedOn        DATETIME      NULL,
        CONSTRAINT PK_DocumentVersion               PRIMARY KEY (VersionID),
        CONSTRAINT UQ_DocumentVersion_DocRevision   UNIQUE (DocumentID, RevisionNo),
        CONSTRAINT CK_DocumentVersion_RevisionNo    CHECK (RevisionNo >= 0),
        CONSTRAINT FK_DocumentVersion_Document      FOREIGN KEY (DocumentID) REFERENCES dbo.Document (DocumentID),
        CONSTRAINT FK_DocumentVersion_Status        FOREIGN KEY (StatusID)   REFERENCES dbo.DocumentStatusMaster (StatusID),
        CONSTRAINT FK_DocumentVersion_EditedBy      FOREIGN KEY (EditedBy)   REFERENCES dbo.UserMaster (UserID),
        CONSTRAINT FK_DocumentVersion_ReviewedBy    FOREIGN KEY (ReviewedBy) REFERENCES dbo.UserMaster (UserID),
        CONSTRAINT FK_DocumentVersion_ApprovedBy    FOREIGN KEY (ApprovedBy) REFERENCES dbo.UserMaster (UserID)
    );

    CREATE INDEX IX_DocumentVersion_StatusID ON dbo.DocumentVersion (StatusID) INCLUDE (DocumentID);

    -- One Approved version per document
    CREATE UNIQUE INDEX UX_DocumentVersion_OneApproved
        ON dbo.DocumentVersion (DocumentID) WHERE StatusID = 4;

    -- One version in progress per document
    CREATE UNIQUE INDEX UX_DocumentVersion_OneInProgress
        ON dbo.DocumentVersion (DocumentID) WHERE StatusID IN (1, 2, 3);

    PRINT 'Table DocumentVersion created.';
END
ELSE
    PRINT 'Table DocumentVersion already exists - nothing changed.';
GO

-- Document.CurrentVersionID -> DocumentVersion (added here because
-- DocumentVersion is created after Document)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Document_CurrentVersion')
BEGIN
    ALTER TABLE dbo.Document
        ADD CONSTRAINT FK_Document_CurrentVersion
        FOREIGN KEY (CurrentVersionID) REFERENCES dbo.DocumentVersion (VersionID);
    PRINT 'Foreign key FK_Document_CurrentVersion added.';
END
GO
