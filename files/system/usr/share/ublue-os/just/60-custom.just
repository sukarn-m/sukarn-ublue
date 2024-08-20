# vim: set ft=make :
# This file can be modified downstream to add custom just commands

# Enable NFS caching
sukarn-enable-nfs-cache:
    #!/usr/bin/bash
    sudo mkdir -p /var/cache/fscache
    sudo restorecon -RF /var/cache/fscache
    sudo systemctl enable --now cachefilesd.service

# Remove NFS caching and cached files
sukarn-remove-nfs-cache:
    #!/usr/bin/bash
    sudo systemctl disable --now cachefilesd.service
    sudo rm -rf /var/cache/fscache

# Add Canon LBP2900B printer
sukarn-add-canon-lbp2900b:
    #!/usr/bin/bash
    sudo lpadmin -p 'LBP2900B' -v usb://Canon/LBP2900?serial=0000C1E62I7Z -P /usr/share/cups/model/CanonLBP-2900-3000.ppd -L 'Canon LBP2900B' -E

sukarn-enroll-fedora-certificate:
    #!/usr/bin/bash
    wget --output-document=/tmp/fedora-ca.cer https://src.fedoraproject.org/rpms/shim-unsigned-x64/blob/rawhide/f/fedora-ca-20200709.cer
    sudo mokutil --timeout -1
    sudo mokutil --import /tmp/fedora-ca.cer
    sudo systemctl reboot

sukarn-fix-grub-double-entry:
    #!/usr/bin/bash
    if [ -d /sys/firmware/efi ]; then
      sudo grub2-switch-to-blscfg
      sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
    else
      block_device=$(lsblk -spnlo name $(grub2-probe --target=device /boot/grub2) | tail -n1)
      sudo grub2-install $block_device
      sudo touch /boot/grub2/.grub2-blscfg-supported
      sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    fi

sukarn-grub-toggle-savedefault:
    #!/usr/bin/bash
    # Function to check if GRUB_SAVEDEFAULT= is present in /etc/default/grub
    function check_savedefault () {
      local line=$(grep "^GRUB_SAVEDEFAULT=" /etc/default/grub)
      if [ -n "$line" ]; then
        return 0 # Found the line
      else
        return 1 # Not found
      fi
    }
    # Function to get GRUB_SAVEDEFAULT value
    function get_savedefault_value () {
      local value=$(grep "^GRUB_SAVEDEFAULT=" /etc/default/grub | cut -d '=' -f2-)
      echo "$value"
    }
    # Function to regenerate grub if the value has changed
    function regenerate_grub () {
      if [ -d /sys/firmware/efi ]; then
        sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
      else
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg
      fi
    }
    if check_savedefault; then
      line_present="true"
    else
      line_present="false"
    fi
    # Ask user if they want to enable or disable GRUB_SAVEDEFAULT
    echo "${bold}Configure GRUB_SAVEDEFAULT${normal}"
    if check_savedefault; then
      current_value=$(get_savedefault_value) || current_value=""
      echo "${bold}Current setting: ${current_value}.${normal}  What would you like to do?"
    else
      echo "${bold}Current setting: Not set.${normal} What would you like to do?"
    fi
    OPTION=$(ugum choose "Nothing" "Enable" "Disable")
    # This is where the magic happens
    case $OPTION in
      Nothing)
        echo "Bye bye!"
        exit 0
        ;;
      Enable)
        if [[ ${current_value} == true ]] && [[ ${line_present} == true ]]; then
          echo "Nothing to do here."
          exit 0
        elif [[ ${current_value} == false ]] && [[ ${line_present} == true ]]; then
          echo "Changing from false to true"
          sudo sed -i 's/GRUB_SAVEDEFAULT=false/GRUB_SAVEDEFAULT=true/' /etc/default/grub
          regenerate_grub
          exit 0
        elif [[ ${line_present} == false ]]; then
          echo "Inserting true"
          sudo sed -i '$a GRUB_SAVEDEFAULT=true' /etc/default/grub
          regenerate_grub
          exit 0
        else
          echo "Error"
          exit 1
        fi
        ;;
      Disable)
        echo "Asked to disable"
        if [[ ${current_value} == false ]] && [[ ${line_present} == true ]]; then
          echo "Nothing to do here."
          exit 0
        elif [[ ${current_value} == true ]] && [[ ${line_present} == true ]]; then
          echo "Changing from true to false"
          sudo sed -i 's/GRUB_SAVEDEFAULT=true/GRUB_SAVEDEFAULT=false/' /etc/default/grub
          regenerate_grub
          exit 0
        elif [[ ${line_present} == false ]]; then
          echo "Inserting false"
          sudo sed -i '$a GRUB_SAVEDEFAULT=false' /etc/default/grub
          regenerate_grub
          exit 0
        else
          echo "Error"
          exit 1
        fi
        exit 0
        ;;
      *)
        echo "Error. Invalid option"
        exit 1
        ;;
    esac
