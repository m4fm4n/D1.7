terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~>0.65.0"
    }
  }

/*  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "<your_bucket_name>"
    region     = "ru-central1"
    key        = "<your_path>"
    access_key = "<your_access_key>"
    secret_key = "<your_secret_key>"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
*/
}

provider "yandex" {
  service_account_key_file = file("<your_path>/key.json")
  cloud_id                 = "<your_cloud_id>"
  folder_id                = "<your_folder_id>"
  zone      = "ru-central1-a"
}


resource "yandex_vpc_network" "network" {
  name = "swarm-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

module "swarm_cluster" {
  source        = "./modules/instance"
  vpc_subnet_id = yandex_vpc_subnet.subnet.id
  managers      = 1
  workers       = 2
}
