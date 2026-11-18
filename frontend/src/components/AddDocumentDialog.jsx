import { useEffect, useState } from "react";
import { Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, IconButton, MenuItem, Stack, TextField, Typography } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { useSnackbar } from "notistack";
import { useAuth } from "../auth/AuthContext";
import { createDocument, submitRevision } from "../api/documentApi";
import { getCategories, getDepartments, getPlantAreas } from "../api/masterApi";
import FilePicker from "./FilePicker";

const EMPTY = { documentNumber: "", title: "", categoryID: "", department: "", plantArea: "", remarks: "" };

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
  const [categories, setCategories] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [plantAreas, setPlantAreas] = useState([]);

  // Start with a clean form every time it opens; the category list comes from the database
  useEffect(() => {
    if (!open) return;
    setForm(EMPTY); setFile(null); setTouched(false); setBusy(false);
    // Dropdown lists come from the database
    const fail = (e) => enqueueSnackbar(e.message, { variant: "error" });
    getCategories("Y").then(setCategories).catch(fail);
    getDepartments("Y").then(setDepartments).catch(fail);
    getPlantAreas("Y").then(setPlantAreas).catch(fail);
  }, [open, enqueueSnackbar]);

  const set = (key) => (e) => setForm({ ...form, [key]: e.target.value });

  const errors = {
    documentNumber: !form.documentNumber.trim() && "Enter the document number.",
    title: !form.title.trim() && "Enter a title.",
    categoryID: !form.categoryID && "Choose a category.",
    department: !form.department && "Choose a department.",
    plantArea: !form.plantArea && "Choose a plant / area.",
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
        categoryID: form.categoryID, department: form.department, plantArea: form.plantArea,
        revisionNo: 1, remarks: form.remarks.trim(), userID: user.userID, file,
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
          <TextField select label="Category" value={form.categoryID} onChange={set("categoryID")} required
            error={!!err("categoryID")} helperText={err("categoryID")}>
            {categories.map((c) => <MenuItem key={c.categoryID} value={c.categoryID}>{c.categoryName}</MenuItem>)}
          </TextField>
          <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr" }, gap: 2 }}>
            <TextField select label="Department" value={form.department} onChange={set("department")} required
              error={!!err("department")} helperText={err("department")}>
              {departments.map((d) => <MenuItem key={d.departmentID} value={d.departmentName}>{d.departmentName}</MenuItem>)}
            </TextField>
            <TextField select label="Plant / Area" value={form.plantArea} onChange={set("plantArea")} required
              error={!!err("plantArea")} helperText={err("plantArea")}>
              {plantAreas.map((p) => <MenuItem key={p.plantAreaID} value={p.plantAreaName}>{p.plantAreaName}</MenuItem>)}
            </TextField>
          </Box>
          <TextField label="Remarks" multiline minRows={2} value={form.remarks} onChange={set("remarks")}
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
