using System;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Topics
{
    public partial class Details : System.Web.UI.Page
    {
        private readonly TopicRepository _repo = new TopicRepository();

        private int TopicId
        {
            get { return int.TryParse(Request.QueryString["id"], out int i) ? i : 0; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Topic t = _repo.GetById(TopicId);
            if (t == null) { Response.Redirect("~/Topics/List"); return; }

            litTitle.Text = Server.HtmlEncode(t.Title);
            // Preserve paragraph breaks while keeping the text HTML-safe.
            litBody.Text = Server.HtmlEncode(t.Body ?? "").Replace("\r\n", "\n").Replace("\n", "<br />");
            imgCover.ImageUrl = ResolveUrl(string.IsNullOrEmpty(t.ImagePath)
                ? "~/Content/placeholder.svg" : t.ImagePath);
        }
    }
}
