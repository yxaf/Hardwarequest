<%@ Page Title="Manage Users" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="ManageUsers.aspx.cs" Inherits="Hardwarequest.Admin.ManageUsers" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card">
    <h2 class="hq-title">Manage users </h2>
    <asp:GridView ID="gvUsers" runat="server" CssClass="table table-striped"
        AutoGenerateColumns="false" DataKeyNames="UserId"
        OnRowCommand="gvUsers_RowCommand">
      <Columns>
        <asp:BoundField DataField="FullName" HeaderText="Name" />
        <asp:BoundField DataField="Username" HeaderText="Username" />
        <asp:BoundField DataField="Email" HeaderText="Email" />
        <asp:BoundField DataField="Role" HeaderText="Role" />
        <asp:TemplateField HeaderText="Set role">
          <ItemTemplate>
            <asp:Button runat="server" CssClass="btn btn-sm btn-outline-primary"
              CommandName="MakeStudent" CommandArgument='<%# Eval("UserId") %>' Text="Student"
              OnClientClick='<%# RoleConfirmJs(Eval("Username"), "Student") %>' />
            <asp:Button runat="server" CssClass="btn btn-sm btn-outline-success"
              CommandName="MakeLecturer" CommandArgument='<%# Eval("UserId") %>' Text="Lecturer"
              OnClientClick='<%# RoleConfirmJs(Eval("Username"), "Lecturer") %>' />
            <asp:Button runat="server" CssClass="btn btn-sm btn-outline-danger"
              CommandName="MakeAdmin" CommandArgument='<%# Eval("UserId") %>' Text="Admin"
              OnClientClick='<%# RoleConfirmJs(Eval("Username"), "Admin") %>' />
          </ItemTemplate>
        </asp:TemplateField>
      </Columns>
    </asp:GridView>
  </div>
</asp:Content>
