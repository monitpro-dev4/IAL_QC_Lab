import { Chip } from "@mui/material";
import { colors } from "../theme";

const tone = {
  Draft: { fg: colors.inkSoft, bg: "#EEF1EF" },
  Submitted: { fg: colors.amber, bg: "#FBF1E1" },
  "Supervisor Approved": { fg: colors.amber, bg: "#FBF1E1" },
  Approved: { fg: colors.green, bg: "#E5F2EA" },
  Rejected: { fg: colors.red, bg: "#FBE7E6" },
  Superseded: { fg: colors.inkSoft, bg: "#EEF1EF" },
  Cancelled: { fg: "#7A4A4A", bg: "#F1E6E6" },
  Archived: { fg: "#36557F", bg: "#E6EDF6" },
  Active: { fg: colors.green, bg: "#E5F2EA" },
  Inactive: { fg: colors.inkSoft, bg: "#EEF1EF" },
};

const label = {
  Submitted: "Under Review",
  "Supervisor Approved": "Under Approval",
};

/** The label shown for a status, e.g. "Submitted" -> "Under Review". */
export const statusLabel = (status) => label[status] || status;

export default function StatusChip({ status, prefix }) {
  if (!status) return null;
  const t = tone[status] || tone.Draft;
  return (
    <Chip
      size="small"
      label={(prefix ? prefix + " " : "") + (label[status] || status)}
      sx={{ color: t.fg, bgcolor: t.bg, border: "none" }}
    />
  );
}
