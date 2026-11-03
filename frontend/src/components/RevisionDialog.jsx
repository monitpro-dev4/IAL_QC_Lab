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
  const [error, setError] = useState("");

  useEffect(() => {
    if (open) { setFile(null); setTitle(initialTitle || ""); setSummary(initialSummary || ""); setError(""); }
  }, [open, initialTitle, initialSummary]);

  const isNew = mode === "new";
  const save = () => {
    if (isNew && !file) return setError("Choose the file for the new revision.");
    if (!isNew && !title.trim()) return setError("");
    onSave({ file, title: title.trim(), summary: summary.trim() });
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
            label="What changed"
            multiline minRows={2}
            value={summary}
            onChange={(e) => setSummary(e.target.value)}
            helperText="Shown in the document's history, e.g. “Updated calibration limits in section 4”."
            slotProps={{ htmlInput: { maxLength: 500 } }}
          />
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
