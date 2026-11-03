/* =============================================================
   Change   : 2026-10-14_001
   Table    : Document
   Purpose  : Category is no longer asked for when a document is
              added, so Document.CategoryID now allows NULL.
              The foreign key to DocumentCategory stays: when a
              category is given it must still be a real one.
   Safe to run again: only changes the column while it is NOT NULL.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.Document') AND name = 'CategoryID' AND is_nullable = 0)
BEGIN
    -- The index depends on the column, so drop it, change the column, then put it back
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Document') AND name = 'IX_Document_CategoryID')
        DROP INDEX IX_Document_CategoryID ON dbo.Document;

    ALTER TABLE dbo.Document ALTER COLUMN CategoryID INT NULL;

    CREATE INDEX IX_Document_CategoryID ON dbo.Document (CategoryID);
    PRINT 'Document.CategoryID now allows NULL.';
END
ELSE
    PRINT 'Document.CategoryID already allows NULL - nothing changed.';
GO
