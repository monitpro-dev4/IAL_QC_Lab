/* =============================================================
   Procedure : DocumentVersionGetFile
   Module    : Document Management
   Purpose   : File details of one revision, used by the backend
               to serve the file for download / viewing.
               FilePath is relative to the configured document root.
   Example   : EXEC DocumentVersionGetFile 1;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentVersionGetFile
    @VersionID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT v.VersionID, v.DocumentID, d.DocumentNumber, v.RevisionNo, v.StatusID,
               v.OriginalFileName, v.StoredFileName, v.FilePath, v.FileType, v.FileSizeKB
        FROM dbo.DocumentVersion v
        JOIN dbo.Document d ON d.DocumentID = v.DocumentID
        WHERE v.VersionID = @VersionID;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
