resource "oci_core_dhcp_options" "dataSDhcpOptions1" {
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.dataSvcn.id
  display_name   = "dataSDhcpOptions"

  // required
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

}

resource "oci_core_internet_gateway" "dataSInternetGateway" {
  compartment_id = var.compartment
  display_name   = "dataSInternetGateway"
  vcn_id         = oci_core_vcn.dataSvcn.id
}
resource "oci_core_route_table" "dataSRouteTableViaIGW" {
  compartment_id = var.compartment
  vcn_id         = oci_core_vcn.dataSvcn.id
  display_name   = "dataSRouteTableViaIGW"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.dataSInternetGateway.id
  }
}

