using System;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Topics
{
    public partial class Create : System.Web.UI.Page
    {
        private readonly TopicRepository _repo = new TopicRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            // Lecturers and Administrators only.
            if (!AuthHelper.IsStaff) Response.Redirect("~/");
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (!IsValid) return;

            if (!ImageUpload.TrySave(fileImage, out string imagePath, out string error))
            {
                lblError.Text = error;
                return;
            }

            var t = new Topic
            {
                Title = txtTitle.Text.Trim(),
                Body = txtBody.Text.Trim(),
                ImagePath = imagePath,
                CreatedByUserId = AuthHelper.CurrentUserId
            };
            _repo.Create(t);
            Response.Redirect("~/Topics/List");
        }
    }
}
