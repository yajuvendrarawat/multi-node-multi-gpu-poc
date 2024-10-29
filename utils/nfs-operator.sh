git clone git@github.com:Jooho/nfs-provisioner-operator.git /var/tmp/nfs-provisioner-operator
kustomize build /var/tmp/nfs-provisioner-operator/config/default/ |oc create -f -
