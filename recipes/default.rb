#
# Cookbook Name:: audit-osx
# Recipe:: default
#

users = AuditOSX.users

# Suggested Controls from CIS Benchmarks OS X 10.10
control_group '1 Install Updates, Patches and Additional Security Software' do
  control '1.1 Verify all application software is current' do
    it 'Software Updates Current/No Pending Updates' do
      expect(command('/usr/sbin/softwareupdate -l').stdout).to match(/(No new software available.)/)
    end
  end
end

control_group '2 System Preferences' do
  context '2.1 Bluetooth' do
    control '2.1.2 Disable Bluetooth "Discoverable" mode when not pairing devices' do
      it 'Bluetooth Not Discoverable' do
        expect(command('/usr/sbin/system_profiler SPBluetoothDataType | grep  -i discoverable').stdout).to match(/Discoverable: Off/)
      end
    end

    control '2.1.3 Show Bluetooth status in menu bar' do
      it 'Shows Bluetooth Status For Visibility' do
        users.each do |user|
          expect(command("/usr/bin/defaults read /Users/#{user}/Library/Preferences/com.apple.systemuiserver.plist | grep Bluetooth.menu").exit_status).to eq 0
        end
      end
    end
  end

  context '2.4 Sharing' do
    control '2.4.1 Disable Remote Apple Events' do
      it 'Remote Apple Events Disabled' do
        expect(command('/usr/sbin/systemsetup -getremoteappleevents').stdout).to match(/Remote Apple Events: Off/)
      end
    end

    control '2.4.2 Disable Internet Sharing' do
      it 'Internet Sharing Not Setup' do
        expect(command('/usr/bin/defaults read /Library/Preferences/SystemConfiguration/com.apple.nat | grep -i Enabled').exit_status).to eq(1)
      end
    end

    control '2.4.3 Disable Screen Sharing' do
      it 'Screen Sharing Disabled' do
        expect(command('launchctl load /System/Library/LaunchDaemons/com.apple.screensharing.plist').stdout).to match(/Service is disabled/)
      end
    end

    control '2.4.5 Disable Remote Login' do
      it 'Remote Login Disabled For Non-Servers' do
        expect(command('systemsetup -getremotelogin').stdout).to match(/Remote Login: Off/)
      end
    end

    control '2.4.7 Disable Bluetooth Sharing' do
      it 'Bluetooth Sharing Not Enabled' do
        users.each do |user|
          expect(command("/usr/bin/sudo -u #{user} /usr/sbin/system_profiler SPBluetoothDataType | grep Enabled").exit_status).to_not eq(0)
        end
      end
    end

    control '2.4.8 Disable File Sharing' do
      it 'Apple File Sharing Disabled' do
        expect(command('launchctl list | egrep AppleFileServer').exit_status).to_not eq(0)
      end
    end

    control '2.4.9 Disable Remote Management' do
      it 'Remote Managemen/Apple Remote Desktop Agent Not Running' do
        expect(command('ps -ef | grep -v egrep | egrep ARDAgent').exit_status).to_not eq(0)
      end
    end
  end

  context '2.6 Security & Privacy' do
    control '2.6.1 Enable FileVault' do
      let(:file_vault) { command('fdesetup status') }

      it 'FileVault Enabled' do
        expect(file_vault.stdout).to match(/FileVault is On/)
      end
    end

    control '2.6.2 Enable Gatekeeper' do
      it 'Gatekeeper Enabled' do
        expect(command('spctl --status').stdout).to match(/assessments enabled/)
      end
    end

    control '2.6.3 Enable Firewall' do
      it 'Firewall Enabled' do
        expect(command('/usr/bin/defaults read /Library/Preferences/com.apple.alf globalstate').stdout).to match(/1/)
      end
    end

    control '2.6.4 Enable Firewall Stealth Mode' do
      it 'Stealth Mode Enabled' do
        expect(command('/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode').stdout).to match(/Stealth mode enabled/)
      end
    end
  end

  control '2.9 Enable Secure Keyboard Entry in terminal.app' do
    it 'Terminal Secure Keyboard Enabled' do
      users.each do |user|
        expect(command("/usr/bin/sudo -u #{user} defaults read -app Terminal SecureKeyboardEntry").stdout).to match(/1/)
      end
    end
  end

  control '2.10 Java 6 is not the default Java runtime' do
    let(:java_version) { command('java -version').stdout }

    it 'Default Java Version Is Not 6' do
      expect(java_version).to_not match(/(1.6.0_)/)
    end
  end

  control '2.11 Configure Secure Empty Trash' do
    it 'Secure Empty Trash Enabled' do
      users.each do |user|
        expect(command("/usr/bin/defaults read /Users/#{user}/Library/Preferences/com.apple.finder EmptyTrashSecurely").stdout.to_i).to eq(1)
      end
    end
  end
