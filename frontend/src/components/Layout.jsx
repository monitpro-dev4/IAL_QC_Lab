import { useEffect, useState } from "react";
import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import {
  AppBar, Avatar, Box, Divider, Drawer, IconButton, ListItemIcon, Menu, MenuItem, Toolbar, Typography, useMediaQuery,
} from "@mui/material";
import { useTheme } from "@mui/material/styles";
import MenuIcon from "@mui/icons-material/Menu";
import SpaceDashboardOutlined from "@mui/icons-material/SpaceDashboardOutlined";
import DescriptionOutlined from "@mui/icons-material/DescriptionOutlined";
import PeopleOutline from "@mui/icons-material/PeopleOutlined";
import KeyOutlined from "@mui/icons-material/KeyOutlined";
import LogoutOutlined from "@mui/icons-material/LogoutOutlined";
import UnfoldMore from "@mui/icons-material/UnfoldMore";
import ScienceOutlined from "@mui/icons-material/ScienceOutlined";
import BuildCircleOutlined from "@mui/icons-material/BuildCircleOutlined";
import { useAuth } from "../auth/AuthContext";
import { colors } from "../theme";
import BrandMark from "./BrandMark";

const DRAWER = 256;

export const initials = (name = "") =>
  name.split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0].toUpperCase()).join("") || "?";

function NavItem({ to, label, icon, badge, end, soon }) {
  return (
    <Box
      component={NavLink}
      to={to}
      end={end}
      sx={{
        display: "flex", alignItems: "center", gap: 1.5, px: 1.5, py: 1.1, mb: 0.5, borderRadius: 2.5,
        color: colors.navyText, textDecoration: "none", fontSize: "0.9375rem", fontWeight: 500, position: "relative",
        transition: "background-color .15s, color .15s",
        "& svg": { fontSize: 21 },
        "&:hover": { bgcolor: colors.navySoft, color: "#E6EDF5" },
        "&.active": {
          bgcolor: "rgba(44, 197, 184, 0.14)", color: "#fff", fontWeight: 600,
          "& svg": { color: colors.tealBright },
        },
      }}
    >
      {icon}
      <Box component="span" sx={{ flexGrow: 1 }}>{label}</Box>
      {soon && (
        <Box component="span" sx={{ fontSize: 11, fontWeight: 600, px: 0.9, py: 0.25, borderRadius: 1.5, bgcolor: "rgba(255,255,255,0.08)", color: colors.navyText }}>
          Soon
        </Box>
      )}
      {badge > 0 && (
        <Box component="span" aria-label={`${badge} waiting`} sx={{
          minWidth: 22, height: 22, px: 0.75, borderRadius: 11, bgcolor: colors.amber, color: "#fff",
          fontSize: 12, fontWeight: 700, display: "grid", placeItems: "center",
        }}>
          {badge}
        </Box>
      )}
    </Box>
  );
}

