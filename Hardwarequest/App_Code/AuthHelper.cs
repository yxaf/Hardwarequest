using System.Web;
using System.Web.Security;

namespace Hardwarequest
{
    // Wraps Forms Authentication + session so pages have one simple API.
    public static class AuthHelper
    {
        private const string RoleKey = "HQ_Role";
        private const string FullNameKey = "HQ_FullName";

        public static void SignIn(string username, string role, string fullName, bool persist = false)
        {
            FormsAuthentication.SetAuthCookie(username, persist);
            HttpContext.Current.Session[RoleKey] = role;
            HttpContext.Current.Session[FullNameKey] = fullName;
        }

        public static void SignOut()
        {
            var session = HttpContext.Current.Session;
            object introSeen = session["IntroSeen"];
            FormsAuthentication.SignOut();
            session.Clear();
            // Keep the visitor-intro flag so logging out doesn't replay the story.
            if (introSeen != null)
                session["IntroSeen"] = introSeen;
        }

        // The navbar greeting reads the display name from session (set at sign-in),
        // so a profile edit must refresh it or the old name sticks until re-login.
        public static void RefreshFullName(string fullName) =>
            HttpContext.Current.Session[FullNameKey] = fullName;

        public static bool IsLoggedIn =>
            HttpContext.Current.User?.Identity?.IsAuthenticated == true;

        public static string CurrentUsername =>
            IsLoggedIn ? HttpContext.Current.User.Identity.Name : null;

        // UserId of the logged-in user (null if signed out). Resolved once per request
        // and cached in HttpContext.Items so list pages don't re-query per row.
        public static int? CurrentUserId
        {
            get
            {
                if (!IsLoggedIn) return null;
                var items = HttpContext.Current.Items;
                const string key = "HQ_CurrentUserId";
                if (items.Contains(key)) return items[key] as int?;

                var user = new Hardwarequest.DataAccess.UserRepository().GetByUsername(CurrentUsername);
                int? id = user?.UserId;
                items[key] = id;
                return id;
            }
        }

        // Edit/delete permission: Administrators manage everything; everyone else
        // manages only items they created.
        public static bool CanManage(int? createdByUserId) =>
            IsInRole(Hardwarequest.Models.UserRole.Administrator) ||
            (CurrentUserId is int me && createdByUserId == me);

        public static string CurrentRole =>
            HttpContext.Current.Session?[RoleKey] as string;

        public static string CurrentFullName =>
            HttpContext.Current.Session?[FullNameKey] as string;

        public static bool IsInRole(string role) =>
            string.Equals(CurrentRole, role, System.StringComparison.Ordinal);

        // Staff = Lecturer or Administrator (can manage content).
        public static bool IsStaff =>
            IsInRole(Hardwarequest.Models.UserRole.Lecturer) ||
            IsInRole(Hardwarequest.Models.UserRole.Administrator);

        // Administrators only (manage hardware parts).
        public static bool IsAdmin =>
            IsInRole(Hardwarequest.Models.UserRole.Administrator);
    }
}
