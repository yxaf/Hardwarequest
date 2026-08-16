using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;

namespace Hardwarequest.Quiz
{
    public partial class Leaderboard : System.Web.UI.Page
    {
        private readonly QuizRepository _repo = new QuizRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            var quizzes = _repo.GetAllQuizzes(publishedOnly: true);
            foreach (var q in quizzes)
                ddlQuiz.Items.Add(new ListItem(q.Title, q.QuizId.ToString()));

            if (quizzes.Count == 0)
            {
                lblNoQuizzes.Visible = true;
                ddlQuiz.Visible = false;
                return;
            }

            // Preselect the quiz named in the query string, when valid.
            string qs = Request.QueryString["quizId"];
            if (!string.IsNullOrEmpty(qs) && ddlQuiz.Items.FindByValue(qs) != null)
                ddlQuiz.SelectedValue = qs;

            BindBoard();
        }

        protected void ddlQuiz_SelectedIndexChanged(object sender, EventArgs e) => BindBoard();

        private void BindBoard()
        {
            int quizId = int.Parse(ddlQuiz.SelectedValue);
            var scores = _repo.GetLeaderboard(quizId, 20);
            rptBoard.DataSource = scores;
            rptBoard.DataBind();
            pnlBoard.Visible = scores.Count > 0;
            lblEmpty.Visible = scores.Count == 0;
        }
    }
}
