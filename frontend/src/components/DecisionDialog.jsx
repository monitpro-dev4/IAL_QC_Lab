import { useEffect, useState } from "react";
import { Button, Dialog, DialogActions, DialogContent, DialogTitle, TextField, Typography } from "@mui/material";

/** Approve or reject a revision. Rejecting needs a reason, so the chemist knows what to fix. */
export default function DecisionDialog({ open, action, documentLabel, busy, onCancel, onConfirm }) {
  const [comments, setComments] = useState("");
  const [touched, setTouched] = useState(false);
  useEffect(() => { if (open) { setComments(""); setTouched(false); } }, [open]);

  const rejecting = action === "Rejected";
  const missing = rejecting && !comments.trim();

  return (
    <Dialog open={open} onClose={busy ? undefined : onCancel} fullWidth maxWidth="sm">
      <DialogTitle>{rejecting ? "Reject revision" : "Approve revision"}</DialogTitle>
      <DialogContent>
        <Typography color="text.secondary" sx={{ mb: 2 }}>{documentLabel}</Typography>
        <TextField
          autoFocus
          fullWidth
          multiline
          minRows={3}
          label={rejecting ? "What needs to change" : "Comments (optional)"}
          value={comments}
          onChange={(e) => setComments(e.target.value)}
          onBlur={() => setTouched(true)}
          error={touched && missing}
          helperText={touched && missing ? "Add a reason so the chemist knows what to fix." : " "}
          slotProps={{ htmlInput: { maxLength: 1000 } }}
        />
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onCancel} disabled={busy}>Cancel</Button>
        <Button
          variant="contained"
          color={rejecting ? "error" : "success"}
          disabled={busy}
          onClick={() => { setTouched(true); if (!missing) onConfirm(comments.trim()); }}
        >
          {rejecting ? "Reject" : "Approve"}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
