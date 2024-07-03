#!/bin/bash

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-drivers
# sudo apt install -y cuda-toolkit-12-5
# sudo apt install -y cudnn
# sudo sed -E 's;PATH="?(.+)";PATH="/usr/local/cuda/bin:\1";g' -i /etc/environment

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo sed -i 's/^#no-cgroups = false/no-cgroups = true/;' /etc/nvidia-container-runtime/config.toml

# sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
cat <<END | sudo tee /usr/local/bin/cdi.sh
#!/bin/bash

if [ ! -f /etc/cdi/nvidia.yaml ]; then
  nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
fi

crontab -u root -r
rm -- \$0
END
sudo chmod +x /usr/local/bin/cdi.sh
(sudo crontab -u root -l 2>/dev/null || true; echo "@reboot sleep 60; /usr/local/bin/cdi.sh") | sudo crontab -u root -

sudo mkdir -p /usr/share/containers/oci/hooks.d
cat <<EOF | sudo tee /usr/share/containers/oci/hooks.d/oci-nvidia-hook.json
{
    "version": "1.0.0",
    "hook": {
        "path": "/usr/bin/nvidia-container-toolkit",
        "args": ["nvidia-container-toolkit", "prestart"],
        "env": [
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        ]
    },
    "when": {
        "always": true,
        "commands": [".*"]
    },
    "stages": ["prestart"]
}
EOF
