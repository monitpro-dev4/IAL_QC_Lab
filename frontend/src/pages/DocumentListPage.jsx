import { Fragment, useEffect, useMemo, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import {
  Alert, Box, Button, Collapse, IconButton, LinearProgress, Paper, Table, TableBody, TableCell, TableContainer,
  ListItemIcon, ListItemText, Menu, MenuItem, Popover, TableHead, TablePagination, TableRow, TextField, Tooltip, Typography,
} from "@mui/material";
import MoreVert from "@mui/icons-material/MoreVert";
import ArrowDropDown from "@mui/icons-material/ArrowDropDown";
import FileDownloadOutlined from "@mui/icons-material/FileDownloadOutlined";
import EditOutlined from "@mui/icons-material/EditOutlined";
import KeyboardArrowDown from "@mui/icons-material/KeyboardArrowDown";
import KeyboardArrowUp from "@mui/icons-material/KeyboardArrowUp";
import AddIcon from "@mui/icons-material/Add";
import { useSnackbar } from "notistack";
import { useAuth } from "../auth/AuthContext";
import { getDocuments, getHistory, openFile } from "../api/documentApi";
import PageHeader from "../components/PageHeader";
import StatusChip, { statusLabel } from "../components/StatusChip";
import AddDocumentDialog from "../components/AddDocumentDialog";
import DocumentEditDialog from "../components/DocumentEditDialog";
import { colors } from "../theme";
import { approvedByName, approvedDate, reviewedByName } from "../format";
import EllipsisText from "../components/EllipsisText";

const COLUMNS = 12;  // arrow, S.No, Doc.No., Title, Plant / Area, Category, Department, Prepared by, Approved by, Approved date, Status, Action
const head = { fontWeight: 600, color: "text.secondary", whiteSpace: "nowrap" };

// Column filters: text boxes match any part of the value, dropdowns match exactly
const NO_FILTERS = { documentNumber: "", title: "", plantArea: "", categoryName: "", department: "", editedBy: "", approvedBy: "", versionStatus: "" };
const TEXT_FILTERS = ["documentNumber", "title", "editedBy", "approvedBy"];
const filterValue = (row, key) => (key === "approvedBy" ? approvedByName(row.versionStatus, row.approvedBy) : row[key]) || "";

// Cancelled and archived documents are on the Archived List tab, not All Documents
const ARCHIVE_STATUSES = ["Cancelled", "Archived"];

/** Documents page: an "All Documents" tab and an "Archived List" tab (cancelled + archived). */
export default function DocumentListPage() {
  const { canEditDocuments } = useAuth();
  const [params, setParams] = useSearchParams();
  const archived = canEditDocuments && params.get("tab") === "archived";
  const [adding, setAdding] = useState(false);
  const [added, setAdded] = useState(0);
  const tabs = [
    { key: "all", label: "All Documents", show: true },
    { key: "archived", label: "Archived List", show: canEditDocuments },
  ].filter((t) => t.show);
  const current = archived ? "archived" : "all";

  return (
    <>
      <PageHeader title="Documents" />
      <Paper sx={{ display: "flex", alignItems: "center", gap: 1, p: 1.25, mb: 2, flexWrap: "wrap" }}>
        <Box role="tablist" aria-label="Document lists" sx={{ display: "flex", gap: 1, flexGrow: 1 }}>
          {tabs.map((t) => (
            <Button key={t.key} role="tab" aria-selected={current === t.key}
              variant={current === t.key ? "contained" : "text"} color={current === t.key ? "primary" : "inherit"}
              onClick={() => setParams(t.key === "all" ? {} : { tab: t.key }, { replace: true })}
              sx={{ borderRadius: 2, px: 2, fontWeight: 600, color: current === t.key ? undefined : "text.secondary" }}>
              {t.label}
            </Button>
          ))}
        </Box>
        {!archived && canEditDocuments && (
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setAdding(true)}>Add document</Button>
        )}
      </Paper>
      <DocumentTable key={current} archived={archived} added={added} initialStatus={params.get("status") || ""} />
      <AddDocumentDialog open={adding} onClose={() => setAdding(false)} onAdded={() => setAdded((n) => n + 1)} />
    </>
  );
}

