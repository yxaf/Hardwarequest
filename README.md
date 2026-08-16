# HardwareQuest

A web application for learning computer hardware, built with ASP.NET Web Forms.
Students explore an interactive 3D PC build, read topic articles, take quizzes and
track their progress; lecturers author quizzes and monitor their students.

---

## Requirements

- Visual Studio 2022 or later, with the **ASP.NET and web development** workload
- .NET Framework 4.7.2 developer pack
- SQL Server LocalDB (installs with Visual Studio by default)

## Running the project

1. Open `Hardwarequest.slnx` in Visual Studio.
2. Press **F5** (or Ctrl+F5).

That is the whole setup. The database file is included in `Hardwarequest/App_Data/`
and is attached automatically by the connection string in `Web.config`, so there is
no database to create or script to run first. The NuGet `packages/` folder is also
included, so the project builds without needing to download anything.

The application opens at `http://localhost:<port>/` in IIS Express.

### Sign-in accounts

| Username | Password  | Role          |
|----------|-----------|---------------|
| `admin`  | `111`     | Administrator |
| `111`    | `111111`  | Lecturer      |
| `222`    | `222222`  | Lecturer      |
| `333`    | `333333`  | Student       |

Passwords are stored as salted PBKDF2-SHA256 hashes (100,000 iterations), never as
plain text — see `DataAccess/PasswordHasher.cs`. New accounts can be created through
the Register page.

Note: every restart of the application signs you out. Authentication tickets issued
before the current run are rejected on purpose (`Global.asax.cs`), so a fresh run
always begins logged out.

---

## Features by role

**Visitors** land on *Inside the Machine*, a guided introduction. All other areas
redirect to the login page.

**Students** can browse hardware components and topic articles, use the 3D Explorer,
take published quizzes, see their own results under *My Progress*, view the
leaderboard, and post in the forum.

**Lecturers** get the *Manage* hub: build and publish quizzes with the drag-and-drop
Quiz Builder, preview a quiz without affecting the leaderboard, review per-student
progress, see quiz statistics as charts, and manage topics and forum threads.

**Administrators** additionally manage user accounts and hardware components.

---

## Project layout

```
Hardwarequest.slnx            Solution file — open this
Hardwarequest/                The web application
  Account/                    Login, Logout, Register, Profile
  Admin/                      User management
  App_Code/                   AuthHelper (roles/sessions), ImageUpload
  App_Data/                   LocalDB database + schema.sql reference
  App_Start/                  Bundle and route configuration
  Content/                    Stylesheets, Bootstrap, uploaded images
  DataAccess/                 Repositories, PasswordHasher, DataSeeder
  Explore/                    3D Explorer and Inside the Machine
  Forum/                      Discussion threads
  Hardware/                   Component CRUD
  Manage/                     Lecturer hub, quiz statistics
  Models/                     Data classes
  Quiz/                       Builder, Take, Leaderboard, progress pages
  Scripts/                    JavaScript, incl. the 3D part models
  Topics/                     Article CRUD
  Site.Master                 Shared layout and navigation
  Web.config                  Connection string and app settings
packages/                     NuGet dependencies
```

## Technical notes

- **Data access** uses ADO.NET (`SqlConnection` / `SqlCommand`) with parameterised
  queries throughout. One repository class per entity in `DataAccess/`.
- **Schema** lives in `App_Data/schema.sql` for reference. At startup
  `Db.EnsureSchema()` applies later column additions to an existing database and
  `DataSeeder.SeedIfEmpty()` populates demo content when the database is empty.
- **The 3D Explorer** (`Explore/Explorer.aspx`) renders PC components with WebGL;
  the part geometry is defined in `Scripts/partmodels.js`.
- **Internet connection**: the quiz statistics charts (Chart.js) and the web fonts
  load from CDNs. Without a connection those charts will not render, but every other
  page works offline.
