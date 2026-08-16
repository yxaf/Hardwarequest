<%@ Page Title="Edit Part" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Edit.aspx.cs" Inherits="Hardwarequest.Hardware.Edit" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:560px;">
    <h2 class="hq-title">Edit part </h2>
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
      <label class="form-label">Current picture</label><br />
      <asp:Image ID="imgCurrent" runat="server" CssClass="img-fluid rounded mb-2" Style="max-width:160px;" />
    </div>
    <div class="mb-3">
      <label class="form-label">Replace picture <span class="text-muted">(leave empty to keep current)</span></label>
      <div class="d-flex align-items-start gap-3">
        <div class="flex-grow-1">
          <asp:FileUpload ID="fileImage" runat="server" CssClass="form-control" data-preview="partImgPrev" />
        </div>
        <img id="partImgPrev" class="rounded" style="display:none;max-height:96px;" alt="New picture preview" />
      </div>
    </div>

    <asp:Button ID="btnSave" runat="server" Text="Save changes" CssClass="btn hq-btn" OnClick="btnSave_Click" />
    <a class="btn btn-link" href="<%= ResolveUrl("~/Hardware/List") %>">Cancel</a>
  </div>
</asp:Content>
