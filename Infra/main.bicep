targetScope = 'resourceGroup'

@description('Azure Region')
param location string = resourceGroup().location

// Existing VM Private IPs
var vm1PrivateIp = '172.16.0.4'
var vm2PrivateIp = '172.16.0.5'

var appGatewayName = 'application-gateway'

// ---------------------------------------
// Existing Virtual Network
// ---------------------------------------

resource vnet 'Microsoft.Network/virtualNetworks@2025-01-01' existing = {
  name: 'vnet-indiasouthcentral-1'
}

// ---------------------------------------
// Public IP for Application Gateway
// ---------------------------------------

resource publicIP 'Microsoft.Network/publicIPAddresses@2025-01-01' = {
  name: 'appgw-public-ip'
  location: location

  sku: {
    name: 'Standard'
  }

  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// ---------------------------------------
// Web Application Firewall Policy
// ---------------------------------------

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-01-01' = {
  name: 'WAF-Policy'
  location: location

  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: true
    }

    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.2'
        }
      ]
    }
  }
}

// ---------------------------------------
// Azure Application Gateway (WAF_v2)
// ---------------------------------------

resource appGateway 'Microsoft.Network/applicationGateways@2025-07-01' = {
  name: appGatewayName
  location: location

  sku: {
    name: 'WAF_v2'
    tier: 'WAF_v2'
  }

  properties: {

    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 2
    }

    firewallPolicy: {
      id: wafPolicy.id
    }

    gatewayIPConfigurations: [
      {
        name: 'gatewayConfig'
        properties: {
          subnet: {
            id: resourceId(
              'Microsoft.Network/virtualNetworks/subnets',
              vnet.name,
              'snet-indiasouthcentral-1'
            )
          }
        }
      }
    ]

    frontendIPConfigurations: [
      {
        name: 'frontendIP'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]

    frontendPorts: [
      {
        name: 'httpPort'
        properties: {
          port: 80
        }
      }
    ]

    backendAddressPools: [
      {
        name: 'VM-APP-1-Pool'
        properties: {
          backendAddresses: [
            {
              ipAddress: vm1PrivateIp
            }
          ]
        }
      }

      {
        name: 'VM-APP-2-Pool'
        properties: {
          backendAddresses: [
            {
              ipAddress: vm2PrivateIp
            }
          ]
        }
      }
    ]

    probes: [
      {
        name: 'healthProbe'
        properties: {
          protocol: 'Http'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3

          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]

    backendHttpSettingsCollection: [
      {
        name: 'backendHttpSettings'
        properties: {
          protocol: 'Http'
          port: 80
          requestTimeout: 30
          cookieBasedAffinity: 'Disabled'

          probe: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/probes',
              appGatewayName,
              'healthProbe'
            )
          }
        }
      }
    ]

    httpListeners: [
      {
        name: 'listener'
        properties: {
          protocol: 'Http'

          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              appGatewayName,
              'frontendIP'
            )
          }

          frontendPort: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendPorts',
              appGatewayName,
              'httpPort'
            )
          }
        }
      }
    ]

    urlPathMaps: [
      {
        name: 'PathMap'

        properties: {
          defaultBackendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              appGatewayName,
              'VM-APP-1-Pool'
            )
          }

          defaultBackendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              appGatewayName,
              'backendHttpSettings'
            )
          }

          pathRules: [
            {
              name: 'VMAPP1'

              properties: {
                paths: [
                  '/app1/*'
                ]

                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    appGatewayName,
                    'VM-APP-1-Pool'
                  )
                }

                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    appGatewayName,
                    'backendHttpSettings'
                  )
                }
              }
            }

            {
              name: 'VMAPP2'

              properties: {
                paths: [
                  '/app2/*'
                ]

                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    appGatewayName,
                    'VM-APP-2-Pool'
                  )
                }

                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    appGatewayName,
                    'backendHttpSettings'
                  )
                }
              }
            }
          ]
        }
      }
    ]

    requestRoutingRules: [
      {
        name: 'PathRoutingRule'

        properties: {
          ruleType: 'PathBasedRouting'
          priority: 100

          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              appGatewayName,
              'listener'
            )
          }

          urlPathMap: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/urlPathMaps',
              appGatewayName,
              'PathMap'
            )
          }
        }
      }
    ]
  }

  dependsOn: [
    publicIP
    wafPolicy
  ]
}

// ---------------------------------------
// Outputs
// ---------------------------------------

output gatewayName string = appGateway.name
output publicIPAddress string = publicIP.properties.ipAddress
output app1Url string = 'http://${publicIP.properties.ipAddress}/app1/'
output app2Url string = 'http://${publicIP.properties.ipAddress}/app2/'
