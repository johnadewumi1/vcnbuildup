resource "null_resource" "webHTTPD" {
  depends_on = [oci_core_instance.dataSWebserver2]
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = "data.oci_core_vnic.dataSWebserver2_vnic.public_ip_address"
      private_key = file(var.private_key_oci)
      script_path = "/home/opc/.oci/oci_api_key.pem"
      agent       = false
      timeout     = "10m"
    }
    inline = ["echo '== 1. installing HTTPD package with yum'",
      "sudo -u root yum -y -q install httpd",

      "echo '== 2. Creating /var/www/html/index.html'",
      "sudo -u root touch /var/www/html/index.html",
      "sudo /bin/su -c \"echo 'welcome to John server1! Your home...' > /var/www/html/index.html\"",

      "echo '== 3. Disabling firewal and strting HTTPD service'",
      "sudo -u root service firewall stop",
    "sudo -u root service httpd start"]
  }
}