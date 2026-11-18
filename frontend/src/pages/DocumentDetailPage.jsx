import { useCallback, useEffect, useState } from "react";
import { Link as RouterLink, useParams } from "react-router-dom";
import {
  Alert, Box, Button, CircularProgress, Divider, Link, Paper, Stack, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Typography,
} from "@mui/material";
import ArrowBack from "@mui/icons-material/ArrowBack";
import { useSnackbar } from "notistack";
import { useAuth } from "../auth/AuthContext";
import {
  createRevision, decideRevision, getDocument, openFile, getHistory, submitRevision, updateRevision,
} from "../api/documentApi";
import ApprovalTrack from "../components/ApprovalTrack";
import StatusChip from "../components/StatusChip";
import DecisionDialog from "../components/DecisionDialog";
import RevisionDialog from "../components/RevisionDialog";
import { approvedByName, approvedDate, reviewedByName, reviewedDate, fmtDate, fmtDateTime, fmtSize } from "../format";
import EllipsisText from "../components/EllipsisText";
import { colors } from "../theme";

function Field({ label, children }) {
  return (
    <Box>
      <Typography variant="body2" color="text.secondary">{label}</Typography>
      <Typography sx={{ fontWeight: 500 }}>{children || "—"}</Typography>
    </Box>
  );
}

function FileLinks({ versionID, name, size }) {
  const { enqueueSnackbar } = useSnackbar();
  const open = (download) => openFile(versionID, name, download).catch((e) => enqueueSnackbar(e.message, { variant: "error" }));
  const isPdf = /\.pdf$/i.test(name || "");
  return (
    <Stack direction="row" spacing={1} sx={{ alignItems: "center", flexWrap: "wrap" }}>
      <Typography variant="body2" sx={{ wordBreak: "break-all", mr: 1 }}>{name}{size ? ` (${fmtSize(size)})` : ""}</Typography>
      {isPdf && <Button size="small" variant="outlined" onClick={() => open(false)}>View</Button>}
      <Button size="small" variant={isPdf ? "text" : "outlined"} onClick={() => open(true)}>Download</Button>
    </Stack>
  );
}

const ACTION_LABEL = {
  Created: "Created", Updated: "Revised", Submitted: "Submitted", Approved: "Approved", Rejected: "Rejected", Superseded: "Superseded",
};

