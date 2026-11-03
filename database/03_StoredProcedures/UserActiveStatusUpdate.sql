/* =============================================================
   Procedure : UserActiveStatusUpdate
   Purpose   : Activate ('Y') or deactivate ('N') a user.
               Users are never deleted, so audit history stays.
   Example   : EXEC UserActiveStatusUpdate 2, 'N', 1;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.UserActiveStatusUpdate
    @UserID      INT,
    @IsActive    CHAR(1),
    @ModifiedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @IsActive NOT IN ('Y', 'N')
        BEGIN
            RAISERROR ('IsActive Must Be Y Or N', 11, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.UserMaster WHERE UserID = @UserID)
        BEGIN
            RAISERROR ('User Not Found', 11, 1);
            RETURN;
        END

        UPDATE dbo.UserMaster
        SET IsActive   = @IsActive,
            ModifiedBy = @ModifiedBy,
            ModifiedOn = GETDATE()
        WHERE UserID = @UserID;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
