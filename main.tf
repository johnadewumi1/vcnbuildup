terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
    }
  }
}

provider "oci" {
  region           = "us-sanjose-1"
  tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaajznex5attydtrmrgudwayqu7kn4krasw2ct4h4pwz7nwbfxoyd4q"
  user_ocid        = "ocid1.user.oc1..aaaaaaaamrhp2f3m2evpmlme32kqavvgynxaz66oxfvrdephahsf72mwk6cq"
  fingerprint      = "39:00:25:bf:cf:9b:00:70:87:f5:75:74:7b:71:b1:40"
  private_key_path = "/home/opc/.oci/oci_api_key.pem"
}


resource "oci_core_vcn" "johnvcn" {
  dns_label      = "internal"
  cidr_block     = var.VCN-CIDR
  compartment_id = var.compartment_ocid
  display_name   = "johnvcn"
}
resource "oci_core_internet_gateway" "john_internet_gateways" {
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  display_name = "john_internet_gateways"
  vcn_id       = oci_core_vcn.johnvcn.id
}
data "oci_identity_availability_domains" "ad" {
  compartment_id = var.compartment_ocid
}
data "template_file" "ad_names" {
  count    = length(data.oci_identity_availability_domains.ad.availability_domains)
  template = lookup(data.oci_identity_availability_domains.ad.availability_domains[count.index], "name")
}

resource "oci_core_route_table" "john_route_table" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.johnvcn.id

  display_name = "john_route_table"
  route_rules {
    network_entity_id = oci_core_internet_gateway.john_internet_gateways.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}
resource "oci_core_subnet" "publicsubnet" {
  cidr_block     = "10.0.0.0/24"
  display_name   = "publicsubnet"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.johnvcn.id
  dns_label      = "johnnydns"
  route_table_id = oci_core_route_table.john_route_table.id
  #   dhcp_options_id = oci_core_dhcp_options.johnDhcpOptions.id
  security_list_ids = [oci_core_security_list.johnsecuritylist.id]
}

resource "oci_core_security_list" "johnsecuritylist" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.johnvcn.id
  display_name   = "johnsecuritylist"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  dynamic "ingress_security_rules" {
    for_each = var.service_ports
    content {
      protocol = "6"
      source   = "0.0.0.0/0"
      tcp_options {
        max = ingress_security_rules.value
        min = ingress_security_rules.value
      }
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = var.VCN-CIDR
  }
}

resource "oci_core_instance" "bastion" {
  availability_domain = data.template_file.ad_names.*.rendered[0]
  compartment_id      = var.compartment_ocid
  shape               = var.shape

  source_details {
    source_id   = var.Images
    source_type = "image"
  }

  create_vnic_details {
    subnet_id = oci_core_subnet.publicsubnet.id
  }

  metadata = {
    ssh_authorized_keys = file(var.public_key_oci)
  }

  timeouts {
    create = "10m"
  }
}

variable "private_key_oci" {
  default = "/home/opc/credentials/id_rsa"
}
variable "public_key_oci" {
  default = "/home/opc/credentials/id_rsa.pub"
}

variable "VCN-CIDR" {
  default = "10.0.0.0/16"
}

variable "service_ports" {
  default = [80, 22, 443]
}

variable "compartment_ocid" {
  default = "ocid1.compartment.oc1..aaaaaaaapqytcu462c27feapv4bvf2ijszoqm7qmqjn4mx3koz3o5tjt5ska"
}

variable "availability_domain" {
  default = "US-SANJOSE-1-AD-1"
}

variable "shape" {
  default = "VM.Standard.E4.Flex"
}

variable "Images" {
  default = "ocid1.instance.oc1.us-sanjose-1.anzwuljrnlc5nbycqn4xi52z4lxxzhrodplw6ghgjkdu3kflf6ojbssor2iq"
}

output "webPublicIp" {
  value = oci_core_instance.bastion.public_ip
}