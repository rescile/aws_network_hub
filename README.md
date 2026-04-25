# AWS Network Transit Hub
A *Network Transit Hub* is a formalized, automated infrastructure subset designed to host specific cloud workloads under a governed security model. Unlike a standard VPC, which may lack inherent guardrails, a landing zone ensures that the network environment is pre-configured for compliance, centralized logging, and identity management before any external services are connected. This zone serves as the *administrative and technical boundary* where the cloud provider's network meets the Salesforce software-defined network.

## The Necessity of a Termination Point for Private IP
When utilizing private IP addressing for Salesforce integration, traffic does not traverse the public internet via standard HTTPS/TLS over an Internet Gateway. Instead, it utilizes *unroutable private IP addresses*. This shift necessitates a dedicated termination point within a transit hub for the following reasons:

### Network Address Translation (NAT) and Routing
Using a SaaS Provider in regulated industires often requires a *VPC Endpoint Interface* within a private subnet. This interface acts as the termination point. Without a landing zone to provide the underlying VPC structure, there is no logical location to assign the private IP addresses required for the two networks to "see" each other.

### Encapsulation of the Security Perimeter
A termination point allows for the application of *Micro-segmentation*. By terminating the connection in a controlled zone, organizations can apply *Stateful Firewalls* (Security Groups) and *Stateless Filters* (Network ACLs) directly to the endpoint. This ensures that if a resource within the cloud environment is compromised, the threat cannot move laterally into the Salesforce environment, as the landing zone acts as a strictly governed gateway.

### Resolution of Private DNS Namespaces
Public instances of services like Salesforce resolve to public IP addresses. When moving to a private connection, the system must resolve to a private IP within the VPC. The network transit hub provides the *Private DNS Zone* infrastructure. This infrastructure intercepts requests for the SaaS provider and redirects them to the private termination point, ensuring that data remains on the internal backbone.

### Auditability and Traffic Symmetrics
Regulatory frameworks (such as SOC2, HIPAA, or GDPR) often require proof of data transit paths. A ltransit hub provides a centralized point for *VPC Flow Logs*. This captures every packet entering or leaving the Salesforce connection. Without this formal termination point, traffic monitoring becomes fragmented, making it difficult to verify that data has remained off the public internet during a compliance audit.

## Technical Architecture

| Component | Technical Role | Necessity for Private IP |
| :--- | :--- | :--- |
| **VPC / VNet** | Logical isolation of resources. | Provides the private IP space for the connection. |
| **Interface Endpoint** | The physical/logical termination point. | Bridges the provider backbone to the SaaS account. |
| **Private DNS** | Authoritative internal name resolution. | Maps provider URLs to internal, private IPs. |
| **IAM & Guardrails** | Identity and Access Management. | Restricts who can modify the private connection. |

In summary, the Network Transit Hub is the prerequisite infrastructure that transforms a "cloud account" into a "secure node" capable of supporting private, non-internet-routable peering with the SaaS provider.
