resource "oci_core_subnet" "dataSWebSubnet" {
  cidr_block        = var.Subnet-CIDR
  display_name      = "dataSWebSubnet"
  dns_label         = "dataSN1"
  compartment_id    = var.compartment
  vcn_id            = oci_core_vcn.dataSvcn.id
  route_table_id    = oci_core_route_table.dataSRouteTableViaIGW.id
  dhcp_options_id   = oci_core_dhcp_options.dataSDhcpOptions1.id
  security_list_ids = [oci_core_security_list.dataSSecurityList.id]
}