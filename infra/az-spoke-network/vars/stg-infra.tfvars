#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------

tags = {
  project       = "cob"
  env           = "stg-infra"
  provisionedby = "terraform"
}

admin_group_members = [
  "9099258b-5241-4ed5-a950-e1883aad28b4"
]

#------------------------------------------------------------------------------
# NETWORKING
#------------------------------------------------------------------------------

vnet_address_space = "192.168.0.0/16"
vnet_subnets = {
  "ClusterSubnet" = {
    name              = "ClusterSubnet"
    service_endpoints = ["Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
    address_prefixes  = ["192.168.0.0/20"]
    network_rules = [
    ]
    routes = [
    ]
  },
  "AppGtwSubnet" = {
    name              = "AppGtwSubnet"
    service_endpoints = ["Microsoft.KeyVault"]
    address_prefixes  = ["192.168.16.0/24"]
    network_rules = [
      {
        name                       = "Allow-Ephemeral-Ports-Inbound"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "65200-65535"
      },
      {
        name                       = "Allow-Ephemeral-Ports-Outbound"
        priority                   = 1002
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "65200-65535"
      }
    ]
    routes = [
    ]
  }
}
