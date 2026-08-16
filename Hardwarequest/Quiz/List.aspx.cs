using System;
using System.Web.UI.WebControls;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Quiz
{
    public partial class List : System.Web.UI.Page
    {
        private readonly QuizRepository _repo = new QuizRepository();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack) Bind();
        }

        private void Bind()
        {
            string diff = ddlDifficulty.SelectedValue;
            var items = _repo.GetAllQuizzes(string.IsNullOrEmpty(diff) ? null : diff, publishedOnly: true);
            rptQuizzes.DataSource = items;
            rptQuizzes.DataBind();
            lblEmpty.Visible = items.Count == 0;
        }

        // Bootstrap colour class for the difficulty badge (green / orange / sky).
        protected string BadgeClass(object difficulty)
        {
            switch (difficulty as string)
            {
                case QuizDifficulty.Hard: return "bg-info";
                case QuizDifficulty.Medium: return "bg-secondary";
                default: return "bg-primary";
            }
        }

        // Staff open quizzes to check them, not to compete.
        protected string TakeLabel => AuthHelper.IsStaff ? "Preview" : "Enter quiz";

        // True when an optional field actually has text (used to hide empty blocks).
        protected bool HasText(object value) => !string.IsNullOrWhiteSpace(value as string);

        // Resolvable cover-image URL, falling back to the shared placeholder.
        protected string GetImage(object path)
        {
            string p = path as string;
            return ResolveUrl(string.IsNullOrEmpty(p) ? "~/Content/placeholder.svg" : p);
        }

        // Points earned per correct answer for this difficulty.
        protected int Weight(object difficulty) =>
            QuizDifficulty.Weight(difficulty as string);

        // Best possible score: every question correct at this difficulty's weight.
        protected int MaxPoints(object questionCount, object difficulty) =>
            Convert.ToInt32(questionCount) * QuizDifficulty.Weight(difficulty as string);

        protected void ddlDifficulty_SelectedIndexChanged(object sender, EventArgs e) => Bind();
    }
}
