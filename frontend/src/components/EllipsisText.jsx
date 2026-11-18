import { Tooltip, Typography } from "@mui/material";

/**
 * One line of text that is cut off with "…" (ellipsis) when it is too long;
 * the full text shows on hover. Used for Remarks, Change summary and Reason for change.
 */
export default function EllipsisText({ text, maxWidth = 200 }) {
  if (!text) return null;
  return (
    <Tooltip title={text} placement="top-start">
      <Typography variant="body2" noWrap sx={{ maxWidth }}>{text}</Typography>
    </Tooltip>
  );
}
