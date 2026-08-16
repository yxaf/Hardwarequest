using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;

namespace Hardwarequest.Forum
{
    public partial class List : System.Web.UI.Page
    {
        private readonly ForumRepository _repo = new ForumRepository();

        // Exposed to the markup data-binding expressions.
        protected bool IsStaff => AuthHelper.IsStaff;

        protected void Page_Load(object sender, EventArgs e)
        {
            // Reading is public; only logged-in users see the "start" button.
            phNew.Visible = AuthHelper.IsLoggedIn;
            pnlLoginHint.Visible = !AuthHelper.IsLoggedIn;
            if (!IsPostBack) Bind();
        }

        private void Bind()
        {
            var items = _repo.GetAllThreads();
            rptThreads.DataSource = items;
            rptThreads.DataBind();
            lblEmpty.Visible = items.Count == 0;
        }

        // Whether the current user may delete this thread (admin or its author).
        protected bool CanManage(object createdByUserId) =>
            AuthHelper.CanManage(createdByUserId as int?);

        protected void rptThreads_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            // Re-check ownership server-side (the button is only hidden, not secured).
            if (e.CommandName == "DeleteThread")
            {
                int id = int.Parse((string)e.CommandArgument);
                var thread = _repo.GetThreadById(id);
                if (thread != null && AuthHelper.CanManage(thread.CreatedByUserId))
                {
                    _repo.DeleteThread(id);
                    Bind();
                }
            }
        }
    }
}
