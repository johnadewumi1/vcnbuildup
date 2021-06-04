# terraform {
#   required_providers {
#     oci = {
#       source = "hashicorp/oci"
#     }
#   }
# }

# provider "oci" {
#   region           = "us-sanjose-1"
#   tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaajznex5attydtrmrgudwayqu7kn4krasw2ct4h4pwz7nwbfxoyd4q"
#   user_ocid        = "ocid1.user.oc1..aaaaaaaamrhp2f3m2evpmlme32kqavvgynxaz66oxfvrdephahsf72mwk6cq"
#   fingerprint      = "39:00:25:bf:cf:9b:00:70:87:f5:75:74:7b:71:b1:40"
#   private_key_path = "/home/opc/.oci/oci_api_key.pem"
# }


# resource "oci_core_vcn" "johnvcn" {
#   dns_label      = "internal"
#   cidr_block     = var.VCN-CIDR
#   compartment_id = var.compartment_ocid
#   display_name   = "johnvcn"
# }
# resource "oci_core_internet_gateway" "john_internet_gateways" {
#   #Required
#   compartment_id = var.compartment_ocid

#   #Optional
#   display_name = "john_internet_gateways"
#   vcn_id       = oci_core_vcn.johnvcn.id
# }
# data "oci_identity_availability_domains" "ad" {
#   compartment_id = var.compartment_ocid
# }
# data "template_file" "ad_names" {
#   count    = length(data.oci_identity_availability_domains.ad.availability_domains)
#   template = lookup(data.oci_identity_availability_domains.ad.availability_domains[count.index], "name")
# }

# resource "oci_core_route_table" "john_route_table" {
#   #Required
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_vcn.johnvcn.id

#   display_name = "john_route_table"
#   route_rules {
#     network_entity_id = oci_core_internet_gateway.john_internet_gateways.id
#     destination       = "0.0.0.0/0"
#     destination_type  = "CIDR_BLOCK"
#   }
# }
# resource "oci_core_subnet" "publicsubnet" {
#   cidr_block     = "10.0.0.0/24"
#   display_name   = "publicsubnet"
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_vcn.johnvcn.id
#   dns_label      = "johnnydns"
#   route_table_id = oci_core_route_table.john_route_table.id
#   #   dhcp_options_id = oci_core_dhcp_options.johnDhcpOptions.id
#   security_list_ids = [oci_core_security_list.johnsecuritylist.id]
# }

# resource "oci_core_security_list" "johnsecuritylist" {
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_vcn.johnvcn.id
#   display_name   = "johnsecuritylist"

#   egress_security_rules {
#     destination = "0.0.0.0/0"
#     protocol    = "6"
#   }

#   dynamic "ingress_security_rules" {
#     for_each = var.service_ports
#     content {
#       protocol = "6"
#       source   = "0.0.0.0/0"
#       tcp_options {
#         max = ingress_security_rules.value
#         min = ingress_security_rules.value
#       }
#     }
#   }
#   ingress_security_rules {
#     protocol = "6"
#     source   = var.VCN-CIDR
#   }
# }

# resource "oci_core_instance" "bastion" {
#   availability_domain = data.template_file.ad_names.*.rendered[0]
#   compartment_id      = var.compartment_ocid
#   shape               = var.shape

#   source_details {
#     source_id   = var.Images
#     source_type = "image"
#   }

#   create_vnic_details {
#     subnet_id = oci_core_subnet.publicsubnet.id
#   }

#   metadata = {
#     ssh_authorized_keys = file(var.public_key_oci)
#   }

#   timeouts {
#     create = "10m"
#   }
# }

# variable "private_key_oci" {
#   default = "/home/opc/credentials/id_rsa"
# }
# variable "public_key_oci" {
#   default = "/home/opc/credentials/id_rsa.pub"
# }

# variable "VCN-CIDR" {
#   default = "10.0.0.0/16"
# }

# variable "service_ports" {
#   default = [80, 22, 443]
# }

# variable "compartment_ocid" {
#   default = "ocid1.compartment.oc1..aaaaaaaapqytcu462c27feapv4bvf2ijszoqm7qmqjn4mx3koz3o5tjt5ska"
# }

# variable "availability_domain" {
#   default = "GrCh:US-SANJOSE-1-AD-1"
# }

# variable "shape" {
#   default = "VM.Standard.E3.Flex"
# }

# variable "Images" {
#   default = "ocid1.image.oc1.us-sanjose-1.aaaaaaaae56w5ardp5desrt2yqozgy2dxtajdjaareji22xzo5pt2dwozxgq"
# }

# output "webPublicIp" {
#   value = oci_core_instance.bastion.public_ip
# }

provider "oci" {
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
  user_ocid           = var.user_ocid
  fingerprint         = var.fingerprint
  private_key_path    = var.private_key_path
}

