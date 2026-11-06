variable "vpc_cidr" {
  default = "192.168.0.0/19"
}

variable "env" {
  default = "Dev"
}

variable "public_subnet_cidrs" {
  default = [
    "192.168.2.0/23",
    "192.168.4.0/23"
  ]
}
