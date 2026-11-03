import { Box, Typography } from "@mui/material";

export default function EmptyState({ title, message, action }) {
  return (
    <Box sx={{ py: 7, px: 2, textAlign: "center" }}>
      <Typography variant="h3" sx={{ mb: 0.75 }}>{title}</Typography>
      {message && <Typography color="text.secondary" sx={{ mb: action ? 2.5 : 0, maxWidth: 460, mx: "auto" }}>{message}</Typography>}
      {action}
    </Box>
  );
}