resource "oci_core_vcn" "dataSvcn" {
  dns_label      = "dataSvcn"
  cidr_block     = var.VCN-CIDR
  compartment_id = var.compartment
  display_name   = "dataSvcn"
}

resource "oci_core_dhcp_options" "dataSDhcpOptions1" {
  compartment_id = var.compartment
  vcn_id = oci_core_vcn.dataSvcn.id
  display_name = "dataSDhcpOptions"

  // required
  options {
    type = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

}

resource "oci_core_internet_gateway" "dataSInternetGateway" {
    compartment_id = var.compartment
    display_name = "dataSInternetGateway"
    vcn_id = oci_core_vcn.dataSvcn.id
}
resource "oci_core_route_table" "dataSRouteTableViaIGW" {
    compartment_id = var.compartment
    vcn_id = oci_core_vcn.dataSvcn.id
    display_name = "dataSRouteTableViaIGW"
    route_rules {
        destination = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        network_entity_id = oci_core_internet_gateway.dataSInternetGateway.id
    }
}

resource "oci_core_security_list" "dataSSecurityList" {
    compartment_id = var.compartment
    display_name = "dataSSecurityList"
    vcn_id = oci_core_vcn.dataSvcn.id

    egress_security_rules {
        protocol = "6"
        destination = "0.0.0.0/0"
    }

    dynamic "ingress_security_rules" {
    for_each = var.service_ports
    content {
        protocol = "6"
        source = "0.0.0.0/0"
        tcp_options {
            max = ingress_security_rules.value
            min = ingress_security_rules.value
            }
        }
    }

    ingress_security_rules {
        protocol = "6"
        source = var.VCN-CIDR
    }
}

resource "oci_core_subnet" "dataSWebSubnet" {
  cidr_block = var.Subnet-CIDR
  display_name = "dataSWebSubnet"
  dns_label = "dataSN1"
  compartment_id = var.compartment
  vcn_id = oci_core_vcn.dataSvcn.id
  route_table_id = oci_core_route_table.dataSRouteTableViaIGW.id
  dhcp_options_id = oci_core_dhcp_options.dataSDhcpOptions1.id
  security_list_ids = [oci_core_security_list.dataSSecurityList.id]
}
resource "oci_core_instance" "dataSWebserver1" {
  availability_domain = var.ADs
  compartment_id = var.compartment
  display_name = "dataSWebServer1"
  shape = var.Shape
  source_details {
     source_type = "image"
     source_id   = var.image
   }

  create_vnic_details {
     subnet_id = oci_core_subnet.dataSWebSubnet.id
     assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = "${file("${var.ssh_authorized_keys}")}"
  }
}

data "oci_core_vnic_attachments" "dataSWebserver1_VNIC1_attach"{
  availability_domain = var.ADs
  compartment_id = var.compartment
  instance_id = oci_core_instance.dataSWebserver1.id
}

variable "region" {
  default = "us-sanjose-1"
}
variable "tenancy_ocid" {
  default = "ocid1.tenancy.oc1..aaaaaaaajznex5attydtrmrgudwayqu7kn4krasw2ct4h4pwz7nwbfxoyd4q"
}
variable "user_ocid" {
  default = "ocid1.user.oc1..aaaaaaaamrhp2f3m2evpmlme32kqavvgynxaz66oxfvrdephahsf72mwk6cq"
}
variable "fingerprint" {
  default = "39:00:25:bf:cf:9b:00:70:87:f5:75:74:7b:71:b1:40"
}
variable "private_key_path" {
  default = "/home/opc/.oci/oci_api_key.pem"
}
variable "compartment" {
  default = "ocid1.compartment.oc1..aaaaaaaapqytcu462c27feapv4bvf2ijszoqm7qmqjn4mx3koz3o5tjt5ska"
}

variable "VCN-CIDR" {
  default = "10.0.0.0/16"
}

variable "Subnet-CIDR" {
  default = "10.0.1.0/24"
}
variable "ADs" {
  default = "GrCh:US-ASHBURN-AD-1"
}

variable "Shape" {
 default = "VM.Standard2.1"
}
variable "image" {
 default = "ocid1.image.oc1.iad.aaaaaaaaw2wavtqrd3ynbrzabcnrs77pinccp55j2gqitjrrj2vf65sqj5kq"
}

variable "FlexShapeOCPUS" {
    default = 1
}
variable "FlexShapeMemory" {
    default = 1
}

variable "instance_os" {
  default = "Oracle Linux"
}

variable "linux_os_version" {
  default = "7.9"
}

variable "service_ports" {
  default = [80,443,22]
}
variable "ssh_public_key" {
  default = ""
}
variable "ssh_authorized_keys" {
  default = "/home/opc/credentials/id_rsa.pub"
}

# Dictionary Locals=
locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex"
  ]
}