export default function DocumentDetailPage() {
  const { id } = useParams();
  const { user, canEditDocuments, isSupervisor, isManager } = useAuth();
  const { enqueueSnackbar } = useSnackbar();
  const [doc, setDoc] = useState(null);
  const [history, setHistory] = useState(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [decision, setDecision] = useState(null);      // "Approved" | "Rejected"
  const [revisionMode, setRevisionMode] = useState(null); // "new" | "edit"

  const load = useCallback(async () => {
    try {
      const [d, h] = await Promise.all([getDocument(id), getHistory(id)]);
      if (d.errorMessage) throw new Error(d.errorMessage);
      setDoc(d);
      setHistory(h);
      setError("");
    } catch (e) {
      setError(e.message);
    }
  }, [id]);

  useEffect(() => { load(); }, [load]);

  const run = async (fn, successMessage) => {
    setBusy(true);
    try {
      await fn();
      enqueueSnackbar(successMessage, { variant: "success" });
      setDecision(null);
      setRevisionMode(null);
      await load();
    } catch (e) {
      enqueueSnackbar(e.message, { variant: "error" });
    } finally {
      setBusy(false);
    }
  };

  if (error) return <><BackLink /><Alert severity="error">{error}</Alert></>;
  if (!doc) return <Box sx={{ display: "grid", placeItems: "center", py: 10 }}><CircularProgress /></Box>;

  const cur = doc.currentVersion;
  const pen = doc.pendingVersion;
  const active = doc.isActive === "Y";
  const mine = pen && pen.editedByUserID === user.userID;
  const lastRejection = pen && history?.log.find((l) => l.revisionNo === pen.revisionNo && l.actionType === "Rejected");

  const canSupervise = pen && pen.statusName === "Submitted" && isSupervisor;
  const canManage = pen && pen.statusName === "Supervisor Approved" && isManager;
  const canRevise = active && canEditDocuments && pen && (pen.statusName === "Draft" || pen.statusName === "Rejected");
  const canSubmit = active && canEditDocuments && pen && pen.statusName === "Draft";
  // any time (a waiting or rejected revision is kept as Superseded), but not while the document is archived
  const canNewRevision = active && canEditDocuments && cur?.statusName !== "Archived";
  const docLabel = `${doc.documentNumber}, ${doc.title}${pen ? `, revision ${pen.revisionNo}` : ""}`;

  return (
    <>
      <BackLink />

      <Box sx={{ display: "flex", gap: 2, alignItems: "flex-start", flexWrap: "wrap", mb: 3 }}>
        <Box sx={{ flexGrow: 1, minWidth: 0 }}>
          <Typography sx={{ fontWeight: 600, color: colors.teal, letterSpacing: "0.02em" }}>{doc.documentNumber}</Typography>
          <Typography variant="h1" sx={{ mt: 0.25 }}>{doc.title}</Typography>
          <Typography color="text.secondary" sx={{ mt: 0.5 }}>
            {cur ? `Current revision ${cur.revisionNo}` : "Not approved yet"}
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          {canNewRevision && <Button variant="contained" onClick={() => setRevisionMode("new")}>Upload new revision</Button>}
        </Stack>
      </Box>


      <Paper sx={{ overflow: "hidden" }}>
        <Typography variant="h2" sx={{ px: { xs: 2, sm: 3 }, py: 2, borderBottom: `1px solid ${colors.line}` }}>
          Revisions ({history?.versions.length ?? 0})
        </Typography>
        {(
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Rev</TableCell><TableCell>Status</TableCell>
                  <TableCell>Prepared by</TableCell><TableCell>Prepared date</TableCell>
                  <TableCell>Reviewed by</TableCell><TableCell>Reviewed date</TableCell>
                  <TableCell>Approved by</TableCell><TableCell>Approved date</TableCell><TableCell>Change summary</TableCell><TableCell>Reason for change</TableCell><TableCell>File</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {history?.versions.map((v) => (
                  <TableRow key={v.versionID}>
                    <TableCell sx={{ fontWeight: 600 }}>{v.revisionNo}</TableCell>
                    <TableCell><StatusChip status={v.statusName} /></TableCell>
                    <TableCell>{v.editedBy}</TableCell>
                    <TableCell sx={{ whiteSpace: "nowrap" }}>{fmtDate(v.createdOn)}</TableCell>
                    <TableCell>{reviewedByName(v.statusName, v.reviewedBy, v.approvedBy)}</TableCell>
                    <TableCell sx={{ whiteSpace: "nowrap" }}>{reviewedDate(v.statusName, v.approvedBy, v.reviewedOn)}</TableCell>
                    <TableCell>{approvedByName(v.statusName, v.approvedBy)}</TableCell>
                    <TableCell sx={{ whiteSpace: "nowrap" }}>{approvedDate(v.statusName, v.approvedBy, v.approvedOn)}</TableCell>
                    <TableCell><EllipsisText text={v.changeSummary} /></TableCell>
                    <TableCell><EllipsisText text={v.reasonForChange} /></TableCell>
                    <TableCell>
                      <Link component="button" variant="body2"
                        onClick={() => openFile(v.versionID, v.originalFileName).catch((e) => enqueueSnackbar(e.message, { variant: "error" }))}>
                        Open
                      </Link>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Paper>

      <DecisionDialog
        open={!!decision}
        action={decision}
        documentLabel={docLabel}
        busy={busy}
        onCancel={() => setDecision(null)}
        onConfirm={(comments) => run(
          () => decideRevision(pen.versionID, decision, user.userID, comments),
          decision === "Rejected" ? "Revision rejected and sent back" : canManage ? "Approved. This is now the current version." : "Approved and sent to the Lab Manager"
        )}
      />

      <RevisionDialog
        open={!!revisionMode}
        mode={revisionMode}
        initialTitle={doc.title}
        initialSummary={revisionMode === "edit" ? pen?.changeSummary : ""}
        busy={busy}
        onCancel={() => setRevisionMode(null)}
        onSave={({ file, title, summary, reason }) => run(
          () => revisionMode === "new"
            ? createRevision({ documentID: doc.documentID, changeSummary: summary, reasonForChange: reason, userID: user.userID, file })
                .then((res) => submitRevision(res.id, user.userID))
            : updateRevision({ versionID: pen.versionID, title, changeSummary: summary, userID: user.userID, file }),
          revisionMode === "new" ? "New revision sent to the Lab Supervisor" : "Revision saved as draft"
        )}
      />
    </>
  );
}

function BackLink() {
  return (
    <Button component={RouterLink} to="/documents" startIcon={<ArrowBack />} sx={{ mb: 2, ml: -1 }}>
      Documents
    </Button>
  );
}
