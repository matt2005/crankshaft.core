# Crankshaft Pi-Gen Stage Directory
#
# This is a custom pi-gen stage that installs Crankshaft on top of 
# Raspberry Pi OS Lite (stage2).
#
# Files:
# - EXPORT_NOHDIMG: Indicates this stage doesn't need a fresh rootfs
# - prerun.sh: Pre-stage setup
# - 00-install-crankshaft-stage00.sh: Main installation script
# - postrun.sh: Post-stage cleanup
#
# The stage installs:
# - Crankshaft infotainment system
# - Crankshaft UI
# - Extensions framework
# - APT repository configuration
# - First-boot setup service
