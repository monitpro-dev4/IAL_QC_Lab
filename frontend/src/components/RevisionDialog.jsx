import { useEffect, useState } from "react";
import { Button, Dialog, DialogActions, DialogContent, DialogTitle, Stack, TextField } from "@mui/material";
import FilePicker from "./FilePicker";

/**
 * mode "new": upload a new revision (file required).
 * mode "edit": change a draft / rejected revision (file and title optional).
 */
export default function RevisionDialog({ open, mode, initialTitle, initialSummary, busy, onCancel, onSave }) {
  const [file, setFile] = useState(null);
  const [title, setTitle] = useState("");
  const [summary, setSummary] = useState("");
  const [reason, setReason] = useState("");
  const [error, setError] = useState("");
  const [touched, setTouched] = useState(false);

  useEffect(() => {
    if (open) { setFile(null); setTitle(initialTitle || ""); setSummary(initialSummary || ""); setReason(""); setError(""); setTouched(false); }
  }, [open, initialTitle, initialSummary]);

  const isNew = mode === "new";
  const summaryMissing = touched && !summary.trim();
  const save = () => {
    setTouched(true);
    if (isNew && !file) setError("Choose the file for the new revision.");
    if (!summary.trim() || (isNew && !file)) return;
    if (!isNew && !title.trim()) return setError("");
    onSave({ file, title: title.trim(), summary: summary.trim(), reason: reason.trim() });
  };

  return (
    <Dialog open={open} onClose={busy ? undefined : onCancel} fullWidth maxWidth="sm">
      <DialogTitle>{isNew ? "Upload new revision" : "Edit revision"}</DialogTitle>
      <DialogContent>
        <Stack spacing={2.5} sx={{ pt: 1 }}>
          {!isNew && (
            <TextField label="Title" value={title} onChange={(e) => setTitle(e.target.value)} required
              error={!title.trim()} helperText={!title.trim() ? "Title is required." : " "} slotProps={{ htmlInput: { maxLength: 200 } }} />
          )}
          <TextField
            label="Change summary"
            required
            multiline minRows={2}
            value={summary}
            onChange={(e) => setSummary(e.target.value)}
            error={summaryMissing}
            helperText={summaryMissing ? "Enter the change summary." : "What was changed, e.g. “Updated calibration limits in section 4”."}
            slotProps={{ htmlInput: { maxLength: 500 } }}
          />
          {isNew && (
            <TextField
              label="Reason for change"
              multiline minRows={2}
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              helperText="Optional. Why it was changed, e.g. “New ISO 17025 requirement”."
              slotProps={{ htmlInput: { maxLength: 500 } }}
            />
          )}
          <FilePicker file={file} onChange={(f) => { setFile(f); setError(""); }} error={error} />
          {!isNew && !file && <span style={{ fontSize: 14, color: "#56636A" }}>Leave the file empty to keep the current one.</span>}
        </Stack>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onCancel} disabled={busy}>Cancel</Button>
        <Button variant="contained" onClick={save} disabled={busy}>{isNew ? "Upload revision" : "Save changes"}</Button>
      </DialogActions>
    </Dialog>
  );
}
