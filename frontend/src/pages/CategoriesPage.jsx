import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Alert, Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, FormControlLabel, Paper, Stack, Switch, TextField, Typography,
} from "@mui/material";
import { DataGrid } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import { useSnackbar } from "notistack";
import { useAuth } from "../auth/AuthContext";
import { getCategories, saveCategory } from "../api/masterApi";
import PageHeader from "../components/PageHeader";
import StatusChip from "../components/StatusChip";

export default function CategoriesPage() {
  const { user } = useAuth();
  const { enqueueSnackbar } = useSnackbar();
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [editing, setEditing] = useState(null);
  const [touched, setTouched] = useState(false);
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    getCategories("").then(setRows).catch((e) => setError(e.message)).finally(() => setLoading(false));
  }, []);
  useEffect(() => { load(); }, [load]);

  const errors = editing && {
    categoryCode: !/^[A-Za-z0-9]{1,10}$/.test(editing.categoryCode.trim()) && "1 to 10 letters or numbers, e.g. SOP.",
    categoryName: !editing.categoryName.trim() && "Enter the category name.",
  };

  const save = async () => {
    setTouched(true);
    if (Object.values(errors).some(Boolean)) return;
    setBusy(true);
    try {
      await saveCategory({ ...editing, createdBy: user.userID });
      enqueueSnackbar(editing.categoryID ? "Category updated" : "Category added", { variant: "success" });
      setEditing(null);
      load();
    } catch (e) {
      enqueueSnackbar(e.message, { variant: "error" });
    } finally {
      setBusy(false);
    }
  };

  const columns = useMemo(() => [
    { field: "categoryCode", headerName: "Code", width: 100, renderCell: ({ row }) => <Typography variant="body2" sx={{ fontWeight: 600, lineHeight: "inherit" }}>{row.categoryCode}</Typography> },
    { field: "categoryName", headerName: "Name", flex: 1, minWidth: 200 },
    { field: "categoryDesc", headerName: "Description", flex: 1.5, minWidth: 220 },
    { field: "isActive", headerName: "Status", width: 110, renderCell: ({ row }) => <StatusChip status={row.isActive === "Y" ? "Active" : "Inactive"} /> },
    {
      field: "actions", headerName: "", width: 90, sortable: false,
      renderCell: ({ row }) => <Button size="small" onClick={() => { setTouched(false); setEditing({ ...row }); }}>Edit</Button>,
    },
  ], []);

  const err = (k) => (touched ? errors?.[k] : false);
  return (
    <>
      <PageHeader title="Document categories" subtitle="The code is used in document numbers, e.g. SOP in IAL-SOP-123."
        actions={<Button variant="contained" startIcon={<AddIcon />} onClick={() => { setTouched(false); setEditing({ categoryID: 0, categoryCode: "", categoryName: "", categoryDesc: "", isActive: "Y" }); }}>Add category</Button>} />
      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      <Paper sx={{ display: "flex", flexDirection: "column", overflow: "hidden" }}>
        <DataGrid rows={rows} columns={columns} getRowId={(r) => r.categoryID} loading={loading}
          disableRowSelectionOnClick disableColumnMenu hideFooter
          sx={{ border: "none", "& .MuiDataGrid-columnHeaderTitle": { fontWeight: 600 } }} />
      </Paper>

      <Dialog open={!!editing} onClose={busy ? undefined : () => setEditing(null)} fullWidth maxWidth="sm">
        {editing && (
          <>
            <DialogTitle>{editing.categoryID ? "Edit category" : "Add category"}</DialogTitle>
            <DialogContent>
              <Stack spacing={2} sx={{ pt: 1 }}>
                <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "140px 1fr" }, gap: 2 }}>
                  <TextField label="Code" required value={editing.categoryCode} onChange={(e) => setEditing({ ...editing, categoryCode: e.target.value.toUpperCase() })}
                    error={!!err("categoryCode")} helperText={err("categoryCode")} slotProps={{ htmlInput: { maxLength: 10 } }} />
                  <TextField label="Name" required value={editing.categoryName} onChange={(e) => setEditing({ ...editing, categoryName: e.target.value })}
                    error={!!err("categoryName")} helperText={err("categoryName")} slotProps={{ htmlInput: { maxLength: 100 } }} />
                </Box>
                <TextField label="Description" value={editing.categoryDesc || ""} onChange={(e) => setEditing({ ...editing, categoryDesc: e.target.value })} slotProps={{ htmlInput: { maxLength: 250 } }} />
                {editing.categoryID !== 0 && (
                  <FormControlLabel label="Active (shown when adding documents)" control={<Switch checked={editing.isActive === "Y"} onChange={(e) => setEditing({ ...editing, isActive: e.target.checked ? "Y" : "N" })} />} />
                )}
              </Stack>
            </DialogContent>
            <DialogActions sx={{ px: 3, pb: 2 }}>
              <Button onClick={() => setEditing(null)} disabled={busy}>Cancel</Button>
              <Button variant="contained" onClick={save} disabled={busy}>{editing.categoryID ? "Save changes" : "Add category"}</Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </>
  );
}
