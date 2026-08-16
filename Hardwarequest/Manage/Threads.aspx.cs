using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Manage
{
    public partial class Threads : System.Web.UI.Page
    {
        private readonly ForumRepository _repo = new ForumRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AuthHelper.IsStaff) { Response.Redirect("~/Default"); return; }
            if (!IsPostBack) Bind();
        }

        private void Bind()
        {
            bool isAdmin = AuthHelper.IsInRole(UserRole.Administrator);
            var items = _repo.GetThreadsForManager(AuthHelper.CurrentUserId, isAdmin);
            rpt.DataSource = items;
            rpt.DataBind();
            lblEmpty.Visible = items.Count == 0;
        }

        protected void rpt_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
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