export default function Layout() {
  const { user, signOut, isAdmin } = useAuth();
  const theme = useTheme();
  const wide = useMediaQuery(theme.breakpoints.up("md"));
  const [open, setOpen] = useState(false);
  const [menu, setMenu] = useState(null);
  const location = useLocation();
  const navigate = useNavigate();
  const forced = user.mustChangePassword;

  useEffect(() => setOpen(false), [location.pathname]);

  const main = [
    { to: "/documents", label: "Documents", icon: <DescriptionOutlined />, show: true, end: true },
  ].filter((i) => i.show && !forced);
  const admin = [
    { to: "/users", label: "Users", icon: <PeopleOutline /> },
  ].filter(() => isAdmin && !forced);

  const doSignOut = async () => { setMenu(null); await signOut(); navigate("/signin"); };

  const nav = (
    <Box sx={{ display: "flex", flexDirection: "column", height: "100%", bgcolor: colors.navy, color: "#fff" }}>
      <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, px: 2.5, pt: 3, pb: 3 }}>
        <BrandMark size={36} />
        <Box>
          <Typography sx={{ fontWeight: 700, fontSize: "1.0625rem", lineHeight: 1.2, color: "#fff" }}>IAL QC Lab</Typography>
          <Typography sx={{ fontSize: "0.8125rem", color: colors.navyText }}>QC Laboratory</Typography>
        </Box>
      </Box>

      <Box component="nav" aria-label="Main" sx={{ px: 1.5, flexGrow: 1, overflowY: "auto" }}>
        {!forced && (
          <>
            <NavItem to="/dashboard" label="Dashboard" icon={<SpaceDashboardOutlined />} />
            <NavItem to="/sample-register" label="Sample Request" icon={<ScienceOutlined />} />
            <NavItem to="/calibration" label="Calibration & PM" icon={<BuildCircleOutlined />} />
          </>
        )}
        {main.map((i) => <NavItem key={i.to} {...i} />)}
        {admin.length > 0 && (
          <>
            {admin.map((i) => <NavItem key={i.to} {...i} />)}
          </>
        )}
      </Box>

      <Box sx={{ p: 1.5 }}>
        <Box
          component="button"
          onClick={(e) => setMenu(e.currentTarget)}
          aria-haspopup="menu"
          aria-label="Account menu"
          sx={{
            width: "100%", display: "flex", alignItems: "center", gap: 1.25, p: 1.25, border: 0, borderRadius: 2.5,
            bgcolor: colors.navySoft, color: "#fff", cursor: "pointer", textAlign: "left", font: "inherit",
            "&:hover": { bgcolor: "#1D3248" },
          }}
        >
          <Avatar sx={{ width: 36, height: 36, bgcolor: colors.tealBright, color: colors.navy, fontSize: 14, fontWeight: 700 }}>
            {initials(user.name)}
          </Avatar>
          <Box sx={{ flexGrow: 1, minWidth: 0 }}>
            <Typography noWrap sx={{ fontWeight: 600, fontSize: "0.875rem", color: "#fff" }}>{user.name}</Typography>
            <Typography noWrap sx={{ fontSize: "0.75rem", color: colors.navyText }}>{user.roles.join(", ")}</Typography>
          </Box>
          <UnfoldMore sx={{ fontSize: 18, color: colors.navyText }} />
        </Box>
      </Box>
    </Box>
  );

  return (
    <Box sx={{ display: "flex", minHeight: "100vh" }}>
      {wide ? (
        <Drawer variant="permanent" sx={{ width: DRAWER, flexShrink: 0, "& .MuiDrawer-paper": { width: DRAWER, border: "none", borderRadius: 0, boxShadow: "none" } }}>
          {nav}
        </Drawer>
      ) : (
        <>
          <AppBar position="fixed" elevation={0} sx={{ bgcolor: colors.navy, borderRadius: 0 }}>
            <Toolbar>
              <IconButton edge="start" onClick={() => setOpen(true)} aria-label="Open menu" sx={{ color: "#fff" }}><MenuIcon /></IconButton>
              <BrandMark size={28} sx={{ ml: 1 }} />
              <Typography sx={{ fontWeight: 700, ml: 1.25 }}>IAL QC Lab</Typography>
            </Toolbar>
          </AppBar>
          <Drawer open={open} onClose={() => setOpen(false)} sx={{ "& .MuiDrawer-paper": { width: DRAWER, border: "none", borderRadius: 0 } }}>
            {nav}
          </Drawer>
        </>
      )}

      <Menu
        anchorEl={menu}
        open={!!menu}
        onClose={() => setMenu(null)}
        anchorOrigin={{ vertical: "top", horizontal: "right" }}
        transformOrigin={{ vertical: "bottom", horizontal: "left" }}
        slotProps={{ paper: { sx: { minWidth: 220, ml: 1 } } }}
      >
        <Box sx={{ px: 2, py: 1.25 }}>
          <Typography sx={{ fontWeight: 600 }}>{user.name}</Typography>
          <Typography variant="body2" color="text.secondary">{user.userName}</Typography>
        </Box>
        <Divider />
        {!forced && (
          <MenuItem onClick={() => { setMenu(null); navigate("/change-password"); }}>
            <ListItemIcon><KeyOutlined fontSize="small" /></ListItemIcon>Change password
          </MenuItem>
        )}
        <MenuItem onClick={doSignOut}>
          <ListItemIcon><LogoutOutlined fontSize="small" /></ListItemIcon>Sign out
        </MenuItem>
      </Menu>

      <Box component="main" sx={{ flexGrow: 1, minWidth: 0, px: { xs: 2, md: 3 }, py: { xs: 10, md: 3 } }}>
        <Box>
          <Outlet />
        </Box>
      </Box>
    </Box>
  );
}
