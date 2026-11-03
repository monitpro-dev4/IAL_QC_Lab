import { Fragment, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Alert, Box, Button, Collapse, IconButton, LinearProgress, Paper, Table, TableBody, TableCell, TableContainer,
  TableHead, TablePagination, TableRow, TextField, Tooltip, Typography,
} from "@mui/material";
import FileDownloadOutlined from "@mui/icons-material/FileDownloadOutlined";
import EditOutlined from "@mui/icons-material/EditOutlined";
import KeyboardArrowDown from "@mui/icons-material/KeyboardArrowDown";
import KeyboardArrowUp from "@mui/icons-material/KeyboardArrowUp";
import AddIcon from "@mui/icons-material/Add";
import { useSnackbar } from "notistack";
import { useAuth } from "../auth/AuthContext";
import { getDocuments, getHistory, openFile } from "../api/documentApi";
import PageHeader from "../components/PageHeader";
import StatusChip from "../components/StatusChip";
import EmptyState from "../components/EmptyState";
import AddDocumentDialog from "../components/AddDocumentDialog";
import DocumentEditDialog from "../components/DocumentEditDialog";
import { colors } from "../theme";
import { approvedByName } from "../format";

const COLUMNS = 8;   // arrow, S.No, Doc.No., Title, Uploaded by, Approved by, Status, Action
const head = { fontWeight: 600, color: "text.secondary", whiteSpace: "nowrap" };

export default function DocumentListPage() {
  const { canEditDocuments } = useAuth();
  const { enqueueSnackbar } = useSnackbar();
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [query, setQuery] = useState("");
  const [adding, setAdding] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [refresh, setRefresh] = useState(0);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(25);
  // People who work on documents see every document with its latest revision;
  // everyone else sees only the approved versions
  const view = canEditDocuments ? "all" : "approved";

  // Search runs 300 ms after typing stops
  useEffect(() => {
    const t = setTimeout(() => { setQuery(search.trim()); setPage(0); }, 300);
    return () => clearTimeout(t);
  }, [search]);

  useEffect(() => {
    setLoading(true);
    setError("");
    getDocuments({ search: query, approvedOnly: view === "approved" })
      .then(setRows)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [query, view, refresh]);

  const download = (versionID, fileName) =>
    openFile(versionID, fileName, true).catch((err) => enqueueSnackbar(err.message, { variant: "error" }));

  const shown = rows.slice(page * pageSize, page * pageSize + pageSize);

  return (
    <>
      <PageHeader
        title="Documents"
        actions={canEditDocuments && (
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setAdding(true)}>Add document</Button>
        )}
      />

      <Box sx={{ display: "flex", gap: 1.5, mb: 2, flexWrap: "wrap", alignItems: "center" }}>
        <TextField
          placeholder="Search number or title"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          sx={{ width: { xs: "100%", sm: 280 }, bgcolor: "#fff" }}
          slotProps={{ htmlInput: { "aria-label": "Search documents" } }}
        />
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Paper sx={{ overflow: "hidden" }}>
        {loading && <LinearProgress />}
        {!loading && rows.length === 0 ? (
          query ? (
            <EmptyState title="No documents match" message="Try a different number or title." />
          ) : (
            <EmptyState
              title={view === "approved" ? "No approved documents yet" : "No documents yet"}
              message={view === "approved" ? "Documents appear here once the Lab Manager approves them." : "Add the first document to start."}
              action={canEditDocuments && <Button variant="contained" onClick={() => setAdding(true)}>Add document</Button>}
            />
          )
        ) : (
          <>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ width: 56 }} />
                    <TableCell sx={{ ...head, width: 70 }} align="center">S.No</TableCell>
                    <TableCell sx={{ ...head, width: 150 }}>Doc.No.</TableCell>
                    <TableCell sx={head}>Title</TableCell>
                    <TableCell sx={{ ...head, width: 170 }}>Uploaded by</TableCell>
                    <TableCell sx={{ ...head, width: 170 }}>Approved by</TableCell>
                    <TableCell sx={{ ...head, width: 200 }}>Status</TableCell>
                    <TableCell sx={{ ...head, width: 110 }} align="center">Action</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
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
              count={rows.length}
              page={page}
              onPageChange={(_, p) => setPage(p)}
              rowsPerPage={pageSize}
              onRowsPerPageChange={(e) => { setPageSize(parseInt(e.target.value, 10)); setPage(0); }}
              rowsPerPageOptions={[25, 50, 100]}
            />
          </>
        )}
      </Paper>
      <AddDocumentDialog open={adding} onClose={() => setAdding(false)} onAdded={() => setRefresh((n) => n + 1)} />
      <DocumentEditDialog open={!!editingId} documentId={editingId} onClose={() => setEditingId(null)} onChanged={() => setRefresh((n) => n + 1)} />
    </>
  );
}

/** One document, with a down arrow that opens all its revisions underneath. */
function DocumentRow({ row, sno, canEdit, onDownload, onEdit }) {
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [versions, setVersions] = useState(null);
  const [error, setError] = useState("");

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
        <TableCell sx={{ fontWeight: 600 }}>{row.documentNumber}</TableCell>
        <TableCell>{row.title}</TableCell>
        <TableCell>{row.editedBy}</TableCell>
        <TableCell>{approvedByName(row.versionStatus, row.approvedBy, row.reviewedBy)}</TableCell>
        <TableCell><StatusChip status={row.versionStatus} /></TableCell>
        <TableCell align="center" sx={{ whiteSpace: "nowrap" }} onClick={(e) => e.stopPropagation()}>
          {row.versionID && (
            <Tooltip title="Download">
              <IconButton size="small" aria-label={`Download ${row.documentNumber}`} onClick={() => onDownload(row.versionID, row.originalFileName)}>
                <FileDownloadOutlined fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
          {canEdit && (
            <Tooltip title="Edit">
              <IconButton size="small" aria-label={`Edit ${row.documentNumber}`} onClick={onEdit}>
                <EditOutlined fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
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
                      <TableCell sx={{ ...head, width: 170 }}>Uploaded by</TableCell>
                      <TableCell sx={{ ...head, width: 170 }}>Approved by</TableCell>
                      <TableCell sx={head}>What changed</TableCell>
                      <TableCell sx={{ ...head, width: 80 }} align="center">File</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {versions.map((v) => (
                      <TableRow key={v.versionID}>
                        <TableCell sx={{ fontWeight: 600 }}>{v.revisionNo}</TableCell>
                        <TableCell><StatusChip status={v.statusName} /></TableCell>
                        <TableCell>{v.editedBy}</TableCell>
                        <TableCell>{approvedByName(v.statusName, v.approvedBy, v.reviewedBy)}</TableCell>
                        <TableCell>{v.changeSummary}</TableCell>
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
