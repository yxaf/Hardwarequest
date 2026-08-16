using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Hardwarequest
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Show a Back button on every page except the Home page, and point it
            // at a logical destination (the current section's landing page) instead
            // of relying on browser history.
            string path = TrimAspx(Request.AppRelativeCurrentExecutionFilePath ?? "");
            phBack.Visible = !path.Equals("~/", StringComparison.OrdinalIgnoreCase)
                          && !path.Equals("~/Default", StringComparison.OrdinalIgnoreCase);
            lnkBack.NavigateUrl = GetBackTarget(path);

            bool loggedIn = AuthHelper.IsLoggedIn;
            phAnon.Visible = !loggedIn;
            phUser.Visible = loggedIn;
            phMember.Visible = loggedIn;
            phStaff.Visible = AuthHelper.IsStaff;
            // Same nav slot, role-dependent target: students track themselves,
            // staff monitor students. (Both sit inside phMember, so anonymous
            // visitors never see either.)
            phNavMyProgress.Visible = !AuthHelper.IsStaff;
            phNavStudentProgress.Visible = AuthHelper.IsStaff;
            phAdmin.Visible = AuthHelper.IsInRole(Hardwarequest.Models.UserRole.Administrator);
            if (loggedIn)
                lnkHello.Text = "Hi, " + (AuthHelper.CurrentFullName ?? AuthHelper.CurrentUsername) + "!";
        }

        /// <summary>
        /// Maps the current page to the page its Back button should return to.
        /// Inner pages (Details/Create/Edit/Take/...) go to their section's landing
        /// page; a section's landing page and any top-level page go Home.
        /// </summary>
        private static string GetBackTarget(string appPath)
        {
            string p = appPath.StartsWith("~/") ? appPath.Substring(2) : appPath;
            string[] parts = p.Split('/');
            if (parts.Length < 2)
                return "~/Default"; // top-level page (e.g. ~/SomePage)

            string folder = parts[0];
            string file = parts[parts.Length - 1];

            // The quiz Builder is reached from the Manage hub, so Back returns there.
            if (folder.Equals("quiz", StringComparison.OrdinalIgnoreCase) &&
                file.Equals("Builder", StringComparison.OrdinalIgnoreCase))
                return "~/Manage/Quizzes";

            string landing;
            switch (folder.ToLowerInvariant())
            {
                case "hardware": landing = "List"; break;
                case "topics": landing = "List"; break;
                case "quiz": landing = "List"; break;
                case "forum": landing = "List"; break;
                case "manage": landing = "Default"; break;
                case "admin": landing = "ManageUsers"; break;
                default: return "~/Default"; // Account, Explore, etc.
            }

            // Already on the section landing page -> go Home instead of pointing at self.
            if (file.Equals(landing, StringComparison.OrdinalIgnoreCase))
                return "~/Default";

            return "~/" + folder + "/" + landing;
        }

        // FriendlyUrls serves pages without their .aspx extension, so path
        // comparisons must work on the extensionless name.
        private static string TrimAspx(string path)
        {
            return path.EndsWith(".aspx", StringComparison.OrdinalIgnoreCase)
                ? path.Substring(0, path.Length - 5)
                : path;
        }
    }
}