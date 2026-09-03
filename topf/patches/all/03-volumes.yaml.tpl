# was talhelper `controlPlane.volumes`. The passphrase came from
# talenv.sops.yaml via envsubst; topf uses Go templates over `data`.
apiVersion: v1alpha1
kind: VolumeConfig
name: STATE
encryption:
  provider: luks2
  keys:
    - slot: 1
      nodeID: {}
---
apiVersion: v1alpha1
kind: VolumeConfig
name: EPHEMERAL
encryption:
  provider: luks2
  keys:
    - slot: 1
      static:
        passphrase: {{ .Data.diskEncryptionPassphrase }}
