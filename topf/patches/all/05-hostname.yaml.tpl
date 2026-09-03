# topf defaults to `auto: stable`, which lets Talos derive the hostname from
# node identity. talhelper pinned it explicitly, and the running nodes are
# already named talos-cp1/2/3 - letting it change would rename the Node
# objects. Pin it to the host from topf.yaml.
apiVersion: v1alpha1
kind: HostnameConfig
auto: "off"
hostname: {{ .Node.Host }}
