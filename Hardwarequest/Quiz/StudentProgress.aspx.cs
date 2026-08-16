using System;
using System.Linq;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;

namespace Hardwarequest.Quiz
{
    // Staff-only monitoring view of all students' quiz performance. The Quiz
    // area already blocks anonymous users in Web.config; students get bounced
    // to their personal MyProgress page.
    public partial class StudentProgress : System.Web.UI.Page
    {
        private readonly QuizRepository _repo = new QuizRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AuthHelper.IsStaff)
            { Response.Redirect("~/Quiz/MyProgress"); return; }

            if (!IsPostBack) Bind();
        }

        private void Bind()
        {
            var rows = _repo.GetStudentProgress();
            litStudents.Text = rows.Count.ToString();
            litActive.Text = rows.Count(r => r.HasAttempts).ToString();
            litAttempts.Text = rows.Sum(r => r.TotalAttempts).ToString();

            lblEmpty.Visible = rows.Count == 0;
            rptStudents.DataSource = rows;
            rptStudents.DataBind();
        }

        protected void rptStudents_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "view") return;
            if (!int.TryParse((string)e.CommandArgument, out int userId)) return;

            var row = _repo.GetStudentProgress().Find(r => r.UserId == userId);
            if (row == null) return;

            litDetailName.Text = Server.HtmlEncode(row.FullName) + " — attempt history";
            rptAttempts.DataSource = _repo.GetScoresByUser(userId);
            rptAttempts.DataBind();
            pnlDetail.Visible = true;
        }
    }
}
