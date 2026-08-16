<%@ Page Title="Student Progress" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="StudentProgress.aspx.cs" Inherits="Hardwarequest.Quiz.StudentProgress" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title">Student Progress</h2>
    <p>Monitor how students are doing across all quizzes.</p>

    <div class="row text-center my-3">
      <div class="col-4">
        <div class="hq-stat">
          <div class="h3 mb-0"><asp:Literal ID="litStudents" runat="server" /></div>
          <small>Students</small>
        </div>
      </div>
      <div class="col-4">
        <div class="hq-stat">
          <div class="h3 mb-0"><asp:Literal ID="litActive" runat="server" /></div>
          <small>Have taken a quiz</small>
        </div>
      </div>
      <div class="col-4">
        <div class="hq-stat">
          <div class="h3 mb-0"><asp:Literal ID="litAttempts" runat="server" /></div>
          <small>Total attempts</small>
        </div>
      </div>
    </div>

    <asp:Label ID="lblEmpty" runat="server" Visible="false"
      Text="No students have registered yet." CssClass="d-block" />

    <div class="table-responsive">
      <table class="table align-middle">
        <thead>
          <tr>
            <th>Student</th><th>Username</th>
            <th class="text-end">Quizzes</th><th class="text-end">Attempts</th>
            <th class="text-end">Best score</th><th class="text-end">Total points</th>
            <th>Last active</th><th></th>
          </tr>
        </thead>
        <tbody>
          <asp:Repeater ID="rptStudents" runat="server" OnItemCommand="rptStudents_ItemCommand">
            <ItemTemplate>
              <tr>
                <td><%# Server.HtmlEncode((string)Eval("FullName")) %></td>
                <td class="text-muted"><%# Server.HtmlEncode((string)Eval("Username")) %></td>
                <td class="text-end"><%# Eval("QuizzesAttempted") %></td>
                <td class="text-end"><%# Eval("TotalAttempts") %></td>
                <td class="text-end fw-bold"><%# Eval("BestScore") %></td>
                <td class="text-end fw-bold"><%# Eval("TotalPoints") %></td>
                <td><%# Eval("LastActiveText") %></td>
                <td class="text-end">
                  <asp:LinkButton runat="server" CssClass="btn btn-sm btn-outline-secondary"
                    Text="View attempts" CommandName="view"
                    CommandArgument='<%# Eval("UserId") %>'
                    Visible='<%# (bool)Eval("HasAttempts") %>' />
                </td>
              </tr>
            </ItemTemplate>
          </asp:Repeater>
        </tbody>
      </table>
    </div>

    <asp:Panel ID="pnlDetail" runat="server" Visible="false" CssClass="mt-4">
      <h3 class="h5"><asp:Literal ID="litDetailName" runat="server" /></h3>
      <table class="table align-middle">
        <thead>
          <tr><th>Quiz</th><th class="text-end">Points</th><th>When</th></tr>
        </thead>
        <tbody>
          <asp:Repeater ID="rptAttempts" runat="server">
            <ItemTemplate>
              <tr>
                <td><%# Server.HtmlEncode((string)Eval("QuizTitle")) %></td>
                <td class="text-end fw-bold"><%# Eval("Points") %></td>
                <td><%# ((System.DateTime)Eval("TakenAt")).ToString("d MMM yyyy, h:mm tt") %></td>
              </tr>
            </ItemTemplate>
          </asp:Repeater>
        </tbody>
      </table>
    </asp:Panel>
  </div>
</asp:Content>
