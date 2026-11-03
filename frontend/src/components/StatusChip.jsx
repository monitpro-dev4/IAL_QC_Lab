import { Chip } from "@mui/material";
import { colors } from "../theme";

const tone = {
  Draft: { fg: colors.inkSoft, bg: "#EEF1EF" },
  Submitted: { fg: colors.amber, bg: "#FBF1E1" },
  "Supervisor Approved": { fg: colors.amber, bg: "#FBF1E1" },
  Approved: { fg: colors.green, bg: "#E5F2EA" },
  Rejected: { fg: colors.red, bg: "#FBE7E6" },
  Superseded: { fg: colors.inkSoft, bg: "#EEF1EF" },
  Active: { fg: colors.green, bg: "#E5F2EA" },
  Inactive: { fg: colors.inkSoft, bg: "#EEF1EF" },
};

const label = {
  Submitted: "Waiting for supervisor",
  "Supervisor Approved": "Waiting for manager",
};

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
