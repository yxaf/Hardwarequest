using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Manage
{
    public partial class Quizzes : System.Web.UI.Page
    {
        private readonly QuizRepository _repo = new QuizRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AuthHelper.IsStaff) { Response.Redirect("~/Default"); return; }
            if (!IsPostBack) Bind();
        }

        private void Bind()
        {
            bool isAdmin = AuthHelper.IsInRole(UserRole.Administrator);
            var items = _repo.GetQuizzesForManager(AuthHelper.CurrentUserId, isAdmin);
            rpt.DataSource = items;
            rpt.DataBind();
            lblEmpty.Visible = items.Count == 0;
        }

        protected string BadgeClass(object difficulty)
        {
            switch (difficulty as string)
            {
                case QuizDifficulty.Hard: return "bg-info";
                case QuizDifficulty.Medium: return "bg-secondary";
                default: return "bg-primary";
            }
        }

        // Yellow "Draft" chip on unpublished quizzes; nothing when published.
        protected string DraftBadge(object isPublished) =>
            (bool)isPublished ? "" : "<span class='badge bg-warning text-dark ms-1'>Draft</span>";

        protected string OwnerLabel(object ownerName)
        {
            string n = ownerName as string;
            return string.IsNullOrEmpty(n) ? "" : "by " + Server.HtmlEncode(n);
        }

        protected string SummaryText(object attempts, object students, object accuracy)
        {
            int a = Convert.ToInt32(attempts);
            if (a == 0) return "No attempts yet";
            int s = Convert.ToInt32(students);
            int pct = (int)Math.Round(Convert.ToDouble(accuracy) * 100);
            return a + " attempt(s) · " + s + " student(s) · " + pct + "% avg accuracy";
        }

        protected void rpt_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "DeleteQuiz")
            {
                int id = int.Parse((string)e.CommandArgument);
                var quiz = _repo.GetQuizById(id);
                if (quiz != null && AuthHelper.CanManage(quiz.CreatedByUserId))
                {
                    _repo.DeleteQuiz(id);
                    Bind();
                }
            }
        }
    }
}
