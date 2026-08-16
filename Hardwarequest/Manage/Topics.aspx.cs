using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Manage
{
    public partial class TopicsManage : System.Web.UI.Page
    {
        private readonly TopicRepository _repo = new TopicRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AuthHelper.IsStaff) { Response.Redirect("~/Default"); return; }
            if (!IsPostBack) Bind();
        }

        private void Bind()
        {
            bool isAdmin = AuthHelper.IsInRole(UserRole.Administrator);
            var items = _repo.GetTopicsForManager(AuthHelper.CurrentUserId, isAdmin);
            rpt.DataSource = items;
            rpt.DataBind();
            lblEmpty.Visible = items.Count == 0;
        }

        protected string OwnerLabel(object ownerName)
        {
            string n = ownerName as string;
            return string.IsNullOrEmpty(n) ? "" : "by " + Server.HtmlEncode(n);
        }

        protected void rpt_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "DeleteTopic")
            {
                int id = int.Parse((string)e.CommandArgument);
                var topic = _repo.GetById(id);
                if (topic != null && AuthHelper.CanManage(topic.CreatedByUserId))
                {
                    _repo.Delete(id);
                    Bind();
                }
            }
        }
    }
}
