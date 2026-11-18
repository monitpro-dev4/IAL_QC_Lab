/* =============================================================
   Change   : 2026-11-11_004
   Table    : DocumentVersion
   Purpose  : DocumentVersion.ReasonForChange - why a new revision was made
              (entered with the Change summary when a revision is uploaded)
   Safe to run again.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.DocumentVersion', 'ReasonForChange') IS NULL
BEGIN
    ALTER TABLE dbo.DocumentVersion ADD ReasonForChange VARCHAR(500) NULL;
    PRINT 'DocumentVersion.ReasonForChange added.';
END
ELSE
    PRINT 'DocumentVersion.ReasonForChange already exists - nothing changed.';
GO
