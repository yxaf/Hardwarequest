using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Quiz
{
    public partial class Take : System.Web.UI.Page
    {
        private readonly QuizRepository _repo = new QuizRepository();
        private readonly UserRepository _users = new UserRepository();

        // The quiz being taken, kept across postback so grading can reload it.
        // Protected so the result panel's leaderboard link can embed it.
        protected int QuizId
        {
            get { return (int)(ViewState["QuizId"] ?? 0); }
            set { ViewState["QuizId"] = value; }
        }

        // Staff never take quizzes for real: they preview. Evaluated per
        // request (not ViewState) so a role change can't be replayed.
        protected bool IsPreview => AuthHelper.IsStaff;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                if (!int.TryParse(Request.QueryString["id"], out int id))
                {
                    Response.Redirect("~/Quiz/List");
                    return;
                }
                QuizId = id;
                LoadQuiz();
            }
        }

        private void LoadQuiz()
        {
            Models.Quiz quiz = _repo.GetQuizById(QuizId);
            if (quiz == null) { Response.Redirect("~/Quiz/List"); return; }
            // Drafts are only previewable by their owner (or an admin).
            if (!quiz.IsPublished && !AuthHelper.CanManage(quiz.CreatedByUserId))
            { Response.Redirect("~/Quiz/List"); return; }

            litTitle.Text = Server.HtmlEncode(quiz.Title);
            lblBadge.Text = QuizDifficulty.Badge(quiz.Difficulty);
            pnlPreview.Visible = IsPreview;

            var questions = _repo.GetQuestions(QuizId);
            if (questions.Count == 0)
            {
                lblError.Text = "This quiz has no questions yet. Please come back later! ";
                btnSubmit.Visible = false;
            }

            rptQuestions.DataSource = questions;
            rptQuestions.DataBind();
        }

        // Build each question's radio options as the repeater binds.
        protected void rptQuestions_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
                return;

            var q = (Question)e.Item.DataItem;
            var litQ = (Label)e.Item.FindControl("litQ");
            var hidQid = (HiddenField)e.Item.FindControl("hidQid");
            var rbl = (RadioButtonList)e.Item.FindControl("rblAnswer");

            litQ.Text = Server.HtmlEncode(q.Text);
            hidQid.Value = q.QuestionId.ToString();

            AddOption(rbl, "A", q.OptionA);
            AddOption(rbl, "B", q.OptionB);
            AddOption(rbl, "C", q.OptionC);
            AddOption(rbl, "D", q.OptionD);
        }

        private static void AddOption(RadioButtonList rbl, string letter, string text)
        {
            if (!string.IsNullOrWhiteSpace(text))
                rbl.Items.Add(new ListItem(text, letter));
        }

        protected void btnSubmit_Click(object sender, EventArgs e)
        {
            var questions = _repo.GetQuestions(QuizId);
            var quiz = _repo.GetQuizById(QuizId);
            if (quiz == null) { Response.Redirect("~/Quiz/List"); return; }

            int correct = 0;
            foreach (RepeaterItem item in rptQuestions.Items)
            {
                var hidQid = (HiddenField)item.FindControl("hidQid");
                var rbl = (RadioButtonList)item.FindControl("rblAnswer");
                if (!int.TryParse(hidQid.Value, out int qid)) continue;

                Question q = questions.Find(x => x.QuestionId == qid);
                if (q == null) continue;

                if (rbl.SelectedValue.Length == 1 && rbl.SelectedValue[0] == q.CorrectOption)
                    correct++;
            }

            int points = correct * QuizDifficulty.Weight(quiz.Difficulty);
            if (!IsPreview) SaveScore(points); // preview results are never recorded
            ShowResult(correct, questions.Count, points);
        }

        private void SaveScore(int points)
        {
            User u = _users.GetByUsername(AuthHelper.CurrentUsername);
            if (u == null) { Response.Redirect("~/Account/Login"); return; }

            _repo.AddScore(new Score { UserId = u.UserId, QuizId = QuizId, Points = points });
        }

        private void ShowResult(int correct, int total, int points)
        {
            pnlQuiz.Visible = false;
            pnlResult.Visible = true;
            litName.Text = Server.HtmlEncode(AuthHelper.CurrentFullName ?? "friend");
            litCorrect.Text = correct.ToString();
            litTotal.Text = total.ToString();
            litPoints.Text = points.ToString();
        }
    }
}
