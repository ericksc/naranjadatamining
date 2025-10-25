#!/usr/bin/env bash
set -e

# ========================
# Variables
# ========================
USER_NAME="orange"
USER_PASS="orange"
HOME_DIR="/home/${USER_NAME}"
CONDA_DIR="${HOME_DIR}/.conda"
VNC_COL_DEPTH=24
VNC_RESOLUTION="1920x1080"
VNC_PW="orange"

# ========================
# System Update & Packages
# ========================
sudo apt-get update
sudo apt-get install -y python3-pip python3-dev python3-virtualenv bzip2 g++ git sudo \
                        xfce4-terminal software-properties-common python3-numpy wget

# ========================
# Install Firefox ESR
# ========================
sudo rm -f /usr/share/xfce4/helpers/debian-sensible-browser.desktop || true
sudo add-apt-repository --yes ppa:mozillateam/ppa
sudo apt-get update
sudo apt-get remove -y --purge firefox || true
sudo apt-get install -y firefox-esr

# ========================
# Create user and set password
# ========================
if id "${USER_NAME}" &>/dev/null; then
    echo "User ${USER_NAME} already exists."
else
    sudo useradd -m -s /bin/bash "${USER_NAME}"
    echo "${USER_NAME}:${USER_PASS}" | sudo chpasswd
    sudo usermod -aG sudo "${USER_NAME}"
fi

# ========================
# Install Miniconda
# ========================
sudo -u "${USER_NAME}" bash <<EOF
cd "${HOME_DIR}"
wget -q -O miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash miniconda.sh -b -p "${CONDA_DIR}"
rm miniconda.sh
EOF

# ========================
# Create Conda environment
# ========================
sudo -u "${USER_NAME}" bash <<EOF
source "${CONDA_DIR}/bin/activate"
"${CONDA_DIR}/bin/conda" create -y -n orange3 python=3.12
source "${CONDA_DIR}/bin/activate" orange3
"${CONDA_DIR}/bin/conda" install -y -c conda-forge \
    pyqt orange3 Orange3-Text Orange3-ImageAnalytics sqlalchemy \
    pymysql psycopg2-binary pyodbc
echo 'export PATH=${CONDA_DIR}/bin:\$PATH' >> "${HOME_DIR}/.bashrc"
EOF

# ========================
# Copy icons, configs, and launchers (requires local directories)
# ========================
sudo mkdir -p /usr/share/backgrounds/images
sudo cp ./icons/orange.png /usr/share/backgrounds/images/orange.png || true
sudo -u "${USER_NAME}" mkdir -p "${CONDA_DIR}/share/orange3"
sudo -u "${USER_NAME}" cp ./icons/orange.png "${CONDA_DIR}/share/orange3/orange.png" || true
sudo -u "${USER_NAME}" mkdir -p "${HOME_DIR}/Desktop"
sudo -u "${USER_NAME}" cp ./orange/orange-canvas.desktop "${HOME_DIR}/Desktop/orange-canvas.desktop" || true
sudo -u "${USER_NAME}" mkdir -p "${HOME_DIR}/.config/xfce4"
sudo -u "${USER_NAME}" cp -r ./config/xfce4/* "${HOME_DIR}/.config/xfce4/" || true
sudo -u "${USER_NAME}" mkdir -p "${HOME_DIR}/install"
sudo -u "${USER_NAME}" cp ./install/chromium-wrapper "${HOME_DIR}/install/chromium-wrapper" || true

# ========================
# Ownership and Permissions
# ========================
sudo chown -R "${USER_NAME}:${USER_NAME}" "${HOME_DIR}/.config" "${HOME_DIR}/Desktop" "${HOME_DIR}/install"

# ========================
# Add VNC configuration
# ========================
sudo mkdir -p /dockerstartup
sudo cp ./install/add-geometry.sh /dockerstartup/add-resolution.sh
sudo chmod +x /dockerstartup/add-resolution.sh

# ========================
# External settings folder
# ========================
sudo -u "${USER_NAME}" mkdir -p "${HOME_DIR}/.config/biolab.si"

# ========================
# Copy VNC startup script
# ========================
sudo -u "${USER_NAME}" cp /headless/wm_startup.sh "${HOME_DIR}" 2>/dev/null || true

# ========================
# Final Message
# ========================
echo "=============================================================="
echo " Orange3 environment setup complete!"
echo " User: ${USER_NAME}"
echo " Password: ${USER_PASS}"
echo " Conda env: orange3"
echo " VNC: ${VNC_RESOLUTION} depth ${VNC_COL_DEPTH}"
echo "=============================================================="
