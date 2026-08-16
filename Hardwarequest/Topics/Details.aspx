<%@ Page Title="Topic" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Details.aspx.cs" Inherits="Hardwarequest.Topics.Details" %>
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
  <div class="hq-card mx-auto" style="max-width:680px;">
    <h2 class="hq-title"><asp:Literal ID="litTitle" runat="server" /></h2>
    <asp:Image ID="imgCover" runat="server" CssClass="img-fluid rounded mb-3" Style="max-width:360px;" />
    <p style="font-size:1.15rem;"><asp:Label ID="litBody" runat="server" /></p>
    <button type="button" class="btn hq-btn" onclick="readAloud('<%= litBody.ClientID %>')">Listen</button>
  </div>
  <script src="<%= ResolveUrl("~/Scripts/readaloud.js") %>"></script>
</asp:Content>
