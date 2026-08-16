<%@ Page Title="Discussion Forum" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="List.aspx.cs" Inherits="Hardwarequest.Forum.List" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title">Discussion Forum </h2>
    <p>Ask questions and share what you've learned about computer hardware! </p>

    <asp:PlaceHolder ID="phNew" runat="server" Visible="false">
      <p><a class="btn hq-btn" href="<%= ResolveUrl("~/Forum/New") %>"> Start a discussion</a></p>
    </asp:PlaceHolder>
    <asp:Panel ID="pnlLoginHint" runat="server" Visible="false">
      <p class="text-muted"><a href="<%= ResolveUrl("~/Account/Login") %>">Log in</a> to start a discussion or reply.</p>
    </asp:Panel>

    <asp:Label ID="lblEmpty" runat="server" Visible="false"
      Text="No discussions yet. Be the first to start one! " CssClass="d-block" />

    <asp:Repeater ID="rptThreads" runat="server" OnItemCommand="rptThreads_ItemCommand">
      <ItemTemplate>
        <div class="row align-items-center py-3 border-bottom">
          <div class="col-12 col-md-8">
            <h3 class="h5 mb-1">
              <a href='<%# ResolveUrl("~/Forum/Thread?id=" + Eval("ThreadId")) %>'>
                <%# Server.HtmlEncode((string)Eval("Title")) %></a>
            </h3>
            <small class="text-muted">
              by <%# Server.HtmlEncode((string)Eval("AuthorName")) %>
              • <%# Eval("ReplyCount") %> repl<%# (int)Eval("ReplyCount") == 1 ? "y" : "ies" %>
            </small>
          </div>
          <div class="col-12 col-md-4 text-md-end mt-2 mt-md-0">
            <small class="text-muted d-block"><%# ((DateTime)Eval("LastActivity")).ToString("d MMM yyyy, h:mm tt") %></small>
            <asp:PlaceHolder runat="server" Visible='<%# CanManage(Eval("CreatedByUserId")) %>'>
              <asp:Button runat="server" CssClass="btn btn-sm btn-outline-danger mt-1" Text="Delete"
                CommandName="DeleteThread" CommandArgument='<%# Eval("ThreadId") %>'
                OnClientClick="return hqConfirm(this,'Delete this whole discussion?');" />
            </asp:PlaceHolder>
          </div>
        </div>
      </ItemTemplate>
    </asp:Repeater>
  </div>
</asp:Content>
