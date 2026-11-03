/* =============================================================
   Script   : 006_Document.sql
   Module   : Document Management
   Purpose  : One row per controlled document (e.g. IAL-SOP-123).
              The file and approval details live in DocumentVersion;
              CurrentVersionID points at the latest Approved version
              (its foreign key is added in 007_DocumentVersion.sql).
   Depends  : 004_DocumentCategory.sql
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Document', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Document
    (
        DocumentID        INT IDENTITY(1,1) NOT NULL,
        DocumentNumber    VARCHAR(50)  NOT NULL,
        Title             VARCHAR(200) NOT NULL,
        CategoryID        INT          NULL,      -- optional (2026-10-14_001)
        CurrentVersionID  INT          NULL,
        IsActive          CHAR(1)      NOT NULL CONSTRAINT DF_Document_IsActive  DEFAULT ('Y'),
        CreatedBy         INT          NULL,
        CreatedOn         DATETIME     NOT NULL CONSTRAINT DF_Document_CreatedOn DEFAULT (GETDATE()),
        ModifiedBy        INT          NULL,
        ModifiedOn        DATETIME     NULL,
        CONSTRAINT PK_Document                  PRIMARY KEY (DocumentID),
        CONSTRAINT UQ_Document_DocumentNumber   UNIQUE (DocumentNumber),
        CONSTRAINT CK_Document_IsActive         CHECK (IsActive IN ('Y','N')),
        CONSTRAINT FK_Document_DocumentCategory FOREIGN KEY (CategoryID) REFERENCES dbo.DocumentCategory (CategoryID)
    );
    CREATE INDEX IX_Document_CategoryID ON dbo.Document (CategoryID);
    PRINT 'Table Document created.';
END
ELSE
    PRINT 'Table Document already exists - nothing changed.';
GO
