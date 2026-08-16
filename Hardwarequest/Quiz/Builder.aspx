<%@ Page Title="Quiz Builder" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Builder.aspx.cs" Inherits="Hardwarequest.Quiz.Builder" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:1000px;">
    <h2 class="hq-title"><asp:Literal ID="litHeading" runat="server" /> <asp:Literal ID="litStatus" runat="server" /></h2>
    <asp:Label ID="lblError" runat="server" CssClass="alert alert-danger d-block mb-3"
      Visible="false" EnableViewState="false" />

    <div class="row">
      <div class="col-md-8 mb-3">
        <label class="form-label">Title</label>
        <asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" />
        <asp:RequiredFieldValidator runat="server" ControlToValidate="txtTitle"
          CssClass="text-danger" Display="Dynamic" ErrorMessage="Title is required" />
      </div>
      <div class="col-md-4 mb-3">
        <label class="form-label">Difficulty</label>
        <asp:DropDownList ID="ddlDifficulty" runat="server" CssClass="form-select">
          <asp:ListItem Value="Easy" Text="Easy (1 point per correct answer)" />
          <asp:ListItem Value="Medium" Text="Medium (2 points per correct answer)" />
          <asp:ListItem Value="Hard" Text="Hard (3 points per correct answer)" />
        </asp:DropDownList>
      </div>
    </div>
    <div class="row mb-3">
      <div class="col-md-8">
        <label class="form-label">Description <span class="text-muted">(optional)</span></label>
        <asp:TextBox ID="txtDescription" runat="server" CssClass="form-control" TextMode="MultiLine"
          Rows="2" MaxLength="500" placeholder="A short sentence about this quiz, shown on its card." />
      </div>
      <div class="col-md-4">
        <label class="form-label">Cover picture <span class="text-muted">(PNG, JPG or GIF, optional)</span></label>
        <asp:FileUpload ID="fileImage" runat="server" CssClass="form-control" data-preview="quizImgPrev" />
        <img id="quizImgPrev" class="img-fluid rounded mt-2 me-2" style="display:none;max-height:80px;" alt="New picture preview" />
        <asp:Image ID="imgCurrent" runat="server" CssClass="img-fluid rounded mt-2" Style="max-height:80px;" />
      </div>
    </div>

    <hr />
    <div class="d-flex justify-content-between align-items-center mb-2">
      <h3 class="h5 mb-0">Questions</h3>
      <span class="text-muted" id="qSummary"></span>
    </div>
    <div id="jsErrors" class="alert alert-danger mb-3" style="display:none;"></div>
    <div id="qList"></div>
    <button type="button" id="btnAddQ" class="btn btn-outline-success my-3">+ Add question</button>

    <asp:HiddenField ID="hidQuestions" runat="server" />
    <hr />
    <asp:Button ID="btnSave" runat="server" CssClass="btn hq-btn" OnClick="btnSave_Click"
      OnClientClick="if (!HQBuilder.beforeSubmit(false)) return false;" />
    <asp:Button ID="btnToggle" runat="server" CssClass="btn btn-outline-success ms-2" OnClick="btnToggle_Click"
      OnClientClick="if (!HQBuilder.beforeSubmit(true)) return false;" />
    <a class="btn btn-link" href="<%= ResolveUrl("~/Manage/Quizzes") %>">Cancel</a>
  </div>

  <script>window.HQ_QUIZ = <%= QuizJson %>;</script>
  <script src="<%= ResolveUrl("~/Scripts/quizbuilder.js") %>"></script>
  <script>
    HQBuilder.init({
      listId: 'qList', addBtnId: 'btnAddQ', summaryId: 'qSummary', errorsId: 'jsErrors',
      hidId: '<%= hidQuestions.ClientID %>',
      ddlId: '<%= ddlDifficulty.ClientID %>',
      publishedNow: <%= IsPublishedNow ? "true" : "false" %>
    });
  </script>
</asp:Content>
