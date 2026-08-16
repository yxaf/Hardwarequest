<%@ Page Title="Take Quiz" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Take.aspx.cs" Inherits="Hardwarequest.Quiz.Take" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:900px;">
    <h2 class="hq-title"><asp:Literal ID="litTitle" runat="server" /></h2>
    <asp:Label ID="lblBadge" runat="server" CssClass="badge bg-secondary mb-3 d-inline-block" />

    <asp:Panel ID="pnlQuiz" runat="server">
      <asp:Label ID="lblError" runat="server" CssClass="text-danger d-block mb-2" />

      <asp:Panel ID="pnlPreview" runat="server" Visible="false" CssClass="alert alert-warning">
        Preview mode &mdash; you are viewing this quiz as staff. Your result will not be saved.
      </asp:Panel>

      <div class="progress tm-progress mb-4" role="progressbar" aria-label="Quiz progress">
        <div class="progress-bar" style="width:100%"></div>
      </div>

      <asp:Repeater ID="rptQuestions" runat="server" OnItemDataBound="rptQuestions_ItemDataBound">
        <ItemTemplate>
          <div class="mb-4 pb-3 border-bottom">
            <p class="fw-bold" style="font-size:1.15rem;">
              <asp:Label ID="litQ" runat="server" />
              <button type="button" class="btn btn-sm btn-outline-secondary ms-2"
                onclick="readAloud('<%# ((System.Web.UI.WebControls.Label)Container.FindControl("litQ")).ClientID %>')">Listen</button>
            </p>
            <asp:HiddenField ID="hidQid" runat="server" />
            <asp:RadioButtonList ID="rblAnswer" runat="server" CssClass="ms-2" />
          </div>
        </ItemTemplate>
      </asp:Repeater>

      <asp:Button ID="btnSubmit" runat="server" Text="Submit answers " CssClass="btn hq-btn"
        OnClick="btnSubmit_Click" />
    </asp:Panel>

    <asp:Panel ID="pnlResult" runat="server" Visible="false" CssClass="text-center">
      <h3 class="h2"> Great job, <asp:Literal ID="litName" runat="server" />!</h3>
      <p style="font-size:1.3rem;">
        You got <asp:Literal ID="litCorrect" runat="server" /> out of
        <asp:Literal ID="litTotal" runat="server" /> correct.
      </p>
      <p style="font-size:1.6rem;" class="fw-bold">You earned <asp:Literal ID="litPoints" runat="server" /> points! </p>
      <% if (!IsPreview) { %>
      <a class="btn btn-warning" href="<%= ResolveUrl("~/Quiz/Leaderboard?quizId=" + QuizId) %>">See the leaderboard</a>
      <% } %>
      <a class="btn hq-btn" href="<%= ResolveUrl("~/Quiz/List") %>"><%= IsPreview ? "Back to quizzes" : "Try another quiz" %></a>
    </asp:Panel>
  </div>
  <script src="<%= ResolveUrl("~/Scripts/readaloud.js") %>"></script>
</asp:Content>
