import { useEffect, useState } from "react";
import { Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, IconButton, Stack, TextField, Typography } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { useSnackbar } from "notistack";
import { useAuth } from "../auth/AuthContext";
import { createDocument, submitRevision } from "../api/documentApi";
import FilePicker from "./FilePicker";

const EMPTY = { documentNumber: "", title: "", changeSummary: "" };

/**
 * Add a new document. It is saved as revision 1 and sent straight to the
 * Lab Supervisor for approval. onAdded runs after it is saved.
 */
export default function AddDocumentDialog({ open, onClose, onAdded }) {
  const { user } = useAuth();
  const { enqueueSnackbar } = useSnackbar();
  const [form, setForm] = useState(EMPTY);
  const [file, setFile] = useState(null);
  const [touched, setTouched] = useState(false);
  const [busy, setBusy] = useState(false);

  // Start with a clean form every time it opens
  useEffect(() => {
    if (open) { setForm(EMPTY); setFile(null); setTouched(false); setBusy(false); }
  }, [open]);

  const set = (key) => (e) => setForm({ ...form, [key]: e.target.value });

  const errors = {
    documentNumber: !form.documentNumber.trim() && "Enter the document number.",
    title: !form.title.trim() && "Enter a title.",
    file: !file && "Choose the document file.",
  };
  const valid = !Object.values(errors).some(Boolean);

  const save = async () => {
    setTouched(true);
    if (!valid) return;
    setBusy(true);
    try {
      const res = await createDocument({
        documentNumber: form.documentNumber.trim(), title: form.title.trim(),
        revisionNo: 1, changeSummary: form.changeSummary.trim(), userID: user.userID, file,
      });
      await submitRevision(res.secondID, user.userID);
      enqueueSnackbar("Document added and sent to the Lab Supervisor", { variant: "success" });
      onClose();
      onAdded?.(res);
    } catch (e) {
      enqueueSnackbar(e.message, { variant: "error" });
      setBusy(false);
    }
  };

  const err = (key) => (touched ? errors[key] : false);
  return (
    <Dialog open={open} onClose={busy ? undefined : onClose} fullWidth maxWidth="sm">
      <DialogTitle sx={{ pr: 7 }}>Add document</DialogTitle>
      <IconButton aria-label="Close" onClick={onClose} disabled={busy} sx={{ position: "absolute", right: 12, top: 12 }}>
        <CloseIcon />
      </IconButton>
      <DialogContent>
        <Stack spacing={2} sx={{ pt: 1 }}>
          <TextField label="Document number" value={form.documentNumber} onChange={set("documentNumber")} required
            error={!!err("documentNumber")} helperText={err("documentNumber")}
            slotProps={{ htmlInput: { maxLength: 50 } }} />
          <TextField label="Title" value={form.title} onChange={set("title")} required
            error={!!err("title")} helperText={err("title")} slotProps={{ htmlInput: { maxLength: 200 } }} />
          <TextField label="Notes" multiline minRows={2} value={form.changeSummary} onChange={set("changeSummary")}
            slotProps={{ htmlInput: { maxLength: 500 } }} />
          <Box>
            <Typography variant="body2" sx={{ fontWeight: 500, mb: 1 }}>File</Typography>
            <FilePicker file={file} onChange={setFile} error={err("file")} />
          </Box>
        </Stack>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2.5 }}>
        <Button variant="contained" onClick={save} disabled={busy}>Add</Button>
      </DialogActions>
    </Dialog>
  );
}
