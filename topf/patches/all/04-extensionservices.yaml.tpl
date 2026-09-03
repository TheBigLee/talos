apiVersion: v1alpha1
kind: ExtensionServiceConfig
name: tailscale
environment:
  - TS_AUTHKEY={{ .Data.tailscaleAuthKey }}
  - TS_EXTRA_ARGS=--login-server=https://headscale.bigli.io
