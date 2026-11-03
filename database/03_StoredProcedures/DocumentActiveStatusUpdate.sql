/* =============================================================
   Procedure : DocumentActiveStatusUpdate
   Module    : Document Management
   Purpose   : Make a document obsolete ('N') or bring it back ('Y').
               Documents are never deleted; inactive ones are hidden
               from the list and cannot get new revisions.
   Who       : Lab Manager, Administrator
   Example   : EXEC DocumentActiveStatusUpdate 1, 'N', 2;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentActiveStatusUpdate
    @DocumentID  INT,
    @IsActive    CHAR(1),
    @UserID      INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @IsActive NOT IN ('Y', 'N')
        BEGIN
            RAISERROR ('IsActive Must Be Y Or N', 11, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.UserRoles ur
                       JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID AND rm.IsActive = 'Y'
                       JOIN dbo.UserMaster u  ON u.UserID  = ur.UserID AND u.IsActive  = 'Y'
                       WHERE ur.UserID = @UserID AND rm.RoleName IN ('Lab Manager','Administrator'))
        BEGIN
            RAISERROR ('Only The Lab Manager Or Administrator Can Change Document Status', 11, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.Document WHERE DocumentID = @DocumentID)
        BEGIN
            RAISERROR ('Document Not Found', 11, 1);
            RETURN;
        END

        UPDATE dbo.Document
        SET IsActive = @IsActive, ModifiedBy = @UserID, ModifiedOn = GETDATE()
        WHERE DocumentID = @DocumentID;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
