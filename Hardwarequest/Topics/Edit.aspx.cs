using System;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Topics
{
    public partial class Edit : System.Web.UI.Page
    {
        private readonly TopicRepository _repo = new TopicRepository();

        private int TopicId
        {
            get { return int.TryParse(Request.QueryString["id"], out int i) ? i : 0; }
        }

        // Existing image path is remembered across the postback.
        private string CurrentImagePath
        {
            get { return ViewState["img"] as string; }
            set { ViewState["img"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AuthHelper.IsStaff) { Response.Redirect("~/"); return; }

            Topic t = _repo.GetById(TopicId);
            if (t == null) { Response.Redirect("~/Topics/List"); return; }
            // Only the creator (or an admin) may edit this topic.
            if (!AuthHelper.CanManage(t.CreatedByUserId)) { Response.Redirect("~/Topics/List"); return; }
            if (IsPostBack) return;

            txtTitle.Text = t.Title;
            txtBody.Text = t.Body;
            CurrentImagePath = t.ImagePath;
            imgCurrent.ImageUrl = ResolveUrl(string.IsNullOrEmpty(t.ImagePath)
                ? "~/Content/placeholder.svg" : t.ImagePath);
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (!IsValid) return;

            string imagePath = CurrentImagePath;
            if (!ImageUpload.TrySave(fileImage, out string uploaded, out string error))
            {
                lblError.Text = error;
                return;
            }
            if (uploaded != null) imagePath = uploaded; // replace only when a new file was sent

            _repo.Update(new Topic
            {
                TopicId = TopicId,
                Title = txtTitle.Text.Trim(),
                Body = txtBody.Text.Trim(),
                ImagePath = imagePath
            });
            Response.Redirect("~/Topics/List");
        }
    }
}
