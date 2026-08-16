using System;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Forum
{
    public partial class New : System.Web.UI.Page
    {
        private readonly ForumRepository _repo = new ForumRepository();
        private readonly UserRepository _users = new UserRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            // Posting requires login (reading does not).
            if (!AuthHelper.IsLoggedIn) Response.Redirect("~/Account/Login");
        }

        protected void btnPost_Click(object sender, EventArgs e)
        {
            if (!IsValid) return;

            User u = _users.GetByUsername(AuthHelper.CurrentUsername);
            if (u == null) { Response.Redirect("~/Account/Login"); return; }

            int threadId = _repo.CreateThread(u.UserId, txtTitle.Text.Trim(), txtBody.Text.Trim());
            Response.Redirect("~/Forum/Thread?id=" + threadId);
        }
    }
}
