

resource "oci_core_instance" "dataSWebserver1" {
  availability_domain = var.ADs
  compartment_id      = var.compartment
  display_name        = "dataSWebServer1"
  shape               = var.Shape
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
data "oci_core_vnic" "dataSWebserver1_vnic" {
  vnic_id = data.oci_core_vnic_attachments.dataSWebserver1_VNIC1_attach.vnic_attachments.0.vnic_id
}


output "webPublicIp" {
  //  value = oci_core_instance.web.public_ip
  value = [data.oci_core_vnic.dataSWebserver1_vnic.public_ip_address]

}