end

control_group '4 Network Configurations' do
  control '4.1 Enable "Show WiFi status in menu bar"' do
    it 'Show WiFi Status In Menu Bar Enabled' do
      expect(command('/usr/bin/defaults read com.apple.systemuiserver menuExtras | grep AirPort.menu').exit_status).to eq(1)
    end
  end

  control '4.3 Ensure http server is not running' do
    it 'Apache Web Server Not Running' do
      expect(command('ps -ef | grep -v grep | grep -i httpd').exit_status).to eq(1)
    end
  end

  control '4.4 Ensure ftp server is not running' do
    it 'FTP Server Not Running' do
      expect(command('launchctl list | egrep ftp').exit_status).to eq(1)
    end
  end

  control '4.5 Ensure nfs server is not running' do
    it 'NFS Server Not Running' do
      expect(command('ps -ef | grep -v grep | grep -i nfsd').exit_status).to eq(1)
    end

    it 'NFS /etc/export Directory Does Not Exist' do
      expect(file('/etc/exports')).to_not be_directory
    end
  end
end

control_group '5 System Access, Authentication and Authorization' do
  control '5.7 Disable automatic login' do
    it 'Automatic Login Not Enabled' do
      expect(command('defaults read /Library/Preferences/com.apple.loginwindow | grep autoLoginUser').exit_status).to eq(1)
    end
  end

  control '5.8 Require a password to wake the computer from sleep or screen saver' do
    it 'Screensaver/Wake From Sleep Password Required' do
      users.each do |user|
        expect(command("/usr/bin/sudo -u #{user} defaults read com.apple.screensaver askForPassword").stdout.to_i).to eq(1)
      end
    end
  end
end

control_group '6 User Accounts and Environment' do
  context '6.1 Accounts Preferences Action Items' do
    control '6.1.1 Display login window as name and password' do
      it 'Login Window Requires Name and Password' do
        expect(command('defaults read /Library/Preferences/com.apple.loginwindow SHOWFULLNAME').stdout.to_i).to eq(1)
      end
    end

    control '6.1.3 Disable guest account login' do
      it 'Guest Account Login Disabled' do
        expect(command('defaults read /Library/Preferences/com.apple.loginwindow.plist GuestEnabled').stdout.to_i).to eq(0)
      end
    end

    control '6.1.4 Disable "Allow guests to connect to shared folders"' do
      it 'AFP Sharing for Guests Disabled' do
        expect(command("defaults read /Library/Preferences/com.apple.AppleFileServer | grep 'guestAccess = 1'").exit_status).to eq(1)
      end

      it 'SMB Sharing for Guests Disabled' do
        expect(command('defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server | grep -i guest').stdout).to match(/(AllowGuestAccess = 0)/)
      end
    end

    control '6.2 Turn on filename extension' do
      it 'Show Filename Extensions Enabled' do
        users.each do |user|
          expect(command("/usr/bin/sudo -u #{user} defaults read NSGlobalDomain AppleShowAllExtensions").stdout.to_i).to eq(1)
        end
      end
    end

    control '6.3 Disable the automatic run of safe files in Safari' do
      it 'Safari Automatic Run Safe Files Disabled' do
        users.each do |user|
          expect(command("/usr/bin/sudo -u #{user} defaults read com.apple.Safari AutoOpenSafeDownloads").stdout.to_i).to eq(0)
        end
      end
    end
  end
end
