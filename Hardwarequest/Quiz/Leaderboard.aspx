<%@ Page Title="Leaderboard" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Leaderboard.aspx.cs" Inherits="Hardwarequest.Quiz.Leaderboard" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title">Leaderboard</h2>
    <p>The top scores for each quiz. Pick a quiz to see its champions!</p>

    <div class="row align-items-end mb-3">
      <div class="col-auto">
        <label class="form-label mb-0">Quiz</label>
        <asp:DropDownList ID="ddlQuiz" runat="server" CssClass="form-select"
          AutoPostBack="true" OnSelectedIndexChanged="ddlQuiz_SelectedIndexChanged" />
      </div>
      <div class="col-auto">
        <a class="btn hq-btn btn-sm" href="<%= ResolveUrl("~/Quiz/List") %>">Take a quiz</a>
      </div>
    </div>

    <asp:Label ID="lblNoQuizzes" runat="server" Visible="false"
      Text="No quizzes yet. Check back soon!" CssClass="d-block" />
    <asp:Label ID="lblEmpty" runat="server" Visible="false"
      Text="No scores yet for this quiz. Be the first to take it!" CssClass="d-block" />

    <asp:Panel ID="pnlBoard" runat="server" Visible="false">
      <table class="table align-middle">
        <thead>
          <tr><th>#</th><th>Name</th><th class="text-end">Best points</th></tr>
        </thead>
        <tbody>
          <asp:Repeater ID="rptBoard" runat="server">
            <ItemTemplate>
              <tr>
                <td class="fw-bold"><%# Container.ItemIndex + 1 %></td>
                <td><%# Server.HtmlEncode((string)Eval("FullName")) %></td>
                <td class="text-end fw-bold"><%# Eval("Points") %></td>
              </tr>
            </ItemTemplate>
          </asp:Repeater>
        </tbody>
      </table>
    </asp:Panel>
  </div>
</asp:Content>
