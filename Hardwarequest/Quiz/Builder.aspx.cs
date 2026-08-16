using System;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using Hardwarequest.DataAccess;
using Hardwarequest.Models;

namespace Hardwarequest.Quiz
{
    public partial class Builder : System.Web.UI.Page
    {
        private readonly QuizRepository _repo = new QuizRepository();

        // Question shape exchanged with quizbuilder.js.
        // Lowercase property names = the literal JSON field names on both sides.
        public class QItem
        {
            public string text { get; set; }
            public string a { get; set; }
            public string b { get; set; }
            public string c { get; set; }
            public string d { get; set; }
            public string correct { get; set; }
        }

        protected int QuizId => int.TryParse(Request.QueryString["id"], out int i) ? i : 0;

        // Injected into the page as window.HQ_QUIZ for quizbuilder.js.
        protected string QuizJson { get; private set; } = "{\"questions\":[]}";
        protected bool IsPublishedNow { get; private set; }

        // Existing cover image, remembered across postbacks (same pattern as Hardware/Edit).
        private string CurrentImagePath
        {
            get { return ViewState["img"] as string; }
            set { ViewState["img"] = value; }
        }
        private bool CurrentPublished
        {
            get { return (bool)(ViewState["pub"] ?? false); }
            set { ViewState["pub"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AuthHelper.IsStaff) { Response.Redirect("~/Quiz/List"); return; }

            Models.Quiz quiz = null;
            if (QuizId != 0)
            {
                quiz = _repo.GetQuizById(QuizId);
                if (quiz == null) { Response.Redirect("~/Manage/Quizzes"); return; }
                // Ownership re-checked on EVERY request, including postbacks.
                if (!AuthHelper.CanManage(quiz.CreatedByUserId)) { Response.Redirect("~/Quiz/List"); return; }
            }

            if (!IsPostBack)
            {
                if (quiz == null)
                {
                    litHeading.Text = "Create a quiz";
                    CurrentPublished = false;
                    imgCurrent.Visible = false;
                }
                else
                {
                    litHeading.Text = "Edit quiz";
                    txtTitle.Text = quiz.Title;
                    ddlDifficulty.SelectedValue = quiz.Difficulty;
                    txtDescription.Text = quiz.Description;
                    CurrentImagePath = quiz.ImagePath;
                    CurrentPublished = quiz.IsPublished;
                    imgCurrent.ImageUrl = ResolveUrl(string.IsNullOrEmpty(quiz.ImagePath)
                        ? "~/Content/placeholder.svg" : quiz.ImagePath);

                    var items = new List<QItem>();
                    foreach (Question q in _repo.GetQuestions(QuizId))
                        items.Add(new QItem
                        {
                            text = q.Text, a = q.OptionA, b = q.OptionB,
                            c = q.OptionC, d = q.OptionD, correct = q.CorrectOption.ToString()
                        });
                    // <-escape so quiz content can never close the <script> block.
                    QuizJson = new JavaScriptSerializer().Serialize(new { questions = items })
                        .Replace("<", "\\u003c");
                }
            }
            // On postback quizbuilder.js re-renders from the posted hidQuestions value,
            // so the default empty HQ_QUIZ is fine.
            IsPublishedNow = CurrentPublished;
            ApplyStatusUi();
        }

        private void ApplyStatusUi()
        {
            litStatus.Text = CurrentPublished
                ? "<span class='badge bg-success align-middle'>Published</span>"
                : "<span class='badge bg-warning text-dark align-middle'>Draft</span>";
            btnSave.Text = CurrentPublished ? "Save changes" : "Save draft";
            btnToggle.Text = CurrentPublished ? "Unpublish" : "Publish";
        }

        // The label is styled as an alert-danger box, so it stays hidden until
        // there is actually something to show.
        private void ShowError(string html)
        {
            lblError.Text = html;
            lblError.Visible = true;
        }

        protected void btnSave_Click(object sender, EventArgs e) { Save(CurrentPublished); }
        protected void btnToggle_Click(object sender, EventArgs e) { Save(!CurrentPublished); }

        // Parses the posted question JSON, re-validates every rule server-side,
        // and writes the whole quiz in one transaction. 'publish' = resulting state.
        private void Save(bool publish)
        {
            List<QItem> items;
            try
            {
                items = new JavaScriptSerializer().Deserialize<List<QItem>>(
                    string.IsNullOrEmpty(hidQuestions.Value) ? "[]" : hidQuestions.Value)
                    ?? new List<QItem>();
            }
            catch
            {
                ShowError("Could not read the questions. Please try again.");
                return;
            }

            var errors = new List<string>();
            string title = txtTitle.Text.Trim();
            if (title.Length == 0) errors.Add("Title is required.");
            if (!QuizDifficulty.IsValid(ddlDifficulty.SelectedValue)) errors.Add("Pick a valid difficulty.");

            var questions = new List<Question>();
            for (int i = 0; i < items.Count; i++)
            {
                QItem it = items[i];
                string label = "Question " + (i + 1);
                string text = (it.text ?? "").Trim();
                string a = (it.a ?? "").Trim(), b = (it.b ?? "").Trim();
                string c = (it.c ?? "").Trim(), d = (it.d ?? "").Trim();
                string correct = (it.correct ?? "").Trim().ToUpperInvariant();

                if (text.Length == 0) errors.Add(label + ": text is required.");
                if (a.Length == 0) errors.Add(label + ": option A is required.");
                if (b.Length == 0) errors.Add(label + ": option B is required.");
                if (correct != "A" && correct != "B" && correct != "C" && correct != "D")
                {
                    errors.Add(label + ": pick the correct answer.");
                }
                else
                {
                    string chosen = correct == "A" ? a : correct == "B" ? b : correct == "C" ? c : d;
                    if (chosen.Length == 0) errors.Add(label + ": the correct answer points at an empty option.");
                }
                questions.Add(new Question
                {
                    Text = text, OptionA = a, OptionB = b,
                    OptionC = c.Length == 0 ? null : c,
                    OptionD = d.Length == 0 ? null : d,
                    CorrectOption = correct.Length == 1 ? correct[0] : 'A'
                });
            }
            if (publish && questions.Count == 0) errors.Add("Add at least one question before publishing.");

            string imagePath = CurrentImagePath;
            if (!ImageUpload.TrySave(fileImage, out string uploaded, out string imgError))
                errors.Add(imgError);
            else if (uploaded != null)
                imagePath = uploaded; // replace only when a new file was sent
            CurrentImagePath = imagePath; // keep an accepted upload across a failed validation round

            if (errors.Count > 0)
            {
                ShowError(string.Join("<br/>", errors.ConvertAll(Server.HtmlEncode)));
                return;
            }

            var quiz = new Models.Quiz
            {
                QuizId = QuizId,
                Title = title,
                Difficulty = ddlDifficulty.SelectedValue,
                Description = txtDescription.Text.Trim(),
                ImagePath = imagePath,
                CreatedByUserId = AuthHelper.CurrentUserId, // only used on INSERT; UPDATE leaves owner unchanged
                IsPublished = publish
            };
            _repo.SaveQuizWithQuestions(quiz, questions);
            Response.Redirect("~/Manage/Quizzes");
        }
    }
}