function DocumentTable({ archived, added, initialStatus }) {
  const { canEditDocuments } = useAuth();
  const { enqueueSnackbar } = useSnackbar();
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [filters, setFilters] = useState({ ...NO_FILTERS, versionStatus: initialStatus });
  const [editingId, setEditingId] = useState(null);
  const [refresh, setRefresh] = useState(0);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  // People who work on documents see every document with its latest revision;
  // everyone else sees only the approved versions
  const view = canEditDocuments ? "all" : "approved";

  useEffect(() => {
    setLoading(true);
    setError("");
    getDocuments({ approvedOnly: view === "approved" })
      .then((list) => setRows(list.filter((r) => ARCHIVE_STATUSES.includes(r.versionStatus) === archived)))
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [view, refresh, archived, added]);

  const setFilterValue = (key, value) => { setFilters((f) => ({ ...f, [key]: value })); setPage(0); };
  const filtering = Object.values(filters).some(Boolean);

  // Dropdown choices = the values that appear in the list
  const choices = useMemo(() => {
    const uniq = (key) => [...new Set(rows.map((r) => filterValue(r, key)).filter(Boolean))].sort();
    return { plantArea: uniq("plantArea"), categoryName: uniq("categoryName"), department: uniq("department"), versionStatus: uniq("versionStatus") };
  }, [rows]);

  const filtered = useMemo(() => rows.filter((r) => Object.entries(filters).every(([key, value]) => {
    if (!value) return true;
    const v = filterValue(r, key);
    return TEXT_FILTERS.includes(key) ? v.toLowerCase().includes(value.trim().toLowerCase()) : v === value;
  })), [rows, filters]);

  const download = (versionID, fileName) =>
    openFile(versionID, fileName, true).catch((err) => enqueueSnackbar(err.message, { variant: "error" }));

  const shown = filtered.slice(page * pageSize, page * pageSize + pageSize);

  const filterHead = (key, label, { select = false, format } = {}) => (
    <FilterHeader label={label} value={filters[key]} onChange={(v) => setFilterValue(key, v)}
      options={select ? choices[key] : null} format={format} />
  );

  return (
    <>
      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Paper sx={{ overflow: "hidden" }}>
        {loading && <LinearProgress />}
          <>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ width: 56 }} />
                    <TableCell sx={{ ...head, width: 70 }} align="center">S.No</TableCell>
                    <TableCell sx={{ ...head, minWidth: 150 }}>{filterHead("documentNumber", "Doc.No.")}</TableCell>
                    <TableCell sx={head}>{filterHead("title", "Title")}</TableCell>
                    <TableCell sx={{ ...head, width: 150 }}>{filterHead("plantArea", "Plant / Area", { select: true })}</TableCell>
                    <TableCell sx={{ ...head, width: 150 }}>{filterHead("categoryName", "Category", { select: true })}</TableCell>
                    <TableCell sx={{ ...head, width: 150 }}>{filterHead("department", "Department", { select: true })}</TableCell>
                    <TableCell sx={{ ...head, width: 150 }}>{filterHead("editedBy", "Prepared by")}</TableCell>
                    <TableCell sx={{ ...head, width: 150 }}>{filterHead("approvedBy", "Approved by")}</TableCell>
                    <TableCell sx={{ ...head, width: 130 }}>Approved date</TableCell>
                    <TableCell sx={{ ...head, width: 170 }}>{filterHead("versionStatus", "Status", { select: true, format: statusLabel })}</TableCell>
                    <TableCell sx={{ ...head, width: 110 }} align="center">
                      {filtering ? (
                        <Button size="small" onClick={() => { setFilters(NO_FILTERS); setPage(0); }}>Clear filters</Button>
                      ) : "Action"}
                    </TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {!loading && filtered.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={COLUMNS} align="center" sx={{ py: 5, color: "text.secondary" }}>
                        {rows.length > 0 ? "No documents match these filters."
                          : archived ? "No archived or cancelled documents."
                          : view === "approved" ? "No approved documents yet." : "No documents yet."}
                      </TableCell>
                    </TableRow>
                  )}
                  {shown.map((row, i) => (
                    <DocumentRow
                      key={`${row.documentID}-${refresh}`}
                      row={row}
                      sno={page * pageSize + i + 1}
                      canEdit={canEditDocuments}
                      onDownload={download}
                      onEdit={() => setEditingId(row.documentID)}
                    />
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
            <TablePagination
              component="div"
              count={filtered.length}
              page={page}
              onPageChange={(_, p) => setPage(p)}
              rowsPerPage={pageSize}
              onRowsPerPageChange={(e) => { setPageSize(parseInt(e.target.value, 10)); setPage(0); }}
              rowsPerPageOptions={[10, 25, 50]}
            />
          </>
      </Paper>
      <DocumentEditDialog open={!!editingId} documentId={editingId} onClose={() => setEditingId(null)} onChanged={() => setRefresh((n) => n + 1)} />
    </>
  );
}

/**
 * Column heading with a down arrow. Clicking the arrow opens the column's filter:
 * a text box (matches any part) or, when options are given, a list to pick from.
 * The arrow turns blue while the column is filtered.
 */
function FilterHeader({ label, value, onChange, options, format = (v) => v }) {
  const [anchor, setAnchor] = useState(null);
  const active = !!value;
  const close = () => setAnchor(null);
  return (
    <Box sx={{ display: "inline-flex", alignItems: "center", gap: 0.25 }}>
      <Box component="span" sx={{ color: active ? "primary.main" : undefined }}>{label}</Box>
      <IconButton size="small" aria-label={`Filter ${label}`} aria-haspopup="true"
        onClick={(e) => setAnchor(e.currentTarget)} sx={{ p: 0.25, color: active ? "primary.main" : "text.secondary" }}>
        <ArrowDropDown fontSize="small" />
      </IconButton>
      {options ? (
        <Menu anchorEl={anchor} open={!!anchor} onClose={close} slotProps={{ paper: { sx: { minWidth: 200, maxHeight: 360 } } }}>
          <MenuItem selected={!value} onClick={() => { onChange(""); close(); }}>All</MenuItem>
          {options.map((o) => (
            <MenuItem key={o} selected={value === o} onClick={() => { onChange(o); close(); }}>{format(o)}</MenuItem>
          ))}
        </Menu>
      ) : (
        <Popover anchorEl={anchor} open={!!anchor} onClose={close}
          anchorOrigin={{ vertical: "bottom", horizontal: "left" }} transformOrigin={{ vertical: "top", horizontal: "left" }}>
          <Box sx={{ p: 1.5, width: 240, display: "flex", gap: 1, alignItems: "center" }}>
            <TextField size="small" fullWidth autoFocus placeholder={`Filter ${label}`} value={value}
              onChange={(e) => onChange(e.target.value)} onKeyDown={(e) => { if (e.key === "Enter") close(); }}
              slotProps={{ htmlInput: { "aria-label": `Filter ${label}` } }} />
            {active && <Button size="small" onClick={() => { onChange(""); close(); }}>Clear</Button>}
          </Box>
        </Popover>
      )}
    </Box>
  );
}

/** One document, with a down arrow that opens all its revisions underneath. */
function DocumentRow({ row, sno, canEdit, onDownload, onEdit }) {
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [versions, setVersions] = useState(null);
  const [error, setError] = useState("");
  const [menuAnchor, setMenuAnchor] = useState(null);

  const toggle = () => {
    const next = !open;
    setOpen(next);
    if (next && !versions) {
      setError("");
      getHistory(row.documentID)
        .then((h) => setVersions([...(h.versions || [])].sort((a, b) => b.revisionNo - a.revisionNo)))
        .catch((e) => setError(e.message));
    }
  };

  return (
    <Fragment>
      {/* Clicking the row opens the document page; the arrow and action buttons don't */}
      <TableRow hover onClick={() => navigate(`/documents/${row.documentID}`)}
        sx={{ cursor: "pointer", "& > td": { borderBottom: open ? "none" : undefined } }}>
        <TableCell sx={{ pr: 0 }} onClick={(e) => e.stopPropagation()}>
          <Tooltip title={open ? "Hide revisions" : "Show revisions"}>
            <IconButton size="small" aria-label={`${open ? "Hide" : "Show"} revisions of ${row.documentNumber}`} aria-expanded={open} onClick={toggle}>
              {open ? <KeyboardArrowUp /> : <KeyboardArrowDown />}
            </IconButton>
          </Tooltip>
        </TableCell>
        <TableCell align="center">{sno}</TableCell>
        <TableCell sx={{ fontWeight: 600, whiteSpace: "nowrap" }}>{row.documentNumber}</TableCell>
        <TableCell><EllipsisText text={row.title} maxWidth={240} /></TableCell>
        <TableCell><EllipsisText text={row.plantArea} maxWidth={150} /></TableCell>
        <TableCell><EllipsisText text={row.categoryName} maxWidth={150} /></TableCell>
        <TableCell><EllipsisText text={row.department} maxWidth={150} /></TableCell>
        <TableCell><EllipsisText text={row.editedBy} maxWidth={150} /></TableCell>
        <TableCell><EllipsisText text={approvedByName(row.versionStatus, row.approvedBy)} maxWidth={150} /></TableCell>
        <TableCell><EllipsisText text={approvedDate(row.versionStatus, row.approvedBy, row.issuedDate)} maxWidth={130} /></TableCell>
        <TableCell><StatusChip status={row.versionStatus} /></TableCell>
        <TableCell align="center" sx={{ whiteSpace: "nowrap" }} onClick={(e) => e.stopPropagation()}>
          {(row.versionID || canEdit) && (
            <Tooltip title="Actions">
              <IconButton size="small" aria-label={`Actions for ${row.documentNumber}`} aria-haspopup="true"
                onClick={(e) => setMenuAnchor(e.currentTarget)}>
                <MoreVert fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
          <Menu anchorEl={menuAnchor} open={!!menuAnchor} onClose={() => setMenuAnchor(null)}
            anchorOrigin={{ vertical: "bottom", horizontal: "right" }} transformOrigin={{ vertical: "top", horizontal: "right" }}>
            {canEdit && (
              <MenuItem onClick={() => { setMenuAnchor(null); onEdit(); }}>
                <ListItemIcon><EditOutlined fontSize="small" /></ListItemIcon>
                <ListItemText>Edit</ListItemText>
              </MenuItem>
            )}
            {row.versionID && (
              <MenuItem onClick={() => { setMenuAnchor(null); onDownload(row.versionID, row.originalFileName); }}>
                <ListItemIcon><FileDownloadOutlined fontSize="small" /></ListItemIcon>
                <ListItemText>Download</ListItemText>
              </MenuItem>
            )}
          </Menu>
        </TableCell>
      </TableRow>

      <TableRow>
        <TableCell colSpan={COLUMNS} sx={{ py: 0, bgcolor: open ? "#F8FAFB" : undefined, borderBottom: open ? undefined : "none" }}>
          <Collapse in={open} timeout="auto" unmountOnExit>
            <Box sx={{ py: 2, pl: { xs: 1, md: 7 }, pr: 1 }}>
              {error && <Alert severity="error">{error}</Alert>}
              {!versions && !error && <LinearProgress sx={{ maxWidth: 240 }} />}
              {versions && versions.length === 0 && <Typography variant="body2" color="text.secondary">No revisions to show.</Typography>}
              {versions && versions.length > 0 && (
                <Table size="small" sx={{ bgcolor: "#fff", border: `1px solid ${colors.line}`, borderRadius: 1 }}>
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ ...head, width: 60 }}>Rev</TableCell>
                      <TableCell sx={{ ...head, width: 200 }}>Status</TableCell>
                      <TableCell sx={{ ...head, width: 150 }}>Prepared by</TableCell>
                      <TableCell sx={{ ...head, width: 150 }}>Reviewed by</TableCell>
                      <TableCell sx={{ ...head, width: 150 }}>Approved by</TableCell>
                      <TableCell sx={{ ...head, width: 130 }}>Approved date</TableCell>
                      <TableCell sx={head}>Change summary</TableCell>
                      <TableCell sx={head}>Reason for change</TableCell>
                      <TableCell sx={{ ...head, width: 80 }} align="center">File</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {versions.map((v) => (
                      <TableRow key={v.versionID}>
                        <TableCell sx={{ fontWeight: 600 }}>{v.revisionNo}</TableCell>
                        <TableCell><StatusChip status={v.statusName} /></TableCell>
                        <TableCell>{v.editedBy}</TableCell>
                        <TableCell>{reviewedByName(v.statusName, v.reviewedBy, v.approvedBy)}</TableCell>
                        <TableCell>{approvedByName(v.statusName, v.approvedBy)}</TableCell>
                        <TableCell sx={{ whiteSpace: "nowrap" }}>{approvedDate(v.statusName, v.approvedBy, v.approvedOn)}</TableCell>
                        <TableCell><EllipsisText text={v.changeSummary} /></TableCell>
                        <TableCell><EllipsisText text={v.reasonForChange} /></TableCell>
                        <TableCell align="center">
                          <Tooltip title={`Download ${v.originalFileName || ""}`}>
                            <IconButton size="small" aria-label={`Download revision ${v.revisionNo} of ${row.documentNumber}`}
                              onClick={() => onDownload(v.versionID, v.originalFileName)}>
                              <FileDownloadOutlined fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </Box>
          </Collapse>
        </TableCell>
      </TableRow>
    </Fragment>
  );
}
