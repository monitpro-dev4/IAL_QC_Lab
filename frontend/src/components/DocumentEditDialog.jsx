import { useCallback, useEffect, useState } from "react";
import {
  Alert, Box, Button, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, IconButton,
  InputAdornment, Stack, TextField, Tooltip,
} from "@mui/material";
import FileDownloadOutlined from "@mui/icons-material/FileDownloadOutlined";
import CloseIcon from "@mui/icons-material/Close";
import { useSnackbar } from "notistack";
import { useAuth } from "../auth/AuthContext";
import { changeDocumentStatus, decideRevision, getDocument, getHistory, openFile } from "../api/documentApi";
import StatusChip from "./StatusChip";
import ConfirmDialog from "./ConfirmDialog";

/**
 * Opened from the edit icon in the document list. For approving and the Lab Manager's controls:
 *  - Lab Supervisor (Under Review) / Lab Manager (Under Approval): Approve or Reject
 *  - Lab Manager: Cancel a pending revision (Under Review, Under Approval, Rejected),
 *    Archive the approved document, or Restore an archived one
 * Everyone else sees the document's details read-only.
 * New revisions are uploaded from the document page (click the row).
 */
export default function DocumentEditDialog({ open, documentId, onClose, onChanged }) {
  const { user, isSupervisor, isManager } = useAuth();
  const { enqueueSnackbar } = useSnackbar();
  const [doc, setDoc] = useState(null);
  const [latest, setLatest] = useState(null);
  const [rejection, setRejection] = useState(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [comments, setComments] = useState("");
  const [touched, setTouched] = useState(false);
  const [confirm, setConfirm] = useState(null);   // "Reject" | "Cancel" | "Archive" waiting for confirmation

  const load = useCallback(async () => {
    setDoc(null); setLatest(null); setError("");
    try {
      const [d, h] = await Promise.all([getDocument(documentId), getHistory(documentId)]);
      if (d.errorMessage) throw new Error(d.errorMessage);
      const pen = d.pendingVersion;
      setDoc(d);
      // The newest revision (whatever its status) is what the list shows
      setLatest([...(h.versions || [])].sort((a, b) => b.revisionNo - a.revisionNo)[0] || null);
      setRejection(pen ? h.log.find((l) => l.revisionNo === pen.revisionNo && l.actionType === "Rejected") : null);
    } catch (e) {
      setError(e.message);
    }
  }, [documentId]);

  useEffect(() => {
    if (!open || !documentId) return;
    setComments(""); setTouched(false); setBusy(false); setConfirm(null);
    load();
  }, [open, documentId, load]);

  const pen = doc?.pendingVersion;
  const cur = doc?.currentVersion;
  // The revision this pop-up is about: the pending one, else the newest; but if the newest was
  // cancelled and an approved / archived version exists, that version (it is the one in use)
  const shown = pen || (latest?.statusName === "Cancelled" && cur ? cur : latest) || cur;
  const status = shown?.statusName;

  const canSupervise = pen?.statusName === "Submitted" && isSupervisor;
  const canManage = pen?.statusName === "Supervisor Approved" && isManager;
  const approving = canSupervise || canManage;
  // Lab Manager controls
  const canCancel = isManager && !!pen && ["Submitted", "Supervisor Approved", "Rejected"].includes(pen.statusName);
  // Archive: a revision Under Approval, or the current approved document
  const canArchive = isManager && (pen?.statusName === "Supervisor Approved"
    || (!pen && status === "Approved" && cur?.versionID === shown?.versionID));
  const canRestore = isManager && status === "Archived";
  const anyAction = approving || canCancel || canArchive || canRestore;
  const missingComment = touched && approving && !comments.trim();

  const finish = async (fn, message) => {
    setBusy(true);
    try {
      await fn();
      enqueueSnackbar(message, { variant: "success" });
      onChanged?.();
      onClose();
    } catch (e) {
      enqueueSnackbar(e.message, { variant: "error" });
      setBusy(false);
      setConfirm(null);
    }
  };

  // Reject needs a comment, then a confirmation; Approve goes straight through
  const askReject = () => {
    setTouched(true);
    if (!comments.trim()) return;
    setConfirm("Reject");
  };

  const decide = (action) => {
    setTouched(true);
    if (action === "Rejected" && !comments.trim()) return;
    finish(() => decideRevision(pen.versionID, action, user.userID, comments.trim()),
      action === "Rejected" ? "Rejected and sent back to the chemist"
        : canManage ? "Approved. This is now the current version." : "Approved and sent to the Lab Manager");
  };

  const statusChange = (action) => {
    const versionID = (action === "Cancel" || (action === "Archive" && pen)) ? pen.versionID : shown.versionID;
    finish(() => changeDocumentStatus(versionID, action, comments.trim()),
      action === "Cancel" ? "Document cancelled" : action === "Archive" ? "Document archived" : "Document restored");
  };

  const download = () =>
    openFile(shown.versionID, shown.originalFileName, true).catch((e) => enqueueSnackbar(e.message, { variant: "error" }));

  return (
    <Dialog open={open} onClose={busy ? undefined : onClose} fullWidth maxWidth="sm">
      <DialogTitle sx={{ display: "flex", alignItems: "center", gap: 1.5, pr: 7 }}>
        Edit document
        {shown && <StatusChip status={status} />}
      </DialogTitle>
      <IconButton aria-label="Close" onClick={onClose} disabled={busy} sx={{ position: "absolute", right: 12, top: 12 }}>
        <CloseIcon />
      </IconButton>
      <DialogContent>
        {error && <Alert severity="error">{error}</Alert>}
        {!doc && !error && <Box sx={{ display: "grid", placeItems: "center", py: 6 }}><CircularProgress /></Box>}
        {doc && shown && (
          <Stack spacing={2} sx={{ pt: 1 }}>
            {rejection && pen?.statusName === "Rejected" && (
              <Alert severity="error"><strong>{rejection.actionBy}</strong> rejected this: “{rejection.comments}”</Alert>
            )}
            <TextField label="Document number" value={doc.documentNumber} disabled />
            <TextField label="Title" value={doc.title} disabled />
            <TextField label="Category" value={doc.categoryName || ""} disabled />
            <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr" }, gap: 2 }}>
              <TextField label="Department" value={doc.department || ""} disabled />
              <TextField label="Plant / Area" value={doc.plantArea || ""} disabled />
            </Box>
            <TextField label="Remarks" multiline minRows={2} value={doc.remarks || ""} disabled />
            <TextField label={`File (revision ${shown.revisionNo})`} value={shown.originalFileName || ""} disabled
              slotProps={{ input: { endAdornment: (
                <InputAdornment position="end">
                  <Tooltip title="Download">
                    <IconButton size="small" aria-label="Download file" onClick={download}><FileDownloadOutlined fontSize="small" /></IconButton>
                  </Tooltip>
                </InputAdornment>
              ) } }} />
            {anyAction && (
              <TextField label="Comments" multiline minRows={2} value={comments} onChange={(e) => setComments(e.target.value)}
                error={missingComment} helperText={missingComment ? "Add a reason when rejecting, so the chemist knows what to fix." : undefined}
                slotProps={{ htmlInput: { maxLength: 1000 } }} />
            )}
          </Stack>
        )}
      </DialogContent>
      {anyAction ? (
        <DialogActions sx={{ px: 3, pb: 2.5, gap: 1 }}>
          {canCancel && (
            <Button variant="outlined" color="warning" disabled={busy}
              onClick={() => setConfirm("Cancel")} sx={{ mr: "auto" }}>Cancel</Button>
          )}
          {canRestore && <Button variant="contained" disabled={busy} onClick={() => statusChange("Restore")}>Restore</Button>}
          {canArchive && <Button variant="outlined" disabled={busy} onClick={() => setConfirm("Archive")}>Archive</Button>}
          {approving && <Button variant="outlined" color="error" disabled={busy} onClick={askReject}>Reject</Button>}
          {approving && <Button variant="contained" color="success" disabled={busy} onClick={() => decide("Approved")}>Approve</Button>}
        </DialogActions>
      ) : <Box sx={{ pb: 1 }} />}

      <ConfirmDialog
        open={!!confirm}
        title={confirm === "Reject" ? "Reject this document?" : confirm === "Cancel" ? "Cancel this document?" : "Archive this document?"}
        message={confirm === "Reject"
          ? "Its status changes to Rejected and it goes back with your comment for a new revision."
          : confirm === "Cancel"
            ? "Its status changes to Cancelled. This can't be undone."
            : "Its status changes to Archived and it is taken out of use. You can restore it later to its previous status."}
        confirmLabel={confirm === "Reject" ? "Yes, reject" : confirm === "Cancel" ? "Yes, cancel" : "Archive"}
        cancelLabel={confirm === "Archive" ? "Cancel" : "No"}
        color={confirm === "Archive" ? "primary" : "error"}
        busy={busy}
        onCancel={() => setConfirm(null)}
        onConfirm={() => (confirm === "Reject" ? decide("Rejected") : statusChange(confirm))}
      />
    </Dialog>
  );
}
