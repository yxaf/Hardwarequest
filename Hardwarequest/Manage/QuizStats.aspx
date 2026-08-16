<%@ Page Title="Quiz Stats" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="QuizStats.aspx.cs" Inherits="Hardwarequest.Manage.QuizStats" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title"><asp:Literal ID="litTitle" runat="server" /></h2>

    <div class="row text-center mb-4">
      <div class="col"><div class="hq-stat"><div class="h3 mb-0"><asp:Literal ID="litAttempts" runat="server" /></div>attempts</div></div>
      <div class="col"><div class="hq-stat"><div class="h3 mb-0"><asp:Literal ID="litStudents" runat="server" /></div>students</div></div>
      <div class="col"><div class="hq-stat"><div class="h3 mb-0"><asp:Literal ID="litAccuracy" runat="server" /></div>avg accuracy</div></div>
      <div class="col"><div class="hq-stat"><div class="h3 mb-0"><asp:Literal ID="litBest" runat="server" /></div>best score</div></div>
      <div class="col"><div class="hq-stat"><div class="h6 mb-0"><asp:Literal ID="litLast" runat="server" /></div>last taken</div></div>
    </div>

    <asp:PlaceHolder ID="phCharts" runat="server" Visible="false">
      <div class="row g-4 mb-4">
        <div class="col-md-6"><h3 class="h6">Score distribution</h3><canvas id="distChart" height="180"></canvas></div>
        <div class="col-md-6"><h3 class="h6">Attempts over time</h3><canvas id="timeChart" height="180"></canvas></div>
      </div>
    </asp:PlaceHolder>

    <h3 class="h6">Students</h3>
    <asp:Label ID="lblNoStudents" runat="server" Visible="false"
      Text="No students have taken this quiz yet." CssClass="d-block text-muted" />
    <asp:Repeater ID="rptRoster" runat="server">
      <HeaderTemplate>
        <table class="table table-sm">
          <thead><tr><th>Student</th><th>Attempts</th><th>Best</th><th>Accuracy</th><th>Last taken</th></tr></thead>
          <tbody>
      </HeaderTemplate>
      <ItemTemplate>
        <tr>
          <td><%# Server.HtmlEncode((string)Eval("FullName")) %></td>
          <td><%# Eval("Attempts") %></td>
          <td><%# Eval("BestPoints") %>/<%# MaxPoints %></td>
          <td><%# (int)System.Math.Round((double)Eval("BestAccuracy") * 100) %>%</td>
          <td><%# ((System.DateTime)Eval("LastTaken")).ToString("yyyy-MM-dd") %></td>
        </tr>
      </ItemTemplate>
      <FooterTemplate></tbody></table></FooterTemplate>
    </asp:Repeater>

    <asp:HiddenField ID="hfChartData" runat="server" />
  </div>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
  <script src="<%= ResolveUrl("~/Scripts/quizstats.js") %>"></script>
</asp:Content>
