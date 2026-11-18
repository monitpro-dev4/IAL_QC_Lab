using IAL_QC_API.DAL;
using IAL_QC_API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Data.SqlClient;

namespace IAL_QC_API.Controllers
{
    /// <summary>
    /// Document Management module.
    /// Uploads (create / new revision / update) are multipart/form-data:
    /// the file is saved first, then the stored procedure records it.
    /// If the stored procedure rejects the request, the saved file is deleted again.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    public class DocumentController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly FileStorage _files;
        private readonly DALDocument dalDocument = new DALDocument();

        public DocumentController(IConfiguration configuration, FileStorage files)
        {
            _configuration = configuration;
            _files = files;
        }

        private SqlConnection GetConnection()
        {
            return new SqlConnection(_configuration.GetConnectionString("Conn"));
        }

        //=========================== Create / upload ===========================

        [HttpPost]
        [Route("DocumentCreate")]
        public async Task<APIResponse> DocumentCreate([FromForm] DocumentCreateModel model)
        {
            model.UserID = User.UserId();
            string error = _files.Validate(model.File);
            if (error != string.Empty) return new APIResponse { ErrorMessage = error };
            if (string.IsNullOrWhiteSpace(model.DocumentNumber))
                return new APIResponse { ErrorMessage = "Document Number And Title Are Required" };

            StoredFile saved = await _files.SaveAsync(model.File, model.DocumentNumber);
            using SqlConnection conn = GetConnection();
            APIResponse response = dalDocument.DocumentCreate(model, saved, conn);
            if (response.ErrorMessage != string.Empty) _files.Delete(saved);
            return response;
        }

        [HttpPost]
        [Route("DocumentVersionCreate")]
        public async Task<APIResponse> DocumentVersionCreate([FromForm] DocumentVersionCreateModel model)
        {
            model.UserID = User.UserId();
            // Every new revision needs a change summary (the reason for change is optional)
            if (string.IsNullOrWhiteSpace(model.ChangeSummary)) return new APIResponse { ErrorMessage = "Change Summary Is Required" };
            string error = _files.Validate(model.File);
            if (error != string.Empty) return new APIResponse { ErrorMessage = error };

            DocumentDetailModel doc;
            using (SqlConnection c = GetConnection()) doc = dalDocument.DocumentGetById(model.DocumentID, c);
            if (doc.ErrorMessage != string.Empty) return new APIResponse { ErrorMessage = doc.ErrorMessage };

            StoredFile saved = await _files.SaveAsync(model.File, doc.DocumentNumber);
            using SqlConnection conn = GetConnection();
            APIResponse response = dalDocument.DocumentVersionCreate(model, saved, conn);
            if (response.ErrorMessage != string.Empty) _files.Delete(saved);
            return response;
        }

        /// <summary>Change a revision that is not approved yet (draft, rejected or waiting). The file is optional.</summary>
        [HttpPost]
        [Route("DocumentVersionUpdate")]
        public async Task<APIResponse> DocumentVersionUpdate([FromForm] DocumentVersionUpdateModel model)
        {
            model.UserID = User.UserId();
            StoredFile saved = null;
            if (model.File != null)
            {
                string error = _files.Validate(model.File);
                if (error != string.Empty) return new APIResponse { ErrorMessage = error };

                DocumentFileModel current;
                using (SqlConnection c = GetConnection()) current = dalDocument.DocumentVersionGetFile(model.VersionID, c);
                if (current == null) return new APIResponse { ErrorMessage = "Document Version Not Found" };

                saved = await _files.SaveAsync(model.File, current.DocumentNumber);
            }

            using SqlConnection conn = GetConnection();
            APIResponse response = dalDocument.DocumentVersionUpdate(model, saved, conn);
            if (response.ErrorMessage != string.Empty) _files.Delete(saved);
            return response;
        }

        //=========================== Workflow ===========================

        [HttpPost]
        [Route("DocumentVersionSubmit")]
        public APIResponse DocumentVersionSubmit(DocumentSubmitModel model)
        {
            model.UserID = User.UserId();
            using SqlConnection conn = GetConnection();
            return dalDocument.DocumentVersionSubmit(model, conn);
        }

        /// <summary>Action = "Approved" or "Rejected". The approval level comes from the revision's status.</summary>
        [HttpPost]
        [Route("DocumentVersionApprove")]
        public APIResponse DocumentVersionApprove(DocumentApproveModel model)
        {
            model.UserID = User.UserId();
            using SqlConnection conn = GetConnection();
            return dalDocument.DocumentVersionApprove(model, conn);
        }

