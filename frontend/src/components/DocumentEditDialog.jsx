import { useCallback, useEffect, useState } from "react";
import {
  Alert, Box, Button, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, IconButton,
  InputAdornment, Stack, TextField, Tooltip,
} from "@mui/material";
import FileDownloadOutlined from "@mui/icons-material/FileDownloadOutlined";
import CloseIcon from "@mui/icons-material/Close";
import { useSnackbar } from "notistack";
import { useAuth } from "../auth/AuthContext";
import { decideRevision, getDocument, getHistory, openFile } from "../api/documentApi";
import StatusChip from "./StatusChip";

/**
 * Opened from the edit icon in the document list. Only for approving / rejecting:
 * the Lab Supervisor (first) or Lab Manager (final) whose turn it is gets a Comments box
 * with Approve and Reject. Everyone else sees the document's details read-only.
 * New revisions are uploaded from the document page (click the row).
 */
export default function DocumentEditDialog({ open, documentId, onClose, onChanged }) {
  const { user, isSupervisor, isManager } = useAuth();
  const { enqueueSnackbar } = useSnackbar();
  const [doc, setDoc] = useState(null);
  const [rejection, setRejection] = useState(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [comments, setComments] = useState("");
  const [touched, setTouched] = useState(false);

  const load = useCallback(async () => {
    setDoc(null); setError("");
    try {
      const [d, h] = await Promise.all([getDocument(documentId), getHistory(documentId)]);
      if (d.errorMessage) throw new Error(d.errorMessage);
      const pen = d.pendingVersion;
      setDoc(d);
      setRejection(pen ? h.log.find((l) => l.revisionNo === pen.revisionNo && l.actionType === "Rejected") : null);
    } catch (e) {
      setError(e.message);
    }
  }, [documentId]);

  useEffect(() => {
    if (!open || !documentId) return;
    setComments(""); setTouched(false); setBusy(false);
    load();
  }, [open, documentId, load]);

  const pen = doc?.pendingVersion;
  const shown = pen || doc?.currentVersion;          // the revision this pop-up is about
  // Self-approval is allowed: a Supervisor / Manager can approve a revision they uploaded
  const canSupervise = pen?.statusName === "Submitted" && isSupervisor;
  const canManage = pen?.statusName === "Supervisor Approved" && isManager;
  const approving = canSupervise || canManage;
  const missingComment = touched && approving && !comments.trim();

  const decide = async (action) => {
    setTouched(true);
    if (action === "Rejected" && !comments.trim()) return;
    setBusy(true);
    try {
      await decideRevision(pen.versionID, action, user.userID, comments.trim());
      enqueueSnackbar(action === "Rejected" ? "Rejected and sent back to the chemist"
        : canManage ? "Approved. This is now the current version." : "Approved and sent to the Lab Manager", { variant: "success" });
      onChanged?.();
      onClose();
    } catch (e) {
      enqueueSnackbar(e.message, { variant: "error" });
      setBusy(false);
    }
  };

  const download = () =>
    openFile(shown.versionID, shown.originalFileName, true).catch((e) => enqueueSnackbar(e.message, { variant: "error" }));

  return (
    <Dialog open={open} onClose={busy ? undefined : onClose} fullWidth maxWidth="sm">
      <DialogTitle sx={{ display: "flex", alignItems: "center", gap: 1.5, pr: 7 }}>
        Edit document
        {shown && <StatusChip status={shown.statusName} />}
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
            <TextField label="What changed" multiline minRows={2} value={shown.changeSummary || ""} disabled />
            <TextField label={`File (revision ${shown.revisionNo})`} value={shown.originalFileName || ""} disabled
              slotProps={{ input: { endAdornment: (
                <InputAdornment position="end">
                  <Tooltip title="Download">
                    <IconButton size="small" aria-label="Download file" onClick={download}><FileDownloadOutlined fontSize="small" /></IconButton>
                  </Tooltip>
                </InputAdornment>
              ) } }} />
            {approving && (
              <TextField label="Comments" multiline minRows={2} value={comments} onChange={(e) => setComments(e.target.value)}
                error={missingComment} helperText={missingComment ? "Add a reason when rejecting, so the chemist knows what to fix." : undefined}
                slotProps={{ htmlInput: { maxLength: 1000 } }} />
            )}
          </Stack>
        )}
      </DialogContent>
      {approving ? (
        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button variant="outlined" color="error" disabled={busy} onClick={() => decide("Rejected")}>Reject</Button>
          <Button variant="contained" color="success" disabled={busy} onClick={() => decide("Approved")}>Approve</Button>
        </DialogActions>
      ) : <Box sx={{ pb: 1 }} />}
    </Dialog>
  );
}
