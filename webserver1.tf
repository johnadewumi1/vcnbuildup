

resource "oci_core_instance" "dataSWebserver1" {
  availability_domain = var.ADs
  compartment_id      = var.compartment
  display_name        = "dataSWebServer1"
  shape               = var.Shape
  fault_domain        = "FAULT-DOMAIN-1"
  source_details {
    source_type = "image"
    source_id   = var.image
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.dataSWebSubnet.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_authorized_keys)
  }
}

data "oci_core_vnic_attachments" "dataSWebserver1_VNIC1_attach" {
  availability_domain = var.ADs
  compartment_id      = var.compartment
  instance_id         = oci_core_instance.dataSWebserver1.id
}
