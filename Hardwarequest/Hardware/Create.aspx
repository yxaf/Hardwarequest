<%@ Page Title="Add Part" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Create.aspx.cs" Inherits="Hardwarequest.Hardware.Create" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:560px;">
    <h2 class="hq-title">Add a computer part </h2>
    <asp:Label ID="lblError" runat="server" CssClass="text-danger d-block mb-2" />

    <div class="mb-3">
      <label class="form-label">Name</label>
      <asp:TextBox ID="txtName" runat="server" CssClass="form-control" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtName"
        CssClass="text-danger" Display="Dynamic" ErrorMessage="Name is required" />
    </div>
    <div class="mb-3">
      <label class="form-label">Kid-friendly description</label>
      <asp:TextBox ID="txtDesc" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4" />
      <asp:RequiredFieldValidator runat="server" ControlToValidate="txtDesc"
        CssClass="text-danger" Display="Dynamic" ErrorMessage="Description is required" />
    </div>
    <div class="mb-3">
      <label class="form-label">Part key <span class="text-muted">(for the 3D explorer, optional)</span></label>
      <asp:TextBox ID="txtPartKey" runat="server" CssClass="form-control" placeholder="e.g. cpu, gpu, ram" />
    </div>
    <div class="mb-3">
      <label class="form-label">Picture <span class="text-muted">(PNG, JPG or GIF, optional)</span></label>
      <div class="d-flex align-items-start gap-3">
        <div class="flex-grow-1">
          <asp:FileUpload ID="fileImage" runat="server" CssClass="form-control" data-preview="partImgPrev" />
        </div>
        <img id="partImgPrev" class="rounded" style="display:none;max-height:96px;" alt="Picture preview" />
      </div>
    </div>

    <asp:Button ID="btnSave" runat="server" Text="Save part" CssClass="btn hq-btn" OnClick="btnSave_Click" />
    <a class="btn btn-link" href="<%= ResolveUrl("~/Hardware/List") %>">Cancel</a>
  </div>
</asp:Content>
