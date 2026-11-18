/* =============================================================
   Change   : 2026-11-11_003
   Table    : Document
   Purpose  : Document.PlantArea (entered when a document is added)
   Safe to run again.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Document', 'PlantArea') IS NULL
BEGIN
    ALTER TABLE dbo.Document ADD PlantArea VARCHAR(100) NULL;
    PRINT 'Document.PlantArea added.';
END
ELSE
    PRINT 'Document.PlantArea already exists - nothing changed.';
GO
