import { Box } from "@mui/material";
import DescriptionOutlined from "@mui/icons-material/DescriptionOutlined";
import ScienceOutlined from "@mui/icons-material/ScienceOutlined";
import BuildCircleOutlined from "@mui/icons-material/BuildCircleOutlined";
import { colors } from "../theme";

const ICONS = { documents: DescriptionOutlined, samples: ScienceOutlined, calibration: BuildCircleOutlined };
export const TONES = {
  teal: { fg: colors.teal, bg: colors.tealTint },
  amber: { fg: colors.amber, bg: colors.amberTint },
  blue: { fg: "#2F5FA7", bg: "#E6EEF9" },
};

export default function ModuleIcon({ moduleKey, tone = "teal", size = 52 }) {
  const Icon = ICONS[moduleKey] || DescriptionOutlined;
  const t = TONES[tone] || TONES.teal;
  return (
    <Box aria-hidden="true" sx={{ width: size, height: size, borderRadius: size * 0.3, bgcolor: t.bg, color: t.fg, display: "grid", placeItems: "center", flexShrink: 0 }}>
      <Icon sx={{ fontSize: size * 0.52 }} />
    </Box>
  );
}
