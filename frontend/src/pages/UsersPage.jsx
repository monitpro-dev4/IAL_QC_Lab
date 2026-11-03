import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Alert, Box, Button, Checkbox, Dialog, DialogActions, DialogContent, DialogTitle, FormControlLabel,
  FormGroup, FormHelperText, MenuItem, Paper, Stack, Switch, TextField, Typography,
} from "@mui/material";
import { DataGrid } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import { useSnackbar } from "notistack";
import { useAuth } from "../auth/AuthContext";
import { getUser, getUsers, resetPassword, saveUser, setUserActive } from "../api/userApi";
import { passwordProblem } from "../api/authApi";
import PasswordField from "../components/PasswordField";
import { getRoles } from "../api/masterApi";
import PageHeader from "../components/PageHeader";
import StatusChip from "../components/StatusChip";

const EMPTY = { userID: 0, name: "", employeeID: "", userName: "", emailAddress: "", mobileNo: "", designation: "", isActive: "Y", roleIDs: [], password: "" };

export default function UsersPage() {
  const { user } = useAuth();
  const { enqueueSnackbar } = useSnackbar();
  const [rows, setRows] = useState([]);
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [roleId, setRoleId] = useState(0);
  const [editing, setEditing] = useState(null);
  const [touched, setTouched] = useState(false);
  const [busy, setBusy] = useState(false);
  const [resetFor, setResetFor] = useState(null);   // user row
  const [newPassword, setNewPassword] = useState("");
  const [resetTouched, setResetTouched] = useState(false);

  useEffect(() => { getRoles().then(setRoles).catch(() => {}); }, []);

  const load = useCallback(() => {
    setLoading(true);
    getUsers({ search: search.trim(), roleId })
      .then((r) => { setRows(r); setError(""); })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [search, roleId]);
  useEffect(() => { const t = setTimeout(load, 300); return () => clearTimeout(t); }, [load]);

  const openEdit = async (userID) => {
    setTouched(false);
    if (!userID) return setEditing({ ...EMPTY });
    try {
      const u = await getUser(userID);
      setEditing({
        userID: u.userID, name: u.name, employeeID: u.employeeID, userName: u.userName, emailAddress: u.emailAddress,
        mobileNo: u.mobileNo, designation: u.designation, isActive: u.isActive, roleIDs: u.roles.map((r) => r.roleID),
      });
    } catch (e) {
      enqueueSnackbar(e.message, { variant: "error" });
    }
  };

  const errors = editing && {
    name: !editing.name.trim() && "Enter the name.",
    employeeID: !editing.employeeID.trim() && "Enter the employee ID.",
    userName: !editing.userName.trim() && "Enter a username.",
    roleIDs: editing.roleIDs.length === 0 && "Choose at least one role.",
    emailAddress: editing.emailAddress && !/^\S+@\S+\.\S+$/.test(editing.emailAddress) && "Enter a valid email address.",
    password: editing.userID === 0 && passwordProblem(editing.password, editing.userName),
  };

  const save = async () => {
    setTouched(true);
    if (Object.values(errors).some(Boolean)) return;
    setBusy(true);
    try {
      await saveUser({ ...editing, roleIDs: editing.roleIDs.join(",") });
      enqueueSnackbar(editing.userID ? "User updated" : `${editing.name} added. Give them their username and first password.`, { variant: "success" });
      setEditing(null);
      load();
    } catch (e) {
      enqueueSnackbar(e.message, { variant: "error" });
    } finally {
      setBusy(false);
    }
  };

  const resetProblem = passwordProblem(newPassword, resetFor?.userName);
  const doReset = async () => {
    setResetTouched(true);
    if (resetProblem) return;
    setBusy(true);
    try {
      await resetPassword(resetFor.userID, newPassword);
      enqueueSnackbar(`Password reset for ${resetFor.name}.`, { variant: "success" });
      setResetFor(null);
    } catch (e) {
      enqueueSnackbar(e.message, { variant: "error" });
    } finally {
      setBusy(false);
    }
  };

  const toggleActive = async (row) => {
    try {
      await setUserActive(row.userID, row.isActive === "Y" ? "N" : "Y");
      enqueueSnackbar(row.isActive === "Y" ? `${row.name} deactivated` : `${row.name} activated`, { variant: "success" });
      load();
    } catch (e) {
      enqueueSnackbar(e.message, { variant: "error" });
    }
  };

  const columns = useMemo(() => [
    { field: "name", headerName: "Name", flex: 1, minWidth: 140, renderCell: ({ row }) => <Typography variant="body2" sx={{ fontWeight: 600, lineHeight: "inherit" }}>{row.name}</Typography> },
    { field: "userName", headerName: "Username", width: 120 },
    { field: "employeeID", headerName: "Employee ID", width: 110 },
    { field: "roleNames", headerName: "Roles", flex: 1, minWidth: 150 },
    { field: "emailAddress", headerName: "Email", flex: 1, minWidth: 130 },
    { field: "isActive", headerName: "Status", width: 100, renderCell: ({ row }) => <StatusChip status={row.isActive === "Y" ? "Active" : "Inactive"} /> },
    {
      field: "actions", headerName: "", width: 290, sortable: false,
      renderCell: ({ row }) => (
        <Box sx={{ display: "flex", gap: 0.5, alignItems: "center", height: "100%" }}>
          <Button size="small" onClick={() => openEdit(row.userID)}>Edit</Button>
          <Button size="small" onClick={() => { setResetFor(row); setNewPassword(""); setResetTouched(false); }}>Reset password</Button>
          {row.userID !== user.userID && (
            <Button size="small" color={row.isActive === "Y" ? "error" : "primary"} onClick={() => toggleActive(row)}>
              {row.isActive === "Y" ? "Deactivate" : "Activate"}
            </Button>
          )}
        </Box>
      ),
    },
  // eslint-disable-next-line react-hooks/exhaustive-deps
  ], [user.userID, load]);

  const err = (k) => (touched ? errors?.[k] : false);
  const setField = (k) => (e) => setEditing({ ...editing, [k]: e.target.value });

  return (
    <>
      <PageHeader title="Users" subtitle="Who can use the system, and what each person can do."
        actions={<Button variant="contained" startIcon={<AddIcon />} onClick={() => openEdit(0)}>Add user</Button>} />

      <Box sx={{ display: "flex", gap: 1.5, mb: 2, flexWrap: "wrap" }}>
        <TextField placeholder="Search name, username, ID or email" value={search} onChange={(e) => setSearch(e.target.value)}
          sx={{ width: { xs: "100%", sm: 320 }, bgcolor: "#fff" }} slotProps={{ htmlInput: { "aria-label": "Search users" } }} />
        <TextField select label="Role" value={roleId} onChange={(e) => setRoleId(e.target.value)} sx={{ width: 220, bgcolor: "#fff" }}>
          <MenuItem value={0}>All roles</MenuItem>
          {roles.map((r) => <MenuItem key={r.roleID} value={r.roleID}>{r.roleName}</MenuItem>)}
        </TextField>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      <Paper sx={{ display: "flex", flexDirection: "column", overflow: "hidden" }}>
        <DataGrid rows={rows} columns={columns} getRowId={(r) => r.userID} loading={loading}
          disableRowSelectionOnClick disableColumnMenu
          initialState={{ pagination: { paginationModel: { pageSize: 25 } } }} pageSizeOptions={[25, 50]}
          sx={{ border: "none", "& .MuiDataGrid-columnHeaderTitle": { fontWeight: 600 } }} />
      </Paper>

      <Dialog open={!!editing} onClose={busy ? undefined : () => setEditing(null)} fullWidth maxWidth="sm">
        {editing && (
          <>
            <DialogTitle>{editing.userID ? `Edit ${editing.name}` : "Add user"}</DialogTitle>
            <DialogContent>
              <Stack spacing={2} sx={{ pt: 1 }}>
                <TextField label="Full name" required value={editing.name} onChange={setField("name")} error={!!err("name")} helperText={err("name")} slotProps={{ htmlInput: { maxLength: 100 } }} />
                <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr" }, gap: 2 }}>
                  <TextField label="Employee ID" required value={editing.employeeID} onChange={setField("employeeID")} error={!!err("employeeID")} helperText={err("employeeID")} slotProps={{ htmlInput: { maxLength: 50 } }} />
                  <TextField label="Username" required value={editing.userName} onChange={setField("userName")} error={!!err("userName")} helperText={err("userName")} slotProps={{ htmlInput: { maxLength: 50 } }} />
                  <TextField label="Email" value={editing.emailAddress} onChange={setField("emailAddress")} error={!!err("emailAddress")} helperText={err("emailAddress")} slotProps={{ htmlInput: { maxLength: 100 } }} />
                  <TextField label="Mobile" value={editing.mobileNo} onChange={setField("mobileNo")} slotProps={{ htmlInput: { maxLength: 15 } }} />
                </Box>
                <TextField label="Designation" value={editing.designation} onChange={setField("designation")} slotProps={{ htmlInput: { maxLength: 100 } }} />
                {editing.userID === 0 && (
                  <PasswordField label="First password" required autoComplete="new-password" value={editing.password} onChange={setField("password")}
                    error={!!err("password")} helperText={err("password")} />
                )}
                <Box>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>Roles</Typography>
                  <FormGroup sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr" } }}>
                    {roles.map((r) => (
                      <FormControlLabel key={r.roleID} label={r.roleName}
                        control={<Checkbox checked={editing.roleIDs.includes(r.roleID)}
                          onChange={(e) => setEditing({
                            ...editing,
                            roleIDs: e.target.checked ? [...editing.roleIDs, r.roleID] : editing.roleIDs.filter((x) => x !== r.roleID),
                          })} />} />
                    ))}
                  </FormGroup>
                  {err("roleIDs") && <FormHelperText error>{err("roleIDs")}</FormHelperText>}
                </Box>
                {editing.userID !== 0 && editing.userID !== user.userID && (
                  <FormControlLabel label="Active" control={<Switch checked={editing.isActive === "Y"} onChange={(e) => setEditing({ ...editing, isActive: e.target.checked ? "Y" : "N" })} />} />
                )}
              </Stack>
            </DialogContent>
            <DialogActions sx={{ px: 3, pb: 2 }}>
              <Button onClick={() => setEditing(null)} disabled={busy}>Cancel</Button>
              <Button variant="contained" onClick={save} disabled={busy}>{editing.userID ? "Save changes" : "Add user"}</Button>
            </DialogActions>
          </>
        )}
      </Dialog>

      <Dialog open={!!resetFor} onClose={busy ? undefined : () => setResetFor(null)} fullWidth maxWidth="xs">
        <DialogTitle>Reset password</DialogTitle>
        <DialogContent>
          <Typography color="text.secondary" sx={{ mb: 2 }}>
            Set a new password for {resetFor?.name}. They will be signed out and sign in again with this password.
          </Typography>
          <PasswordField fullWidth autoFocus label="New password" autoComplete="new-password" value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)} error={resetTouched && !!resetProblem}
            helperText={(resetTouched && resetProblem) || undefined} />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setResetFor(null)} disabled={busy}>Cancel</Button>
          <Button variant="contained" onClick={doReset} disabled={busy}>Reset password</Button>
        </DialogActions>
      </Dialog>
    </>
  );
}
