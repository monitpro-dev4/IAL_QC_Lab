/* =============================================================
   Script   : 004_DocumentCategory.sql
   Module   : Document Management
   Purpose  : Document types (SOP, ISO document, work instruction...)
              CategoryCode is used in document numbers, e.g. IAL-SOP-123
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.DocumentCategory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DocumentCategory
    (
        CategoryID    INT IDENTITY(1,1) NOT NULL,
        CategoryCode  VARCHAR(10)  NOT NULL,
        CategoryName  VARCHAR(100) NOT NULL,
        CategoryDesc  VARCHAR(250) NULL,
        IsActive      CHAR(1)      NOT NULL CONSTRAINT DF_DocumentCategory_IsActive  DEFAULT ('Y'),
        CreatedBy     INT          NULL,
        CreatedOn     DATETIME     NOT NULL CONSTRAINT DF_DocumentCategory_CreatedOn DEFAULT (GETDATE()),
        ModifiedBy    INT          NULL,
        ModifiedOn    DATETIME     NULL,
        CONSTRAINT PK_DocumentCategory          PRIMARY KEY (CategoryID),
        CONSTRAINT UQ_DocumentCategory_Code     UNIQUE (CategoryCode),
        CONSTRAINT UQ_DocumentCategory_Name     UNIQUE (CategoryName),
        CONSTRAINT CK_DocumentCategory_IsActive CHECK (IsActive IN ('Y','N'))
    );
    PRINT 'Table DocumentCategory created.';
END
ELSE
    PRINT 'Table DocumentCategory already exists - nothing changed.';
GO
