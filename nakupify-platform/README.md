
## Deployment

First install OLMv1 with [guide](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/install/install.md). 
Needed for [Keycloak operator](https://www.keycloak.org/operator/installation) (maybe look into [this](https://artifacthub.io/packages/olm/community-operators/keycloak-operator) helm chart for it) which installs Keycloak CRDs into the cluster.

It looks like the CRDs need to be installed manually by following this [link](https://www.keycloak.org/operator/installation#_installing_by_using_kubectl_without_operator_lifecycle_manager)