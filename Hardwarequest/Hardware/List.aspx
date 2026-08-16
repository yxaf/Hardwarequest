<%@ Page Title="Computer Parts" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="List.aspx.cs" Inherits="Hardwarequest.Hardware.List" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title">Computer Parts </h2>
    <asp:PlaceHolder ID="phStaffActions" runat="server" Visible="false">
      <p><a class="btn hq-btn" href="<%= ResolveUrl("~/Hardware/Create") %>"> Add new part</a></p>
    </asp:PlaceHolder>

    <div class="row g-2 mb-3">
      <div class="col-sm-8 col-md-6">
        <div class="input-group">
          <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control"
            placeholder="Search parts by name…" />
          <asp:Button ID="btnSearch" runat="server" CssClass="btn hq-btn" Text=" Search"
            OnClick="btnSearch_Click" />
          <asp:Button ID="btnClear" runat="server" CssClass="btn btn-outline-secondary" Text="Clear"
            OnClick="btnClear_Click" CausesValidation="false" />
        </div>
      </div>
    </div>

    <asp:Label ID="lblEmpty" runat="server" Visible="false"
      Text="No parts yet. Check back soon! " CssClass="d-block" />

    <asp:Repeater ID="rptParts" runat="server" OnItemCommand="rptParts_ItemCommand">
      <ItemTemplate>
        <div class="row align-items-center py-3 border-bottom">
          <div class="col-3 col-md-2 text-center">
            <asp:Image runat="server" CssClass="img-fluid rounded"
              ImageUrl='<%# GetImage(Eval("ImagePath"), Eval("PartKey")) %>' AlternateText='<%# Eval("Name") %>' />
          </div>
          <div class="col-9 col-md-10">
            <h3 class="h4"><%# Server.HtmlEncode((string)Eval("Name")) %></h3>
            <p class="mb-2"><%# Server.HtmlEncode((string)Eval("ChildDescription")) %></p>
            <a class="btn btn-sm btn-outline-primary"
              href='<%# ResolveUrl("~/Hardware/Details?id=" + Eval("Id")) %>'>Details</a>
            <asp:PlaceHolder runat="server" Visible='<%# IsAdmin %>'>
              <a class="btn btn-sm btn-outline-success"
                href='<%# ResolveUrl("~/Hardware/Edit?id=" + Eval("Id")) %>'>Edit</a>
              <asp:Button runat="server" CssClass="btn btn-sm btn-outline-danger" Text="Delete"
                CommandName="DeletePart" CommandArgument='<%# Eval("Id") %>'
                OnClientClick="return hqConfirm(this,'Delete this part?');" />
            </asp:PlaceHolder>
          </div>
        </div>
      </ItemTemplate>
    </asp:Repeater>
  </div>
</asp:Content>
