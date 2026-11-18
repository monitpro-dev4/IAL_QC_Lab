/* =============================================================
   Change   : 2026-11-17_002
   Tables   : Document, DocumentVersion
   Purpose  : Document.Remarks - remarks entered when a document is added.
              (Until now they were saved as revision 1's change summary;
              "Change summary" is now only for uploaded revisions.)
              Existing documents: revision 1's change summary is moved
              into Document.Remarks.
   Safe to run again.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Document', 'Remarks') IS NULL
BEGIN
    ALTER TABLE dbo.Document ADD Remarks VARCHAR(500) NULL;
    PRINT 'Document.Remarks added.';
END
GO

-- Move revision 1's text into the document's remarks (only where remarks are still empty)
UPDATE d SET Remarks = v.ChangeSummary, ModifiedOn = GETDATE()
FROM dbo.Document d
JOIN dbo.DocumentVersion v ON v.DocumentID = d.DocumentID AND v.RevisionNo = (SELECT MIN(RevisionNo) FROM dbo.DocumentVersion WHERE DocumentID = d.DocumentID)
WHERE d.Remarks IS NULL AND NULLIF(LTRIM(RTRIM(v.ChangeSummary)), '') IS NOT NULL;
PRINT CONCAT(@@ROWCOUNT, ' document(s) got their remarks from revision 1.');

UPDATE v SET ChangeSummary = NULL
FROM dbo.DocumentVersion v
JOIN dbo.Document d ON d.DocumentID = v.DocumentID
WHERE v.RevisionNo = (SELECT MIN(RevisionNo) FROM dbo.DocumentVersion WHERE DocumentID = v.DocumentID)
  AND v.ChangeSummary = d.Remarks;
PRINT CONCAT(@@ROWCOUNT, ' first revision(s) no longer repeat the remarks as a change summary.');
GO
