# IAL QC Lab Application

Web application for the Indian Additives Limited (IAL) QC Lab, with three modules:
Sample Register, Lab Calibration & PM Schedule, and Document Management.

## Folder structure

| Folder | Purpose |
| --- | --- |
| `frontend/` | User interface (web pages, components, styles) |
| `backend/` | Server-side code: APIs, business logic, notifications, authentication |
| `database/migrations/` | Scripts that create and change tables, run in order |
| `database/seeds/` | Starter data: plants, roles, sample types, test users |
| `database/scripts/` | One-off scripts: data import, backups, reports |

Project documents (requirements, design, test cases, manuals) live in `../doc/`.

## Tech stack

| Layer | Technology |
| --- | --- |
| Database | SQL Server 2022 (database `IAL_QC`), stored procedures only |
| Backend | ASP.NET Core Web API, .NET 10 - Controller / DAL / Model |
| Frontend | React 18 + Vite, Material UI, MUI DataGrid, notistack, axios |

## Run the backend

1. Database: run the scripts in `database/` in folder order
   (01_Database, 02_Tables, 05_Changes, 03_StoredProcedures, 04_SeedData).
   The scripts are safe to run again, so after pulling new changes just run them all in this order.
2. Check `backend/IAL_QC_API/appsettings.json`:
   - `ConnectionStrings:Conn` - SQL Server connection
   - `FileSettings:DocumentRoot` - folder where uploaded documents are saved
   - `AllowedOrigins` - frontend URL(s)
3. Open `backend/IAL_QC.sln` in Visual Studio and press F5,
   or run `dotnet run --project backend/IAL_QC_API`.
4. Swagger (API test page): http://localhost:5080/swagger

## Backend structure (`backend/IAL_QC_API`)

| Folder | Purpose |
| --- | --- |
| `Controllers/` | API endpoints: `UserController`, `MasterController`, `DocumentController` |
| `DAL/` | Calls the stored procedures (one class per area) |
| `Model/` | Request / response classes |
| `Helpers/FileStorage.cs` | Saves, finds and deletes uploaded document files |

## Run the frontend

1. Start the backend first (above).
2. In `frontend/`: `npm install`, then `npm run dev`.
3. Open http://localhost:5173. In development, `/api` calls are forwarded to the
   backend on port 5080 (see `vite.config.js`).
4. First run on an empty database: the sign-in page asks you to create the
   Administrator (name, username, password). Then sign in and add users from Users.

## Sign-in and security

- Username + password. Passwords are stored as BCrypt hashes, never as text.
- The admin gives each new user a first password; they must change it at first sign-in.
  "Reset password" on the Users page does the same and signs the user out everywhere.
- 5 wrong passwords lock the account for 15 minutes (an admin reset unlocks it).
- Users stay signed in until they click Sign out. A sign out, password change or reset,
  or deactivating the user ends the session immediately.
- Every API call needs the login token; the user is always taken from the token,
  never from the request. Users, roles and categories: Administrator only.
  Draft / in-review files: document staff only (Chemist, Supervisor, Manager, QA, Admin).
- Swagger: sign in with `api/Auth/Login`, then click Authorize and paste the token.

For the IAL server: set `VITE_API_URL` in `frontend/.env.production`, then `npm run build`
and host the `dist/` folder.

Note: `frontend/.npmrc` sets `include=dev`, because this PC has `NODE_ENV=production`
set system-wide, which otherwise makes npm skip Vite.

## Frontend structure (`frontend/src`)

| Folder / file | Purpose |
| --- | --- |
| `api/` | One file per area (`documentApi`, `userApi`, `masterApi`), all through `client.js` |
| `auth/AuthContext.jsx` | Signed-in user and role checks (`isSupervisor`, `canEditDocuments`, ...) |
| `pages/` | Documents, document detail, add document, waiting for me, users, categories, sign-in |
| `components/` | Layout, approval track, status chip, file picker, dialogs |
| `theme.js` | Colours and type: teal = actions, amber = in progress, green = approved, red = rejected |

Tests: `database/06_Tests` (SQL, rolled back) and `backend/tests/Api_Smoke_Test.ps1` (run against a test database).
