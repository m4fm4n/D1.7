resource "null_resource" "docker-swarm-manager" {
  count = var.managers
  depends_on = [yandex_compute_instance.vm-manager]
  connection {
    user        = var.ssh_credentials.user
    private_key = file(var.ssh_credentials.private_key)
    host        = yandex_compute_instance.vm-manager[count.index].network_interface.0.nat_ip_address
  }

  provisioner "file" {
    source      = "~/module_d/D1/D1.7/docker-stack.yml"
    destination = "/home/${var.ssh_credentials.user}/docker-stack.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com | sh",
      "sudo usermod -aG docker $USER",
      "sudo apt install -y docker-compose",
      "sudo docker swarm init",
      "sleep 10",
      "echo COMPLETED"
    ]
  }
}


resource "null_resource" "docker-swarm-manager-join" {
  count = var.managers
  depends_on = [yandex_compute_instance.vm-manager, null_resource.docker-swarm-manager]
  connection {
    user        = var.ssh_credentials.user
    private_key = file(var.ssh_credentials.private_key)
    host        = yandex_compute_instance.vm-manager[count.index].network_interface.0.nat_ip_address
  }


  provisioner "local-exec" {
    command = "TOKEN=$(ssh -i ${var.ssh_credentials.private_key} -o StrictHostKeyChecking=no ${var.ssh_credentials.user}@${yandex_compute_instance.vm-manager[count.index].network_interface.0.nat_ip_address} docker swarm join-token -q worker); echo '#!/usr/bin/bash\nsudo docker swarm join --token '$TOKEN' ${yandex_compute_instance.vm-manager[count.index].network_interface.0.nat_ip_address}:2377\nexit 0' > join.sh"

  }
}

resource "null_resource" "docker-swarm-worker" {
  count = var.workers
  depends_on = [yandex_compute_instance.vm-worker, null_resource.docker-swarm-manager-join]
  connection {
    user        = var.ssh_credentials.user
    private_key = file(var.ssh_credentials.private_key)
    host        = yandex_compute_instance.vm-worker[count.index].network_interface.0.nat_ip_address
  }

  provisioner "file" {
    source      = "~/module_d/D1/D1.7/join.sh"
    destination = "/home/${var.ssh_credentials.user}/join.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com | sh",
      "sudo usermod -aG docker $USER",
      "sleep 10",
      "chmod +x /home/${var.ssh_credentials.user}/join.sh",
      "/home/${var.ssh_credentials.user}/join.sh",
      "echo JOIN COMPLETED"
    ]
  }
}


resource "null_resource" "docker-swarm-manager-start" {
  depends_on = [yandex_compute_instance.vm-manager, null_resource.docker-swarm-manager-join, null_resource.docker-swarm-worker]
  connection {
    user        = var.ssh_credentials.user
    private_key = file(var.ssh_credentials.private_key)
    host        = yandex_compute_instance.vm-manager[0].network_interface.0.nat_ip_address
  }

  provisioner "remote-exec" {
    inline = [
        "docker stack deploy -c /home/${var.ssh_credentials.user}/docker-stack.yml sockshop-swarm"
    ]
  }

  provisioner "local-exec" {
    command = "rm ~/module_d/D1/D1.7/join.sh"
  }
}

