import { Box } from "@mui/material";
import { colors } from "../theme";

/** App mark: a lab flask on a teal tile. */
export default function BrandMark({ size = 36, sx }) {
  return (
    <Box
      aria-hidden="true"
      sx={{
        width: size, height: size, borderRadius: size * 0.28, flexShrink: 0, display: "grid", placeItems: "center",
        background: `linear-gradient(140deg, ${colors.tealBright}, ${colors.teal})`, ...sx,
      }}
    >
      <svg width={size * 0.56} height={size * 0.56} viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M9 3h6M10 3v6l-5.2 8.6A2 2 0 0 0 6.5 21h11a2 2 0 0 0 1.7-3.4L14 9V3" />
        <path d="M7.5 15h9" />
      </svg>
    </Box>
  );
}
