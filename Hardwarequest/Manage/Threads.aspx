<%@ Page Title="My Threads" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Threads.aspx.cs" Inherits="Hardwarequest.Manage.Threads" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title">My Threads</h2>
    <asp:Label ID="lblEmpty" runat="server" Visible="false" CssClass="d-block"
      Text="You have not started any discussions yet." />
    <asp:Repeater ID="rpt" runat="server" OnItemCommand="rpt_ItemCommand">
      <HeaderTemplate>
        <table class="table table-sm align-middle">
          <thead><tr><th>Title</th><th>Author</th><th>Replies</th><th>Last activity</th><th></th></tr></thead>
          <tbody>
      </HeaderTemplate>
      <ItemTemplate>
        <tr>
          <td><%# Server.HtmlEncode((string)Eval("Title")) %></td>
          <td><%# Server.HtmlEncode((string)Eval("AuthorName")) %></td>
          <td><%# Eval("ReplyCount") %></td>
          <td><%# ((System.DateTime)Eval("LastActivity")).ToString("yyyy-MM-dd HH:mm") %></td>
          <td class="text-end">
            <a class="btn btn-sm btn-outline-primary"  href='<%# ResolveUrl("~/Forum/Thread?id=" + Eval("ThreadId")) %>'>View</a>
            <asp:Button runat="server" CssClass="btn btn-sm btn-outline-danger" Text="Delete"
              CommandName="DeleteThread" CommandArgument='<%# Eval("ThreadId") %>'
              OnClientClick="return hqConfirm(this,'Delete this thread and all its replies?');" />
          </td>
        </tr>
      </ItemTemplate>
      <FooterTemplate></tbody></table></FooterTemplate>
    </asp:Repeater>
  </div>
</asp:Content>
