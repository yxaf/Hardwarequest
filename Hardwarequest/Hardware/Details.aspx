<%@ Page Title="Part Details" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Details.aspx.cs" Inherits="Hardwarequest.Hardware.Details" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:640px;">
    <h2 class="hq-title"><asp:Literal ID="litName" runat="server" /></h2>
    <asp:Image ID="imgPart" runat="server" CssClass="img-fluid rounded mb-3" Style="max-width:320px;" />
    <% if (HasModel) { %>
    <div id="partViewer" class="rounded mb-1" style="height:420px; overflow:hidden;"></div>
    <p class="text-muted small mb-3">Drag to spin, scroll to zoom</p>
    <% } %>
    <p style="font-size:1.2rem;"><asp:Label ID="litDesc" runat="server" /></p>
    <button type="button" class="btn hq-btn" onclick="readAloud('<%= litDesc.ClientID %>')">Listen Read aloud</button>
  </div>
  <script src="<%= ResolveUrl("~/Scripts/readaloud.js") %>"></script>
  <% if (HasModel) { %>
  <script src="https://unpkg.com/three@0.132.2/build/three.min.js"></script>
  <script src="https://unpkg.com/three@0.132.2/examples/js/controls/OrbitControls.js"></script>
  <script src="<%= ResolveUrl("~/Scripts/partmodels.js") %>"></script>
  <script>
    if (!(window.HQPartModels && HQPartModels.mount('partViewer', '<%= PartKeyJs %>'))) {
      // 3D failed (no WebGL / CDN offline): fall back to the photo.
      document.getElementById('partViewer').style.display = 'none';
      document.getElementById('<%= imgPart.ClientID %>').classList.remove('d-none');
    }
  </script>
  <% } %>
</asp:Content>
