import { Button } from "@mui/material";
import { Link } from "react-router-dom";
import EmptyState from "../components/EmptyState";

export default function NotFoundPage() {
  return (
    <EmptyState
      title="Page not found"
      message="The address may be wrong, or the page has moved."
      action={<Button variant="contained" component={Link} to="/dashboard">Go to the dashboard</Button>}
    />
  );
}
