# Terraform을 이용한 NCP 설정

## Terraform 설치

[Terraform 사이트](https://developer.hashicorp.com/terraform/install) 참조

## NCP 테라폼 문서

- 테라폼 사이트: https://terraform.io
  - Registry: https://registry.terraform.io
    - Browse Providers
      - "NaverCloudPlatform/ncloud" 검색
        - Documentation 선택
        - 소스: https://github.com/NaverCloudPlatform/terraform-provider-ncloud

## 테라폼 설정 코드

### `main.tf` 파일(필수)

#### 테라폼 프로바이더 및 접근 key 설정

```hcl
terraform {
  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = "3.3.1"
    }
  }
  required_version = ">= 0.13"
}

provider "ncloud" {
  access_key  = var.access_key
  secret_key  = var.secret_key
  region      = var.region
  site        = var.site
  support_vpc = var.support_vpc
}
```

#### VPC 생성

```hcl
resource "ncloud_vpc" "main_vpc" {
  name            = "main-vpc"
  ipv4_cidr_block = "10.0.0.0/16"
}
```

#### Network ACL 생성

- Network Web ACL 생성

```hcl
resource "ncloud_network_acl" "main_web_nacl" {
  vpc_no      = ncloud_vpc.main_vpc.id
  name        = "main-web-acl"
  description = "Web ACL"
}

resource "ncloud_network_acl_rule" "main_web_nacl_rule" {
  network_acl_no = ncloud_network_acl.main_web_nacl.id

  inbound {
    priority    = 15
    protocol    = "TCP"
    rule_action = "ALLOW"
    ip_block    = "10.0.0.0/16"
    port_range  = "1-65535"
  }

  inbound {
    priority    = 20
    protocol    = "TCP"
    rule_action = "ALLOW"
    ip_block    = "220.78.43.230/32"
    port_range  = "1-65535"
  }

  inbound {
    priority    = 199
    protocol    = "TCP"
    rule_action = "DROP"
    ip_block    = "0.0.0.0/0"
    port_range  = "22"
  }

  outbound {
    priority    = 0
    protocol    = "ICMP"
    rule_action = "ALLOW"
    ip_block    = "0.0.0.0/0"
  }

  outbound {
    priority    = 10
    protocol    = "TCP"
    rule_action = "ALLOW"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
  }

  outbound {
    priority    = 20
    protocol    = "UDP"
    rule_action = "ALLOW"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
  }
}
```

- Network Public Load Balancer ACL 생성

```hcl
resource "ncloud_network_acl" "main_public_lb_nacl" {
  vpc_no      = ncloud_vpc.main_vpc.id
  name        = "main-public-lb-acl"
  description = "Public Load Balancer ACL"
}

resource "ncloud_network_acl_rule" "main_public_lb_nacl_rule" {
  network_acl_no = ncloud_network_acl.main_public_lb_nacl.id

  inbound {
    priority    = 10
    protocol    = "TCP"
    rule_action = "ALLOW"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
  }

  outbound {
    priority    = 10
    protocol    = "TCP"
    rule_action = "ALLOW"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
  }

}
```

- Network Private Load Balancer ACL 생성

```hcl
resource "ncloud_network_acl" "main_private_lb_nacl" {
  vpc_no      = ncloud_vpc.main_vpc.id
  name        = "main-private-lb-acl"
  description = "Private Load Balancer ACL"
}

resource "ncloud_network_acl_rule" "main_private_lb_nacl_rule" {
  network_acl_no = ncloud_network_acl.main_private_lb_nacl.id

  inbound {
    priority    = 0
    protocol    = "ICMP"
    rule_action = "ALLOW"
    ip_block    = "0.0.0.0/0"
  }

  inbound {
    priority    = 10
    protocol    = "TCP"
    rule_action = "ALLOW"
    ip_block    = "10.0.0.0/16"
    port_range  = "1-65535"
  }

  inbound {
    priority    = 20
    protocol    = "UDP"
    rule_action = "ALLOW"
    ip_block    = "10.0.0.0/16"
    port_range  = "1-65535"
  }

  outbound {
    priority    = 0
    protocol    = "ICMP"
    rule_action = "ALLOW"
    ip_block    = "0.0.0.0/0"
  }

  outbound {
    priority    = 10
    protocol    = "TCP"
    rule_action = "ALLOW"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
  }

  outbound {
    priority    = 20
    protocol    = "UDP"
    rule_action = "ALLOW"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
  }
}
```

#### Subnet 생성

```hcl
resource "ncloud_subnet" "main_web_subnet" {
  vpc_no         = ncloud_vpc.main_vpc.id
  subnet         = "10.0.1.0/24"
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.main_web_nacl.id
  subnet_type    = "PUBLIC"
  usage_type     = "GEN"
  name           = "main-web-subnet"
}

resource "ncloud_subnet" "main_public_lb_subnet" {
  vpc_no         = ncloud_vpc.main_vpc.id
  subnet         = "10.0.255.0/24"
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.main_public_lb_nacl.id
  subnet_type    = "PUBLIC"
  usage_type     = "LOADB"
  name           = "main-public-lb-subnet"
}

resource "ncloud_subnet" "main_private_lb_subnet" {
  vpc_no         = ncloud_vpc.main_vpc.id
  subnet         = "10.0.6.0/24"
  zone           = "KR-2"
  network_acl_no = ncloud_network_acl.main_private_lb_nacl.id
  subnet_type    = "PRIVATE"
  usage_type     = "LOADB"
  name           = "main-private-lb-subnet"
}
```

#### ACG 생성

```hcl
resource "ncloud_access_control_group" "main_web_acg" {
  vpc_no      = ncloud_vpc.main_vpc.id
  name        = "main-web-acg"
  description = "Allow SSH, WEB"
}

resource "ncloud_access_control_group_rule" "main_web_acg_rule" {
  access_control_group_no = ncloud_access_control_group.main_web_acg.id

  inbound {
    protocol = "ICMP"
    ip_block = "0.0.0.0/0"
  }

  inbound {
    protocol    = "TCP"
    ip_block    = "220.78.43.230/32"
    port_range  = "22"
    description = "Allow SSH"
  }

  outbound {
    protocol    = "ICMP"
    ip_block    = "0.0.0.0/0"
    description = "Allow all outbound"
  }

  outbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
    description = "Allow all outbound"
  }

  outbound {
    protocol    = "UDP"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
    description = "Allow all outbound"
  }
}
```

#### Login Key 생성

서버나 쿠버네티스 노드에서 사용할 로그인 키 생성

```hcl
resource "ncloud_login_key" "loginkey" {
  key_name = var.login_key_name
}
```

#### 작업 호스트 생성

작업용 호스트를 생성한다.

- 호스트를 생성할 때 사용할 이미지를 찾는다.

```hcl
data "ncloud_server_image_numbers" "kvm-image" {
  server_image_name = "ubuntu-24.04"
  filter {
    name   = "hypervisor_type"
    values = ["KVM"]
  }
}
```

- 호스트의 사양을 찾는다.

```hcl
data "ncloud_server_specs" "kvm-spec" {
  filter {
    name   = "server_spec_code"
    values = ["c2-g3"]
  }
}
```

- 호스트를 생성한다.

```hcl
resource "ncloud_server" "main_server" {
  subnet_no                     = ncloud_subnet.main_web_subnet.id
  name                          = "main-server"
  server_image_number           = data.ncloud_server_image_numbers.kvm-image.image_number_list.0.server_image_number
  server_spec_code              = data.ncloud_server_specs.kvm-spec.server_spec_list.0.server_spec_code
  fee_system_type_code          = "MTRAT"
  is_protect_server_termination = false
  init_script_no                = null
  login_key_name                = ncloud_login_key.loginkey.key_name
}
```

#### 호스트에 public IP 할당

```hcl
resource "ncloud_public_ip" "main_server_public_ip" {
  server_instance_no = ncloud_server.main_server.id
}
```

#### Container Registry 용 Object Storage 버킷 생성

```hcl
resource "ncloud_objectstorage_bucket" "docker_image_bitcamp_teacher01" {
  bucket_name = "docker-image-bitcamp-teacher01"
}
```

#### SourceCommit 용 Object Storage 버킷 생성

```hcl
resource "ncloud_objectstorage_bucket" "source_commit_bitcamp_teacher01" {
  bucket_name = "source-commit-bitcamp-teacher01"
}
```

#### 쿠버네티스 설정

- Kubernetes Cluster 생성

```hcl
data "ncloud_nks_versions" "version" {
  hypervisor_code = "KVM"
  filter {
    name   = "value"
    values = ["1.32.3"]
    regex  = true
  }
}

resource "ncloud_nks_cluster" "cluster" {
  name                 = "k8s-20250521"
  hypervisor_code      = "KVM"
  cluster_type         = "SVR.VNKS.STAND.C002.M008.G003"
  k8s_version          = data.ncloud_nks_versions.version.versions.0.value
  kube_network_plugin  = "cilium"
  vpc_no               = ncloud_vpc.main_vpc.id
  zone                 = "KR-2"
  public_network       = true
  subnet_no_list       = [ncloud_subnet.main_web_subnet.id]
  lb_private_subnet_no = ncloud_subnet.main_private_lb_subnet.id
  lb_public_subnet_no  = ncloud_subnet.main_public_lb_subnet.id
  log {
    audit = true
  }
  login_key_name = ncloud_login_key.loginkey.key_name
}
```

- 노드에 사용할 호스트 이미지와 사양을 찾는다.

```hcl
data "ncloud_nks_server_images" "image" {
  hypervisor_code = "KVM"
  filter {
    name   = "label"
    values = ["ubuntu-22.04"]
    regex  = true
  }
}

data "ncloud_nks_server_products" "product" {
  software_code = data.ncloud_nks_server_images.image.images[0].value
  zone          = "KR-2"

  filter {
    name   = "product_type"
    values = ["STAND"]
  }

  filter {
    name   = "cpu_count"
    values = ["2"]
  }

  filter {
    name   = "memory_size"
    values = ["8GB"]
  }
}
```

- 노드풀을 생성한다.

```hcl
resource "ncloud_nks_node_pool" "default_pool" {
  cluster_uuid     = ncloud_nks_cluster.cluster.uuid
  node_pool_name   = "default-pool"
  node_count       = 1
  software_code    = data.ncloud_nks_server_images.image.images[0].value
  server_spec_code = data.ncloud_nks_server_products.product.products.0.value
  storage_size     = 100
  autoscale {
    enabled = false
    min     = 2
    max     = 2
  }
}
```

### `veriables.tf` 파일(선택)

설정 파일에서 사용하는 변수 선언

```hcl
variable "access_key" {
  description = "Naver Cloud Access Key"
  type        = string
}

variable "secret_key" {
  description = "Naver Cloud Secret Key"
  type        = string
}

variable "region" {
  description = "Region to deploy resources"
  type        = string
  default     = "KR" # 한국 리전
}

variable "site" {
  description = "Naver Cloud API Site"
  type        = string
  default     = "public"
}

variable "support_vpc" {
  description = "Whether to use VPC environment"
  type        = bool
  default     = true
}

variable "login_key_name" {
  description = "Name of the SSH login key registered in NCP"
  type        = string
}
```

### `terraform.tfvars` 파일(선택)

변수의 값을 지정. git으로 공유하지 말아야 한다.

```hcl
access_key     = ""
secret_key     = ""
region         = "KR"
site           = "public"
support_vpc    = true
login_key_name = "main-key"
```

### `outputs.tf` 파일(선택)

출력을 정의.

```hcl
output "vpc_id" {
  value = ncloud_vpc.main_vpc.id
}

output "main_key_private_key" {
  value     = ncloud_login_key.loginkey.private_key
  sensitive = true
}
```

### 테라폼 실행

```bash
terraform init      # 초기화 (provider 설치 등)
terraform plan      # 실행 계획 미리보기
terraform apply     # 실제 인프라 생성
terraform destroy   # 생성한 인프라 삭제
```

## 테라폼 수행 완료 후 작업

### `loginkey` 키를 `.pem` 파일로 저장

```bash
terraform output -raw main_key_private_key > main-key.pem
chmod 400 main-key.pem
```

### 작업 호스트의 ACG 변경

- 호스트의 ACG를 `main-web-acg` 로 변경한다.
  - VPC / Server / main-server 선택
    - ACG 수정

### 작업 호스트에 사용자 등록

- 호스트에 root로 접속하여, 원격 접속용으로 사용자를 추가한다.

```bash
# 사용자를 생성한다.
adduser bitcamp

# 사용자에게 sudo 권한 부여하기 위해 편집기를 띄운다.
visudo
```

```bash
# 편집기에서 다음 항목 추가
bitcamp ALL=(ALL) ALL
```

### Container Registry 생성

도커 이미지를 저장할 저장소를 생성한다. 테라폼으로 생성할 수 없기 때문에 콘솔 웹 화면에서 직접 작업해야 한다.

- services> Containers> Container Registry > 레지스트리 생성
- 레지스트리 이름 : k8s-edu-(내가원하는영문자or숫자)
- 버킷 : `docker-image-xxx` 로 시작하는 위에서 만든 버킷 선택
- ‘생성’ 버튼 클릭