        /// <summary>Lab Manager only. Action = "Cancel" (pending revision), "Archive" (approved document) or "Restore" (archived document).</summary>
        [HttpPost]
        [Route("DocumentStatusChange")]
        [Authorize(Roles = AppRoles.LabManager)]
        public APIResponse DocumentStatusChange(DocumentApproveModel model)
        {
            model.UserID = User.UserId();
            using SqlConnection conn = GetConnection();
            return dalDocument.DocumentStatusChange(model, conn);
        }

        [HttpPost]
        [Route("DocumentActiveStatusUpdate")]
        public APIResponse DocumentActiveStatusUpdate(DocumentStatusModel model)
        {
            model.UserID = User.UserId();
            using SqlConnection conn = GetConnection();
            return dalDocument.DocumentActiveStatusUpdate(model, conn);
        }

        //=========================== Lists / details ===========================

        /// <summary>approvedOnly = true: what normal users see. false: every document incl. drafts.</summary>
        [HttpGet]
        [Route("DocumentList")]
        public List<DocumentListModel> DocumentList(string search = null, int categoryId = 0, bool approvedOnly = true, string isActive = "Y")
        {
            // Drafts and obsolete documents are only listed for people who work on documents
            if (!User.IsInAnyRole(AppRoles.DraftViewers)) { approvedOnly = true; isActive = "Y"; }
            using SqlConnection conn = GetConnection();
            return dalDocument.DocumentList(search, categoryId, approvedOnly, isActive, conn);
        }

        [HttpGet]
        [Route("DocumentGetById")]
        public DocumentDetailModel DocumentGetById(int documentId)
        {
            using SqlConnection conn = GetConnection();
            return dalDocument.DocumentGetById(documentId, conn);
        }

        [HttpGet]
        [Route("DocumentHistory")]
        public DocumentHistoryModel DocumentHistory(int documentId)
        {
            using SqlConnection conn = GetConnection();
            DocumentHistoryModel history = dalDocument.DocumentHistory(documentId, conn);
            // People who don't work on documents only see revisions that were approved (current or older),
            // not ones still in review or rejected, and not the approval comments
            if (!User.IsInAnyRole(AppRoles.DraftViewers))
            {
                history.Versions = history.Versions.Where(v => v.ApprovedOn != null).ToList();
                history.Log = new List<DocumentLogModel>();
            }
            return history;
        }

        [HttpGet]
        [Route("DocumentPendingApprovals")]
        public List<PendingApprovalModel> DocumentPendingApprovals()
        {
            using SqlConnection conn = GetConnection();
            return dalDocument.DocumentPendingApprovals(User.UserId(), conn);
        }

        /// <summary>Download a revision's file. inline = true opens it in the browser (PDF).</summary>
        [HttpGet]
        [Route("DocumentDownload")]
        public IActionResult DocumentDownload(int versionId, bool inline = false)
        {
            DocumentFileModel file;
            using (SqlConnection conn = GetConnection()) file = dalDocument.DocumentVersionGetFile(versionId, conn);
            if (file == null) return NotFound(new APIResponse { ErrorMessage = "Document Version Not Found" });

            // Approved and superseded revisions: everyone. Drafts and revisions in review: document staff only.
            bool released = file.StatusID == 4 || file.StatusID == 6;
            if (!released && !User.IsInAnyRole(AppRoles.DraftViewers))
                return StatusCode(StatusCodes.Status403Forbidden, new APIResponse { ErrorMessage = "This Revision Is Not Approved Yet" });

            string path = _files.GetFullPath(file.FilePath, file.StoredFileName);
            if (path == null || !System.IO.File.Exists(path))
                return NotFound(new APIResponse { ErrorMessage = "File Not Found On Server" });

            // Never keep controlled documents in the browser cache (shared lab PCs, signed-out users)
            Response.Headers.CacheControl = "no-store, private";
            Response.Headers.Pragma = "no-cache";

            if (!new FileExtensionContentTypeProvider().TryGetContentType(path, out string contentType))
                contentType = "application/octet-stream";

            return inline
                ? PhysicalFile(path, contentType)
                : PhysicalFile(path, contentType, file.OriginalFileName);
        }
    }
}
