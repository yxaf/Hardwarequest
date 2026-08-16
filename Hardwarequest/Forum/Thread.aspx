<%@ Page Title="Discussion" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Thread.aspx.cs" Inherits="Hardwarequest.Forum.Thread" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title"><asp:Literal ID="litTitle" runat="server" /></h2>
    <p class="text-muted">Started by <asp:Literal ID="litAuthor" runat="server" /></p>

    <asp:Repeater ID="rptPosts" runat="server" OnItemCommand="rptPosts_ItemCommand">
      <ItemTemplate>
        <div class="p-3 mb-2 rounded" style="background:#f5f9ff;">
          <div class="d-flex justify-content-between">
            <strong><%# Server.HtmlEncode((string)Eval("AuthorName")) %></strong>
            <small class="text-muted"><%# ((DateTime)Eval("CreatedAt")).ToString("d MMM yyyy, h:mm tt") %></small>
          </div>
          <p class="mb-1 mt-2" style="white-space:pre-wrap;"><%# Server.HtmlEncode((string)Eval("Body")) %></p>
          <asp:PlaceHolder runat="server" Visible='<%# CanManage(Eval("UserId")) %>'>
            <asp:Button runat="server" CssClass="btn btn-sm btn-outline-danger" Text="Delete"
              CommandName="DeletePost" CommandArgument='<%# Eval("PostId") %>'
              OnClientClick="return hqConfirm(this,'Delete this post?');" />
          </asp:PlaceHolder>
        </div>
      </ItemTemplate>
    </asp:Repeater>

    <asp:Panel ID="pnlReply" runat="server" Visible="false" CssClass="mt-4">
      <h3 class="h5">Add a reply </h3>
      <asp:TextBox ID="txtBody" runat="server" CssClass="form-control mb-2" TextMode="MultiLine" Rows="3" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtBody"
        CssClass="text-danger d-block mb-2" Display="Dynamic" ErrorMessage="Please write something before posting" />
      <asp:Button ID="btnReply" runat="server" Text="Post reply" CssClass="btn hq-btn" OnClick="btnReply_Click" />
    </asp:Panel>
    <asp:Panel ID="pnlLoginHint" runat="server" Visible="false" CssClass="mt-4">
      <p class="text-muted"><a href="<%= ResolveUrl("~/Account/Login") %>">Log in</a> to join the discussion.</p>
    </asp:Panel>
  </div>
</asp:Content>
