using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;

namespace Hardwarequest.Topics
{
    public partial class List : System.Web.UI.Page
    {
        private readonly TopicRepository _repo = new TopicRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack) Bind();
        }

        private void Bind()
        {
            var items = _repo.GetAll();
            rptTopics.DataSource = items;
            rptTopics.DataBind();
            lblEmpty.Visible = items.Count == 0;
        }

        // Resolvable cover-image URL, falling back to the shared placeholder.
        protected string GetImage(object path)
        {
            string p = path as string;
            return ResolveUrl(string.IsNullOrEmpty(p) ? "~/Content/placeholder.svg" : p);
        }

        // A short preview of the body for the card.
        protected string Snippet(object body)
        {
            string s = (body as string ?? "").Trim();
            return s.Length <= 120 ? s : s.Substring(0, 120).TrimEnd() + "…";
        }

    }
}
