variable "passphrase" {
  # Change passphrase to be at least 16 characters long:
  default   = "changeme!"
  sensitive = true
}

terraform {
  encryption {
    #    method "unencrypted" "migrate" {}

    ## Step 1: Add the desired key provider:
    key_provider "pbkdf2" "pbkdf2_provider" {
      passphrase = var.passphrase
    }
    ## Step 2: Set up your encryption method:
    method "aes_gcm" "encrypt_tf_state" {
      keys = key_provider.pbkdf2.pbkdf2_provider
    }

    state {
      ## Step 3: Link the desired encryption method:
      method = method.aes_gcm.encrypt_tf_state

      ## Step 4: Run "tofu apply".

      ## Step 5: Consider adding the "enforced" option:
      enforced = true
      #fallback {
      #  method = method.unencrypted.migrate
      #}
    }

    ## Step 6: Repeat steps 3-5 for plan{} if needed.
    plan {
      ## Step 3: Link the desired encryption method:
      method = method.aes_gcm.encrypt_tf_state

      ## Step 4: Run "tofu apply".

      ## Step 5: Consider adding the "enforced" option:
      enforced = true
      #fallback {
      #  method = method.unencrypted.migrate
      #}
    }
  }
}

